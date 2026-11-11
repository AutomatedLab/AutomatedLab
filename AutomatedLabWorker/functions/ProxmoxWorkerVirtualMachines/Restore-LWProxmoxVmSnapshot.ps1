function Restore-LWProxmoxVmSnapshot
{
    <#
    .SYNOPSIS
        Restores Proxmox virtual machines to a previous snapshot.

    .DESCRIPTION
        Rolls each Proxmox VM in ComputerName back to the snapshot '<VM name>_<SnapshotName>' that AutomatedLab
        created. The lab machines among them that are running are stopped first and started again afterwards.

        When a rollback task fails, the VM is rolled back again, at most ProxmoxSnapshotRollbackRetries more
        times (default 2) and ProxmoxSnapshotRollbackRetryDelaySeconds apart (default 20). Before each new
        attempt the VM is read afresh from the cluster: a running VM is stopped, and a lock in the VM
        configuration, for example 'rollback', gets at most one more delay period to clear. A lock that stays
        ends the attempts for this VM, because the Proxmox API cannot remove it. A task that ends with
        'WARNINGS: <n>' counts as a successful rollback only when the VM is stopped and not locked afterwards.

        All VMs are processed before a failure is reported. A VM whose rollback failed is not started again.
        The function then throws one terminating error with the error id ProxmoxSnapshotRollbackFailed that
        lists every failed VM with its VMID, node, task UPID and the text of the Proxmox task.

        A rollback request that the Proxmox API does not answer with status 200 still ends the function at
        once. A VM without the snapshot is skipped with a warning and started again if it was running.

    .PARAMETER ComputerName
        The names of the Proxmox VMs to restore, which are the resource names of the lab machines.

    .PARAMETER SnapshotName
        The name of the snapshot to restore to, without the prefix '<VM name>_'. Must not contain spaces.

    .EXAMPLE
        Restore-LWProxmoxVmSnapshot -ComputerName DC01 -SnapshotName BeforeSchemaUpdate

        Restores the DC01 VM to the BeforeSchemaUpdate snapshot

    .EXAMPLE
        Restore-LWProxmoxVmSnapshot -ComputerName DC01,SQL01 -SnapshotName BeforePatching

        Restores multiple VMs to the same snapshot
    #>
    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [ValidatePattern('^\S+$')]
        [string]$SnapshotName
    )

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    Write-LogFunctionEntry

    $lab = Get-Lab

    # No -Default: Get-LabConfigurationItem would turn a configured 0 into the default.
    $rollbackRetries = 2
    $configuredRetries = Get-LabConfigurationItem -Name ProxmoxSnapshotRollbackRetries
    if (-not [string]::IsNullOrEmpty([string]$configuredRetries))
    {
        $rollbackRetries = [Math]::Max(0, [int]$configuredRetries)
    }

    $retryDelaySeconds = 20
    $configuredDelay = Get-LabConfigurationItem -Name ProxmoxSnapshotRollbackRetryDelaySeconds
    if (-not [string]::IsNullOrEmpty([string]$configuredDelay))
    {
        $retryDelaySeconds = [Math]::Max(0, [int]$configuredDelay)
    }

    $taskTimeoutInSeconds = 600
    $values = @{
        status = 'stopped'
    }

    # After a failed rollback the session cache no longer tells the status or the lock of a VM.
    $getVmState = {
        param
        (
            [string]$Name
        )

        try
        {
            $liveVm = @(Get-LWProxmoxVM -ComputerName $Name -NoCache -ErrorAction Stop)[0]
            $vmConfig = @(Get-LWProxmoxVMConfig -ComputerName $Name -NoCache -ErrorAction Stop)[0]
            [pscustomobject]@{
                Status = [string]$liveVm.status
                Lock   = [string]$vmConfig.lock
                Error  = ''
            }
        }
        catch
        {
            [pscustomobject]@{
                Status = 'unknown'
                Lock   = ''
                Error  = $_.Exception.Message
            }
        }
    }

    $runningMachines = Get-LabVM -IsRunning -ComputerName $ComputerName -IncludeLinux
    if ($runningMachines)
    {
        Stop-LabVM -ComputerName $runningMachines -Wait
    }

    $vms = Get-LWProxmoxVM -ComputerName $ComputerName
    $failures = [ordered]@{}

    foreach ($machine in $ComputerName)
    {
        $vm = $vms | Where-Object Name -eq $machine
        $vmSnapshotName = '{0}_{1}' -f $machine, $SnapshotName
        if (-not $vm)
        {
            Write-ScreenInfo -Message "$machine could not be found in $($resourceGroupName). Skipping snapshot." -type Warning
            continue
        }

        $snapshot = Get-LWProxmoxVmSnapshot -ComputerName $machine -SnapshotName $SnapshotName -ErrorAction SilentlyContinue
        if (-not $snapshot)
        {
            Write-ScreenInfo -Message "No snapshot named $SnapshotName found for $machine. Skipping restore." -Type Warning
            continue
        }

        $attempts = $rollbackRetries + 1
        $failure = ''
        for ($attempt = 1; $attempt -le $attempts; $attempt++)
        {
            if ($attempt -gt 1)
            {
                Start-Sleep -Seconds $retryDelaySeconds

                # A lock gets at most one more delay period to clear, because the Proxmox API cannot remove it.
                $vmState = & $getVmState -Name $machine
                $lockWaitSeconds = 0
                while ($vmState.Lock -and $lockWaitSeconds -lt $retryDelaySeconds)
                {
                    $pollSeconds = [Math]::Min(5, $retryDelaySeconds - $lockWaitSeconds)
                    Start-Sleep -Seconds $pollSeconds
                    $lockWaitSeconds += $pollSeconds
                    $vmState = & $getVmState -Name $machine
                }

                if ($vmState.Lock)
                {
                    $failure += " The VM is still locked ('$($vmState.Lock)') after another $lockWaitSeconds seconds, so it was not rolled back again. Check the VM and its task log on node '$($vm.node)' before you remove the lock with 'qm unlock $($vm.VmId)'."
                    break
                }

                if ($vmState.Status -ne 'stopped' -and -not $vmState.Error)
                {
                    Write-ScreenInfo -Message "Stopping Proxmox machine '$machine' (status '$($vmState.Status)') before it is rolled back again." -Type Warning
                    $stopResult = Invoke-LWProxmoxCallWithRetry -ActivityName "Stop VM '$machine'" -ScriptBlock { Stop-PveVm -VmIdOrName $vm.VmId }
                    $stopText = "$($stopResult.StatusCode) $($stopResult.ReasonPhrase)"
                    if ($stopResult.StatusCode -eq 200)
                    {
                        $stopTaskResult = Wait-LWProxmoxTasksStatus -Upid $stopResult.Response.data -Node $vm.node -DesiredValues $values -TimeoutInSeconds $taskTimeoutInSeconds
                        $stopText = ConvertTo-LWProxmoxTaskResultText -TaskResult $stopTaskResult -TimeoutInSeconds $taskTimeoutInSeconds
                    }

                    $vmState = & $getVmState -Name $machine
                    if ($vmState.Status -ne 'stopped' -and -not $vmState.Error)
                    {
                        $failure += " It was not rolled back again because it could not be stopped: the stop ended with '$stopText' and the VM status is '$($vmState.Status)'."
                        break
                    }
                }

                if ($vmState.Error)
                {
                    $failure += " It was not rolled back again because the VM could not be read: $($vmState.Error)"
                    break
                }
            }

            $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Restore snapshot '$SnapshotName' for VM '$machine'" -ScriptBlock { Undo-PveVmSnapshot -VmIdOrName $vm.VmId -Snapname $vmSnapshotName }
            if ($result.StatusCode -ne 200)
            {
                Write-Error "Could not restore snapshot '$SnapshotName' for Proxmox machine '$machine': The error was '$($result.StatusCode)'" -ErrorAction Stop
            }

            $upid = $result.Response.data
            $taskResult = Wait-LWProxmoxTasksStatus -Upid $upid -Node $vm.node -DesiredValues $values -TimeoutInSeconds $taskTimeoutInSeconds
            $taskText = ConvertTo-LWProxmoxTaskResultText -TaskResult $taskResult -TimeoutInSeconds $taskTimeoutInSeconds
            if ($taskText -eq 'OK')
            {
                $failure = ''
                break
            }

            # As for a start, task warnings count only by the state that the rollback left behind.
            $vmState = & $getVmState -Name $machine
            if ($taskText -like 'WARNINGS:*' -and $vmState.Status -eq 'stopped' -and -not $vmState.Lock)
            {
                Write-ScreenInfo -Message "The rollback of Proxmox machine '$machine' to snapshot '$SnapshotName' ended with '$taskText'. The VM is stopped and not locked, so the snapshot counts as restored." -Type Warning
                $failure = ''
                break
            }

            $failure = "Proxmox machine '$machine' (VMID $($vm.VmId), node '$($vm.node)'), snapshot '$SnapshotName', attempt $attempt of $($attempts): the task '$upid' ended with '$taskText'."
            if ($vmState.Error)
            {
                $failure += " The VM could not be read afterwards: $($vmState.Error)"
            }
            else
            {
                if ($vmState.Lock)
                {
                    $failure += " The VM is locked ('$($vmState.Lock)')."
                }

                if ($vmState.Status -ne 'stopped')
                {
                    $failure += " The VM status is '$($vmState.Status)'."
                }
            }

            if ($attempt -lt $attempts)
            {
                Write-ScreenInfo -Message "$failure Rolling it back again in $retryDelaySeconds seconds." -Type Warning
            }
        }

        if ($failure)
        {
            $failures[$machine] = $failure
            Write-ScreenInfo -Message "$failure The VM is not started." -Type Error
        }
    }

    if ($runningMachines)
    {
        # A VM whose rollback failed may be locked or only partly rolled back, so it must not be used.
        $machinesToStart = @($runningMachines | Where-Object { $_.ResourceName -notin $failures.Keys })
        if ($machinesToStart.Count -gt 0)
        {
            Start-LabVM -ComputerName $machinesToStart -Wait
        }
    }

    Write-LogFunctionExit

    if ($failures.Count -gt 0)
    {
        $message = "Could not restore snapshot '$SnapshotName' for $($failures.Count) of $($ComputerName.Count) Proxmox machine(s). They were not started:"
        $message = (@($message) + @($failures.Values)) -join [Environment]::NewLine
        Write-Error -Message $message -ErrorId 'ProxmoxSnapshotRollbackFailed' -Category InvalidResult -TargetObject @($failures.Keys) -ErrorAction Stop
    }
}
