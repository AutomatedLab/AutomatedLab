function Wait-LWProxmoxRestartVM {
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [switch]$DoNotUseCredSsp,

        [double]$TimeoutInMinutes = 15,

        [int]$ProgressIndicator,

        [switch]$NoNewLine,

        [datetime]
        $MonitoringStartTime = (Get-Date),

        [System.Management.Automation.Job[]]$MonitorJob,

        [AutomatedLab.Machine[]]$StartMachinesWhileWaiting
    )

    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Write-LogFunctionEntry

    $start = (Get-Date)

    Write-PSFMessage -Message "Starting monitoring the servers at '$start'"

    $machines = Get-LabVM -ComputerName $ComputerName

    # Track initial state - mark all machines as not yet stopped
    $machines | Add-Member -Name HasStopped -MemberType NoteProperty -Value $false -Force

    $ProgressIndicatorTimer = (Get-Date)

    # Phase 1: Use Proxmox API to detect when each VM has stopped (rebooting).
    # This avoids relying on WinRM which is unavailable during reboot and whose
    # disconnected-session auto-reconnection can cause cascading errors.
    do {
        if (((Get-Date) - $ProgressIndicatorTimer).TotalSeconds -ge $ProgressIndicator) {
            Write-ProgressIndicator
            $ProgressIndicatorTimer = (Get-Date)
        }

        # Check MonitorJob for failures (mirrors HyperV handler behavior)
        if ($MonitorJob) {
            foreach ($job in $MonitorJob) {
                if ($job.State -eq 'Failed') {
                    $result = $job | Receive-Job -ErrorVariable jobError

                    $criticalError = $jobError | Where-Object { $_.Exception.Message -like 'AL_CRITICAL*' }
                    if ($criticalError) { throw $criticalError.Exception }

                    $nonCriticalErrors = $jobError | Where-Object { $_.Exception.Message -like 'AL_ERROR*' }
                    foreach ($nonCriticalError in $nonCriticalErrors) {
                        Write-PSFMessage "There was a non-critical error in job $($job.ID) '$($job.Name)' with the message: '($nonCriticalError.Exception.Message)'"
                    }
                }
            }
        }

        # Start additional machines while waiting (mirrors HyperV handler behavior)
        if ($StartMachinesWhileWaiting) {
            Start-LabVM -ComputerName $StartMachinesWhileWaiting[0] -NoNewline:$NoNewLine
            $StartMachinesWhileWaiting = $StartMachinesWhileWaiting | Where-Object { $_ -ne $StartMachinesWhileWaiting[0] }
        }

        $vmStatus = Get-LWProxmoxVMStatus -ComputerName $ComputerName -ErrorAction SilentlyContinue

        foreach ($machine in $machines) {
            if ($machine.HasStopped) { continue }

            $status = if ($vmStatus) { $vmStatus[$machine.Name] } else { $null }
            if ($status -eq 'Stopped') {
                Write-PSFMessage -Message "VM '$($machine.Name)' has stopped (reboot in progress)"
                $machine.HasStopped = $true
            }
        }

        if (($machines | Where-Object { -not $_.HasStopped }).Count -gt 0) {
            Start-Sleep -Seconds 5
        }
    }
    until (($machines | Where-Object { -not $_.HasStopped }).Count -eq 0 -or (Get-Date).AddMinutes(-$TimeoutInMinutes) -gt $start)

    if (($machines | Where-Object { -not $_.HasStopped }).Count -gt 0) {
        Write-PSFMessage -Message "Not all machines stopped within timeout. Proceeding to wait for them to come back online."
    }
    else {
        Write-PSFMessage -Message "All machines have stopped: ($($machines.Name -join ', '))"
    }

    # Phase 2: Wait for the VMs to come back online via WinRM (same as HyperV handler).
    # By this point, the original job sessions should have been cleaned up or timed out,
    # so we can safely poll via WinRM without interference.
    $remainingMinutes = [math]::Max(1, $TimeoutInMinutes - ((Get-Date) - $start).TotalMinutes)
    Wait-LabVM -ComputerName $ComputerName -ProgressIndicator $ProgressIndicator -TimeoutInMinutes $remainingMinutes -DoNotUseCredSsp:$DoNotUseCredSsp -NoNewLine:$NoNewLine

    if (-not $NoNewLine) {
        Write-ProgressIndicatorEnd
    }

    if ((Get-Date).AddMinutes(-$TimeoutInMinutes) -gt $start) {
        foreach ($machine in $machines) {
            Write-Error -Message "Timeout while waiting for computers to restart. Computers '$($machine.Name)' not restarted" -TargetObject $machine.Name
        }
    }

    Write-PSFMessage -Message "Finished monitoring the servers at '$(Get-Date)'"

    Write-LogFunctionExit
}
