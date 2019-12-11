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
    Start-Process -Wait "C:\SPInstall\PrerequisiteInstaller.exe" –ArgumentList "/unattended /SQLNCli:C:\SPInstall\PrerequisiteInstallerFiles\sqlncli.msi `
               /IDFX:C:\SPInstall\PrerequisiteInstallerFiles\Windows6.1-KB974405-x64.msu  `
               /IDFX11:C:\SPInstall\PrerequisiteInstallerFiles\MicrosoftIdentityExtensions-64.msi `
               /Sync:C:\SPInstall\PrerequisiteInstallerFiles\Synchronization.msi  `
               /AppFabric:C:\SPInstall\PrerequisiteInstallerFiles\WindowsServerAppFabricSetup_x64.exe  `
               /KB2671763:C:\SPInstall\PrerequisiteInstallerFiles\AppFabric1.1-RTM-KB2671763-x64-ENU.exe  `
               /MSIPCClient:C:\SPInstall\PrerequisiteInstallerFiles\setup_msipc_x64.msi  `
               /WCFDataServices:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices.exe  `
               /WCFDataServices56:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices56.exe"
}
$SharePoint2016InstallScript = {
    Start-Process -Wait "C:\SPInstall\PrerequisiteInstaller.exe" –ArgumentList "/unattended /SQLNCli:C:\SPInstall\PrerequisiteInstallerFiles\sqlncli.msi `
    /IDFX11:C:\SPInstall\PrerequisiteInstallerFiles\MicrosoftIdentityExtensions-64.msi `
    /Sync:C:\SPInstall\PrerequisiteInstallerFiles\Synchronization.msi  `
    /AppFabric:C:\SPInstall\PrerequisiteInstallerFiles\WindowsServerAppFabricSetup_x64.exe  `
    /KB3092423:C:\SPInstall\PrerequisiteInstallerFiles\AppFabric-KB3092423-x64-ENU.exe  `
    /MSIPCClient:C:\SPInstall\PrerequisiteInstallerFiles\setup_msipc_x64.msi  `
    /WCFDataServices56:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices.exe  `
    /DotNetFx:C:\SPInstall\PrerequisiteInstallerFiles\NDP462-KB3151800-x86-x64-AllOS-ENU.exe  `
    /ODBC:C:\SPInstall\PrerequisiteInstallerFiles\msodbcsql.msi  `
    /MSVCRT11:C:\SPInstall\PrerequisiteInstallerFiles\vcredist_64_2012.exe  `
    /MSVCRT14:C:\SPInstall\PrerequisiteInstallerFiles\vcredist_64_2015.exe"
}
$SharePoint2019InstallScript = {
    Start-Process -Wait "C:\SPInstall\PrerequisiteInstaller.exe" –ArgumentList "/unattended /SQLNCli:C:\SPInstall\PrerequisiteInstallerFiles\sqlncli.msi `
    /IDFX11:C:\SPInstall\PrerequisiteInstallerFiles\MicrosoftIdentityExtensions-64.msi `
    /Sync:C:\SPInstall\PrerequisiteInstallerFiles\Synchronization.msi  `
    /AppFabric:C:\SPInstall\PrerequisiteInstallerFiles\WindowsServerAppFabricSetup_x64.exe  `
    /KB3092423:C:\SPInstall\PrerequisiteInstallerFiles\AppFabric-KB3092423-x64-ENU.exe  `
    /MSIPCClient:C:\SPInstall\PrerequisiteInstallerFiles\setup_msipc_x64.msi  `
    /WCFDataServices56:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices.exe  `
    /DotNetFx:C:\SPInstall\PrerequisiteInstallerFiles\NDP472-KB4054530-x86-x64-AllOS-ENU.exe  `
    /MSVCRT11:C:\SPInstall\PrerequisiteInstallerFiles\vcredist_64_2012.exe  `
    /MSVCRT141:C:\SPInstall\PrerequisiteInstallerFiles\vcredist_64_2017.exe"
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

    if (-not $machines)
    {
        Write-ScreenInfo -Message "There is SharePoint server in the lab" -Type Warning
        Write-LogFunctionExit
        return
    }
	
    Write-ScreenInfo -Message 'Waiting for machines with SharePoint role to start up' -NoNewline
    Start-LabVM -ComputerName $machines -Wait -ProgressIndicator 15
      
    # Mount OS ISO for Windows Feature Installation
    Install-LabWindowsFeature -ComputerName $machines -FeatureName Net-Framework-Features, Web-Server, Web-WebServer, Web-Common-Http, Web-Static-Content, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-App-Dev, Web-Asp-Net, Web-Net-Ext, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Health, Web-Http-Logging, Web-Log-Libraries, Web-Request-Monitor, Web-Http-Tracing, Web-Security, Web-Basic-Auth, Web-Windows-Auth, Web-Filtering, Web-Digest-Auth, Web-Performance, Web-Stat-Compression, Web-Dyn-Compression, Web-Mgmt-Tools, Web-Mgmt-Console, Web-Mgmt-Compat, Web-Metabase, WAS, WAS-Process-Model, WAS-NET-Environment, WAS-Config-APIs, Web-Lgcy-Scripting, Windows-Identity-Foundation, Server-Media-Foundation, Xps-Viewer -IncludeAllSubFeature -IncludeManagementTools

    $oldMachines = $machines | Where-Object { $_.OperatingSystem.Version -lt 10 }
    if ($Null -ne $oldMachines)
    {
        # Application Server is deprecated in 2016+, despite the SharePoint documentation stating otherwise
        Install-LabWindowsFeature -ComputerName $oldMachines -FeatureName Application-Server, AS-Web-Support, AS-TCP-Port-Sharing, AS-WAS-Support, AS-HTTP-Activation, AS-TCP-Activation, AS-Named-Pipes, AS-Net-Framework -IncludeManagementTools -IncludeAllSubFeature
    }

    Write-ScreenInfo -Message "Restaring server to complete Windows Features installation"
    Restart-LabVM $machines

    # Mount SharePoint ISO
    $versionGroups = $machines | Group-Object { $null = $_.Roles.RoleName -match 'SharePoint\d{4}'; $Matches.0 }
    Dismount-LabIsoImage -ComputerName $machines -SupressOutput

    foreach ($group in $versionGroups)
    {
        Mount-LabIsoImage -ComputerName $group.Group -IsoPath ($lab.Sources.ISOs | Where-Object { $_.Name -eq $group.Name }) -SupressOutput
    }

    Write-ScreenInfo -Message "Copying installation files for SharePoint to server"
    Invoke-LabCommand -ComputerName $machines -ActivityName "Copy SharePoint Installation Files" -ScriptBlock {
        Copy-Item -Path "D:\" -Destination "C:\SPInstall\" -Recurse
    }

    # Install VCPP for good measure
    Write-ScreenInfo -Message "Downloading all the VC Redistributables..."
    foreach ($thing in @('cppredist32_2012', 'cppredist64_2012', 'cppredist32_2015', 'cppredist64_2015', 'cppredist32_2017', 'cppredist64_2017'))
    {
        $fName = $thing -replace '(cppredist)(\d\d)_(\d{4})', 'vcredist_$2_$3.exe'
        Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name $thing) -Path $labsources\SoftwarePackages -FileName $fName -NoDisplay
    }

    Copy-LabFileItem -Path $labsources\SoftwarePackages\vcredist_64_2012.exe, $labsources\SoftwarePackages\vcredist_64_2015.exe, $labsources\SoftwarePackages\vcredist_64_2017.exe -ComputerName $machines  -DestinationFolderPath "C:\SPInstall\prerequisiteinstallerfiles"

    # Download and copy Prerequisite Files to server
    foreach ($group in $versionGroups)
    {
        Write-ScreenInfo -Message "Downloading and copying prerequisite files for $($group.Name) to server"
        if (-not (Test-Path -Path $labsources\SoftwarePackages\$($group.Name)))
        {
            $null = New-Item -ItemType Directory -Path $labsources\SoftwarePackages\$($group.Name)
        }
        
        foreach ($prereqUri in (Get-LabConfigurationItem -Name "$($group.Name)Prerequisites"))
        {
            Get-LabInternetFile -Uri $prereqUri -Path $labsources\SoftwarePackages\$($group.Name)
        }

        Copy-LabFileItem -ComputerName $group.Group -Path $labsources\SoftwarePackages\$($group.Name) -DestinationFolderPath "C:\SPInstall\prerequisiteinstallerfiles"
    

        # Installing Prereqs
        Write-ScreenInfo -Message "Installing prerequisite files for $($group.Name) on server"
        Invoke-LabCommand -PassThru -ComputerName $group.Group -ActivityName "Install $($group.Name) Prerequisites" -ScriptBlock (Get-Variable -Name "$($Group.Name)InstallScript").Value
    }

    Write-ScreenInfo -Message "Restarting server to complete prerequisites installation"
    Restart-LabVM $machines

    # Install SharePoint 2013 binaries
    Write-ScreenInfo -Message "Installing SharePoint binaries on server"

    foreach ($group in $versionGroups)
    {
        $productKey = Get-LabConfigurationItem -Name "$($group.Name)Key"
        $configFile = $setupConfigFileContent -f $productKey
        Invoke-LabCommand -ComputerName $machines -ActivityName "Install SharePoint" -ScriptBlock {
            Set-Content -Force -Path C:\SPInstall\files\al-config.xml -Value $configFile
            Start-Process -Wait "C:\SPInstall\setup.exe" –ArgumentList "/config C:\SPInstall\files\al-config.xml"          
        } -Variable (Get-Variable -Name configFile)
    }
    Write-ScreenInfo -Message "Waiting for SharePoint role to complete installation" -NoNewLine
}
#endregion Install-LabSharePoint
