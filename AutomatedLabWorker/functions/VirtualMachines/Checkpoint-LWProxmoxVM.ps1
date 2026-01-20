function Checkpoint-LWProxmoxVM {
    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [ValidatePattern('^\S+$')]
        [string]$SnapshotName
    )

    Write-LogFunctionEntry

    $lab = Get-Lab

    $jobs = foreach ($machine in $ComputerName) {
        $vm = Get-LWProxmoxVM -Name $machine -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-ScreenInfo -Message "Proxmox VM '$machine' could not be found. Skipping snapshot." -Type Warning
            continue
        }

        $existingSnapshot = Get-LWProxmoxVmSnapshot -ComputerName $machine -SnapshotName $SnapshotName
        if ($existingSnapshot) {
            Write-ScreenInfo -Message "Snapshot '$SnapshotName' for '$machine' already exists as '$($existingSnapshot.SnapshotName)'. Not creating it again." -Type Warning
            continue
        }

        $vmSnapshotName = '{0}_{1}' -f $machine, $SnapshotName
        $result = New-PveNodesQemuSnapshot -Node $global:proxmoxNode -Description 'Created by AutomatedLab' -Snapname $vmSnapshotName -Vmid $vm.VmId
        if ($result.StatusCode -ne 200) {
            Write-Error "Could not create snapshot '$SnapshotName' for Proxmox machine '$machine': The error was '$($result.StatusCode)'" -ErrorAction Stop
        }
        $values = @{
            status = 'stopped'
        }
        $taskResult = Wait-LWProxmoxTasksStatus -Upid $result.Response.data -DesiredValues $values -TimeoutInSeconds 600
        if ($taskResult -ne 'OK') {
            Write-Error -Message "Failed to create snapshot '$SnapshotName' for Proxmox machine '$machine'. Task did not complete successfully with the error '$taskResult'." -TargetObject $machine
        }
    }

    Write-LogFunctionExit
}
