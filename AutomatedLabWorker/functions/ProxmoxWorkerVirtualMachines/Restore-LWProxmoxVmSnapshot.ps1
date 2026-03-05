function Restore-LWProxmoxVmSnapshot
{
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

    $runningMachines = Get-LabVM -IsRunning -ComputerName $ComputerName -IncludeLinux
    if ($runningMachines)
    {
        Stop-LabVM -ComputerName $runningMachines -Wait
    }

    $vms = Get-LWProxmoxVM -ComputerName $ComputerName
    $machineStatus = @{}

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

        $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Restore snapshot '$SnapshotName' for VM '$machine'" -ScriptBlock { Undo-PveVmSnapshot -VmIdOrName $vm.VmId -Snapname $vmSnapshotName }
        if ($result.StatusCode -ne 200)
        {
            Write-Error "Could not restore snapshot '$SnapshotName' for Proxmox machine '$machine': The error was '$($result.StatusCode)'" -ErrorAction Stop
        }

        $values = @{
            status = 'stopped'
        }
        $result = Wait-LWProxmoxTasksStatus -Upid $result.Response.data -Node $vm.node -DesiredValues $values -TimeoutInSeconds 600
        if ($result -ne 'OK')
        {
            Write-Error "Failed to restore snapshot '$SnapshotName' for Proxmox machine '$machine': $($result.Message)"
            continue
        }
    }

    if ($runningMachines)
    {
        Start-LabVM -ComputerName $runningMachines -Wait
    }

    Write-LogFunctionExit
}
