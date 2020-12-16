#region New-LabBaseImages
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

    $oses = (Get-LabVm -All).OperatingSystem

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

        $legacyDiskPath = Join-Path -Path $lab.Target.Path -ChildPath "BASE_$($os.OperatingSystemName.Replace(' ', ''))_$($os.Version).vhdx"
        if (Test-Path $legacyDiskPath)
        {
            [int]$legacySize = (Get-Vhd -Path $legacyDiskPath).Size / 1GB
            $newName = Join-Path -Path $lab.Target.Path -ChildPath "BASE_$($os.OperatingSystemName.Replace(' ', ''))_$($os.Version)_$($legacySize).vhdx"
            $affectedDisks = @()
            $affectedDisks += Get-VM | Get-VMHardDiskDrive | Get-VHD | Where-Object ParentPath -eq $legacyDiskPath
            $affectedDisks += Get-VM | Get-VMSnapshot | Get-VMHardDiskDrive | Get-VHD | Where-Object ParentPath -eq $legacyDiskPath
            
            if ($affectedDisks)
            {
                $affectedVms = Get-VM | Where-Object {
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

        $baseDiskPath = Join-Path -Path $lab.Target.Path -ChildPath "BASE_$($os.OperatingSystemName.Replace(' ', ''))_$($os.Version)_$($lab.Target.ReferenceDiskSizeInGB).vhdx"
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
#endregion New-LabBaseImages


function Stop-ShellHWDetectionService
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [CmdletBinding()]
    param ( )

    Write-LogFunctionEntry

    $service = Get-Service -Name ShellHWDetection -ErrorAction SilentlyContinue
    if (-not $service)
    {
        Write-PSFMessage -Message "The service 'ShellHWDetection' is not installed, exiting."
        Write-LogFunctionExit
        return
    }

    Write-PSFMessage -Message 'Stopping the ShellHWDetection service (Shell Hardware Detection) to prevent the OS from responding to the new disks.'

    $retries = 5
    while ($retries -gt 0 -and ((Get-Service -Name ShellHWDetection).Status -ne 'Stopped'))
    {
        Write-Debug -Message 'Trying to stop ShellHWDetection'

        Stop-Service -Name ShellHWDetection | Out-Null
        Start-Sleep -Seconds 1
        if ((Get-Service -Name ShellHWDetection).Status -eq 'Running')
        {
            Write-Debug -Message "Could not stop service ShellHWDetection. Retrying."
            Start-Sleep -Seconds 5
        }
        $retries--
    }

    Write-LogFunctionExit
}

function Start-ShellHWDetectionService
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [CmdletBinding()]
    param ( )

    Write-LogFunctionEntry

    $service = Get-Service -Name ShellHWDetection -ErrorAction SilentlyContinue
    if (-not $service)
    {
        Write-PSFMessage -Message "The service 'ShellHWDetection' is not installed, exiting."
        Write-LogFunctionExit
        return
    }

    if ((Get-Service -Name ShellHWDetection).Status -eq 'Running')
    {
        Write-PSFMessage -Message "'ShellHWDetection' Service is already running."
        Write-LogFunctionExit
        return
    }

    Write-PSFMessage -Message 'Starting the ShellHWDetection service (Shell Hardware Detection) again.'

    $retries = 5
    while ($retries -gt 0 -and ((Get-Service -Name ShellHWDetection).Status -ne 'Running'))
    {
        Write-Debug -Message 'Trying to start ShellHWDetection'
        Start-Service -Name ShellHWDetection -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        if ((Get-Service -Name ShellHWDetection).Status -ne 'Running')
        {
            Write-Debug -Message 'Could not start service ShellHWDetection. Retrying.'
            Start-Sleep -Seconds 5
        }
        $retries--
    }

    Write-LogFunctionExit
}


#region New-LabVHDX
function New-LabVHDX
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByName')]
        [string[]]$Name,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
        [switch]$All
    )

    Write-LogFunctionEntry

    $lab = Get-Lab
    if (-not $lab)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    Write-PSFMessage -Message 'Stopping the ShellHWDetection service (Shell Hardware Detection) to prevent the OS from responding to the new disks.'
    Stop-ShellHWDetectionService

    if ($Name)
    {
        $disks = $lab.Disks | Where-Object Name -in $Name
    }
    else
    {
        $disks = $lab.Disks
    }

    if (-not $disks)
    {
        Write-PSFMessage -Message 'No disks found to create. Either the given name is wrong or there is no disk defined yet'
        Write-LogFunctionExit
        return
    }

    $disksPath = Join-Path -Path $lab.Target.Path -ChildPath Disks

    foreach ($disk in $disks)
    {
        Write-ScreenInfo -Message "Creating disk '$($disk.Name)'" -TaskStart -NoNewLine
        $diskPath = Join-Path -Path $disksPath -ChildPath ($disk.Name + '.vhdx')
        if (-not (Test-Path -Path $diskPath))
        {
            $params = @{
                VhdxPath = $diskPath
                SizeInGB = $disk.DiskSize
                SkipInitialize = $disk.SkipInitialization
                Label = $disk.Label
                UseLargeFRS = $disk.UseLargeFRS
                AllocationUnitSize = $disk.AllocationUnitSize
            }
            if ($disk.DriveLetter)
            {
                $params.DriveLetter = $disk.DriveLetter
            }
            New-LWVHDX @params
            Write-ScreenInfo -Message 'Done' -TaskEnd
        }
        else
        {
            Write-ScreenInfo "The disk '$diskPath' does already exist, no new disk is created." -Type Warning -TaskEnd
        }
    }

    Write-PSFMessage -Message 'Starting the ShellHWDetection service (Shell Hardware Detection) again.'
    Start-ShellHWDetectionService

    Write-LogFunctionExit
}
#endregion New-LabVHDX

