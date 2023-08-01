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
        [int]$SourceImageIndex,

        [Parameter(Mandatory=$false)]
        [Switch]$SkipSuperseededCleanup
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
    $windowsImage = Get-WindowsImage -ImagePath $installWim.FullName -Index $SourceImageIndex
    Write-PSFMessage -Level Host -Message "The Windows Image targeted is named '$($windowsImage.ImageName)'"

    Write-PSFMessage -Level Host -Message "Mounting Windows Image '$($windowsImage.ImagePath)' to folder '$mountTempFolder'"
    Set-ItemProperty $installWim.FullName -Name IsReadOnly -Value $false
    Mount-WindowsImage -Path $mountTempFolder -ImagePath $installWim.FullName -Index $SourceImageIndex

    $patches = Get-ChildItem -Path $UpdateFolderPath\* -Include *.msu, *.cab
    Write-PSFMessage -Level Host -Message "Found $($patches.Count) patches in the UpdateFolderPath '$UpdateFolderPath'"

    Write-PSFMessage -Level Host -Message "Adding patches to the mounted Windows Image. This can take quite some time..."
    foreach ($patch in $patches)
    {
        Write-PSFMessage -Level Host -Message "Adding patch '$($patch.Name)'..."
        Add-WindowsPackage -PackagePath $patch.FullName -Path $mountTempFolder | Out-Null
        Write-PSFMessage -Level Host -Message 'finished'
    }

    if (! $SkipSuperseededCleanup) {
        Write-PSFMessage -Level Host -Message "Cleaning up superseeded updates.  This can take quite some time..."
        $cmd = "dism.exe /image:$mountTempFolder /Cleanup-Image /StartComponentCleanup /ResetBase"
        Write-PSFMessage -Message $cmd
        $global:dismResult = Invoke-Expression -Command $cmd 2>&1
        Write-PSFMessage -Level Host -Message 'finished'
    }

    Write-PSFMessage -Level Host -Message "Dismounting Windows Image from path '$mountTempFolder' and saving the changes. This can take quite some time again..."
    Dismount-WindowsImage -Path $mountTempFolder -Save
    Set-ItemProperty $installWim.FullName -Name IsReadOnly -Value $true
    Write-PSFMessage -Level Host -Message 'finished'

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
