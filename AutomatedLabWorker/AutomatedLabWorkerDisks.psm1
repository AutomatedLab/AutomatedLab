#region New-LWReferenceVHDX
function New-LWReferenceVHDX
{
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
    Write-Verbose "Beginning at $start"
    
    $imageList = Get-LabAvailableOperatingSystem -Path $IsoOsPath
    Write-Verbose "The Windows Image list contains $($imageList.Count) items"
	
    Write-Verbose "Mounting ISO image '$IsoOsPath'"
    Mount-DiskImage -ImagePath $IsoOsPath
	
    Write-Verbose 'Getting disk image of the ISO'
    $isoImage = Get-DiskImage -ImagePath $IsoOsPath | Get-Volume
    Write-Verbose "Got disk image '$($isoImage.DriveLetter)'"
	
    $isoDrive = "$($isoImage.DriveLetter):"
    Write-Verbose "OS ISO mounted on drive letter '$isoDrive'"
	
    $image = $imageList | Where-Object OperatingSystemName -eq $OsName
	
    if (-not $image)
    {
        throw "The specified image ('$OsName') could not be found on the ISO '$(Split-Path -Path $IsoOsPath -Leaf)'. Please specify one of the following values: $($imageList.ImageName -join ', ')"
    }
	
    $imageIndex = $image.ImageIndex
    Write-Verbose "Selected image index '$imageIndex' with name '$($image.ImageName)'"
	
    $vmDisk = New-VHD -Path $ReferenceVhdxPath -SizeBytes ($SizeInGB * 1GB) -ErrorAction Stop
    Write-Verbose "Created VHDX file '$($vmDisk.Path)'"
	
    Write-ScreenInfo -Message "Creating base image for operating system '$OsName'" -NoNewLine -TaskStart
    
    Mount-DiskImage -ImagePath $ReferenceVhdxPath
    $vhdDisk = Get-DiskImage -ImagePath $ReferenceVhdxPath | Get-Disk
    $vhdDiskNumber = [string]$vhdDisk.Number
    Write-Verbose "Reference image is on disk number '$vhdDiskNumber'"
	
    Initialize-Disk -Number $vhdDiskNumber -PartitionStyle $PartitionStyle | Out-Null
    if ($PartitionStyle -eq 'MBR')
    {
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
		
        $diskpartCmd = "@
            select disk $vhdDiskNumber
            select partition $($systemPartition.PartitionNumber)
            format quick fs=fat32 label=System
            exit
        @"
        $diskpartCmd | diskpart.exe | Out-Null		
		
        $reservedPartition = New-Partition -DiskNumber $vhdDiskNumber -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' -Size 128MB
		
        $vhdWindowsDrive = New-Partition -DiskNumber $vhdDiskNumber -UseMaximumSize -AssignDriveLetter |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel 'System' -Confirm:$false
    }
	
    $vhdWindowsVolume = "$($vhdWindowsDrive.DriveLetter):"
    Write-Verbose "VHD drive '$vhdWindowsDrive', Vhd volume '$vhdWindowsVolume'"

    Write-Verbose "Disabling Bitlocker Drive Encryption on drive $vhdWindowsVolume"
    if (Test-Path -Path C:\Windows\System32\manage-bde.exe)
    {
        manage-bde.exe -off $vhdWindowsVolume | Out-Null #without this on some devices (for exmaple Surface 3) the VHD was auto-encrypted
    }
	
    Write-Verbose 'Applying image to the volume...'
    
    if ($image.Installation -eq 'Nano Server')
    {
        $wimPath = "$isoDrive\NanoServer\NanoServer.wim"
    }
    else
    {
        $wimPath = "$isoDrive\Sources\install.wim"
    }
    $job = Start-Job -ScriptBlock { Dism.exe /apply-Image /ImageFile:$using:wimPath /index:$using:imageIndex /ApplyDir:$using:vhdWindowsVolume\ }
	
    Wait-LWLabJob -Job $job -NoDisplay -ProgressIndicator 20 -Timeout 60
    Start-Sleep -Seconds 5
    
    Write-Verbose 'Setting BCDBoot'
    if ($PartitionStyle -eq 'MBR')
    {
        bcdboot.exe $vhdWindowsVolume\Windows /s $vhdWindowsVolume /f BIOS | Out-Null
    }
    else
    {
        $possibleDrives = [char[]](65..90)
        $drives = (Get-PSDrive -PSProvider FileSystem).Name
        $freeDrives = Compare-Object -ReferenceObject $possibleDrives -DifferenceObject $drives | Where-Object { $_.SideIndicator -eq '<=' } 
        $freeDrive = ($freeDrives | Select-Object -First 1).InputObject

        $diskpartCmd = "@
            select disk $vhdDiskNumber
            select partition $($systemPartition.PartitionNumber)
            assign letter=$freeDrive
            exit
        @"
        $diskpartCmd | diskpart.exe | Out-Null
		
        bcdboot.exe $vhdWindowsVolume\Windows /s "$($freeDrive):" /f UEFI | Out-Null
		
        $diskpartCmd = "@
            select disk $vhdDiskNumber
            select partition $($systemPartition.PartitionNumber)
            remove letter=$freeDrive
            exit
        @"
        $diskpartCmd | diskpart.exe | Out-Null
    }
    
    if ($image.Installation -eq 'Nano Server')
    {
        $packages = Get-ChildItem -Path $isoDrive\NanoServer\Packages -File
        foreach ($package in $packages)
        {
            Add-WindowsPackage -Path $vhdWindowsVolume -PackagePath $package.FullName | Out-Null
        }
        
        $packages = Get-ChildItem -Path $isoDrive\NanoServer\Packages\en-US -File
        foreach ($package in $packages)
        {
            Add-WindowsPackage -Path $vhdWindowsVolume -PackagePath $package.FullName | Out-Null
        }
    }
	
    Write-Verbose 'Dismounting ISO and new disk'
    Dismount-DiskImage -ImagePath $IsoOsPath
    Dismount-DiskImage -ImagePath $ReferenceVhdxPath
	
    Write-ScreenInfo -Message 'Finished creating base image' -TaskEnd
	
    $end = Get-Date
    Write-Verbose "Runtime: '$($end - $start)'"
	
    Write-LogFunctionExit
}
#endregion New-LWReferenceVHDX

