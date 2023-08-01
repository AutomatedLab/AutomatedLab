function Checkpoint-LWAzureVM
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string]$SnapshotName
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $lab = Get-Lab
    $resourceGroupName = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
    $runningMachines = Get-LabVM -IsRunning -ComputerName $ComputerName -IncludeLinux
    if ($runningMachines)
    {
        Stop-LWAzureVM -ComputerName $runningMachines -StayProvisioned $true
        Wait-LabVMShutdown -ComputerName $runningMachines
    }

    $jobs = foreach ($machine in $ComputerName)
    {
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $machine -ErrorAction SilentlyContinue
        if (-not $vm)
        {
            Write-ScreenInfo -Message "$machine could not be found in $($resourceGroupName). Skipping snapshot." -type Warning
            continue
        }

        $vmSnapshotName = '{0}_{1}' -f $machine, $SnapshotName
        $existingSnapshot = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmSnapshotName -ErrorAction SilentlyContinue
        if ($existingSnapshot)
        {
            Write-ScreenInfo -Message "Snapshot $SnapshotName for $machine already exists as $($existingSnapshot.Name). Not creating it again." -Type Warning
            continue
        }

        $osSourceDisk = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $vm.StorageProfile.OsDisk.Name
        $snapshotConfig = New-AzSnapshotConfig -SourceUri $osSourceDisk.Id -CreateOption Copy -Location $vm.Location
        New-AzSnapshot -Snapshot $snapshotConfig -SnapshotName $vmSnapshotName -ResourceGroupName $resourceGroupName -AsJob
    }

    if ($jobs.State -contains 'Failed')
    {
        Write-ScreenInfo -Type Error -Message "At least one snapshot creation failed: $($jobs.Name -join ',')."
        $skipRemove = $true
    }

    if ($jobs)
    {
        $null = $jobs | Wait-Job
        $jobs | Remove-Job
    }

    if ($runningMachines)
    {
        Start-LWAzureVM -ComputerName $runningMachines
        Wait-LabVM -ComputerName $runningMachines
    }

    Write-LogFunctionExit
}
