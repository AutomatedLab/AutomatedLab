$setupConfigFileContent = '<Configuration>
    <Package Id="sts">
        <Setting Id="LAUNCHEDFROMSETUPSTS" Value="Yes"/>
    </Package>

    <Package Id="spswfe">
        <Setting Id="SETUPCALLED" Value="1"/>
    </Package>

    <Logging Type="verbose" Path="%temp%" Template="SharePoint Server Setup(*).log"/>
    <PIDKEY Value="{0}" />
    <Display Level="none" CompletionNotice="no" />
    <Setting Id="SERVERROLE" Value="APPLICATION"/>
    <Setting Id="USINGUIINSTALLMODE" Value="0"/>
    <Setting Id="SETUP_REBOOT" Value="Never" />
    <Setting Id="SETUPTYPE" Value="CLEAN_INSTALL"/>
</Configuration>'

$SharePoint2013InstallScript = {
    param
    (
        [string]
        $Mode = '/unattended'
    )
    (Start-Process -PassThru -Wait "C:\SPInstall\PrerequisiteInstaller.exe" –ArgumentList "$Mode /SQLNCli:C:\SPInstall\PrerequisiteInstallerFiles\sqlncli.msi `
               /IDFX:C:\SPInstall\PrerequisiteInstallerFiles\Windows6.1-KB974405-x64.msu  `
               /IDFX11:C:\SPInstall\PrerequisiteInstallerFiles\MicrosoftIdentityExtensions-64.msi `
               /Sync:C:\SPInstall\PrerequisiteInstallerFiles\Synchronization.msi  `
               /AppFabric:C:\SPInstall\PrerequisiteInstallerFiles\WindowsServerAppFabricSetup_x64.exe  `
               /KB2671763:C:\SPInstall\PrerequisiteInstallerFiles\AppFabric1.1-RTM-KB2671763-x64-ENU.exe  `
               /MSIPCClient:C:\SPInstall\PrerequisiteInstallerFiles\setup_msipc_x64.msi  `
               /WCFDataServices:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices.exe  `
               /WCFDataServices56:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices56.exe").ExitCode
}
$SharePoint2016InstallScript = {
    param
    (
        [string]
        $Mode = '/unattended'
    )
    (Start-Process -PassThru -Wait "C:\SPInstall\PrerequisiteInstaller.exe" –ArgumentList "$Mode /SQLNCli:C:\SPInstall\PrerequisiteInstallerFiles\sqlncli.msi `
    /IDFX11:C:\SPInstall\PrerequisiteInstallerFiles\MicrosoftIdentityExtensions-64.msi `
    /Sync:C:\SPInstall\PrerequisiteInstallerFiles\Synchronization.msi  `
    /AppFabric:C:\SPInstall\PrerequisiteInstallerFiles\WindowsServerAppFabricSetup_x64.exe  `
    /KB3092423:C:\SPInstall\PrerequisiteInstallerFiles\AppFabric-KB3092423-x64-ENU.exe  `
    /MSIPCClient:C:\SPInstall\PrerequisiteInstallerFiles\setup_msipc_x64.exe  `
    /WCFDataServices56:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices.exe  `
    /DotNetFx:C:\SPInstall\PrerequisiteInstallerFiles\NDP462-KB3151800-x86-x64-AllOS-ENU.exe  `
    /ODBC:C:\SPInstall\PrerequisiteInstallerFiles\msodbcsql.msi  `
    /MSVCRT11:C:\SPInstall\PrerequisiteInstallerFiles\vcredist_64_2012.exe  `
    /MSVCRT14:C:\SPInstall\PrerequisiteInstallerFiles\vcredist_64_2015.exe").ExitCode
}
$SharePoint2019InstallScript = {
    param
    (
        [string]
        $Mode = '/unattended'
    )
    (Start-Process -Wait -PassThru "C:\SPInstall\PrerequisiteInstaller.exe" –ArgumentList "$Mode /SQLNCli:C:\SPInstall\PrerequisiteInstallerFiles\sqlncli.msi `
    /IDFX11:C:\SPInstall\PrerequisiteInstallerFiles\MicrosoftIdentityExtensions-64.msi `
    /Sync:C:\SPInstall\PrerequisiteInstallerFiles\Synchronization.msi  `
    /AppFabric:C:\SPInstall\PrerequisiteInstallerFiles\WindowsServerAppFabricSetup_x64.exe  `
    /KB3092423:C:\SPInstall\PrerequisiteInstallerFiles\AppFabric-KB3092423-x64-ENU.exe  `
    /MSIPCClient:C:\SPInstall\PrerequisiteInstallerFiles\setup_msipc_x64.exe  `
    /WCFDataServices56:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices.exe  `
    /DotNet472:C:\SPInstall\PrerequisiteInstallerFiles\NDP472-KB4054530-x86-x64-AllOS-ENU.exe  `
    /MSVCRT11:C:\SPInstall\PrerequisiteInstallerFiles\vcredist_64_2012.exe  `
    /MSVCRT141:C:\SPInstall\PrerequisiteInstallerFiles\vcredist_64_2017.exe").ExitCode
}

#region Install-LabSharePoint
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
    $versionGroups = $machines | Group-Object { $null = $_.Roles.Name -match 'SharePoint\d{4}'; $Matches[0] }

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
            $spImage = Mount-LabIsoImage -ComputerName $group.Group -IsoPath ($lab.Sources.ISOs | Where-Object { $_.Name -eq $group.Name }).Path -PassThru
            Invoke-LabCommand -ComputerName $machines -ActivityName "Copy SharePoint Installation Files" -ScriptBlock {
                Copy-Item -Path "$($spImage.DriveLetter)\" -Destination "C:\SPInstall\" -Recurse
            } -Variable (Get-Variable -Name spImage) -AsJob -PassThru
        }        
    }

    Wait-LWLabJob -Job $jobs -NoDisplay

    foreach ($thing in @('cppredist32_2012', 'cppredist64_2012', 'cppredist32_2015', 'cppredist64_2015', 'cppredist32_2017', 'cppredist64_2017'))
    {
        $fName = $thing -replace '(cppredist)(\d\d)_(\d{4})', 'vcredist_$2_$3.exe'
        Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name $thing) -Path $labsources\SoftwarePackages -FileName $fName -NoDisplay
    }

    Copy-LabFileItem -Path $labsources\SoftwarePackages\vcredist_64_2012.exe, $labsources\SoftwarePackages\vcredist_64_2015.exe, $labsources\SoftwarePackages\vcredist_64_2017.exe -ComputerName $machines  -DestinationFolderPath "C:\SPInstall\prerequisiteinstallerfiles"

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
            $params = @{
                Uri      = $prereqUri
                Path     = "$labsources\SoftwarePackages\$($group.Name)"
                PassThru = $true
            }

            if ($prereqUri -match '1CAA41C7' -and $group.Name -eq 'SharePoint2013')
            {
                # This little snowflake would like both packages, pretty please
                $params.FileName = 'WcfDataServices56.exe'
            }

            $download = Get-LabInternetFile @params
            if ($download.FullName.EndsWith('.zip'))
            {
                # Sync client...
                if ($lab.DefaultVirtualizationEngine -eq 'Azure')
                {
                    $anyVm = Get-LabVm -IsRunning | Select-Object -First 1
                    Copy-LabFileItem -Path $download.FullName -DestinationFolderPath C:\ -ComputerName $anyVm -UseAzureLabSourcesOnAzureVm $true
                    Invoke-LabCommand -ComputerName $anyVm -ScriptBlock {
                        Expand-Archive -Path (Join-Path -Path C:\ -ChildPath $download.FileName) -DestinationPath Z:\SoftwarePackages\$($group.Name) -Force
                        Get-ChildItem -Recurse -Path "Z:\SoftwarePackages\$($group.Name)" -Filter Synchronization.msi | Move-Item -Destination (Join-Path -Path "Z:\SoftwarePackages\$($group.Name)" -ChildPath Synchronization.msi) -Force
                    } -Variable (Get-Variable download,group)
                }
                else
                {
                    Expand-Archive -Path $download.FullName -DestinationPath "$labsources\SoftwarePackages\$($group.Name)" -Force
                    Get-ChildItem -Recurse -Path "$labsources\SoftwarePackages\$($group.Name)" -Filter Synchronization.msi | Move-Item -Destination (Join-Path -Path "$labsources\SoftwarePackages\$($group.Name)" -ChildPath Synchronization.msi) -Force
                }
            }
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
    $failed = $instResult | Where-Object { $_ -notin 0, 3010 }
    if ($null -ne $failed)
    {
        Write-ScreenInfo -Type Error -Message "The following SharePoint servers failed installing prerequisites $($failed.PSComputerName)"
        return
    }

    $rebootRequired = $instResult | Where-Object { $_ -eq 3010 }
    while ($null -ne $rebootRequired)
    {
        Write-ScreenInfo -Type Verbose -Message "Some machines require a second pass at installing prerequisites: $($rebootRequired.PSComputerName -join ',')"
        Restart-LabVM -ComputerName $rebootRequired.PSComputerName -Wait
        $instResult = Invoke-LabCommand -PassThru -ComputerName $rebootRequired.PSComputerName -ActivityName "Install $($group.Name) Prerequisites" -ScriptBlock { & C:\DeployDebug\SPPrereq.ps1 -Mode '/unattended /continue' } | Where-Object { $_ -eq 3010 }
        $failed = $instResult | Where-Object { $_ -notin 0, 3010 }
        if ($null -ne $failed)
        {
            Write-ScreenInfo -Type Error -Message "The following SharePoint servers failed installing prerequisites $($failed.PSComputerName)"
        }

        $rebootRequired = $instResult | Where-Object { $_ -eq 3010 }
    }

    # Install SharePoint 2013 binaries
    Write-ScreenInfo -Message "Installing SharePoint binaries on server"

    $jobs = foreach ($group in $versionGroups)
    {
        $productKey = Get-LabConfigurationItem -Name "$($group.Name)Key"
        $configFile = $setupConfigFileContent -f $productKey
        Invoke-LabCommand -ComputerName $group.Group -ActivityName "Install SharePoint $($group.Name)" -ScriptBlock {
            Set-Content -Force -Path C:\SPInstall\files\al-config.xml -Value $configFile
            $null = Start-Process -Wait "C:\SPInstall\setup.exe" –ArgumentList "/config C:\SPInstall\files\al-config.xml"
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
#endregion Install-LabSharePoint
