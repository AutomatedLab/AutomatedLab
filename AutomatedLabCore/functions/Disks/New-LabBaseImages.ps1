function New-LabBaseImages
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    $lab = Get-Lab
    if (-not $lab)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $oses = (Get-LabVm -All | Where-Object {[string]::IsNullOrWhiteSpace($_.ReferenceDiskPath)}).OperatingSystem

    if (-not $lab.Sources.AvailableOperatingSystems)
    {
        throw "There isn't a single operating system ISO available in the lab. Please call 'Get-LabAvailableOperatingSystem' to see what AutomatedLab has found and check the LabSources folder location by calling 'Get-LabSourcesLocation'."
    }

    $osesProcessed = @()
    $BaseImagesCreated = 0

    foreach ($os in $oses)
    {
        if (-not $os.ProductKey)
        {
            $message = "The product key is unknown for the OS '$($os.OperatingSystemName)' in ISO image '$($os.OSName)'. Cannot install lab until this problem is solved."
            Write-LogFunctionExitWithError -Message $message
            throw $message
        }

        $archString = if ($os.Architecture -eq 'x86') { "_$($os.Architecture)"} else { '' }
        $legacyDiskPath = Join-Path -Path $lab.Target.Path -ChildPath "BASE_$($os.OperatingSystemName.Replace(' ', ''))$($archString)_$($os.Version).vhdx"
        if (Test-Path $legacyDiskPath)
        {
            [int]$legacySize = (Get-Vhd -Path $legacyDiskPath).Size / 1GB
            $newName = Join-Path -Path $lab.Target.Path -ChildPath "BASE_$($os.OperatingSystemName.Replace(' ', ''))$($archString)_$($os.Version)_$($legacySize).vhdx"
            $affectedDisks = @()
            $affectedDisks += Get-LWHypervVM | Get-VMHardDiskDrive | Get-VHD | Where-Object ParentPath -eq $legacyDiskPath
            $affectedDisks += Get-LWHypervVM | Get-VMSnapshot | Get-VMHardDiskDrive | Get-VHD | Where-Object ParentPath -eq $legacyDiskPath
            
            if ($affectedDisks)
            {
                $affectedVms = Get-LWHypervVM | Where-Object {
                    ($_ | Get-VMHardDiskDrive | Get-VHD | Where-Object { $_.ParentPath -eq $legacyDiskPath -and $_.Attached }) -or
                    ($_ | Get-VMSnapshot | Get-VMHardDiskDrive | Get-VHD | Where-Object { $_.ParentPath -eq $legacyDiskPath -and $_.Attached })                
                }
            }

            if ($affectedVms)
            {
                Write-ScreenInfo -Type Warning -Message "Unable to rename $(Split-Path -Leaf -Path $legacyDiskPath) to $(Split-Path -Leaf -Path $newName), disk is currently in use by VMs: $($affectedVms.Name -join ',').
                You will need to clean up the disk manually, while a new reference disk is being created. To cancel, press CTRL-C and shut down the affected VMs manually."
                $count = 5
                do
                {
                    Write-ScreenInfo -Type Warning -NoNewLine:$($count -ne 1) -Message "$($count) "
                    Start-Sleep -Seconds 1
                    $count--
                }
                until ($count -eq 0)
                Write-ScreenInfo -Type Warning -Message "A new reference disk will be created."
            }
            elseif (-not (Test-Path -Path $newName))
            {
                Write-ScreenInfo -Message "Renaming $(Split-Path -Leaf -Path $legacyDiskPath) to $(Split-Path -Leaf -Path $newName) and updating VHD parent paths"                
                Rename-Item -Path $legacyDiskPath -NewName $newName
                $affectedDisks | Set-VHD -ParentPath $newName
            }
            else
            {
                # This is the critical scenario: If both files exist (i.e. a VM was running and the disk could not be renamed)
                # changing the parent of the VHD to the newly created VHD would not work. Renaming the old VHD to the new format
                # would also not work, as there would again be ID conflicts. All in all, the worst situtation
                Write-ScreenInfo -Type Warning -Message "Unable to rename $(Split-Path -Leaf -Path $legacyDiskPath) to $(Split-Path -Leaf -Path $newName) since both files exist and would cause issues with the Parent Disk ID for existing differencing disks"
            }
        }

        $baseDiskPath = Join-Path -Path $lab.Target.Path -ChildPath "BASE_$($os.OperatingSystemName.Replace(' ', ''))$($archString)_$($os.Version)_$($lab.Target.ReferenceDiskSizeInGB).vhdx"
        $os.BaseDiskPath = $baseDiskPath


        $hostOsVersion = [System.Environment]::OSVersion.Version

        if ($hostOsVersion -ge [System.Version]'6.3' -and $os.Version -ge [System.Version]'6.2')
        {
            Write-PSFMessage -Message "Host OS version is '$($hostOsVersion)' and OS to create disk for is version '$($os.Version)'. So, setting partition style to GPT."
            $partitionStyle = 'GPT'
        }
        else
        {
            Write-PSFMessage -Message "Host OS version is '$($hostOsVersion)' and OS to create disk for is version '$($os.Version)'. So, KEEPING partition style as MBR."
            $partitionStyle = 'MBR'
        }

        if ($osesProcessed -notcontains $os)
        {
            $osesProcessed += $os

            if (-not (Test-Path $baseDiskPath))
            {
                Stop-ShellHWDetectionService

                New-LWReferenceVHDX -IsoOsPath $os.IsoPath `
                    -ReferenceVhdxPath $baseDiskPath `
                    -OsName $os.OperatingSystemName `
                    -ImageName $os.OperatingSystemImageName `
                    -SizeInGb $lab.Target.ReferenceDiskSizeInGB `
                    -PartitionStyle $partitionStyle

                $BaseImagesCreated++
            }
            else
            {
                Write-PSFMessage -Message "The base image $baseDiskPath already exists"
            }
        }
        else
        {
            Write-PSFMessage -Message "Base disk for operating system '$os' already created previously"
        }
    }

    if (-not $BaseImagesCreated)
    {
        Write-ScreenInfo -Message 'All base images were created previously'
    }

    Start-ShellHWDetectionService

    Write-LogFunctionExit
}