#region New-LWVHDX
function New-LWVHDX
{
    [Cmdletbinding()]
    Param (
        #Path to reference VHD
        [Parameter(Mandatory = $true)]
        [string]$VhdxPath,
		
        #Size of the reference VHD
        [Parameter(Mandatory = $true)]
        [int]$SizeInGB,

		[switch]$SkipInitialize
    )
	
    Write-LogFunctionEntry
	
    $VmDisk = New-VHD -Path $VhdxPath -SizeBytes ($SizeInGB * 1GB) -ErrorAction Stop
    Write-Verbose "Created VHDX file '$($vmDisk.Path)'"
	
	if ($SkipInitialize)
	{
		Write-Verbose -Message "Skipping the initialization of '$($vmDisk.Path)'"
		Write-LogFunctionExit
		return
	}

    $mountedVhd = $VmDisk | Mount-VHD -PassThru
	
    $mountedVhd | Initialize-Disk
    $mountedVhd | New-Partition -UseMaximumSize -AssignDriveLetter |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel Data -Force -Confirm:$false |
    Out-Null
	
    $VmDisk | Dismount-VHD
	
    Write-LogFunctionExit
}
#endregion New-LWVHDX

#region Remove-LWVHDX
function Remove-LWVHDX
{
    [Cmdletbinding()]
    Param (
        #Path to reference VHD
        [Parameter(Mandatory = $true)]
        [string]$VhdxPath
    )
	
    Write-LogFunctionEntry
	
    $VmDisk = Get-VHD -Path $VhdxPath -ErrorAction SilentlyContinue
    if (-not $VmDisk)
    {
        Write-Warning -Message "VHDX '$VhdxPath' does not exist, cannot remove it"
    }
    else
    {
        $VmDisk | Remove-Item
        Write-Verbose "VHDX '$($vmDisk.Path)' removed"
    }
	
    Write-LogFunctionExit
}
#endregion Remove-LWVHDX

#region Add-LWVMVHDX
function Add-LWVMVHDX
{
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$VMName,
		
        [Parameter(Mandatory = $true)]
        [string]$VhdxPath
    )
	
    Write-LogFunctionEntry
	
    if (-not (Test-Path -Path $VhdxPath))
    {
        Write-Error 'VHDX cannot be found'
        return
    }
	
    $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
    if (-not $vm)
    {
        Write-Error 'VM cannot be found'
        return
    }
	
    Add-VMHardDiskDrive -VM $vm -Path $VhdxPath
	
    Write-LogFunctionExit
}
#endregion Add-LWVMVHDX