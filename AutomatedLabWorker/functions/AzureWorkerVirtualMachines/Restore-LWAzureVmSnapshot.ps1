function Restore-LWAzureVmSnapshot
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

    $vms = Get-AzVM -ResourceGroupName $resourceGroupName | Where-Object Name -In $ComputerName
    $machineStatus = @{}
    $ComputerName.ForEach( { $machineStatus[$_] = @{ Stage1 = $null; Stage2 = $null; Stage3 = $null } })

    foreach ($machine in $ComputerName)
    {
        $vm = $vms | Where-Object Name -eq $machine
        $vmSnapshotName = '{0}_{1}' -f $machine, $SnapshotName
        if (-not $vm)
        {
            Write-ScreenInfo -Message "$machine could not be found in $($resourceGroupName). Skipping snapshot." -type Warning
            continue
        }

        $snapshot = Get-AzSnapshot -SnapshotName $vmSnapshotName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
        if (-not $snapshot)
        {
            Write-ScreenInfo -Message "No snapshot named $vmSnapshotName found for $machine. Skipping restore." -Type Warning
            continue
        }

        $osDiskName = $vm.StorageProfile.OsDisk.name
        $oldOsDisk = Get-AzDisk -Name $osDiskName -ResourceGroupName $resourceGroupName
        $disksToRemove += $oldOsDisk.Name
        $storageType = $oldOsDisk.sku.name
        $diskconf = New-AzDiskConfig -AccountType $storagetype -Location $oldOsdisk.Location -SourceResourceId $snapshot.Id -CreateOption Copy

        $machineStatus[$machine].Stage1 = @{
            VM      = $vm
            OldDisk = $oldOsDisk.Name
            Job     = New-AzDisk -Disk $diskconf -ResourceGroupName $resourceGroupName -DiskName "$($vm.Name)-$((New-Guid).ToString())" -AsJob
        }
    }

    if ($machineStatus.Values.Stage1.Job)
    {
        $null = $machineStatus.Values.Stage1.Job | Wait-Job
    }

    $failedStage1 = $($machineStatus.GetEnumerator() | Where-Object -FilterScript { $_.Value.Stage1.Job.State -eq 'Failed' }).Name
    if ($failedStage1) { Write-ScreenInfo -Type Error -Message "The following machines failed to create a new disk from the snapshot: $($failedStage1 -join ',')" }

    $ComputerName = $($machineStatus.GetEnumerator() | Where-Object -FilterScript { $_.Value.Stage1.Job.State -eq 'Completed' }).Name

    foreach ($machine in $ComputerName)
    {
        $vm = $vms | Where-Object Name -eq $machine
        $newDisk = $machineStatus[$machine].Stage1.Job | Receive-Job -Keep
        $null = Set-AzVMOSDisk -VM $vm -ManagedDiskId $newDisk.Id -Name $newDisk.Name
        $machineStatus[$machine].Stage2 = @{
            Job = Update-AzVM -ResourceGroupName $resourceGroupName -VM $vm -AsJob
        }
    }

    if ($machineStatus.Values.Stage2.Job)
    {
        $null = $machineStatus.Values.Stage2.Job | Wait-Job
    }

    $failedStage2 = $($machineStatus.GetEnumerator() | Where-Object -FilterScript { $_.Value.Stage2.Job.State -eq 'Failed' }).Name
    if ($failedStage2) { Write-ScreenInfo -Type Error -Message "The following machines failed to update with the new OS disk created from a snapshot: $($failedStage2 -join ',')" }

    $ComputerName = $($machineStatus.GetEnumerator() | Where-Object -FilterScript { $_.Value.Stage2.Job.State -eq 'Completed' }).Name

    foreach ($machine in $ComputerName)
    {
        $disk = $machineStatus[$machine].Stage1.OldDisk
        $machineStatus[$machine].Stage3 = @{
            Job = Remove-AzDisk -ResourceGroupName $resourceGroupName -DiskName $disk -Confirm:$false -Force -AsJob
        }
    }
    if ($machineStatus.Values.Stage3.Job)
    {
        $null = $machineStatus.Values.Stage3.Job | Wait-Job
    }

    $failedStage3 = $($machineStatus.GetEnumerator() | Where-Object -FilterScript { $_.Value.Stage3.Job.State -eq 'Failed' }).Name
    if ($failedStage3)
    {
        $failedDisks = $failedStage3.ForEach( { $machineStatus[$_].Stage1.OldDisk })
        Write-ScreenInfo -Type Warning -Message "The following machines failed to remove their old OS disk in a background job: $($failedStage3 -join ','). Trying to remove the disks again synchronously."

        foreach ($machine in $failedStage3)
        {
            $disk = $machineStatus[$machine].Stage1.OldDisk
            $null = Remove-AzDisk -ResourceGroupName $resourceGroupName -DiskName $disk -Confirm:$false -Force
        }
    }

    if ($runningMachines)
    {
        Start-LWAzureVM -ComputerName $runningMachines
        Wait-LabVM -ComputerName $runningMachines
    }

    if ($machineStatus.Values.Values.Job)
    {
        $machineStatus.Values.Values.Job | Remove-Job
    }

    Write-LogFunctionExit
}
