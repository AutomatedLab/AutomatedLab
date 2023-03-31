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
