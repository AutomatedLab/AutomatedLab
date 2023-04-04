function New-LabSourcesFolder
{
    [CmdletBinding(
            SupportsShouldProcess = $true,
    ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(Mandatory = $false)]
        [System.String]
        $DriveLetter,

        [switch]
        $Force,

        [switch]
        $FolderStructureOnly,

        [ValidateSet('master','develop')]
        [string]
        $Branch = 'master'
    )

    $path = Get-LabSourcesLocation -Local
    if (-not $path -and (Get-LabConfigurationItem -Name LabSourcesLocation))
    {
        $path = Get-LabConfigurationItem -Name LabSourcesLocation
    }
    elseif (-not $path)
    {
        $path = (Join-Path -Path (Get-LabConfigurationItem -Name OsRoot) -ChildPath LabSources)
    }

    if ($DriveLetter)
    {
        try
        {
            $drive = [System.IO.DriveInfo]$DriveLetter
        }
        catch
        {
            throw "$DriveLetter is not a valid drive letter. Exception was ($_.Exception.Message)"
        }

        if (-not $drive.IsReady)
        {
            throw "LabSource cannot be placed on $DriveLetter. The drive is not ready."
        }

        $Path = Join-Path -Path $drive.RootDirectory -ChildPath LabSources
    }

    if ((Test-Path -Path $Path) -and -not $Force)
    {
        return $Path
    }

    if (-not $Force.IsPresent)
    {
        Write-ScreenInfo -Message 'Downloading LabSources from GitHub. This only happens once if no LabSources folder can be found.' -Type Warning
    }

    if ($PSCmdlet.ShouldProcess('Downloading module and creating new LabSources', $Path))
    {
        if ($FolderStructureOnly.IsPresent)
        {
            $null = New-Item -Path (Join-Path -Path $Path -ChildPath ISOs\readme.md) -Force
            $null = New-Item -Path (Join-Path -Path $Path -ChildPath SoftwarePackages\readme.md) -Force
            $null = New-Item -Path (Join-Path -Path $Path -ChildPath PostInstallationActivities\readme.md) -Force
            $null = New-Item -Path (Join-Path -Path $Path -ChildPath Tools\readme.md) -Force
            $null = New-Item -Path (Join-Path -Path $Path -ChildPath CustomRoles\readme.md) -Force
            'ISO files go here' | Set-Content -Force -Path (Join-Path -Path $Path -ChildPath ISOs\readme.md)
            'Software packages (for example installers) go here. To prepare offline setups, visit https://automatedlab.org/en/latest/Wiki/Basic/fullyoffline' | Set-Content -Force -Path (Join-Path -Path $Path -ChildPath SoftwarePackages\readme.md)
            'Pre- and Post-Installation activities go here. For more information, visit https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Get-LabInstallationActivity' | Set-Content -Force -Path (Join-Path -Path $Path -ChildPath PostInstallationActivities\readme.md)
            'Tools to copy to all lab VMs (if parameter ToolsPath is used) go here' | Set-Content -Force -Path (Join-Path -Path $Path -ChildPath Tools\readme.md)
            'Custom roles go here. For more information, visit https://automatedlab.org/en/latest/Wiki/Advanced/customroles' | Set-Content -Force -Path (Join-Path -Path $Path -ChildPath CustomRoles\readme.md)
            return $Path
        }

        $temporaryPath = [System.IO.Path]::GetTempFileName().Replace('.tmp', '')
        [void] (New-Item -ItemType Directory -Path $temporaryPath -Force)
        $archivePath = (Join-Path -Path $temporaryPath -ChildPath "$Branch.zip")

        try
        {
            Get-LabInternetFile -Uri ('https://github.com/AutomatedLab/AutomatedLab/archive/{0}.zip' -f $Branch) -Path $archivePath -ErrorAction Stop
        }
        catch
        {
            Write-Error "Could not download the LabSources folder due to connection issues. Please try again." -ErrorAction Stop
        }

        Microsoft.PowerShell.Archive\Expand-Archive -Path $archivePath -DestinationPath $temporaryPath

        if (-not (Test-Path -Path $Path))
        {
            $Path = (New-Item -ItemType Directory -Path $Path).FullName
        }

        Copy-Item -Path (Join-Path -Path $temporaryPath -ChildPath AutomatedLab-*/LabSources/*) -Destination $Path -Recurse -Force:$Force

        Remove-Item -Path $temporaryPath -Recurse -Force -ErrorAction SilentlyContinue

        $Path
    }
}
