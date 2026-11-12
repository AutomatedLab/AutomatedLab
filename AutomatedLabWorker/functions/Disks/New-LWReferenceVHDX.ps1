function New-LWReferenceVHDX
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param (
        #ISO of OS
        [Parameter(Mandatory = $true)]
        [string]$IsoOsPath,

        #Path to reference VHD
        [Parameter(Mandatory = $true)]
        [string]$ReferenceVhdxPath,

        #Path to reference VHD
        [Parameter(Mandatory = $true)]
        [string]$OsName,

        #Real image name in ISO file
        [Parameter(Mandatory = $true)]
        [string]$ImageName,

        #Size of the reference VHD
        [Parameter(Mandatory = $true)]
        [int]$SizeInGB,

        [Parameter(Mandatory = $true)]
        [ValidateSet('MBR', 'GPT')]
        [string]$PartitionStyle
    )

    Write-LogFunctionEntry

    # Get start time
    $start = Get-Date
    Write-PSFMessage "Beginning at $start"

    try
    {
        $FDVDenyWriteAccess = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE -Name FDVDenyWriteAccess -ErrorAction SilentlyContinue).FDVDenyWriteAccess

        $imageList = Get-LabAvailableOperatingSystem -Path $IsoOsPath
        Write-PSFMessage "The Windows Image list contains $($imageList.Count) items"

        Write-PSFMessage "Mounting ISO image '$IsoOsPath'"
        [void] (Mount-DiskImage -ImagePath $IsoOsPath)

        Write-PSFMessage 'Getting disk image of the ISO'
        $isoImage = Get-DiskImage -ImagePath $IsoOsPath | Get-Volume
        Write-PSFMessage "Got disk image '$($isoImage.DriveLetter)'"

        $isoDrive = "$($isoImage.DriveLetter):"
        Write-PSFMessage "OS ISO mounted on drive letter '$isoDrive'"

        $image = $imageList | Where-Object OperatingSystemName -eq $OsName

        if (-not $image)
        {
            throw "The specified image ('$OsName') could not be found on the ISO '$(Split-Path -Path $IsoOsPath -Leaf)'. Please specify one of the following values: $($imageList.ImageName -join ', ')"
        }

        $imageIndex = $image.ImageIndex
        Write-PSFMessage "Selected image index '$imageIndex' with name '$($image.ImageName)'"

        $vmDisk = New-VHD -Path $ReferenceVhdxPath -SizeBytes ($SizeInGB * 1GB) -ErrorAction Stop
        Write-PSFMessage "Created VHDX file '$($vmDisk.Path)'"

        Write-ScreenInfo -Message "Creating base image for operating system '$OsName'" -NoNewLine -TaskStart

        [void] (Mount-DiskImage -ImagePath $ReferenceVhdxPath)
        $vhdDisk = Get-DiskImage -ImagePath $ReferenceVhdxPath | Get-Disk
        $vhdDiskNumber = [string]$vhdDisk.Number
        Write-PSFMessage "Reference image is on disk number '$vhdDiskNumber'"

        Initialize-Disk -Number $vhdDiskNumber -PartitionStyle $PartitionStyle | Out-Null
        if ($PartitionStyle -eq 'MBR')
        {
            if ($FDVDenyWriteAccess) {
                Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE -Name FDVDenyWriteAccess -Value 0
            }
            $vhdWindowsDrive = New-Partition -DiskNumber $vhdDiskNumber -UseMaximumSize -IsActive -AssignDriveLetter |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel 'System' -Confirm:$false
        }
        else
        {
            $vhdRecoveryPartition = New-Partition -DiskNumber $vhdDiskNumber -GptType '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' -Size 300MB
            $vhdRecoveryDrive = $vhdRecoveryPartition | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows RE Tools' -Confirm:$false

            $recoveryPartitionNumber = (Get-Disk -Number $vhdDiskNumber | Get-Partition | Where-Object Type -eq Recovery).PartitionNumber
            $diskpartCmd = @"
select disk $vhdDiskNumber
select partition $recoveryPartitionNumber
gpt attributes=0x8000000000000001
exit
"@
            $diskpartCmd | diskpart.exe | Out-Null

            $systemPartition = New-Partition -DiskNumber $vhdDiskNumber -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -Size 100MB
            #does not work, seems to be a bug. Using diskpart as a workaround
            #$systemPartition | Format-Volume -FileSystem FAT32 -NewFileSystemLabel 'System' -Confirm:$false

            $diskpartCmd = @"
select disk $vhdDiskNumber
select partition $($systemPartition.PartitionNumber)
format quick fs=fat32 label=System
exit
"@
            $diskpartCmd | diskpart.exe | Out-Null

            $reservedPartition = New-Partition -DiskNumber $vhdDiskNumber -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' -Size 128MB

            if ($FDVDenyWriteAccess) {
                Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE -Name FDVDenyWriteAccess -Value 0
            }
            $vhdWindowsDrive = New-Partition -DiskNumber $vhdDiskNumber -UseMaximumSize -AssignDriveLetter |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel 'System' -Confirm:$false
        }

        $vhdWindowsVolume = "$($vhdWindowsDrive.DriveLetter):"
        Write-PSFMessage "VHD drive '$vhdWindowsDrive', Vhd volume '$vhdWindowsVolume'"

        Write-PSFMessage "Disabling Bitlocker Drive Encryption on drive $vhdWindowsVolume"
        if (Test-Path -Path C:\Windows\System32\manage-bde.exe)
        {
            manage-bde.exe -off $vhdWindowsVolume | Out-Null #without this on some devices (for exmaple Surface 3) the VHD was auto-encrypted
        }

        Write-PSFMessage 'Applying image to the volume...'

        $installFilePath = Get-Item -Path "$isoDrive\Sources\install.*" | Where-Object Name -Match '.*\.(esd|wim)'

        $job = Start-Job -ScriptBlock {
            $output = Dism.exe /English /apply-Image /ImageFile:$using:installFilePath /index:$using:imageIndex /ApplyDir:$using:vhdWindowsVolume\
            New-Object PSObject -Property @{
                Outout = $output
                LastExitCode = $LASTEXITCODE
            }
        }

        $dismResult = Wait-LWLabJob -Job $job -NoDisplay -ProgressIndicator 20 -Timeout 60 -PassThru
        if ($dismResult.LastExitCode)
        {
            throw (New-Object System.ComponentModel.Win32Exception($dismResult.LastExitCode,
            "The base image for operating system '$OsName' could not be created. The error is $($dismResult.LastExitCode)"))
        }
        Start-Sleep -Seconds 10

        Write-PSFMessage 'Setting BCDBoot'
        # Prefer the image's own bcdboot.exe (version-matched to the guest OS) and
        # fall back to the host's. On newer hosts the host bcdboot can fail to write
        # a boot store for an older guest image (observed exit 193 / ERROR_BAD_EXE_FORMAT:
        # host Windows 11 25H2, build 26200, servicing a Windows Server 2022, build 20348,
        # image). Previously the exit code was discarded, so this produced a silently
        # unbootable base image with an empty EFI System Partition.
        $imageBcdboot = Join-Path $vhdWindowsVolume 'Windows\System32\bcdboot.exe'
        $bcdbootExe = if (Test-Path -Path $imageBcdboot) { $imageBcdboot } else { 'bcdboot.exe' }
        if ($PartitionStyle -eq 'MBR')
        {
            # Capture bcdboot's own output (stdout and stderr) so a failure can be
            # diagnosed from the message it prints (for example 'Failure when attempting
            # to copy boot files.') rather than only from the numeric exit code. The
            # surrounding try/catch handles any terminating error from native stderr.
            $bcdbootOutput = & $bcdbootExe $vhdWindowsVolume\Windows /s $vhdWindowsVolume /f BIOS 2>&1
            $bcdbootExitCode = $LASTEXITCODE
            if ($bcdbootExitCode -ne 0 -and $bcdbootExe -ne 'bcdboot.exe')
            {
                Write-PSFMessage -Level Warning -Message "Image bcdboot.exe failed (exit $bcdbootExitCode) for '$OsName'; retrying with the host bcdboot.exe. bcdboot output: $($bcdbootOutput -join ' ')"
                # Keep $bcdbootOutput pointing at the run that ultimately failed (the host's).
                $bcdbootOutput = bcdboot.exe $vhdWindowsVolume\Windows /s $vhdWindowsVolume /f BIOS 2>&1
                $bcdbootExitCode = $LASTEXITCODE
            }
        }
        else
        {
            $possibleDrives = [char[]](65..90)
            $drives = (Get-PSDrive -PSProvider FileSystem).Name
            $freeDrives = Compare-Object -ReferenceObject $possibleDrives -DifferenceObject $drives | Where-Object { $_.SideIndicator -eq '<=' }
            $freeDrive = ($freeDrives | Select-Object -First 1).InputObject

            $diskpartCmd = @"
    select disk $vhdDiskNumber
    select partition $($systemPartition.PartitionNumber)
    assign letter=$freeDrive
    exit
"@
            $diskpartCmd | diskpart.exe | Out-Null

            # Capture bcdboot's own output (stdout and stderr); see the BIOS path above.
            $bcdbootOutput = & $bcdbootExe $vhdWindowsVolume\Windows /s "$($freeDrive):" /f UEFI 2>&1
            $bcdbootExitCode = $LASTEXITCODE
            if ($bcdbootExitCode -ne 0 -and $bcdbootExe -ne 'bcdboot.exe')
            {
                Write-PSFMessage -Level Warning -Message "Image bcdboot.exe failed (exit $bcdbootExitCode) for '$OsName'; retrying with the host bcdboot.exe. bcdboot output: $($bcdbootOutput -join ' ')"
                # Keep $bcdbootOutput pointing at the run that ultimately failed (the host's).
                $bcdbootOutput = bcdboot.exe $vhdWindowsVolume\Windows /s "$($freeDrive):" /f UEFI 2>&1
                $bcdbootExitCode = $LASTEXITCODE
            }

            $diskpartCmd = @"
    select disk $vhdDiskNumber
    select partition $($systemPartition.PartitionNumber)
    remove letter=$freeDrive
    exit
"@
            $diskpartCmd | diskpart.exe | Out-Null
        }

        # Do not proceed with an unbootable base image. Previously bcdboot's exit code
        # was discarded (| Out-Null with no check), turning a failed boot-store write
        # into a generic firmware error ("the boot loader did not load an operating
        # system") that surfaced only when a VM was started much later.
        if ($bcdbootExitCode -ne 0)
        {
            $bcdbootMessage = ($bcdbootOutput | Where-Object { $_ } | ForEach-Object { $_.ToString().Trim() }) -join ' '
            throw "bcdboot failed (exit code $bcdbootExitCode) while writing the boot store for operating system '$OsName'. The base image would be unbootable. This usually means the host's bcdboot.exe cannot service the guest image (for example a host/guest Windows build mismatch). bcdboot output: $bcdbootMessage"
        }
    }
    catch
    {
        Write-PSFMessage 'Dismounting ISO and new disk'
        [void] (Dismount-DiskImage -ImagePath $ReferenceVhdxPath)
        [void] (Dismount-DiskImage -ImagePath $IsoOsPath)
        Remove-Item -Path $ReferenceVhdxPath -Force #removing as the creation did not succeed
        if ($FDVDenyWriteAccess) {
            Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE -Name FDVDenyWriteAccess -Value $FDVDenyWriteAccess
        }

        throw $_.Exception
    }

    Write-PSFMessage 'Dismounting ISO and new disk'
    [void] (Dismount-DiskImage -ImagePath $ReferenceVhdxPath)
    [void] (Dismount-DiskImage -ImagePath $IsoOsPath)
    if ($FDVDenyWriteAccess) {
        Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE -Name FDVDenyWriteAccess -Value $FDVDenyWriteAccess
    }
    Write-ScreenInfo -Message 'Finished creating base image' -TaskEnd

    $end = Get-Date
    Write-PSFMessage "Runtime: '$($end - $start)'"

    Write-LogFunctionExit
}