#region Get-LabVHDX
function Get-LabVHDX
{
    [OutputType([AutomatedLab.Disk])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch]$All
    )

    Write-LogFunctionEntry

    $lab = Get-Lab
    if (-not $lab)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        $results = $lab.Disks | Where-Object -FilterScript {
            $_.Name -in $Name
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'All')
    {
        $results = $lab.Disks
    }

    if ($results)
    {
        $diskPath = Join-Path -Path $lab.Target.Path -ChildPath Disks
        foreach ($result in $results)
        {
            $result.Path = Join-Path -Path $diskPath -ChildPath ($result.Name + '.vhdx')
        }

        Write-LogFunctionExit -ReturnValue $results.ToString()

        return $results
    }
    else
    {
        return
    }
}
#endregion Get-LabVHDX

#region Update-LabIsoImage
function Update-LabIsoImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory)]
        [string]$SourceIsoImagePath,

        [Parameter(Mandatory)]
        [string]$TargetIsoImagePath,

        [Parameter(Mandatory)]
        [string]$UpdateFolderPath,

        [Parameter(Mandatory)]
        [int]$SourceImageIndex
    )

    if ($IsLinux)
    {
        throw 'Sorry - not implemented on Linux yet.'
    }

    #region Expand-IsoImage
    function Expand-IsoImage
    {
        param(
            [Parameter(Mandatory)]
            [string]$SourceIsoImagePath,

            [Parameter(Mandatory)]
            [string]$OutputPath,

            [switch]$Force
        )

        if (-not (Test-Path -Path $SourceIsoImagePath -PathType Leaf))
        {
            Write-Error "The specified ISO image '$SourceIsoImagePath' could not be found"
            return
        }

        if ((Test-Path -Path $OutputPath) -and -not $Force)
        {
            Write-Error "The output folder does already exist" -TargetObject $OutputPath
            return
        }
        else
        {
            Remove-Item -Path $OutputPath -Force -Recurse -ErrorAction Ignore
        }

        New-Item -ItemType Directory -Path $OutputPath | Out-Null


        $image = Mount-LabDiskImage -ImagePath $SourceIsoImagePath -StorageType ISO -PassThru
        Get-PSDrive | Out-Null #This is just to refresh the drives. Somehow if this cmdlet is not called, PowerShell does not see the new drives.

        if($image)
        {
            $source = Join-Path -Path ([IO.DriveInfo][string]$image.DriveLetter).Name -ChildPath '*'

            Write-PSFMessage -Message "Extracting ISO image '$source' to '$OutputPath'"
            Copy-Item -Path $source -Destination $OutputPath -Recurse -Force
            [void] (Dismount-LabDiskImage -ImagePath $SourceIsoImagePath)
            Write-PSFMessage -Message 'Copy complete'
        }
        else
        {
            Write-Error "Could not mount ISO image '$SourceIsoImagePath'" -TargetObject $SourceIsoImagePath
            return
        }
    }
    #endregion Expand-IsoImage

    #region Get-IsoImageName
    function Get-IsoImageName
    {
        param(
            [Parameter(Mandatory)]
            [string]$IsoImagePath
        )

        if (-not (Test-Path -Path $IsoImagePath -PathType Leaf))
        {
            Write-Error "The specified ISO image '$IsoImagePath' could not be found"
            return
        }

        $image = Mount-DiskImage $IsoImagePath -StorageType ISO -PassThru
        $image | Get-Volume | Select-Object -ExpandProperty FileSystemLabel
        [void] ($image | Dismount-DiskImage)
    }
    #endregion Get-IsoImageName

    if (-not (Test-Path -Path $SourceIsoImagePath -PathType Leaf))
    {
        Write-Error "The specified ISO image '$SourceIsoImagePath' could not be found"
        return
    }

    if (Test-Path -Path $TargetIsoImagePath -PathType Leaf)
    {
        Write-Error "The specified target ISO image '$TargetIsoImagePath' does already exist"
        return
    }

    if ([System.IO.Path]::GetExtension($TargetIsoImagePath) -ne '.iso')
    {
        Write-Error "The specified target ISO image path must have the extension '.iso'"
        return
    }

    Write-PSFMessage -Level Host -Message 'Creating an updated ISO from'
    Write-PSFMessage -Level Host -Message "Target path             $TargetIsoImagePath"
    Write-PSFMessage -Level Host -Message "Source path             $SourceIsoImagePath"
    Write-PSFMessage -Level Host -Message "with updates from path  $UpdateFolderPath"
    Write-PSFMessage -Level Host -Message "This process can take a long time, depending on the number of updates"
    $start = Get-Date
    Write-PSFMessage -Level Host -Message "Start time: $start"

    $extractTempFolder = New-Item -ItemType Directory -Path $labSources -Name ([guid]::NewGuid())
    $mountTempFolder = New-Item -ItemType Directory -Path $labSources -Name ([guid]::NewGuid())

    $isoImageName = Get-IsoImageName -IsoImagePath $SourceIsoImagePath

    Write-PSFMessage -Level Host -Message "Extracting ISO image '$SourceIsoImagePath' to '$extractTempFolder'"
    Expand-IsoImage -SourceIsoImagePath $SourceIsoImagePath -OutputPath $extractTempFolder -Force

    $installWim = Get-ChildItem -Path $extractTempFolder -Filter install.wim -Recurse
    Write-PSFMessage -Level Host -Message "Working with '$installWim'"
    Write-PSFMessage -Level Host -Message "Exporting install.wim to $labSources"
    Export-WindowsImage -SourceImagePath $installWim.FullName -DestinationImagePath $labSources\install.wim -SourceIndex $SourceImageIndex

    $windowsImage = Get-WindowsImage -ImagePath $labSources\install.wim
    Write-PSFMessage -Level Host -Message "The Windows Image exported is named '$($windowsImage.ImageName)'"

    $patches = Get-ChildItem -Path $UpdateFolderPath\* -Include *.msu, *.cab
    Write-PSFMessage -Level Host -Message "Found $($patches.Count) patches in the UpdateFolderPath '$UpdateFolderPath'"

    Write-PSFMessage -Level Host -Message "Mounting Windows Image '$($windowsImage.ImagePath)' to folder "
    Mount-WindowsImage -Path $mountTempFolder -ImagePath $windowsImage.ImagePath -Index 1

    Write-PSFMessage -Level Host -Message "Adding patches to the mounted Windows Image. This can take quite some time..."
    foreach ($patch in $patches)
    {
        Write-PSFMessage -Level Host -Message "Adding patch '$($patch.Name)'..."
        Add-WindowsPackage -PackagePath $patch.FullName -Path $mountTempFolder | Out-Null
        Write-PSFMessage -Level Host -Message 'finished'
    }

    Write-PSFMessage -Level Host -Message "Dismounting Windows Image from path '$mountTempFolder' and saving the changes. This can take quite some time again..."
    Dismount-WindowsImage -Path $mountTempFolder -Save
    Write-PSFMessage -Level Host -Message 'finished'

    Write-PSFMessage -Level Host -Message "Moving updated Windows Image '$labsources\install.wim' to '$extractTempFolder'"
    Move-Item -Path $labsources\install.wim -Destination $extractTempFolder\sources -Force

    Write-PSFMessage -Level Host -Message "Calling oscdimg.exe to create a new bootable ISO image '$TargetIsoImagePath'..."
    $cmd = "$labSources\Tools\oscdimg.exe -m -o -u2 -l$isoImageName -udfver102 -bootdata:2#p0,e,b$extractTempFolder\boot\etfsboot.com#pEF,e,b$extractTempFolder\efi\microsoft\boot\efisys.bin $extractTempFolder $TargetIsoImagePath"
    Write-PSFMessage -Message $cmd
    $global:oscdimgResult = Invoke-Expression -Command $cmd 2>&1
    Write-PSFMessage -Level Host -Message 'finished'

    Write-PSFMessage -Level Host -Message "Deleting temp folder '$extractTempFolder'"
    Remove-Item -Path $extractTempFolder -Recurse -Force

    Write-PSFMessage -Level Host -Message "Deleting temp folder '$mountTempFolder'"
    Remove-Item -Path $mountTempFolder -Recurse -Force

    $end = Get-Date
    Write-PSFMessage -Level Host -Message "finished at $end. Runtime: $($end - $start)"
}
#endregion Update-LabIsoImage

