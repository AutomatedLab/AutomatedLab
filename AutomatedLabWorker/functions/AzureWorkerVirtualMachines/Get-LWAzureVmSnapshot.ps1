function Get-LWAzureVmSnapshot
{
    param
    (
        [Parameter()]
        [Alias('VMName')]
        [string[]]
        $ComputerName,

        [Parameter()]
        [Alias('Name')]
        [string]
        $SnapshotName
    )

    Test-LabHostConnected -Throw -Quiet

    $snapshots = Get-AzSnapshot -ResourceGroupName (Get-LabAzureDefaultResourceGroup).Name -ErrorAction SilentlyContinue

    if ($SnapshotName)
    {
        $snapshots = $snapshots | Where-Object { ($_.Name -split '_')[1] -eq $SnapshotName }
    }

    if ($ComputerName)
    {
        $snapshots = $snapshots | Where-Object { ($_.Name -split '_')[0] -in $ComputerName }
    }

    $snapshots.ForEach({
            [AutomatedLab.Snapshot]::new(($_.Name -split '_')[1], ($_.Name -split '_')[0], $_.TimeCreated)
        })
}
