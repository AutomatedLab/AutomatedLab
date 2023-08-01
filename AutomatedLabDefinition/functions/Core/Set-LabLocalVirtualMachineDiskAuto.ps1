function Set-LabLocalVirtualMachineDiskAuto
{
    [CmdletBinding()]
    param
    (
        [int64]
        $SpaceNeeded
    )

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.LocalDisk
    $drives = New-Object $type

    #read the cache
    try
    {
        if ($IsLinux -or $IsMacOs)
        {
            $cachedDrives = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/LocalDisks.xml'))
        }
        else
        {
            $cachedDrives = $type::ImportFromRegistry('Cache', 'LocalDisks')
        }
        Write-PSFMessage "Read $($cachedDrives.Count) drive infos from the cache"
    }
    catch
    {
        Write-PSFMessage 'Could not read info from the cache'
    }

    #Retrieve drives with enough space for placement of VMs
    foreach ($drive in (Get-LabVolumesOnPhysicalDisks | Where-Object FreeSpace -ge $SpaceNeeded))
    {
        $drives.Add($drive)
    }

    if (-not $drives)
    {
        return $false
    }

    #if the current disk config is different from the is in the cache, wait until the running lab deployment is done.
    if ($cachedDrives -and (Compare-Object -ReferenceObject $drives.DriveLetter -DifferenceObject $cachedDrives.DriveLetter))
    {
        $labDiskDeploymentInProgressPath = Get-LabConfigurationItem -Name DiskDeploymentInProgressPath
        if (Test-Path -Path $labDiskDeploymentInProgressPath)
        {
            Write-ScreenInfo "Another lab disk deployment seems to be in progress. If this is not correct, please delete the file '$labDiskDeploymentInProgressPath'." -Type Warning
            Write-ScreenInfo "Waiting with 'Get-DiskSpeed' until other disk deployment is finished. Otherwise a mounted virtual disk could be chosen for deployment." -NoNewLine
            do
            {
                Write-ScreenInfo -Message . -NoNewLine
                Start-Sleep -Seconds 15
            } while (Test-Path -Path $labDiskDeploymentInProgressPath)
        }
        Write-ScreenInfo 'done'

        #refresh the list of drives with enough space for placement of VMs
        $drives.Clear()
        foreach ($drive in (Get-LabVolumesOnPhysicalDisks | Where-Object FreeSpace -ge $SpaceNeeded))
        {
            $drives.Add($drive)
        }

        if (-not $drives)
        {
            return $false
        }
    }

    Write-Debug -Message "Drive letters placed on physical drives: $($drives.DriveLetter -Join ', ')"
    foreach ($drive in $drives)
    {
        Write-Debug -Message "Drive $drive free space: $($drive.FreeSpaceGb)GB)"
    }

    #Measure speed on drives found
    Write-PSFMessage -Message 'Measuring speed on fixed drives...'

    for ($i = 0; $i -lt $drives.Count; $i++)
    {
        $drive = $drives[$i]

        if ($cachedDrives -contains $drive)
        {
            $drive = ($cachedDrives -eq $drive)[0]
            $drives[$drives.IndexOf($drive)] = $drive
            Write-PSFMessage -Message "(cached) Measurements for drive $drive (serial: $($drive.Serial)) (signature: $($drive.Signature)): Read=$([int]($drive.ReadSpeed)) MB/s  Write=$([int]($drive.WriteSpeed)) MB/s  Total=$([int]($drive.TotalSpeed)) MB/s"
        }
        else
        {
            $result = Get-DiskSpeed -DriveLetter $drive.DriveLetter
            $drive.ReadSpeed = $result.ReadRandom
            $drive.WriteSpeed = $result.WriteRandom

            Write-PSFMessage -Message "Measurements for drive $drive (serial: $($drive.Serial)) (signature: $($drive.Signature)): Read=$([int]($drive.ReadSpeed)) MB/s  Write=$([int]($drive.WriteSpeed)) MB/s  Total=$([int]($drive.TotalSpeed)) MB/s"
        }
    }

    if ($IsLinux -or $IsMacOs)
    {
        $drives.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/LocalDisks.xml'))
    }
    else
    {
        $drives.ExportToRegistry('Cache', 'LocalDisks')
    }

    #creating a new list is required as otherwise $drives would be converted into an Object[]
    $drives = $drives | Sort-Object -Property TotalSpeed -Descending
    $bootDrive = $drives | Where-Object DriveLetter -eq $env:SystemDrive[0]
    if ($bootDrive)
    {
        Write-PSFMessage -Message "Boot drive is drive '$bootDrive'"
    }
    else
    {
        Write-PSFMessage -Message 'Boot drive is not part of the selected drive'
    }

    if ($drives[0] -ne $bootDrive)
    {
        #Fastest drive is not the boot drive. Selecting this drive!
        Write-PSFMessage -Message "Selecing drive $($drives[0].DriveLetter) for VMs based on speed and NOT being the boot drive"
        $script:lab.Target.Path = "$($drives[0].DriveLetter):\AutomatedLab-VMs"
    }
    else
    {
        if ($drives.Count -lt 2)
        {
            Write-PSFMessage "Selecing drive $($drives[0].DriveLetter) for VMs as it is the only one"
            $script:lab.Target.Path = "$($drives[0].DriveLetter):\AutomatedLab-VMs"
        }
        #Fastest drive is the boot drive. If speed on next fastest drive is close to the boot drive in speed (within 50%), select this drive now instead of the boot drive
        #If not, select the boot drive
        elseif (($drives[1].TotalSpeed * 100 / $drives[0].TotalSpeed) -gt 50)
        {
            Write-PSFMessage "Selecing drive $($drives[1].DriveLetter) for VMs based on speed and NOT being the boot drive"
            Write-PSFMessage "Selected disk speed compared to system disk is $(($drives[1].TotalSpeed * 100 / $drives[0].TotalSpeed))%"

            $script:lab.Target.Path = "$($drives[1].DriveLetter):\AutomatedLab-VMs"
        }
        else
        {
            Write-PSFMessage "Selecing drive $($drives[0].DriveLetter) for VMs based on speed though this drive is actually the boot drive but is much faster than second fastest drive ($($drives[1].DriveLetter))"
            Write-PSFMessage ('Selected system disk, speed of next fastest disk compared to system disk is {0:P}' -f ($drives[1].TotalSpeed / $drives[0].TotalSpeed))
            $script:lab.Target.Path = "$($drives[0].DriveLetter):\AutomatedLab-VMs"
        }
    }
}