#region Update-LabBaseImage
function Update-LabBaseImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory)]
        [string]$BaseImagePath,

        [Parameter(Mandatory)]
        [string]$UpdateFolderPath
    )

    if ($IsLinux)
    {
        throw 'Sorry - not implemented on Linux yet.'
    }

    if (-not (Test-Path -Path $BaseImagePath -PathType Leaf))
    {
        Write-Error "The specified image '$BaseImagePath' could not be found"
        return
    }

    if ([System.IO.Path]::GetExtension($BaseImagePath) -ne '.vhdx')
    {
        Write-Error "The specified image must have the extension '.vhdx'"
        return
    }

    $patchesCab = Get-ChildItem -Path $UpdateFolderPath\* -Include *.cab -ErrorAction SilentlyContinue
    $patchesMsu = Get-ChildItem -Path $UpdateFolderPath\* -Include *.msu -ErrorAction SilentlyContinue

    if (($null -eq $patchesCab) -and ($null -eq $patchesMsu))
    {
        Write-Error "No .cab and .msu files found in '$UpdateFolderPath'"
        return
    }

    Write-PSFMessage -Level Host -Message 'Updating base image'
    Write-PSFMessage -Level Host -Message $BaseImagePath
    Write-PSFMessage -Level Host -Message "with $($patchesCab.Count + $patchesMsu.Count) updates from"
    Write-PSFMessage -Level Host -Message $UpdateFolderPath
    Write-PSFMessage -Level Host -Message 'This process can take a long time, depending on the number of updates'

    $start = Get-Date
    Write-PSFMessage -Level Host -Message "Start time: $start"

    Write-PSFMessage -Level Host -Message 'Creating temp folder (mount point)'
    $mountTempFolder = New-Item -ItemType Directory -Path $labSources -Name ([guid]::NewGuid())

    Write-PSFMessage -Level Host -Message "Mounting Windows Image '$BaseImagePath'"
    Write-PSFMessage -Level Host -Message "to folder '$mountTempFolder'"
    Mount-WindowsImage -Path $mountTempFolder -ImagePath $BaseImagePath -Index 1

    Write-PSFMessage -Level Host -Message 'Adding patches to the mounted Windows Image.'
    $patchesCab | ForEach-Object {

        $UpdateReady = Get-WindowsPackage -PackagePath $_ -Path $mountTempFolder | Select-Object -Property PackageState, PackageName, Applicable

        if ($UpdateReady.PackageState -eq 'Installed')
        {
            Write-PSFMessage -Level Host -Message "$($UpdateReady.PackageName) is already installed"
        }
        elseif ($UpdateReady.Applicable -eq $true)
        {
            Add-WindowsPackage -PackagePath $_.FullName -Path $mountTempFolder
        }
    }
    $patchesMsu | ForEach-Object {

        Add-WindowsPackage -PackagePath $_.FullName -Path $mountTempFolder
    }

    Write-PSFMessage -Level Host -Message "Dismounting Windows Image from path '$mountTempFolder' and saving the changes. This can take quite some time again..."
    Dismount-WindowsImage -Path $mountTempFolder -Save
    Write-PSFMessage -Level Host -Message 'finished'

    Write-PSFMessage -Level Host -Message "Deleting temp folder '$mountTempFolder'"
    Remove-Item -Path $mountTempFolder -Recurse -Force

    $end = Get-Date
    Write-PSFMessage -Level Host -Message "finished at $end. Runtime: $($end - $start)"
}
#endregion Update-LabBaseImage

