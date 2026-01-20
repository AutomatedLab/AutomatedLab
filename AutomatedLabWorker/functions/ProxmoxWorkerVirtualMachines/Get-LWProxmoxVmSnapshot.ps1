function Get-LWProxmoxVmSnapshot {
    param
    (
        [Parameter()]
        [Alias('VMName')]
        [string[]]
        $ComputerName,

        [Parameter()]
        [string]
        $SnapshotName
    )

    $vms = Get-LWProxmoxVM -Name $ComputerName

    $snapshots = foreach ($vm in $vms) {
        (Get-PveNodesQemuSnapshot -Node $proxmoxNode -Vmid $vm.VmId).Response.data | Where-Object name -ne current
    }

    $snapshots = $snapshots | Where-Object { $_.Name -like '*_*' }

    if ($SnapshotName) {
        $snapshots = $snapshots | Where-Object {
            $nameElements = $_.Name -split '_'
            $name = $nameElements[1..($nameElements.Length - 1)] -join '_'
            $name -eq $SnapshotName
        }
    }

    $snapshots.ForEach({
            $creationTime = [DateTimeOffset]::FromUnixTimeSeconds($_.snaptime).DateTime
            $nameElements = $_.Name -split '_'
            [AutomatedLab.Snapshot]::new($nameElements[1..($nameElements.Length - 1)] -join '_', $nameElements[0], $creationTime)
        })
}
