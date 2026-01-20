function Remove-LWProxmoxVMSnapshot
{
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory, ParameterSetName = 'BySnapshotName')]
        [Parameter(Mandatory, ParameterSetName = 'AllSnapshots')]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'BySnapshotName')]
        [ValidatePattern('^\S+$')]
        [string]$SnapshotName,

        [Parameter(ParameterSetName = 'AllSnapshots')]
        [switch]$All
    )

    Write-LogFunctionEntry

    $vms = if ($ComputerName)
    {
        Get-LWProxmoxVM -Name $ComputerName
    }
    else
    {
        Get-LWProxmoxVM -Name (Get-LabVM)
    }

    foreach ($vm in $vms)
    {
        if ($SnapshotName)
        {
            $snapshots = Get-LWProxmoxVmSnapshot -ComputerName $vm.Name -SnapshotName $SnapshotName
            if (-not $snapshots)
            {
                Write-ScreenInfo -Message "Snapshot '$SnapshotName' for '$($vm.Name)' does not exist. Skipping removal." -Type Warning
                continue
            }
        }
        else
        {
            $snapshots = Get-LWProxmoxVmSnapshot -ComputerName $vm.Name
            if (-not $snapshots)
            {
                Write-ScreenInfo -Message "No snapshots found for '$($vm.Name)'. Skipping removal." -Type Warning
                continue
            }
        }

        foreach ($snapshot in $snapshots)
        {
            Write-PSFMessage -Message "Removing snapshot '$($snapshot.Name)' for VM '$($vm.Name)'" -Level Verbose
            $vmSnapshotName = '{0}_{1}' -f $vm.Name, $snapshot.SnapshotName
            $result = Remove-PveNodesQemuSnapshot -Node $vm.node -Vmid $vm.VmId -Snapname $vmSnapshotName
            if ($result.StatusCode -ne 200)
            {
                Write-Error "Could not remove snapshot '$($snapshot.Name)' for Proxmox machine '$($vm.Name)': The error was '$($result.StatusCode)'"
            }

            $values = @{
                status = 'stopped'
            }
            $taskResult = Wait-LWProxmoxTasksStatus -Upid $result.Response.data -Node $vm.node -DesiredValues $values -TimeoutInSeconds 600

            if ($taskResult -ne 'OK')
            {
                Write-Error -Message "Failed to remove snapshot '$($snapshot.Name)' for Proxmox machine '$($vm.Name)'. Task did not complete successfully with the error '$taskResult'." -TargetObject $snapshot
            }
        }
    }

    Write-LogFunctionExit

}