#region Mount-LabDiskImage
function Mount-LabDiskImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingCmdletAliases", "")]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ImagePath,

        [ValidateSet('ISO','VHD','VHDSet','VHDx','Unknown')]
        $StorageType,

        [switch]
        $PassThru
    )

    if (Get-Command -Name Mount-DiskImage -ErrorAction SilentlyContinue)
    {
        $diskImage = Mount-DiskImage -ImagePath $ImagePath -StorageType $StorageType -PassThru

        if ($PassThru.IsPresent)
        {
            $diskImage | Add-Member -MemberType NoteProperty -Name DriveLetter -Value ($diskImage | Get-Volume).DriveLetter -PassThru
        }
    }
    elseif ($IsLinux)
    {
        if (-not (Test-Path -Path /mnt/automatedlab))
        {
            $null = New-Item -Path /mnt/automatedlab -Force -ItemType Directory
        }

        $image = Get-Item -Path $ImagePath
        $null = mount -o loop $ImagePath /mnt/automatedlab/$($image.BaseName)
        [PSCustomObject]@{
            ImagePath   = $ImagePath
            FileSize    = $image.Length
            Size        = $image.Length
            DriveLetter = "/mnt/automatedlab/$($image.BaseName)"
        }
    }
    else
    {
        throw 'Neither Mount-DiskImage exists, nor is this a Linux system.'
    }
}
#endregion

#region Dismount-LabDiskImage
function Dismount-LabDiskImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ImagePath
    )

    if (Get-Command -Name Dismount-DiskImage -ErrorAction SilentlyContinue)
    {
        Dismount-DiskImage -ImagePath $ImagePath
    }
    elseif ($IsLinux)
    {
        $image = Get-Item -Path $ImagePath
        $null = umount /mnt/automatedlab/$($image.BaseName)
    }
    else
    {
        throw 'Neither Dismount-DiskImage exists, nor is this a Linux system.'
    }
}
#endregion
