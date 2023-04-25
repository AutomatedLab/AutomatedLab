function Install-LabSharePoint
{
    [CmdletBinding()]
    param
    (
        [switch]
        $CreateCheckPoints
    )

    Write-LogFunctionEntry

    $lab = Get-Lab

    if (-not (Get-LabVM))
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -Role SharePoint2013, SharePoint2016, SharePoint2019
    $versionGroups = $machines | Group-Object { $_.Roles.Name | Where-Object { $_ -match 'SharePoint\d{4}' } }

    if (-not $machines)
    {
        Write-ScreenInfo -Message "There is no SharePoint server in the lab" -Type Warning
        Write-LogFunctionExit
        return
    }

    foreach ($group in $versionGroups)
    {
        if ($null -eq ($lab.Sources.ISOs | Where-Object { $_.Name -eq $group.Name }))
        {
            Write-ScreenInfo -Message "No ISO was added for $($Group.Name). Please use Add-LabIsoImageDefinition to add it before installing a lab."
            return
        }
    }

    Write-ScreenInfo -Message 'Waiting for machines with SharePoint role to start up' -NoNewline
    Start-LabVM -ComputerName $machines -Wait -ProgressIndicator 15

    # Mount OS ISO for Windows Feature Installation
    Write-ScreenInfo -Message 'Installing required features'
    Install-LabWindowsFeature -ComputerName $machines -FeatureName Net-Framework-Features, Web-Server, Web-WebServer, Web-Common-Http, Web-Static-Content, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-App-Dev, Web-Asp-Net, Web-Net-Ext, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Health, Web-Http-Logging, Web-Log-Libraries, Web-Request-Monitor, Web-Http-Tracing, Web-Security, Web-Basic-Auth, Web-Windows-Auth, Web-Filtering, Web-Digest-Auth, Web-Performance, Web-Stat-Compression, Web-Dyn-Compression, Web-Mgmt-Tools, Web-Mgmt-Console, Web-Mgmt-Compat, Web-Metabase, WAS, WAS-Process-Model, WAS-NET-Environment, WAS-Config-APIs, Web-Lgcy-Scripting, Windows-Identity-Foundation, Server-Media-Foundation, Xps-Viewer -IncludeAllSubFeature -IncludeManagementTools -NoDisplay

    $oldMachines = $machines | Where-Object { $_.OperatingSystem.Version -lt 10 }
    if ($Null -ne $oldMachines)
    {
        # Application Server is deprecated in 2016+, despite the SharePoint documentation stating otherwise
        Install-LabWindowsFeature -ComputerName $oldMachines -FeatureName Application-Server, AS-Web-Support, AS-TCP-Port-Sharing, AS-WAS-Support, AS-HTTP-Activation, AS-TCP-Activation, AS-Named-Pipes, AS-Net-Framework -IncludeManagementTools -IncludeAllSubFeature -NoDisplay
    }

    Restart-LabVM -ComputerName $machines -Wait

    # Mount SharePoint ISO
    Dismount-LabIsoImage -ComputerName $machines -SupressOutput

    $jobs = foreach ($group in $versionGroups)
    {
        foreach ($machine in $group.Group)
        {
            $spImage = Mount-LabIsoImage -ComputerName $machine -IsoPath ($lab.Sources.ISOs | Where-Object { $_.Name -eq $group.Name }).Path -PassThru
            Invoke-LabCommand -ComputerName $machine -ActivityName "Copy SharePoint Installation Files" -ScriptBlock {
                Copy-Item -Path "$($spImage.DriveLetter)\" -Destination "C:\SPInstall\" -Recurse
                if ((Test-Path -Path 'C:\SPInstall\prerequisiteinstallerfiles') -eq $false)
                {
                    $null = New-Item -Path 'C:\SPInstall\prerequisiteinstallerfiles' -ItemType Directory
                }
            } -Variable (Get-Variable -Name spImage) -AsJob -PassThru
        }
    }

    Wait-LWLabJob -Job $jobs -NoDisplay

    foreach ($thing in @('cppredist32_2012', 'cppredist64_2012', 'cppredist32_2015', 'cppredist64_2015', 'cppredist32_2017', 'cppredist64_2017'))
    {
        $fName = $thing -replace '(cppredist)(\d\d)_(\d{4})', 'vcredist_$2_$3.exe'
        Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name $thing) -Path $labsources\SoftwarePackages -FileName $fName -NoDisplay
    }

    Copy-LabFileItem -Path $labsources\SoftwarePackages\vcredist_64_2012.exe, $labsources\SoftwarePackages\vcredist_64_2015.exe, $labsources\SoftwarePackages\vcredist_64_2017.exe -ComputerName $machines.Name  -DestinationFolderPath "C:\SPInstall\prerequisiteinstallerfiles"

    # Download and copy Prerequisite Files to server
    Write-ScreenInfo -Message "Downloading and copying prerequisite files to servers"
    foreach ($group in $versionGroups)
    {
        if ($lab.DefaultVirtualizationEngine -eq 'HyperV' -and -not (Test-Path -Path $labsources\SoftwarePackages\$($group.Name)))
        {
            $null = New-Item -ItemType Directory -Path $labsources\SoftwarePackages\$($group.Name)
        }

        foreach ($prereqUri in (Get-LabConfigurationItem -Name "$($group.Name)Prerequisites"))
        {
            $internalUri = New-Object System.Uri($prereqUri)
            $fileName = $internalUri.Segments[$internalUri.Segments.Count - 1]

            $params = @{
                Uri      = $prereqUri
                Path     = "$labsources\SoftwarePackages\$($group.Name)\$($fileName)"
                PassThru = $true
            }

            if ($prereqUri -match '1CAA41C7' -and $group.Name -eq 'SharePoint2013')
            {
                # This little snowflake would like both packages, pretty please
                $params.FileName = 'WcfDataServices56.exe'
            }

            $download = Get-LabInternetFile @params
        }

        Copy-LabFileItem -ComputerName $group.Group -Path $labsources\SoftwarePackages\$($group.Name)\* -DestinationFolderPath "C:\SPInstall\prerequisiteinstallerfiles"

        # Installing Prereqs
        Write-ScreenInfo -Message "Installing prerequisite files for $($group.Name) on server" -Type Verbose
        Invoke-LabCommand -ComputerName $group.Group -NoDisplay -ScriptBlock {
            param ([string] $Script )
            if (-not (Test-Path -Path C:\DeployDebug))
            {
                $null = New-Item -ItemType Directory -Path C:\DeployDebug
            }
            Set-Content C:\DeployDebug\SPPrereq.ps1 -Value $Script

        } -ArgumentList (Get-Variable -Name "$($Group.Name)InstallScript").Value.ToString()
    }

    $instResult = Invoke-LabCommand -PassThru -ComputerName $machines -ActivityName "Install SharePoint (all) Prerequisites" -ScriptBlock { & C:\DeployDebug\SPPrereq.ps1 -Mode '/unattended' }
    $failed = $instResult | Where-Object { $_.ExitCode -notin 0, 3010 }
    if ($failed)
    {
        Write-ScreenInfo -Type Error -Message "The following SharePoint servers failed installing prerequisites $($failed.PSComputerName)"
        return
    }

    $rebootRequired = $instResult | Where-Object { $_.ExitCode -eq 3010 }
    while ($rebootRequired)
    {
        Write-ScreenInfo -Type Verbose -Message "Some machines require a second pass at installing prerequisites: $($rebootRequired.HostName -join ',')"
        Restart-LabVM -ComputerName $rebootRequired.HostName -Wait
        $instResult = Invoke-LabCommand -PassThru -ComputerName $rebootRequired.HostName -ActivityName "Install $($group.Name) Prerequisites" -ScriptBlock { & C:\DeployDebug\SPPrereq.ps1 -Mode '/unattended /continue' } | Where-Object { $_ -eq 3010 }
        $failed = $instResult | Where-Object { $_.ExitCode -notin 0, 3010 }
        if ($failed)
        {
            Write-ScreenInfo -Type Error -Message "The following SharePoint servers failed installing prerequisites $($failed.HostName)"
        }

        $rebootRequired = $instResult | Where-Object { $_.ExitCode -eq 3010 }
    }

    # Install SharePoint binaries
    Write-ScreenInfo -Message "Installing SharePoint binaries on server"
    Restart-LabVM -ComputerName $machines -Wait

    $jobs = foreach ($group in $versionGroups)
    {
        $productKey = Get-LabConfigurationItem -Name "$($group.Name)Key"
        $configFile = $spsetupConfigFileContent -f $productKey
        Invoke-LabCommand -ComputerName $group.Group -ActivityName "Install SharePoint $($group.Name)" -ScriptBlock {
            Set-Content -Force -Path C:\SPInstall\files\al-config.xml -Value $configFile
            $null = Start-Process -Wait "C:\SPInstall\setup.exe" -ArgumentList "/config C:\SPInstall\files\al-config.xml"
            Set-Content C:\DeployDebug\SPInst.cmd -Value 'C:\SPInstall\setup.exe /config C:\SPInstall\files\al-config.xml'
            Get-ChildItem -Path (Join-Path ([IO.Path]::GetTempPath()) 'SharePoint Server Setup*') | Get-Content
        } -Variable (Get-Variable -Name configFile) -AsJob -PassThru
    }

    Write-ScreenInfo -Message "Waiting for SharePoint role to complete installation" -NoNewLine
    Wait-LWLabJob -Job $jobs -NoDisplay

    foreach ($job in $jobs)
    {
        $jobResult = (Receive-Job -Job $job -Wait -AutoRemoveJob)
        Write-ScreenInfo -Type Verbose -Message "Installation result $jobResult"
    }
}
