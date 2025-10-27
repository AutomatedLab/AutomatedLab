if ($PSEdition -eq 'Core') {
    Add-Type -Path $PSScriptRoot/lib/core/AutomatedLab.dll

    # These modules SHOULD be marked as Core compatible, as tested with Windows 10.0.18362.113
    # However, if they are not, they need to be imported.
    $requiredModules = @('Dism')
    $requiredModulesImplicit = @('International') # These modules should be imported via implicit remoting. Might suffer from implicit sessions getting removed though

    $ipmoErr = $null # Initialize, otherwise Import-MOdule -Force will extend this variable indefinitely
    if ($requiredModulesImplicit -and $IsWindows) {
        try {
            if ((Get-Command Import-Module).Parameters.ContainsKey('UseWindowsPowerShell')) {
                Import-Module -Name $requiredModulesImplicit -UseWindowsPowerShell -WarningAction SilentlyContinue -ErrorAction Stop -Force -ErrorVariable +ipmoErr
            }
            else {
                Import-WinModule -Name $requiredModulesImplicit -WarningAction SilentlyContinue -ErrorAction Stop -Force -ErrorVariable +ipmoErr
            }
        }
        catch {
            Remove-Module -Name $requiredModulesImplicit -Force -ErrorAction SilentlyContinue
            Clear-Variable -Name ipmoErr -ErrorAction SilentlyContinue
            foreach ($m in $requiredModulesImplicit) {
                Get-ChildItem -Directory -Path ([IO.Path]::GetTempPath()) -Filter "RemoteIpMoProxy_$($m)*_localhost_*" | Remove-Item -Recurse -Force
            }

            if ((Get-Command Import-Module).Parameters.ContainsKey('UseWindowsPowerShell')) {
                Import-Module -Name $requiredModulesImplicit -UseWindowsPowerShell -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -Force -ErrorVariable +ipmoErr
            }
            else {
                Import-WinModule -Name $requiredModulesImplicit -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -Force -ErrorVariable +ipmoErr
            }
        }
    }

    if ($requiredModules -and $IsWindows) {
        Import-Module -Name $requiredModules -SkipEditionCheck -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -Force -ErrorVariable +ipmoErr
    }

    if ($ipmoErr) {
        Write-PSFMessage -Level Warning -Message "Could not import modules: $($ipmoErr.TargetObject -join ',') - your experience might be impacted."
    }
}
else {
    Add-Type -Path $PSScriptRoot/lib/full/AutomatedLab.dll
}

if ((Get-Module -ListAvailable Ships) -and (Get-Module -ListAvailable AutomatedLab.Ships)) {
    Import-Module Ships, AutomatedLab.Ships
    [void] (New-PSDrive -PSProvider SHiPS -Name Labs -Root "AutomatedLab.Ships#LabHost" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
}

Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value true

#region Register default configuration if not present
$labAppDataRoot = if (-not $IsLinux -and -not $IsMacOs) {
    Join-Path ([System.Environment]::GetFolderPath('CommonApplicationData')) -ChildPath "AutomatedLab"
}
else {
    Join-Path -Path $Home -ChildPath .automatedlab
}
Set-PSFConfig -Module 'AutomatedLab' -Name LabAppDataRoot -Value $labAppDataRoot -Initialize -Validation string -Description "Root folder to Labs, Assets and Stores"
Set-PSFConfig -Module 'AutomatedLab' -Name 'DisableVersionCheck' -Value $false -Initialize -Validation bool -Description 'Set to true to skip checking GitHub for an updated AutomatedLab release'

if (-not (Get-PSFConfigValue -FullName AutomatedLab.DisableVersionCheck)) {
    $usedRelease = (Split-Path -Leaf -Path $PSScriptRoot) -as [version]
    $currentRelease = try { ((Invoke-RestMethod -Method Get -Uri https://api.github.com/repos/AutomatedLab/AutomatedLab/releases/latest -ErrorAction Stop).tag_Name -replace 'v') -as [Version] } catch {}

    if ($currentRelease -and $usedRelease -lt $currentRelease) {
        Write-PSFMessage -Level Host -Message "Your version of AutomatedLab is outdated. Consider updating to the recent version, $currentRelease"
    }
}


Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Ifttt.Key' -Value 'Your IFTTT key here' -Initialize -Validation string -Description "IFTTT Key Name"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Ifttt.EventName' -Value 'The name of your IFTTT event' -Initialize -Validation String -Description "IFTTT Event Name"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Mail.Port' -Value 25 -Initialize -Validation integer -Description "Port of your SMTP Server"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Mail.SmtpServer' -Value 'your SMTP server here' -Initialize -Validation string -Description "Adress of your SMTP server"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Mail.To' -Value @('Recipients here') -Initialize -Validation stringarray -Description "A list of default recipients"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Mail.From' -Value "$($env:USERNAME)@localhost" -Initialize -Validation string -Description "Your sender address"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Mail.Priority' -Value 'Normal' -Initialize -Validation string -Description "Priority of your message"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Mail.CC' -Value @('Recipients here') -Initialize -Validation stringarray -Description "A list of default CC recipients"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Toast.Image' -Value 'https://raw.githubusercontent.com/AutomatedLab/AutomatedLab/master/Assets/Automated-Lab_icon512.png' -Initialize -Validation string -Description "The image for your toast notification"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Voice.Culture' -Value 'en-us' -Initialize -Validation string -Description "Voice culture, needs to be available and defaults to en-us"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Voice.Gender' -Value 'female' -Initialize -Validation string -Description "Gender of voice to use"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.SubscribedProviders' -Value @('Toast') -Initialize -Validation stringarray -Description 'List of subscribed providers'
Set-PSFConfig -Module 'AutomatedLab' -Name 'MachineFileName' -Value 'Machines.xml' -Initialize -Validation string -Description 'The file name for the deserialized machines. Do not change unless you know what you are doing.'
Set-PSFConfig -Module 'AutomatedLab' -Name 'DiskFileName' -Value 'Disks.xml' -Initialize -Validation string -Description 'The file name for the deserialized disks. Do not change unless you know what you are doing.'
Set-PSFConfig -Module 'AutomatedLab' -Name 'LabFileName' -Value 'Lab.xml' -Initialize -Validation string -Description 'The file name for the deserialized labs. Do not change unless you know what you are doing.'
Set-PSFConfig -Module 'AutomatedLab' -Name 'DefaultAddressSpace' -Value '192.168.10.0/24' -Initialize -Validation string -Description 'Default address space if no address space is selected'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_WaitLabMachine_Online -Value 60 -Initialize -Validation integer -Description 'Timeout in minutes for Wait-LabVm'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_StartLabMachine_Online -Value 60 -Initialize -Validation integer -Description 'Timeout in minutes for Start-LabVm'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_RestartLabMachine_Shutdown -Value 30 -Initialize -Validation integer -Description 'Timeout in minutes for Restart-LabVm'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_StopLabMachine_Shutdown -Value 30 -Initialize -Validation integer -Description 'Timeout in minutes for Stop-LabVm'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_TestPortInSeconds -Value 2 -Initialize -Validation integer -Description 'Timeout in seconds for Test-Port'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_InstallLabCAInstallation -Value 40 -Initialize -Validation integer -Description 'Timeout in minutes for CA setup'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_DcPromotionRestartAfterDcpromo -Value 60 -Initialize -Validation integer -Description 'Timeout in minutes for restart after DC Promo'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_DcPromotionAdwsReady -Value 20 -Initialize -Validation integer -Description 'Timeout in minutes for availability of ADWS after DC Promo'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_Sql2008Installation -Value 90 -Initialize -Validation integer -Description 'Timeout in minutes for SQL 2008'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_Sql2012Installation -Value 90 -Initialize -Validation integer -Description 'Timeout in minutes for SQL 2012'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_Sql2014Installation -Value 90 -Initialize -Validation integer -Description 'Timeout in minutes for SQL 2014'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_ConfigurationManagerInstallation -Value 60 -Initialize -Validation integer -Description 'Timeout in minutes to wait for the installation of Configuration Manager. Default value 60.'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_VisualStudio2013Installation -Value 90 -Initialize -Validation integer -Description 'Timeout in minutes for VS 2013'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_VisualStudio2015Installation -Value 90 -Initialize -Validation integer -Description 'Timeout in minutes for VS 2015'
Set-PSFConfig -Module 'AutomatedLab' -Name DefaultProgressIndicator -Value 10 -Initialize -Validation integer -Description 'After how many minutes will a progress indicator be written'
Set-PSFConfig -Module 'AutomatedLab' -Name DisableConnectivityCheck -Value $false -Initialize -Validation bool -Description 'Indicates whether connectivity checks should be skipped. Certain systems like Azure DevOps build workers do not send ICMP packges and the method might always fail'
Set-PSFConfig -Module 'AutomatedLab' -Name 'VmPath' -Value $null -Validation string -Initialize -Description 'VM storage location'
$osroot = if ([System.Environment]::OSVersion.Platform -eq 'Win32NT') {
    'C:\'
}
else {
    '/'
}
Set-PSFConfig -Module 'AutomatedLab' -Name OsRoot -Value $osroot -Initialize -Validation string
Set-PSFConfig -Module 'AutomatedLab' -Name OverridePowerPlan -Value $true -Initialize -Validation bool -Description 'On Windows: Indicates that power settings will be set to High Power during lab deployment'
Set-PSFConfig -Module 'AutomatedLab' -Name SendFunctionTelemetry -Value $false -Initialize -Validation bool -Description 'Indicates if function call telemetry is sent' -Hidden
Set-PSFConfig -Module 'AutomatedLab' -Name DoNotWaitForLinux -Value $false -Initialize -Validation bool -Description 'Indicates that you will not wait for Linux VMs to be ready, e.g. because you are offline and PowerShell cannot be installed.'
Set-PSFConfig -Module 'AutomatedLab' -Name DoNotPrompt -Value $false -Initialize -Validation bool -Description 'Indicates that AutomatedLab should not display prompts. Workaround for environments that register as interactive, even if they are not. Skips enabling telemetry, skips Azure lab sources sync, forcibly configures remoting' -Hidden

#PSSession settings
Set-PSFConfig -Module 'AutomatedLab' -Name InvokeLabCommandRetries -Value 3 -Initialize -Validation integer -Description 'Number of retries for Invoke-LabCommand'
Set-PSFConfig -Module 'AutomatedLab' -Name InvokeLabCommandRetryIntervalInSeconds -Value 10 -Initialize -Validation integer -Description 'Retry interval for Invoke-LabCommand'
Set-PSFConfig -Module 'AutomatedLab' -Name MaxPSSessionsPerVM -Value 5 -Initialize -Validation integer -Description 'Maximum number of sessions per VM'
Set-PSFConfig -Module 'AutomatedLab' -Name DoNotUseGetHostEntryInNewLabPSSession -Value $true -Initialize -Validation bool -Description 'Do not use hosts file for session creation'

#DSC
Set-PSFConfig -Module 'AutomatedLab' -Name DscMofPath -Value 'DscConfigurations' -Initialize -Validation string -Description 'Default path for MOF files on Pull server'
Set-PSFConfig -Module 'AutomatedLab' -Name DscPullServerRegistrationKey -Value 'ec717ee9-b343-49ee-98a2-26e53939eecf'  -Initialize -Validation string  -Description 'DSC registration key used on all Dsc Pull servers and clients'

#General VM settings
Set-PSFConfig -Module 'AutomatedLab' -Name DisableWindowsDefender -Value $true -Initialize -Validation bool -Description 'Indicates that Windows Defender should be disabled on the lab VMs'
Set-PSFConfig -Module 'AutomatedLab' -Name DoNotSkipNonNonEnglishIso -Value $false -Initialize -Validation bool  -Description 'Indicates that non English ISO files will not be skipped'
Set-PSFConfig -Module 'AutomatedLab' -Name DefaultDnsForwarder1 -Value 1.1.1.1 -Initialize -Description 'If routing is installed on a Root DC, this forwarder is used'
Set-PSFConfig -Module 'AutomatedLab' -Name DefaultDnsForwarder2 -Value 8.8.8.8 -Initialize -Description 'If routing is installed on a Root DC, this forwarder is used'
Set-PSFConfig -Module 'AutomatedLab' -Name WinRmMaxEnvelopeSizeKb -Value 500 -Validation integerpositive -Initialize -Description 'CAREFUL! Fiddling with the defaults will likely result in errors if you do not know what you are doing! Configure a different envelope size on all lab machines if necessary.'
Set-PSFConfig -Module 'AutomatedLab' -Name WinRmMaxConcurrentOperationsPerUser -Value 1500 -Validation integerpositive -Initialize -Description 'CAREFUL! Fiddling with the defaults will likely result in errors if you do not know what you are doing! Configure a different number of per-user concurrent operations on all lab machines if necessary.'
Set-PSFConfig -Module 'AutomatedLab' -Name WinRmMaxConnections -Value 300 -Validation integerpositive -Initialize -Description 'CAREFUL! Fiddling with the defaults will likely result in errors if you do not know what you are doing! Configure a different max number of connections on all lab machines if necessary.'

#Hyper-V VM Settings
Set-PSFConfig -Module 'AutomatedLab' -Name SetLocalIntranetSites -Value 'All'  -Initialize -Validation string  -Description 'All, Forest, Domain, None'
Set-PSFConfig -Module 'AutomatedLab' -Name DisableClusterCheck -Value $false -Initialize -Validation bool -Description 'Set to true to disable checking cluster with Get-LWHyperVVM in case you are suffering from performance issues. Caution: While this speeds up deployment, the likelihood for errors increases when machines are migrated away from the host!'
Set-PSFConfig -Module 'AutomatedLab' -Name DoNotAddVmsToCluster -Value $false -Initialize -Validation bool -Description 'Set to true to skip adding VMs to a cluster if AutomatedLab is being run on a cluster node'


#Hyper-V VMConnect Settings
Set-PSFConfig -Module 'AutomatedLab' -Name VMConnectWriteConfigFile -Value $true -Initialize -Validation string -Description "Enable the writing of VMConnect config files by default"
Set-PSFConfig -Module 'AutomatedLab' -Name VMConnectDesktopSize -Value '1366, 768' -Initialize -Validation string -Description "The default resolution for Hyper-V's VMConnect.exe"
Set-PSFConfig -Module 'AutomatedLab' -Name VMConnectFullScreen -Value $false -Initialize -Validation string -Description "Enable full screen mode for VMConnect.exe"
Set-PSFConfig -Module 'AutomatedLab' -Name VMConnectUseAllMonitors -Value $false -Initialize -Validation string -Description "Use all monitors for VMConnect.exe"
Set-PSFConfig -Module 'AutomatedLab' -Name VMConnectRedirectedDrives -Value 'none' -Initialize -Validation string -Description "Drives to mount in a VMConnect session. Use '*' for all drives or a semicolon seperated list."

#Hyper-V Network settings
Set-PSFConfig -Module 'AutomatedLab' -Name MacAddressPrefix -Value '0017FB' -Initialize -Validation string -Description 'The MAC address prefix for Hyper-V labs' -Handler { if ($args[0].Length -eq 0 -or $args[0].Length -gt 11) { Write-PSFMessage -Level Error -Message "Invalid prefix length for MacAddressPrefix! $($args[0]) needs to be at least one character and at most 11 characters"; throw "Invalid prefix length for MacAddressPrefix! $($args[0]) needs to be at least one character and at most 11 characters" } }
Set-PSFConfig -Module 'AutomatedLab' -Name DisableDeviceNaming -Value $false -Validation bool -Initialize -Description 'Disables Device Naming for VM NICs. Enabled by default for Hosts > 2016 and Gen 2 Guests > 2016'

#Hyper-V Disk Settings
Set-PSFConfig -Module 'AutomatedLab' -Name CreateOnlyReferencedDisks -Value $true -Initialize -Validation bool -Description 'Disks that are not references by a VM will not be created'

#Admin Center
Set-PSFConfig -Module 'AutomatedLab' -Name WacDownloadUrl -Value 'http://aka.ms/WACDownload' -Validation string -Initialize -Description 'Windows Admin Center Download URL'
Set-PSFConfig -Module 'AutomatedLab' -Name WacMsIntermediateCaCert -Value 'https://www.microsoft.com/pkiops/certs/MicCodSigPCA2011_2011-07-08.crt' -Validation string -Initialize -Description 'Windows Admin Center Code-Signing Cert Intermediate CA cert URL'

#Host Settings
Set-PSFConfig -Module 'AutomatedLab' -Name DiskDeploymentInProgressPath -Value (Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath "LabDiskDeploymentInProgress.txt") -Initialize -Validation string -Description 'The file indicating that Hyper-V disks are being configured to reduce disk congestion'
Set-PSFConfig -Module 'AutomatedLab' -Name SwitchDeploymentInProgressPath -Value (Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath "VSwitchDeploymentInProgress.txt") -Initialize -Validation string -Description 'The file indicating that VM switches are being deployed in case multiple lab deployments are started in parallel'
Set-PSFConfig -Module 'AutomatedLab' -Name SkipHostFileModification -Value $false -Initialize -Validation bool -Description 'Indicates that the hosts file should not be modified when deploying a new lab.'

#Azure
Set-PSFConfig -Module 'AutomatedLab' -Name MinimumAzureModuleVersion -Value '4.1.0' -Initialize -Validation string -Description 'The minimum expected Azure module version'
Set-PSFConfig -Module 'AutomatedLab' -Name DefaultAzureRoleSize -Value 'D' -Initialize -Validation string -Description 'The default Azure role size, e.g. from Get-LabAzureAvailableRoleSize'
Set-PSFConfig -Module 'AutomatedLab' -Name LabSourcesMaxFileSizeMb -Value 50 -Initialize -Validation integer -Description 'The default file size for Sync-LabAzureLabSources'
Set-PSFConfig -Module 'AutomatedLab' -Name AutoSyncLabSources -Value $false -Initialize -Validation bool -Description 'Toggle auto-sync of Azure lab sources in Azure labs'
Set-PSFConfig -Module 'AutomatedLab' -Name LabSourcesSyncIntervalDays -Value 60 -Initialize -Validation integerpositive -Description 'Interval in days for lab sources auto-sync'
Set-PSFConfig -Module 'AutomatedLab' -Name AzureDiskSkus -Value @('Standard_LRS', 'Premium_LRS', 'StandardSSD_LRS') # 'UltraSSD_LRS' is not allowed!
Set-PSFConfig -Module 'AutomatedLab' -Name AzureEnableJit -Value $false -Initialize -Validation bool -Description 'Enable this setting to have AutomatedLab configure ports 22, 3389 and 5986 for JIT access. Can be done manually with Enable-LabAzureJitAccess and requested (after enabling) with Request-LabAzureJitAccess'
Set-PSFConfig -Module 'AutomatedLab' -Name AzureDisableLabSourcesStorage -Value $false -Initialize -Validation bool -Description 'Enable this setting to opt out of creating Lab Sources storage. This will prolong your lab deployment times significantly, if ISOs have to be mounted or large files have to be copied.'
Set-PSFConfig -Module 'AutomatedLab' -Name RequiredAzModules -Value @(
    # Syntax: Name, MinimumVersion, RequiredVersion
    @{
        Name           = 'Az.Accounts'
        MinimumVersion = '5.1.0'
    }
    @{
        Name           = 'Az.Storage'
        MinimumVersion = '9.0.0'
    }
    @{
        Name           = 'Az.Compute'
        MinimumVersion = '10.0.1'
    }
    @{
        Name           = 'Az.Network'
        MinimumVersion = '7.17.0'
    }
    @{
        Name           = 'Az.Resources'
        MinimumVersion = '8.0.0'
    }
    @{
        Name           = 'Az.Websites'
        MinimumVersion = '3.4.1'
    }
    @{
        Name           = 'Az.Security'
        MinimumVersion = '1.8.0'
    }
) -Initialize -Description 'Required Az modules'

Set-PSFConfig -Module 'AutomatedLab' -Name RequiredAzStackModules -Value @(
    @{
        Name           = 'Az.Accounts'
        MinimumVersion = '2.2.8'
    }
    @{
        Name           = 'Az.Storage'
        MinimumVersion = '2.6.2'
    }
    @{
        Name           = 'Az.Compute'
        MinimumVersion = '3.3.0'
    }
    @{
        Name           = 'Az.Network'
        MinimumVersion = '1.2.0'
    }
    @{
        Name           = 'Az.Resources'
        MinimumVersion = '0.12.0'
    }
    @{
        Name           = 'Az.Websites'
        MinimumVersion = '0.11.0'
    }
) -Initialize -Description 'Required Az Stack Hub modules'
Set-PSFConfig -Module 'AutomatedLab' -Name UseLatestAzureProviderApi -Value $true -Description 'Indicates that the latest provider API versions available in the labs region should be used' -Initialize -Validation bool

#Office
Set-PSFConfig -Module 'AutomatedLab' -Name OfficeDeploymentTool -Value 'https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_18827-20140.exe' -Initialize -Validation string -Description 'Link to Microsoft Office deployment tool'

#SysInternals
Set-PSFConfig -Module 'AutomatedLab' -Name SkipSysInternals -Value $false -Initialize -Validation bool -Description 'Set to true to skip downloading Sysinternals'
Set-PSFConfig -Module 'AutomatedLab' -Name SysInternalsUrl -Value 'https://technet.microsoft.com/en-us/sysinternals/bb842062' -Initialize -Validation string -Description 'Link to SysInternals to check for newer versions'
Set-PSFConfig -Module 'AutomatedLab' -Name SysInternalsDownloadUrl -Value 'https://download.sysinternals.com/files/SysinternalsSuite.zip' -Initialize -Validation string -Description 'Link to download of SysInternals'

#.net Framework
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet452DownloadLink -Value 'https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.5.2'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet46DownloadLink -Value 'http://download.microsoft.com/download/6/F/9/6F9673B1-87D1-46C4-BF04-95F24C3EB9DA/enu_netfx/NDP46-KB3045557-x86-x64-AllOS-ENU_exe/NDP46-KB3045557-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.6'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet462DownloadLink -Value 'https://download.microsoft.com/download/8/b/7/8b79adc2-162c-4cf4-a200-3aeaadc455bf/NDP462-KB3151800-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.6.2'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet471DownloadLink -Value 'https://download.microsoft.com/download/8/b/7/8b79adc2-162c-4cf4-a200-3aeaadc455bf/NDP471-KB4033342-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.7.1'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet472DownloadLink -Value 'https://download.microsoft.com/download/f/3/a/f3a6af84-da23-40a5-8d1c-49cc10c8e76f/NDP472-KB4054530-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.7.2'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet48DownloadLink -Value 'https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe' -Initialize -Validation string -Description 'Link to .NET 4.8'

# C++ redist
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist64_2017 -Value 'https://aka.ms/vs/15/release/vc_redist.x64.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2017 (x64)'
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist32_2017 -Value 'https://aka.ms/vs/15/release/vc_redist.x86.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2017 (x86)'

Set-PSFConfig -Module 'AutomatedLab' -Name cppredist64_2015 -Value 'https://download.microsoft.com/download/6/A/A/6AA4EDFF-645B-48C5-81CC-ED5963AEAD48/vc_redist.x64.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2015 (x64)'
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist32_2015 -Value 'https://download.microsoft.com/download/6/A/A/6AA4EDFF-645B-48C5-81CC-ED5963AEAD48/vc_redist.x86.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2015 (x86)'

Set-PSFConfig -Module 'AutomatedLab' -Name cppredist64_2013 -Value 'https://aka.ms/highdpimfc2013x64enu' -Initialize -Validation string -Description 'Link to VC++ redist 2013 (x64)'
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist32_2013 -Value 'https://aka.ms/highdpimfc2013x86enu' -Initialize -Validation string -Description 'Link to VC++ redist 2013 (x86)'

Set-PSFConfig -Module 'AutomatedLab' -Name cppredist64_2012 -Value 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2012 (x64)'
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist32_2012 -Value 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2012 (x86)'

Set-PSFConfig -Module 'AutomatedLab' -Name cppredist64_2010 -Value 'http://go.microsoft.com/fwlink/?LinkId=404264&clcid=0x409' -Initialize -Validation string -Description 'Link to VC++ redist 2010 (x64)'

# IIS URL Rewrite Module
Set-PSFConfig -Module automatedlab -Name IisUrlRewriteDownloadUrl -Value "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi" -Validation string -Description 'Link to IIS URL Rewrite Module needed for Exchange 2016 and 2019'

#SQL Server 2016 Management Studio
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2016ManagementStudio -Value 'https://go.microsoft.com/fwlink/?LinkID=840946' -Initialize -Validation string -Description 'Link to SSMS 2016'
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2017ManagementStudio -Value 'https://go.microsoft.com/fwlink/?linkid=2099720' -Initialize -Validation string -Description 'Link to SSMS 2017 18.2'
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2019ManagementStudio -Value 'https://aka.ms/ssmsfullsetup' -Initialize -Validation string -Description 'Link to SSMS latest'
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2022ManagementStudio -Value 'https://aka.ms/ssmsfullsetup' -Initialize -Validation string -Description 'Link to SSMS latest'

# SSRS
Set-PSFConfig -Module 'AutomatedLab' -Name SqlServerReportBuilder -Value https://download.microsoft.com/download/5/E/B/5EB40744-DC0A-47C0-8B0A-1830E74D3C23/ReportBuilder.msi
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2017SSRS -Value https://download.microsoft.com/download/E/6/4/E6477A2A-9B58-40F7-8AD6-62BB8491EA78/SQLServerReportingServices.exe
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2019SSRS -Value https://download.microsoft.com/download/1/a/a/1aaa9177-3578-4931-b8f3-373b24f63342/SQLServerReportingServices.exe
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2022SSRS -Value https://download.microsoft.com/download/8/3/2/832616ff-af64-42b5-a0b1-5eb07f71dec9/SQLServerReportingServices.exe

#SQL Server sample database contents
#Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2008 -Value 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=msftdbprodsamples&DownloadId=478218&FileTime=129906742909030000&Build=21063' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2008'
#Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2008R2 -Value 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=msftdbprodsamples&DownloadId=478218&FileTime=129906742909030000&Build=21063' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2008 R2'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2012 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2012.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2012'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2014 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2014.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2014'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2016 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2016'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2017 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2017'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2019 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2019'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2022 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2022'

#Access Database Engine
Set-PSFConfig -Module 'AutomatedLab' -Name AccessDatabaseEngine2016x86 -Value 'https://download.microsoft.com/download/3/5/C/35C84C36-661A-44E6-9324-8786B8DBE231/AccessDatabaseEngine.exe' -Initialize -Validation string -Description 'Link to Access Database Engine (required for DSC Pull)'
#TFS Build Agent
Set-PSFConfig -Module 'AutomatedLab' -Name BuildAgentUri -Value 'https://download.agent.dev.azure.com/agent/4.258.1/vsts-agent-win-x64-4.258.1.zip' -Initialize -Validation string -Description 'Link to Azure DevOps/VSTS Build Agent'

# SCVMM
Set-PSFConfig -Module 'AutomatedLab' -Name SqlOdbc11 -Value 'https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/msodbcsql.msi' -Initialize -Validation string
Set-PSFConfig -Module 'AutomatedLab' -Name SqlOdbc13 -Value 'https://download.microsoft.com/download/D/5/E/D5EEF288-A277-45C8-855B-8E2CB7E25B96/x64/msodbcsql.msi' -Initialize -Validation string
Set-PSFConfig -Module 'AutomatedLab' -Name SqlCommandLineUtils -Value 'https://download.microsoft.com/download/C/8/8/C88C2E51-8D23-4301-9F4B-64C8E2F163C5/x64/MsSqlCmdLnUtils.msi' -Initialize -Validation string
Set-PSFConfig -Module 'AutomatedLab' -Name WindowsAdk -Value 'https://download.microsoft.com/download/2/d/9/2d9c8902-3fcd-48a6-a22a-432b08bed61e/ADK/adksetup.exe' -Initialize -Validation string
Set-PSFConfig -Module 'AutomatedLab' -Name WindowsAdkPe -Value 'https://download.microsoft.com/download/5/5/6/556e01ec-9d78-417d-b1e1-d83a2eff20bc/ADKWinPEAddons/adkwinpesetup.exe' -Initialize -Validation string

# SCOM
Set-PSFConfig -Module AutomatedLab -Name SqlClrType2014 -Value 'https://download.microsoft.com/download/6/7/8/67858AF1-B1B3-48B1-87C4-4483503E71DC/ENU/x64/SQLSysClrTypes.msi' -Initialize -Validation string
Set-PSFConfig -Module AutomatedLab -Name SqlClrType2016 -Value "https://download.microsoft.com/download/6/4/5/645B2661-ABE3-41A4-BC2D-34D9A10DD303/ENU/x64/SQLSysClrTypes.msi" -Initialize -Validation string
Set-PSFConfig -Module AutomatedLab -Name SqlClrType2019 -Value "https://download.microsoft.com/download/d/d/1/dd194c5c-d859-49b8-ad64-5cbdcbb9b7bd/SQLSysClrTypes.msi" -Initialize -Validation string
Set-PSFConfig -Module 'AutomatedLab' -Name ReportViewer2015 -Value 'https://download.microsoft.com/download/A/1/2/A129F694-233C-4C7C-860F-F73139CF2E01/ENU/x86/ReportViewer.msi'

# OpenSSH
Set-PSFConfig -Module 'AutomatedLab' -Name OpenSshUri -Value 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/v7.6.0.0p1-Beta/OpenSSH-Win64.zip' -Initialize -Validation string -Description 'Link to OpenSSH binaries'
Set-PSFConfig -Module 'AutomatedLab' -Name 'AzureLocationsUrls' -Value @{
    'East US'             = 'speedtesteus'
    'East US 2'           = 'speedtesteus2'
    'South Central US'    = 'speedtestscus'
    'West US 2'           = 'speedtestwestus2'
    'Australia East'      = 'speedtestoze'
    'Southeast Asia'      = 'speedtestsea'
    'North Europe'        = 'speedtestne'
    'Sweden Central'      = 'speedtestesc'
    'UK South'            = 'speedtestuks'
    'West Europe'         = 'speedtestwe'
    'Central US'          = 'speedtestcus'
    'South Africa North'  = 'speedtestsan'
    'Central India'       = 'speedtestcentralindia'
    'East Asia'           = 'speedtestea'
    'Japan East'          = 'speedtestjpe'
    'Canada Central'      = 'speedtestcac'
    'France Central'      = 'speedtestfrc'
    'Norway East'         = 'azspeednoeast'
    'Switzerland North'   = 'speedtestchn'
    'UAE North'           = 'speedtestuaen'
    'Brazil'              = 'speedtestnea'
    'North Central US'    = 'speedtestnsus'
    'West US'             = 'speedtestwus'
    'West Central US'     = 'speedtestwestcentralus'
    'Australia Southeast' = 'speedtestozse'
    'Japan West'          = 'speedtestjpw'
    'Korea South'         = 'speedtestkoreasouth'
    'South India'         = 'speedtesteastindia'
    'West India'          = 'speedtestwestindia'
    'Canada East'         = 'speedtestcae'
    'Germany North'       = 'speedtestden'
    'Switzerland West'    = 'speedtestchw'
    'UK West'             = 'speedtestukw'
} -Initialize -Description 'Hashtable containing all Azure Speed Test URLs for automatic region placement'

Set-PSFConfig -Module 'AutomatedLab' -Name SupportGen2VMs -Value $true -Initialize -Validation bool -Description 'Indicates that Gen2 VMs are supported'
Set-PSFConfig -Module 'AutomatedLab' -Name AzureRetryCount -Value 3 -Initialize -Validation integer -Description 'The number of retries for Azure actions like creating a virtual network'

# SharePoint
Set-PSFConfig -Module AutomatedLab -Name SharePoint2013Key -Value 'N3MDM-DXR3H-JD7QH-QKKCR-BY2Y7' -Validation String -Initialize -Description 'SP 2013 trial key'
Set-PSFConfig -Module AutomatedLab -Name SharePoint2016Key -Value 'NQGJR-63HC8-XCRQH-MYVCH-3J3QR' -Validation String -Initialize -Description 'SP 2016 trial key'
Set-PSFConfig -Module AutomatedLab -Name SharePoint2019Key -Value 'M692G-8N2JP-GG8B2-2W2P7-YY7J6' -Validation String -Initialize -Description 'SP 2019 trial key'

Set-PSFConfig -Module AutomatedLab -Name SharePoint2013Prerequisites -Value @(
    'https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe'
    "http://download.microsoft.com/download/9/1/3/9138773A-505D-43E2-AC08-9A77E1E0490B/1033/x64/sqlncli.msi",
    "http://download.microsoft.com/download/8/F/9/8F93DBBD-896B-4760-AC81-646F61363A6D/WcfDataServices.exe",
    "http://download.microsoft.com/download/9/1/D/91DA8796-BE1D-46AF-8489-663AB7811517/setup_msipc_x64.msi",
    "http://download.microsoft.com/download/E/0/0/E0060D8F-2354-4871-9596-DC78538799CC/Synchronization.msi",
    "http://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe",
    "http://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/r2/MicrosoftIdentityExtensions-64.msi",
    "http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.1-KB974405-x64.msu",
    "http://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe",
    "http://download.microsoft.com/download/7/B/5/7B51D8D1-20FD-4BF0-87C7-4714F5A1C313/AppFabric1.1-RTM-KB2671763-x64-ENU.exe"
) -Initialize -Description 'List of prerequisite urls for SP2013' -Validation stringarray

Set-PSFConfig -Module AutomatedLab -Name SharePoint2016Prerequisites -Value @(
    "https://download.microsoft.com/download/B/E/D/BED73AAC-3C8A-43F5-AF4F-EB4FEA6C8F3A/ENU/x64/sqlncli.msi",
    "https://download.microsoft.com/download/3/C/F/3CF781F5-7D29-4035-9265-C34FF2369FA2/setup_msipc_x64.exe",
    "https://download.microsoft.com/download/B/9/D/B9D6E014-C949-4A1E-BA6B-2E0DEBA23E54/SyncSetup_en.x64.zip",
    "https://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe",
    "https://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/MicrosoftIdentityExtensions-64.msi",
    "https://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe",
    "https://download.microsoft.com/download/F/1/0/F1093AF6-E797-4CA8-A9F6-FC50024B385C/AppFabric-KB3092423-x64-ENU.exe",
    'https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/msodbcsql.msi'
    'https://download.microsoft.com/download/8/b/7/8b79adc2-162c-4cf4-a200-3aeaadc455bf/NDP462-KB3151800-x86-x64-AllOS-ENU.exe'
) -Initialize -Description 'List of prerequisite urls for SP2013' -Validation stringarray

Set-PSFConfig -Module AutomatedLab -Name SharePoint2019Prerequisites -Value @(
    'https://download.microsoft.com/download/F/3/C/F3C64941-22A0-47E9-BC9B-1A19B4CA3E88/ENU/x64/sqlncli.msi',
    'https://download.microsoft.com/download/3/C/F/3CF781F5-7D29-4035-9265-C34FF2369FA2/setup_msipc_x64.exe',
    'https://download.microsoft.com/download/E/0/0/E0060D8F-2354-4871-9596-DC78538799CC/Synchronization.msi',
    'https://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe',
    'https://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/MicrosoftIdentityExtensions-64.msi',
    'https://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe',
    'https://download.microsoft.com/download/F/1/0/F1093AF6-E797-4CA8-A9F6-FC50024B385C/AppFabric-KB3092423-x64-ENU.exe',
    'https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/msodbcsql.msi',
    'https://download.microsoft.com/download/f/3/a/f3a6af84-da23-40a5-8d1c-49cc10c8e76f/NDP472-KB4054530-x86-x64-AllOS-ENU.exe'
) -Initialize -Description 'List of prerequisite urls for SP2013' -Validation stringarray

# Dynamics 365 CRM
Set-PSFConfig -Module AutomatedLab -Name SqlServerNativeClient2012 -Value "https://download.microsoft.com/download/B/E/D/BED73AAC-3C8A-43F5-AF4F-EB4FEA6C8F3A/ENU/x64/sqlncli.msi" -Initialize -Validation string
Set-PSFConfig -Module AutomatedLab -Name SqlClrType2014 -Value "https://download.microsoft.com/download/1/3/0/13089488-91FC-4E22-AD68-5BE58BD5C014/ENU/x64/SQLSysClrTypes.msi" -Initialize -Validation string
Set-PSFConfig -Module AutomatedLab -Name SqlClrType2016 -Value "https://download.microsoft.com/download/6/4/5/645B2661-ABE3-41A4-BC2D-34D9A10DD303/ENU/x64/SQLSysClrTypes.msi" -Initialize -Validation string
Set-PSFConfig -Module AutomatedLab -Name SqlClrType2019 -Value "https://download.microsoft.com/download/d/d/1/dd194c5c-d859-49b8-ad64-5cbdcbb9b7bd/SQLSysClrTypes.msi" -Initialize -Validation string
Set-PSFConfig -Module AutomatedLab -Name SqlSmo2016 -Value "https://download.microsoft.com/download/6/4/5/645B2661-ABE3-41A4-BC2D-34D9A10DD303/ENU/x64/SharedManagementObjects.msi" -Initialize -Validation string
Set-PSFConfig -Module AutomatedLab -Name Dynamics365Uri -Value 'https://download.microsoft.com/download/B/D/0/BD0FA814-9885-422A-BA0E-54CBB98C8A33/CRM9.0-Server-ENU-amd64.exe' -Initialize -Validation String

# Exchange Server
Set-PSFConfig -Module AutomatedLab -Name Exchange2013DownloadUrl -Value 'https://download.microsoft.com/download/7/F/D/7FDCC96C-26C0-4D49-B5DB-5A8B36935903/Exchange2013-x64-cu23.exe'
Set-PSFConfig -Module AutomatedLab -Name Exchange2016DownloadUrl -Value 'https://download.microsoft.com/download/8/d/2/8d2d01b4-5bbb-4726-87da-0e331bc2b76f/ExchangeServer2016-x64-CU23.ISO'
Set-PSFConfig -Module AutomatedLab -Name Exchange2019DownloadUrl -Value 'https://download.microsoft.com/download/b/c/7/bc766694-8398-4258-8e1e-ce4ddb9b3f7d/ExchangeServer2019-x64-CU12.ISO'

# ConfigMgr
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerWmiExplorer -Value 'https://github.com/vinaypamnani/wmie2/releases/download/v2.0.0.2/WmiExplorer_2.0.0.2.zip' -Description 'Link to WMI explorer' -Validation string
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl1902CB -Value 'http://download.microsoft.com/download/1/B/C/1BCADBD7-47F6-40BB-8B1F-0B2D9B51B289/SC_Configmgr_SCEP_1902.exe' -Description 'Link to ConfigMgr 1902 CB' -Validation string
#Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl1902TP -Value 'http://download.microsoft.com/download/1/B/C/1BCADBD7-47F6-40BB-8B1F-0B2D9B51B289/SC_Configmgr_SCEP_1902.exe'
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2002CB -Value "https://download.microsoft.com/download/e/0/a/e0a2dd5e-2b96-47e7-9022-3030f8a1807b/MEM_Configmgr_2002.exe" -Description 'Link to ConfigMgr 2002 CB' -Validation string
#Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2002TP -Value "https://download.microsoft.com/download/D/8/E/D8E795CE-44D7-40B7-9067-D3D1313865E5/Configmgr_TechPreview2010.exe"
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2103CB -Value "https://download.microsoft.com/download/8/8/8/888d525d-5523-46ba-aca8-4709f54affa8/MEM_Configmgr_2103.exe" -Description 'Link to ConfigMgr 2103 CB' -Validation string
#Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2103TP -Value "https://download.microsoft.com/download/D/8/E/D8E795CE-44D7-40B7-9067-D3D1313865E5/Configmgr_TechPreview2103.exe"
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2203CB -Value 'https://download.microsoft.com/download/f/5/5/f55e3b9c-781d-493b-932b-16aa1b2f6371/MEM_Configmgr_2203.exe' -Description 'Link to ConfigMgr 2203 CB' -Validation string
#Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2210TP -Value "https://download.microsoft.com/download/D/8/E/D8E795CE-44D7-40B7-9067-D3D1313865E5/Configmgr_TechPreview2210.exe"
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2411TP -Value "https://download.microsoft.com/download/D/8/E/D8E795CE-44D7-40B7-9067-D3D1313865E5/ConfigMgr_TechPreview2411.exe" -Description 'Link to ConfigMgr 2411 TP' -Validation string

# Validation
Set-PSFConfig -Module AutomatedLab -Name ValidationSettings -Value @{
    ValidRoleProperties     = @{
        Orchestrator2012         = @{
            'DatabaseServer'         = '[string] Name of the database server'
            'DatabaseName'           = '[string] Name of the Database'
            'ServiceAccount'         = '[string] Name of the service account'
            'ServiceAccountPassword' = '[string] Plaintext password of the service account'
        }
        DC                       = @{
            'IsReadOnly'   = '[string] valid values true, false. Indicates a RODC'
            'SiteName'     = '[string] Name of the site to place this DC in. Defaults to Default-First-Site-Name'
            'SiteSubnet'   = '[string] Subnet CIDR, required if SiteName is used'
            'DatabasePath' = '[string] Local path for AD Database'
            'LogPath'      = '[string] Local path for LogDB'
            'SysvolPath'   = '[string] Local path for Sysvol'
            'DsrmPassword' = '[string] Plaintext DSRM password'
        }
        CaSubordinate            = @{
            'ParentCA'                   = '[string]'
            'ParentCALogicalName'        = '[string]'
            'CACommonName'               = '[string]'
            'CAType'                     = '[string] Type of Sub CA. Valid values: EnterpriseSubordinateCA, StandAloneSubordinateCA, <auto>'
            'KeyLength'                  = @'
[string] Integer in string. Valid values depend on Crypo Provider

Microsoft Base Smart Card Crypto Provider => 1024,2048,4096
Microsoft Enhanced Cryptographic Provider 1.0 => 512,1024,2048,4096
ECDSA_P256#Microsoft Smart Card Key Storage Provider => 256
ECDSA_P521#Microsoft Smart Card Key Storage Provider => 521
RSA#Microsoft Software Key Storage Provider => 512,1024,2048,4096
Microsoft Base Cryptographic Provider v1.0 => 512,1024,2048,4096
ECDSA_P521#Microsoft Software Key Storage Provider => 521
ECDSA_P256#Microsoft Software Key Storage Provider => 256
Microsoft Strong Cryptographic Provider => 512,1024,2048,4096
ECDSA_P384#Microsoft Software Key Storage Provider => 384
Microsoft Base DSS Cryptographic Provider => 512,1024
RSA#Microsoft Smart Card Key Storage Provider => 1024,2048,4096
DSA#Microsoft Software Key Storage Provider => 512,1024,2048,4096
ECDSA_P384#Microsoft Smart Card Key Storage Provider => 384
'@
            'CryptoProviderName'         = @'
[string] Name of Crypto Provider. Valid Values:

Microsoft Base Smart Card Crypto Provider
Microsoft Enhanced Cryptographic Provider 1.0
ECDSA_P256#Microsoft Smart Card Key Storage Provider
ECDSA_P521#Microsoft Smart Card Key Storage Provider
RSA#Microsoft Software Key Storage Provider
Microsoft Base Cryptographic Provider v1.0
ECDSA_P521#Microsoft Software Key Storage Provider
ECDSA_P256#Microsoft Software Key Storage Provider
Microsoft Strong Cryptographic Provider
ECDSA_P384#Microsoft Software Key Storage Provider
Microsoft Base DSS Cryptographic Provider
RSA#Microsoft Smart Card Key Storage Provider
DSA#Microsoft Software Key Storage Provider
ECDSA_P384#Microsoft Smart Card Key Storage Provider
'@
            'HashAlgorithmName'          = @'
[string] Hash algorithm to use. Valid values depend on Crypo Provider

Microsoft Base Smart Card Crypto Provider => 'sha1','md2','md4','md5'
Microsoft Enhanced Cryptographic Provider 1.0 =>'sha1','md2','md4','md5'
ECDSA_P256#Microsoft Smart Card Key Storage Provider =>'sha256','sha384','sha512','sha1'
ECDSA_P521#Microsoft Smart Card Key Storage Provider =>'sha256','sha384','sha512','sha1'
RSA#Microsoft Software Key Storage Provider =>'sha256','sha384','sha512','sha1','md5','md4','md2'
Microsoft Base Cryptographic Provider v1.0 =>'sha1','md2','md4','md5'
ECDSA_P521#Microsoft Software Key Storage Provider =>'sha256','sha384','sha512','sha1'
ECDSA_P256#Microsoft Software Key Storage Provider =>'sha256','sha384','sha512','sha1'
Microsoft Strong Cryptographic Provider =>'sha1','md2','md4','md5'
ECDSA_P384#Microsoft Software Key Storage Provider =>'sha256','sha384','sha512','sha1'
Microsoft Base DSS Cryptographic Provider =>'sha1'
RSA#Microsoft Smart Card Key Storage Provider =>'sha256','sha384','sha512','sha1','md5','md4','md2'
DSA#Microsoft Software Key Storage Provider =>'sha1'
ECDSA_P384#Microsoft Smart Card Key Storage Provider =>'sha256','sha384','sha512','sha1'
'@
            'DatabaseDirectory'          = '[string] Local path to the CA database'
            'LogDirectory'               = '[string] Local path to the CA log folder'
            'ValidityPeriod'             = '[string] CA cert validity Period. Valid values <auto>, Years, Months, Weeks, Days, Hours'
            'ValidityPeriodUnits'        = '[string] Integer in a string containing the units of the select ValidityPeriod, e.g. 6 for ValidityPeriod Weeks'
            'CertsValidityPeriod'        = '[string] Issued certificate validity period. Valid values <auto>, Years, Months, Weeks, Days, Hours'
            'CertsValidityPeriodUnits'   = '[string] Integer in a string containing the units of the select CertsValidityPeriod, e.g. 6 for CertsValidityPeriod Weeks'
            'CRLPeriod'                  = '[string] Certificate Revocation List Period. Valid values <auto>, Years, Months, Weeks, Days, Hours'
            'CRLPeriodUnits'             = '[string] Integer in a string containing the units of the select CRLPeriod, e.g. 6 for CRLPeriod Weeks'
            'CRLOverlapPeriod'           = '[string] Certificate Revocation List Overlap Period. Valid values <auto>, Years, Months, Weeks, Days, Hours'
            'CRLOverlapUnits'            = '[string] Integer in a string containing the units of the select CRLOverlapPeriod, e.g. 6 for CRLOverlapPeriod Weeks'
            'CRLDeltaPeriod'             = '[string] Delta Certificate Revocation List Period. Valid values <auto>, Years, Months, Weeks, Days, Hours'
            'CRLDeltaPeriodUnits'        = '[string] Integer in a string containing the units of the select CRLDeltaPeriod, e.g. 6 for CRLDeltaPeriod Weeks'
            'UseLDAPAIA'                 = '[string] Indicates that LDAP-hosted Authority Information Access should be used. Valid values Yes, No, <auto>'
            'UseHTTPAIA'                 = '[string] Indicates that HTTP-hosted Authority Information Access should be used. Valid values Yes, No, <auto>'
            'AIAHTTPURL01'               = '[string] HTTP (HTTPS not supported) Authority Information Access URL'
            'AIAHTTPURL02'               = '[string] HTTP (HTTPS not supported) Authority Information Access URL'
            'AIAHTTPURL01UploadLocation' = '[string] Local folder for Authority Information Access uploads'
            'AIAHTTPURL02UploadLocation' = '[string] Local folder for Authority Information Access uploads'
            'UseLDAPCRL'                 = '[string] Indicates that an LDAP-integrated CRL Distribution Point should be used. Valid values Yes, No, <auto>'
            'UseHTTPCRL'                 = '[string] Indicates that an HTTP-hosted CRL Distribution Point should be used. Valid values Yes, No, <auto>'
            'CDPHTTPURL01'               = '[string] HTTP (HTTPS not supported) CRL Distribution Point URL'
            'CDPHTTPURL02'               = '[string] HTTP (HTTPS not supported) CRL Distribution Point URL'
            'CDPHTTPURL01UploadLocation' = '[string] Local folder for  CRL Distribution Point uploads'
            'CDPHTTPURL02UploadLocation' = '[string] Local folder for  CRL Distribution Point uploads'
            'InstallWebEnrollment'       = '[string] Valid values Yes, No, <auto>'
            'InstallWebRole'             = '[string] Valid values Yes, No, <auto>'
            'CPSURL'                     = '[string] Certificate Policy Statement URL'
            'CPSText'                    = '[string] Certificate Policy Statement Text'
            'InstallOCSP'                = '[string] Indicates that the Online Responder should be enabled. Valid values Yes, No, <auto>'
            'OCSPHTTPURL01'              = '[string] HTTP (HTTPS not supported) URL for the online responder'
            'OCSPHTTPURL02'              = '[string] HTTP (HTTPS not supported) URL for the online responder'
            'DoNotLoadDefaultTemplates'  = '[string] Indicates that default templates should not be loaded. Valid value Yes - any other value disables this flag.'
        }
        Office2016               = @{
            'SharedComputerLicensing' = '[string] ???'
        }
        DSCPullServer            = @{
            'DoNotPushLocalModules' = '[string] boolean in a string, indicates that local DSC resource modules should not be publishes. Valid values 0,1, false, true'
            'DatabaseEngine'        = '[string] The database engine to use. Defaults to edb'
            'SqlServer'             = '[string] The SQL server where the database is stored, if engine is sql'
            'DatabaseName'          = '[string] The name of the database for DSC, if engine is sql. Defaults to DSC'
        }
        FirstChildDC             = @{
            'ParentDomain'          = '[string] Name of parent domain for this child domain'
            'NewDomain'             = '[string] Name of new domain'
            'DomainFunctionalLevel' = '[string] Functional level of the domain'
            'SiteName'              = '[string] Name of the site to place this DC in. Defaults to Default-First-Site-Name'
            'SiteSubnet'            = '[string] Subnet CIDR, required if SiteName is used'
            'NetBIOSDomainName'     = '[string] Name of the NETBIOS domain, eg CONTOSO'
            'DatabasePath'          = '[string] Local path for AD Database'
            'LogPath'               = '[string] Local path for LogDB'
            'SysvolPath'            = '[string] Local path for Sysvol'
            'DsrmPassword'          = '[string] Plaintext DSRM password'
        }
        ADFS                     = @(
            'DisplayName'
            'ServiceName'
            'ServicePassword'
        )
        RootDC                   = @{
            'ForestFunctionalLevel' = '[string] Functional level of the forest'
            'DomainFunctionalLevel' = '[string] Functional level of the domain'
            'SiteName'              = '[string] Name of the site to place this DC in. Defaults to Default-First-Site-Name'
            'SiteSubnet'            = '[string] Subnet CIDR, required if SiteName is used'
            'NetBIOSDomainName'     = '[string] Name of the NETBIOS domain, eg CONTOSO'
            'DatabasePath'          = '[string] Local path for AD Database'
            'LogPath'               = '[string] Local path for LogDB'
            'SysvolPath'            = '[string] Local path for Sysvol'
            'DsrmPassword'          = '[string] Plaintext DSRM password'
        }
        CaRoot                   = @{
            'CACommonName'               = '[string]'
            'CAType'                     = '[string] Type of Sub CA. Valid values: EnterpriseSubordinateCA, StandAloneSubordinateCA, <auto>'
            'KeyLength'                  = @'
[string] Integer in string. Valid values depend on Crypo Provider

Microsoft Base Smart Card Crypto Provider => 1024,2048,4096
Microsoft Enhanced Cryptographic Provider 1.0 => 512,1024,2048,4096
ECDSA_P256#Microsoft Smart Card Key Storage Provider => 256
ECDSA_P521#Microsoft Smart Card Key Storage Provider => 521
RSA#Microsoft Software Key Storage Provider => 512,1024,2048,4096
Microsoft Base Cryptographic Provider v1.0 => 512,1024,2048,4096
ECDSA_P521#Microsoft Software Key Storage Provider => 521
ECDSA_P256#Microsoft Software Key Storage Provider => 256
Microsoft Strong Cryptographic Provider => 512,1024,2048,4096
ECDSA_P384#Microsoft Software Key Storage Provider => 384
Microsoft Base DSS Cryptographic Provider => 512,1024
RSA#Microsoft Smart Card Key Storage Provider => 1024,2048,4096
DSA#Microsoft Software Key Storage Provider => 512,1024,2048,4096
ECDSA_P384#Microsoft Smart Card Key Storage Provider => 384
'@
            'CryptoProviderName'         = @'
[string] Name of Crypto Provider. Valid Values:

Microsoft Base Smart Card Crypto Provider
Microsoft Enhanced Cryptographic Provider 1.0
ECDSA_P256#Microsoft Smart Card Key Storage Provider
ECDSA_P521#Microsoft Smart Card Key Storage Provider
RSA#Microsoft Software Key Storage Provider
Microsoft Base Cryptographic Provider v1.0
ECDSA_P521#Microsoft Software Key Storage Provider
ECDSA_P256#Microsoft Software Key Storage Provider
Microsoft Strong Cryptographic Provider
ECDSA_P384#Microsoft Software Key Storage Provider
Microsoft Base DSS Cryptographic Provider
RSA#Microsoft Smart Card Key Storage Provider
DSA#Microsoft Software Key Storage Provider
ECDSA_P384#Microsoft Smart Card Key Storage Provider
'@
            'HashAlgorithmName'          = @'
[string] Hash algorithm to use. Valid values depend on Crypo Provider

Microsoft Base Smart Card Crypto Provider => 'sha1','md2','md4','md5'
Microsoft Enhanced Cryptographic Provider 1.0 =>'sha1','md2','md4','md5'
ECDSA_P256#Microsoft Smart Card Key Storage Provider =>'sha256','sha384','sha512','sha1'
ECDSA_P521#Microsoft Smart Card Key Storage Provider =>'sha256','sha384','sha512','sha1'
RSA#Microsoft Software Key Storage Provider =>'sha256','sha384','sha512','sha1','md5','md4','md2'
Microsoft Base Cryptographic Provider v1.0 =>'sha1','md2','md4','md5'
ECDSA_P521#Microsoft Software Key Storage Provider =>'sha256','sha384','sha512','sha1'
ECDSA_P256#Microsoft Software Key Storage Provider =>'sha256','sha384','sha512','sha1'
Microsoft Strong Cryptographic Provider =>'sha1','md2','md4','md5'
ECDSA_P384#Microsoft Software Key Storage Provider =>'sha256','sha384','sha512','sha1'
Microsoft Base DSS Cryptographic Provider =>'sha1'
RSA#Microsoft Smart Card Key Storage Provider =>'sha256','sha384','sha512','sha1','md5','md4','md2'
DSA#Microsoft Software Key Storage Provider =>'sha1'
ECDSA_P384#Microsoft Smart Card Key Storage Provider =>'sha256','sha384','sha512','sha1'
'@
            'DatabaseDirectory'          = '[string] Local path to the CA database'
            'LogDirectory'               = '[string] Local path to the CA log folder'
            'ValidityPeriod'             = '[string] CA cert validity Period. Valid values <auto>, Years, Months, Weeks, Days, Hours'
            'ValidityPeriodUnits'        = '[string] Integer in a string containing the units of the select ValidityPeriod, e.g. 6 for ValidityPeriod Weeks'
            'CertsValidityPeriod'        = '[string] Issued certificate validity period. Valid values <auto>, Years, Months, Weeks, Days, Hours'
            'CertsValidityPeriodUnits'   = '[string] Integer in a string containing the units of the select CertsValidityPeriod, e.g. 6 for CertsValidityPeriod Weeks'
            'CRLPeriod'                  = '[string] Certificate Revocation List Period. Valid values <auto>, Years, Months, Weeks, Days, Hours'
            'CRLPeriodUnits'             = '[string] Integer in a string containing the units of the select CRLPeriod, e.g. 6 for CRLPeriod Weeks'
            'CRLOverlapPeriod'           = '[string] Certificate Revocation List Overlap Period. Valid values <auto>, Years, Months, Weeks, Days, Hours'
            'CRLOverlapUnits'            = '[string] Integer in a string containing the units of the select CRLOverlapPeriod, e.g. 6 for CRLOverlapPeriod Weeks'
            'CRLDeltaPeriod'             = '[string] Delta Certificate Revocation List Period. Valid values <auto>, Years, Months, Weeks, Days, Hours'
            'CRLDeltaPeriodUnits'        = '[string] Integer in a string containing the units of the select CRLDeltaPeriod, e.g. 6 for CRLDeltaPeriod Weeks'
            'UseLDAPAIA'                 = '[string] Indicates that LDAP-hosted Authority Information Access should be used. Valid values Yes, No, <auto>'
            'UseHTTPAIA'                 = '[string] Indicates that HTTP-hosted Authority Information Access should be used. Valid values Yes, No, <auto>'
            'AIAHTTPURL01'               = '[string] HTTP (HTTPS not supported) Authority Information Access URL'
            'AIAHTTPURL02'               = '[string] HTTP (HTTPS not supported) Authority Information Access URL'
            'AIAHTTPURL01UploadLocation' = '[string] Local folder for Authority Information Access uploads'
            'AIAHTTPURL02UploadLocation' = '[string] Local folder for Authority Information Access uploads'
            'UseLDAPCRL'                 = '[string] Indicates that an LDAP-integrated CRL Distribution Point should be used. Valid values Yes, No, <auto>'
            'UseHTTPCRL'                 = '[string] Indicates that an HTTP-hosted CRL Distribution Point should be used. Valid values Yes, No, <auto>'
            'CDPHTTPURL01'               = '[string] HTTP (HTTPS not supported) CRL Distribution Point URL'
            'CDPHTTPURL02'               = '[string] HTTP (HTTPS not supported) CRL Distribution Point URL'
            'CDPHTTPURL01UploadLocation' = '[string] Local folder for  CRL Distribution Point uploads'
            'CDPHTTPURL02UploadLocation' = '[string] Local folder for  CRL Distribution Point uploads'
            'InstallWebEnrollment'       = '[string] Valid values Yes, No, <auto>'
            'InstallWebRole'             = '[string] Valid values Yes, No, <auto>'
            'CPSURL'                     = '[string] Certificate Policy Statement URL'
            'CPSText'                    = '[string] Certificate Policy Statement Text'
            'InstallOCSP'                = '[string] Indicates that the Online Responder should be enabled. Valid values Yes, No, <auto>'
            'OCSPHTTPURL01'              = '[string] HTTP (HTTPS not supported) URL for the online responder'
            'OCSPHTTPURL02'              = '[string] HTTP (HTTPS not supported) URL for the online responder'
            'DoNotLoadDefaultTemplates'  = '[string] Indicates that default templates should not be loaded. Valid value Yes - any other value disables this flag.'
        }
        Tfs2015                  = @{
            'Port'              = '[string] Integer, Port to use.'
            'InitialCollection' = '[string] Name of the intial collection'
            'DbServer'          = '[string] Name of the SQL server. Defaults to any available in the lab'
        }
        Tfs2017                  = @{
            'Port'              = '[string] Integer, Port to use.'
            'InitialCollection' = '[string] Name of the intial collection'
            'DbServer'          = '[string] Name of the SQL server. Defaults to any available in the lab'
        }
        Tfs2018                  = @{
            'Port'              = '[string] Integer, Port to use.'
            'InitialCollection' = '[string] Name of the intial collection'
            'DbServer'          = '[string] Name of the SQL server. Defaults to any available in the lab'
        }
        AzDevOps                 = @{
            'Port'              = '[string] Integer, Port to use.'
            'InitialCollection' = '[string] Name of the intial collection'
            'DbServer'          = '[string] Name of the SQL server. Defaults to any available in the lab'
            'PAT'               = '[string] Privileged Access Token if a hosted Azure DevOps instance is used'
            'Organisation'      = '[string] Azure DevOps Organisation, if no VM should be deployed. Format: https://dev.azure.com/YourOrgHere'
        }
        TfsBuildWorker           = @{
            'NumberOfBuildWorkers' = '[string] Integer in a string, Number of Build Worker services to host on this VM'
            'TfsServer'            = '[string] Name of the TFS/Azure DevOps server'
            'AgentPool'            = '[string] Name of the Agent Pool that will be used/created'
            'PAT'                  = '[string] Privileged Access Token if a hosted Azure DevOps instance is used'
            'Organisation'         = '[string] Azure DevOps Organisation, if no VM should be deployed. Format: https://dev.azure.com/YourOrgHere'
            'Capabilities'         = '[string] A hashtable, converted to Json (!), containing the names and values of the Agent capabilities.'
        }
        WindowsAdminCenter       = @{
            'Port' = '[string] The port WAC should listen on'
        }
        Scvmm2016                = @{
            'MUOptIn'                     = '[string] 0 or 1. Defaults to 0. Indicates that Microsoft Update should be used.'
            'SqlMachineName'              = '[string] Name of the SQL Server'
            'LibraryShareDescription'     = '[string] Description of the library share'
            'UserName'                    = '[string] User name of the server service'
            'CompanyName'                 = '[string] Name of the company'
            'IndigoHTTPSPort'             = '[string] HTTPS Port of the management (?)'
            'SQMOptIn'                    = '[string] 0 or 1. Telemetry opt in. Defaults to 0'
            'TopContainerName'            = '[string] Organizational Unit, defaults to CN=VMMServer,DC=contoso,DC=com'
            'SqlInstanceName'             = '[string] Name of the SQL Instance, defaults to MSSQLSERVER'
            'RemoteDatabaseImpersonation' = '[string] 0 or 1. Defaults to 0'
            'LibraryShareName'            = '[string] Name of the library share, defaults to MSSCVMMLibrary'
            'SqlDatabaseName'             = '[string] Name of the SQL database, defaults to VirtualManagerDB'
            'VmmServiceLocalAccount'      = '[string] 0 or 1. Defaults to 0. Indicates that a local service account should be used.'
            'IndigoNETTCPPort'            = '[string] TCP Port of management (?)'
            'CreateNewLibraryShare'       = '[string] 0 or 1, defaults to 1. Indicates if a new library share should be created'
            'WSManTcpPort'                = '[string] Web Service Management Port, defaults to 5985'
            'IndigoHTTPPort'              = '[string] HTTP Port of the management (?)'
            'ProductKey'                  = '[string] Product Key to use'
            'BitsTcpPort'                 = '[string] Port for BITS transfers. Defaults to 443'
            'CreateNewSqlDatabase'        = '[string] 0 or 1. Defaults to 1, indicates that a new DB should be created'
            'ProgramFiles'                = '[string] Install location for SCVMM. Defaults to C:\Program Files\Microsoft System Center\Virtual Machine Manager {0}'
            'LibrarySharePath'            = '[string] Library share path, defaults to C:\ProgramData\Virtual Machine Manager Library Files'
            'IndigoTcpPort'               = '[string] TCP Port of management (?)'
            'SkipServer'                  = '[string] Value irrelevant, if parameter is present, only the Console will be deployed'
            'ConnectHyperVRoleVms'        = '[string] List of Hyper-V VMs to connect, separated by ; or ,'
            'ConnectClusters'             = '[string] List of Hyper-V Clusters to connect, separated by ; or ,'
        }
        Scvmm2019                = @{
            'MUOptIn'                     = '[string] 0 or 1. Defaults to 0. Indicates that Microsoft Update should be used.'
            'SqlMachineName'              = '[string] Name of the SQL Server'
            'LibraryShareDescription'     = '[string] Description of the library share'
            'UserName'                    = '[string] User name of the server service'
            'CompanyName'                 = '[string] Name of the company'
            'IndigoHTTPSPort'             = '[string] HTTPS Port of the management (?)'
            'SQMOptIn'                    = '[string] 0 or 1. Telemetry opt in. Defaults to 0'
            'TopContainerName'            = '[string] Organizational Unit, defaults to CN=VMMServer,DC=contoso,DC=com'
            'SqlInstanceName'             = '[string] Name of the SQL Instance, defaults to MSSQLSERVER'
            'RemoteDatabaseImpersonation' = '[string] 0 or 1. Defaults to 0'
            'LibraryShareName'            = '[string] Name of the library share, defaults to MSSCVMMLibrary'
            'SqlDatabaseName'             = '[string] Name of the SQL database, defaults to VirtualManagerDB'
            'VmmServiceLocalAccount'      = '[string] 0 or 1. Defaults to 0. Indicates that a local service account should be used.'
            'IndigoNETTCPPort'            = '[string] TCP Port of management (?)'
            'CreateNewLibraryShare'       = '[string] 0 or 1, defaults to 1. Indicates if a new library share should be created'
            'WSManTcpPort'                = '[string] Web Service Management Port, defaults to 5985'
            'IndigoHTTPPort'              = '[string] HTTP Port of the management (?)'
            'ProductKey'                  = '[string] Product Key to use'
            'BitsTcpPort'                 = '[string] Port for BITS transfers. Defaults to 443'
            'CreateNewSqlDatabase'        = '[string] 0 or 1. Defaults to 1, indicates that a new DB should be created'
            'ProgramFiles'                = '[string] Install location for SCVMM. Defaults to C:\Program Files\Microsoft System Center\Virtual Machine Manager {0}'
            'LibrarySharePath'            = '[string] Library share path, defaults to C:\ProgramData\Virtual Machine Manager Library Files'
            'IndigoTcpPort'               = '[string] TCP Port of management (?)'
            'SkipServer'                  = '[string] Value irrelevant, if parameter is present, only the Console will be deployed'
            'ConnectHyperVRoleVms'        = '[string] List of Hyper-V VMs to connect, separated by ; or ,'
            'ConnectClusters'             = '[string] List of Hyper-V Clusters to connect, separated by ; or ,'
        }
        DynamicsFull             = @{
            'SqlServer'                        = '[string] Name of the SQL backend'
            'ReportingUrl'                     = '[string] URI to SQL Reporting'
            'OrganizationCollation'            = '[string] Default collation for the organization'
            'IsoCurrencyCode'                  = '[string] Currency code, e.g. USD'
            'CurrencyName'                     = '[string] Currency name, e.g. US Dollar'
            'CurrencySymbol'                   = '[string] Currency Symbol, e.g. $'
            'CurrencyPrecision'                = '[string] Precision, e.g. 2'
            'Organization'                     = '[string] Name of the organization'
            'OrganizationUniqueName'           = '[string] Unique name of the organization, usually lower-case with no separators'
            'CrmServiceAccount'                = '[string] Service account name, will be created'
            'SandboxServiceAccount'            = '[string] Service account name, will be created'
            'DeploymentServiceAccount'         = '[string] Service account name, will be created'
            'AsyncServiceAccount'              = '[string] Service account name, will be created'
            'VSSWriterServiceAccount'          = '[string] Service account name, will be created'
            'MonitoringServiceAccount'         = '[string] Service account name, will be created'
            'CrmServiceAccountPassword'        = '[string] Plaintext password for sedrvice account'
            'SandboxServiceAccountPassword'    = '[string] Plaintext password for sedrvice account'
            'DeploymentServiceAccountPassword' = '[string] Plaintext password for sedrvice account'
            'AsyncServiceAccountPassword'      = '[string] Plaintext password for sedrvice account'
            'VSSWriterServiceAccountPassword'  = '[string] Plaintext password for sedrvice account'
            'MonitoringServiceAccountPassword' = '[string] Plaintext password for sedrvice account'
            'IncomingExchangeServer'           = '[string] Exchange server for incoming messages'
            'PrivUserGroup'                    = '[string] User group DN for privileged user'
            'SQLAccessGroup'                   = '[string] User group DN for SQL access'
            'ReportingGroup'                   = '[string] User group DN for Reporting access'
            'PrivReportingGroup'               = '[string] User group DN for privileged reporting'
            'LicenseKey'                       = '[string] Defaults to trial key'
        }
        DynamicsFrontend         = @{
            'SqlServer'                        = '[string] Name of the SQL backend'
            'ReportingUrl'                     = '[string] URI to SQL Reporting'
            'OrganizationCollation'            = '[string] Default collation for the organization'
            'IsoCurrencyCode'                  = '[string] Currency code, e.g. USD'
            'CurrencyName'                     = '[string] Currency name, e.g. US Dollar'
            'CurrencySymbol'                   = '[string] Currency Symbol, e.g. $'
            'CurrencyPrecision'                = '[string] Precision, e.g. 2'
            'Organization'                     = '[string] Name of the organization'
            'OrganizationUniqueName'           = '[string] Unique name of the organization, usually lower-case with no separators'
            'CrmServiceAccount'                = '[string] Service account name, will be created'
            'SandboxServiceAccount'            = '[string] Service account name, will be created'
            'DeploymentServiceAccount'         = '[string] Service account name, will be created'
            'AsyncServiceAccount'              = '[string] Service account name, will be created'
            'VSSWriterServiceAccount'          = '[string] Service account name, will be created'
            'MonitoringServiceAccount'         = '[string] Service account name, will be created'
            'CrmServiceAccountPassword'        = '[string] Plaintext password for sedrvice account'
            'SandboxServiceAccountPassword'    = '[string] Plaintext password for sedrvice account'
            'DeploymentServiceAccountPassword' = '[string] Plaintext password for sedrvice account'
            'AsyncServiceAccountPassword'      = '[string] Plaintext password for sedrvice account'
            'VSSWriterServiceAccountPassword'  = '[string] Plaintext password for sedrvice account'
            'MonitoringServiceAccountPassword' = '[string] Plaintext password for sedrvice account'
            'IncomingExchangeServer'           = '[string] Exchange server for incoming messages'
            'PrivUserGroup'                    = '[string] User group DN for privileged user'
            'SQLAccessGroup'                   = '[string] User group DN for SQL access'
            'ReportingGroup'                   = '[string] User group DN for Reporting access'
            'PrivReportingGroup'               = '[string] User group DN for privileged reporting'
            'LicenseKey'                       = '[string] Defaults to trial key'
        }
        DynamicsBackend          = @{
            'SqlServer'                        = '[string] Name of the SQL backend'
            'ReportingUrl'                     = '[string] URI to SQL Reporting'
            'OrganizationCollation'            = '[string] Default collation for the organization'
            'IsoCurrencyCode'                  = '[string] Currency code, e.g. USD'
            'CurrencyName'                     = '[string] Currency name, e.g. US Dollar'
            'CurrencySymbol'                   = '[string] Currency Symbol, e.g. $'
            'CurrencyPrecision'                = '[string] Precision, e.g. 2'
            'Organization'                     = '[string] Name of the organization'
            'OrganizationUniqueName'           = '[string] Unique name of the organization, usually lower-case with no separators'
            'CrmServiceAccount'                = '[string] Service account name, will be created'
            'SandboxServiceAccount'            = '[string] Service account name, will be created'
            'DeploymentServiceAccount'         = '[string] Service account name, will be created'
            'AsyncServiceAccount'              = '[string] Service account name, will be created'
            'VSSWriterServiceAccount'          = '[string] Service account name, will be created'
            'MonitoringServiceAccount'         = '[string] Service account name, will be created'
            'CrmServiceAccountPassword'        = '[string] Plaintext password for sedrvice account'
            'SandboxServiceAccountPassword'    = '[string] Plaintext password for sedrvice account'
            'DeploymentServiceAccountPassword' = '[string] Plaintext password for sedrvice account'
            'AsyncServiceAccountPassword'      = '[string] Plaintext password for sedrvice account'
            'VSSWriterServiceAccountPassword'  = '[string] Plaintext password for sedrvice account'
            'MonitoringServiceAccountPassword' = '[string] Plaintext password for sedrvice account'
            'IncomingExchangeServer'           = '[string] Exchange server for incoming messages'
            'PrivUserGroup'                    = '[string] User group DN for privileged user'
            'SQLAccessGroup'                   = '[string] User group DN for SQL access'
            'ReportingGroup'                   = '[string] User group DN for Reporting access'
            'PrivReportingGroup'               = '[string] User group DN for privileged reporting'
            'LicenseKey'                       = '[string] Defaults to trial key'
        }
        DynamicsAdmin            = @{
            'SqlServer'                        = '[string] Name of the SQL backend'
            'ReportingUrl'                     = '[string] URI to SQL Reporting'
            'OrganizationCollation'            = '[string] Default collation for the organization'
            'IsoCurrencyCode'                  = '[string] Currency code, e.g. USD'
            'CurrencyName'                     = '[string] Currency name, e.g. US Dollar'
            'CurrencySymbol'                   = '[string] Currency Symbol, e.g. $'
            'CurrencyPrecision'                = '[string] Precision, e.g. 2'
            'Organization'                     = '[string] Name of the organization'
            'OrganizationUniqueName'           = '[string] Unique name of the organization, usually lower-case with no separators'
            'CrmServiceAccount'                = '[string] Service account name, will be created'
            'SandboxServiceAccount'            = '[string] Service account name, will be created'
            'DeploymentServiceAccount'         = '[string] Service account name, will be created'
            'AsyncServiceAccount'              = '[string] Service account name, will be created'
            'VSSWriterServiceAccount'          = '[string] Service account name, will be created'
            'MonitoringServiceAccount'         = '[string] Service account name, will be created'
            'CrmServiceAccountPassword'        = '[string] Plaintext password for sedrvice account'
            'SandboxServiceAccountPassword'    = '[string] Plaintext password for sedrvice account'
            'DeploymentServiceAccountPassword' = '[string] Plaintext password for sedrvice account'
            'AsyncServiceAccountPassword'      = '[string] Plaintext password for sedrvice account'
            'VSSWriterServiceAccountPassword'  = '[string] Plaintext password for sedrvice account'
            'MonitoringServiceAccountPassword' = '[string] Plaintext password for sedrvice account'
            'IncomingExchangeServer'           = '[string] Exchange server for incoming messages'
            'PrivUserGroup'                    = '[string] User group DN for privileged user'
            'SQLAccessGroup'                   = '[string] User group DN for SQL access'
            'ReportingGroup'                   = '[string] User group DN for Reporting access'
            'PrivReportingGroup'               = '[string] User group DN for privileged reporting'
            'LicenseKey'                       = '[string] Defaults to trial key'
        }
        ScomManagement           = @{
            'ManagementGroupName'           = '[string] Management Group name, defaults to SCOM<version>'
            'SqlServerInstance'             = '[string] SQL Instance to select'
            'SqlInstancePort'               = '[string] Port of the SQL instance'
            'DatabaseName'                  = '[string] SQL Database backend name'
            'DwSqlServerInstance'           = '[string] SQL Data Warehouse Server Instance name'
            'InstallLocation'               = '[string] Installation directory, defaults to C:\Program Files\Microsoft System Center\Operations Manager'
            'DwSqlInstancePort'             = '[string] SQL Data Warehouse Instance Port'
            'DwDatabaseName'                = '[string] SQL Data Warehouse Database backend name'
            'ActionAccountUser'             = '[string] Service Account, defaults to OM19AA, will be created'
            'ActionAccountPassword'         = '[string] Plaintext password for service account'
            'DASAccountUser'                = '[string] Service Account, defaults to OM19DAS, will be created'
            'DASAccountPassword'            = '[string] Plaintext password for service account'
            'DataReaderUser'                = '[string] Service Account, defaults to OM19READ, will be created'
            'DataReaderPassword'            = '[string] Plaintext password for service account'
            'DataWriterUser'                = '[string] Service Account, defaults to OM19WRITE, will be created'
            'DataWriterPassword'            = '[string] Plaintext password for service account'
            'EnableErrorReporting'          = '[string] Never, Queued or Always. Defaults to Never'
            'SendCEIPReports'               = '[string] 0 or 1, indicates that CEIP reports should be sent. Defaults to 0'
            'UseMicrosoftUpdate'            = '[string] 0 or 1, incicates that MS Update should be used. Defaults to 0'
            'AcceptEndUserLicenseAgreement' = '[string] Accept EULA. Defaults to 1. THERE IS NO POINT OF USING 0 IN A LAB'
            'ProductKey'                    = '[string] Product key to activate'
        }
        ScomConsole              = @{
            'InstallLocation'               = '[string] Installation directory, defaults to C:\Program Files\Microsoft System Center\Operations Manager'
            'EnableErrorReporting'          = '[string] Never, Queued or Always. Defaults to Never'
            'SendCEIPReports'               = '[string] 0 or 1, indicates that CEIP reports should be sent. Defaults to 0'
            'UseMicrosoftUpdate'            = '[string] 0 or 1, incicates that MS Update should be used. Defaults to 0'
            'AcceptEndUserLicenseAgreement' = '[string] Accept EULA. Defaults to 1. THERE IS NO POINT OF USING 0 IN A LAB'
        }

        ScomWebConsole           = @{
            'ManagementServer'              = '[string] Name of the SCOM management server'
            'WebSiteName'                   = '[string] Name of the website to host. Defaults to Default Web Site'
            'WebConsoleAuthorizationMode'   = '[string] Mixed or Network. Authentication method for web console. Defaults to Mixed'
            'SendCEIPReports'               = '[string] 0 or 1, indicates that CEIP reports should be sent. Defaults to 0'
            'UseMicrosoftUpdate'            = '[string] 0 or 1, incicates that MS Update should be used. Defaults to 0'
            'AcceptEndUserLicenseAgreement' = '[string] Accept EULA. Defaults to 1. THERE IS NO POINT OF USING 0 IN A LAB'
        }
                
        FailoverNode             = @{
            'ClusterName' = '[string] The name of the cluster the node will join.'
            'ClusterIP'   = '[string] The IP address of the cluster.'
        }
        HyperV                   = @{
            'MaximumStorageMigrations'                  = '[uint32] The maximum number of storage migrations allowed.'
            'MaximumVirtualMachineMigrations'           = '[uint32] The maximum number of virtual machine migrations allowed.'
            'VirtualMachineMigrationAuthenticationType' = '[Microsoft.HyperV.PowerShell.MigrationAuthenticationType] The authentication type for virtual machine migration.'
            'UseAnyNetworkForMigration'                 = '[bool] Whether to use any network for migration.'
            'VirtualMachineMigrationPerformanceOption'  = '[Microsoft.HyperV.PowerShell.VMMigrationPerformance] The performance option for virtual machine migration.'
            'ResourceMeteringSaveInterval'              = '[timespan] The save interval for resource metering.'
            'NumaSpanningEnabled'                       = '[bool] Whether NUMA spanning is enabled.'
            'EnableEnhancedSessionMode'                 = '[bool] Whether enhanced session mode is enabled.'
        }
        SQLServer2012            = @{
            'Features'              = '[string[]] The features to install. Possible values: SQLENGINE, REPLICATION, FULLTEXT, RS, AS, IS, MDS, DQC, CONN, BC, SDK, TOOLS, OCS'
            'ConfigurationFile'     = '[string] The path to the configuration file.'
            'InstanceName'          = '[string] The name of the SQL Server instance.'
            'Collation'             = '[string] The collation for the SQL Server instance.'
            'SQLSvcAccount'         = '[string] The account to run the SQL Server service.'
            'SQLSvcPassword'        = '[string] The password for the SQL Server service account.'
            'AgtSvcAccount'         = '[string] The account to run the SQL Server Agent service.'
            'AgtSvcPassword'        = '[string] The password for the SQL Server Agent service account.'
            'RsSvcAccount'          = '[string] The account to run the SQL Server Reporting Services service.'
            'RsSvcPassword'         = '[string] The password for the SQL Server Reporting Services service account.'
            'AgtSvcStartupType'     = '[string] The startup type for the SQL Server Agent service.'
            'BrowserSvcStartupType' = '[string] The startup type for the SQL Server Browser service.'
            'RsSvcStartupType'      = '[string] The startup type for the SQL Server Reporting Services service.'
            'AsSysAdminAccounts'    = '[string[]] The accounts to add to the SQL Server sysadmin role.'
            'AsSvcAccount'          = '[string] The account to run the SQL Server Analysis Services service.'
            'AsSvcPassword'         = '[string] The password for the SQL Server Analysis Services service account.'
            'IsSvcAccount'          = '[string] The account to run the SQL Server Integration Services service.'
            'IsSvcPassword'         = '[string] The password for the SQL Server Integration Services service account.'
            'SQLSysAdminAccounts'   = '[string[]] The accounts to add to the SQL Server sysadmin role.'
        }
        SQLServer2014            = @{
            'Features'              = '[string[]] The features to install. Possible values: SQLENGINE, REPLICATION, FULLTEXT, RS, AS, IS, MDS, DQC, CONN, BC, SDK, TOOLS, OCS'
            'ConfigurationFile'     = '[string] The path to the configuration file.'
            'InstanceName'          = '[string] The name of the SQL Server instance.'
            'Collation'             = '[string] The collation for the SQL Server instance.'
            'SQLSvcAccount'         = '[string] The account to run the SQL Server service.'
            'SQLSvcPassword'        = '[string] The password for the SQL Server service account.'
            'AgtSvcAccount'         = '[string] The account to run the SQL Server Agent service.'
            'AgtSvcPassword'        = '[string] The password for the SQL Server Agent service account.'
            'RsSvcAccount'          = '[string] The account to run the SQL Server Reporting Services service.'
            'RsSvcPassword'         = '[string] The password for the SQL Server Reporting Services service account.'
            'AgtSvcStartupType'     = '[string] The startup type for the SQL Server Agent service.'
            'BrowserSvcStartupType' = '[string] The startup type for the SQL Server Browser service.'
            'RsSvcStartupType'      = '[string] The startup type for the SQL Server Reporting Services service.'
            'AsSysAdminAccounts'    = '[string[]] The accounts to add to the SQL Server sysadmin role.'
            'AsSvcAccount'          = '[string] The account to run the SQL Server Analysis Services service.'
            'AsSvcPassword'         = '[string] The password for the SQL Server Analysis Services service account.'
            'IsSvcAccount'          = '[string] The account to run the SQL Server Integration Services service.'
            'IsSvcPassword'         = '[string] The password for the SQL Server Integration Services service account.'
            'SQLSysAdminAccounts'   = '[string[]] The accounts to add to the SQL Server sysadmin role.'
        }
        SQLServer2016            = @{
            'Features'              = '[string[]] The features to install. Possible values: SQLENGINE, REPLICATION, FULLTEXT, RS, AS, IS, MDS, DQC, CONN, BC, SDK, TOOLS, OCS'
            'ConfigurationFile'     = '[string] The path to the configuration file.'
            'InstanceName'          = '[string] The name of the SQL Server instance.'
            'Collation'             = '[string] The collation for the SQL Server instance.'
            'SQLSvcAccount'         = '[string] The account to run the SQL Server service.'
            'SQLSvcPassword'        = '[string] The password for the SQL Server service account.'
            'AgtSvcAccount'         = '[string] The account to run the SQL Server Agent service.'
            'AgtSvcPassword'        = '[string] The password for the SQL Server Agent service account.'
            'RsSvcAccount'          = '[string] The account to run the SQL Server Reporting Services service.'
            'RsSvcPassword'         = '[string] The password for the SQL Server Reporting Services service account.'
            'AgtSvcStartupType'     = '[string] The startup type for the SQL Server Agent service.'
            'BrowserSvcStartupType' = '[string] The startup type for the SQL Server Browser service.'
            'RsSvcStartupType'      = '[string] The startup type for the SQL Server Reporting Services service.'
            'AsSysAdminAccounts'    = '[string[]] The accounts to add to the SQL Server sysadmin role.'
            'AsSvcAccount'          = '[string] The account to run the SQL Server Analysis Services service.'
            'AsSvcPassword'         = '[string] The password for the SQL Server Analysis Services service account.'
            'IsSvcAccount'          = '[string] The account to run the SQL Server Integration Services service.'
            'IsSvcPassword'         = '[string] The password for the SQL Server Integration Services service account.'
            'SQLSysAdminAccounts'   = '[string[]] The accounts to add to the SQL Server sysadmin role.'
        }
        SQLServer2017            = @{
            'Features'              = '[string[]] The features to install. Possible values: SQLENGINE, REPLICATION, FULLTEXT, RS, AS, IS, MDS, DQC, CONN, BC, SDK, TOOLS, OCS'
            'ConfigurationFile'     = '[string] The path to the configuration file.'
            'InstanceName'          = '[string] The name of the SQL Server instance.'
            'Collation'             = '[string] The collation for the SQL Server instance.'
            'SQLSvcAccount'         = '[string] The account to run the SQL Server service.'
            'SQLSvcPassword'        = '[string] The password for the SQL Server service account.'
            'AgtSvcAccount'         = '[string] The account to run the SQL Server Agent service.'
            'AgtSvcPassword'        = '[string] The password for the SQL Server Agent service account.'
            'RsSvcAccount'          = '[string] The account to run the SQL Server Reporting Services service.'
            'RsSvcPassword'         = '[string] The password for the SQL Server Reporting Services service account.'
            'AgtSvcStartupType'     = '[string] The startup type for the SQL Server Agent service.'
            'BrowserSvcStartupType' = '[string] The startup type for the SQL Server Browser service.'
            'RsSvcStartupType'      = '[string] The startup type for the SQL Server Reporting Services service.'
            'AsSysAdminAccounts'    = '[string[]] The accounts to add to the SQL Server sysadmin role.'
            'AsSvcAccount'          = '[string] The account to run the SQL Server Analysis Services service.'
            'AsSvcPassword'         = '[string] The password for the SQL Server Analysis Services service account.'
            'IsSvcAccount'          = '[string] The account to run the SQL Server Integration Services service.'
            'IsSvcPassword'         = '[string] The password for the SQL Server Integration Services service account.'
            'SQLSysAdminAccounts'   = '[string[]] The accounts to add to the SQL Server sysadmin role.'
        }
        SQLServer2019            = @{
            'Features'              = '[string[]] The features to install. Possible values: SQLENGINE, REPLICATION, FULLTEXT, RS, AS, IS, MDS, DQC, CONN, BC, SDK, TOOLS, OCS'
            'ConfigurationFile'     = '[string] The path to the configuration file.'
            'InstanceName'          = '[string] The name of the SQL Server instance.'
            'Collation'             = '[string] The collation for the SQL Server instance.'
            'SQLSvcAccount'         = '[string] The account to run the SQL Server service.'
            'SQLSvcPassword'        = '[string] The password for the SQL Server service account.'
            'AgtSvcAccount'         = '[string] The account to run the SQL Server Agent service.'
            'AgtSvcPassword'        = '[string] The password for the SQL Server Agent service account.'
            'RsSvcAccount'          = '[string] The account to run the SQL Server Reporting Services service.'
            'RsSvcPassword'         = '[string] The password for the SQL Server Reporting Services service account.'
            'AgtSvcStartupType'     = '[string] The startup type for the SQL Server Agent service.'
            'BrowserSvcStartupType' = '[string] The startup type for the SQL Server Browser service.'
            'RsSvcStartupType'      = '[string] The startup type for the SQL Server Reporting Services service.'
            'AsSysAdminAccounts'    = '[string[]] The accounts to add to the SQL Server sysadmin role.'
            'AsSvcAccount'          = '[string] The account to run the SQL Server Analysis Services service.'
            'AsSvcPassword'         = '[string] The password for the SQL Server Analysis Services service account.'
            'IsSvcAccount'          = '[string] The account to run the SQL Server Integration Services service.'
            'IsSvcPassword'         = '[string] The password for the SQL Server Integration Services service account.'
            'SQLSysAdminAccounts'   = '[string[]] The accounts to add to the SQL Server sysadmin role.'
        }
        SQLServer2022            = @{
            'Features'              = '[string[]] The features to install. Possible values: SQLENGINE, REPLICATION, FULLTEXT, RS, AS, IS, MDS, DQC, CONN, BC, SDK, TOOLS, OCS'
            'ConfigurationFile'     = '[string] The path to the configuration file.'
            'InstanceName'          = '[string] The name of the SQL Server instance.'
            'Collation'             = '[string] The collation for the SQL Server instance.'
            'SQLSvcAccount'         = '[string] The account to run the SQL Server service.'
            'SQLSvcPassword'        = '[string] The password for the SQL Server service account.'
            'AgtSvcAccount'         = '[string] The account to run the SQL Server Agent service.'
            'AgtSvcPassword'        = '[string] The password for the SQL Server Agent service account.'
            'RsSvcAccount'          = '[string] The account to run the SQL Server Reporting Services service.'
            'RsSvcPassword'         = '[string] The password for the SQL Server Reporting Services service account.'
            'AgtSvcStartupType'     = '[string] The startup type for the SQL Server Agent service.'
            'BrowserSvcStartupType' = '[string] The startup type for the SQL Server Browser service.'
            'RsSvcStartupType'      = '[string] The startup type for the SQL Server Reporting Services service.'
            'AsSysAdminAccounts'    = '[string[]] The accounts to add to the SQL Server sysadmin role.'
            'AsSvcAccount'          = '[string] The account to run the SQL Server Analysis Services service.'
            'AsSvcPassword'         = '[string] The password for the SQL Server Analysis Services service account.'
            'IsSvcAccount'          = '[string] The account to run the SQL Server Integration Services service.'
            'IsSvcPassword'         = '[string] The password for the SQL Server Integration Services service account.'
            'SQLSysAdminAccounts'   = '[string[]] The accounts to add to the SQL Server sysadmin role.'
        }
        ScomReporting            = @{
            'ManagementServer'              = '[string] Name of the SCOM management server'
            'SRSInstance'                   = '[string] SQL Reporting Services Instance'
            'DataReaderUser'                = '[string] Service Account, defaults to OM19READ, will be created'
            'DataReaderPassword'            = '[string] Plaintext password for service account'
            'SendODRReports'                = '[string] 0 or 1, indicated that reports should be sent. Defaults to 0'
            'UseMicrosoftUpdate'            = '[string] 0 or 1, incicates that MS Update should be used. Defaults to 0'
            'AcceptEndUserLicenseAgreement' = '[string] Accept EULA. Defaults to 1. THERE IS NO POINT OF USING 0 IN A LAB'
            'InstallLocation'               = '[string] Installation directory, defaults to C:\Program Files\Microsoft System Center\Operations Manager'
        }
        RemoteDesktopSessionHost = @{
            'CollectionName'               = '[string] Name of the collection'
            'CollectionDescription'        = '[string] Description of the collection'
            'PersonalUnmanaged'            = '[string] Value irrelevant. If present, PersonalUnmanaged will be true'
            'AutoAssignUser'               = '[string] Boolean type 0,1,false or true. Indicates that users should be auto-assigned to this host'
            'GrantAdministrativePrivilege' = '[string] Boolean type 0,1,false or true. Indicates that users are granted admin privileges'
            'PooledUnmanaged'              = '[string] Value irrelevant. If present, PoolUnmanaged will be true'
        }
        RemoteDesktopGateway     = @{
            'GatewayExternalFqdn'  = '[string] External FQDN of the GW'
            'BypassLocal'          = '[string] Boolean type 0,1,false or true. Indicates whether authorized remote users bypass the RD Gateway server for local connections.'
            'LogonMethod'          = '[string] Password, GatewayAuthMode, AllowUserToSelectDuringConnection. Specifies the method for authenticating user access to the RD Gateway server'
            'UseCachedCredentials' = '[string] Boolean type 0,1,false or true. Indicates that cached credentials may be used.'
            'GatewayMode'          = '[string] DoNotUse, Custom, Automatic. Specifies a value that indicates whether or not authorized remote users use the RD Gateway server and, if so, whether they detect existing RD Gateway settings automatically or enter settings manually'
        }
        RemoteDesktopLicensing   = @{
            'Mode' = '[string] Specifies the licensing mode to configure for the deployment. Valid values are PerUser, PerDevice, and NotConfigured.'
        }
        ConfigurationManager     = @{
            'Version'         = '[string] Version to use, e.g. 2103'
            'Branch'          = '[string] Branch to use, e.g. CB'
            'Roles'           = '[string] Comma-separated list of roles in single string. Valid roles: None, Management point, Distribution Point, Software Update Point, Reporting Services Point, Endpoint Protection Point'
            'SiteName'        = '[string] CM Site Name, defaults to AutomatedLab-01'
            'SiteCode'        = '[string] CM Site Code, defaults to AL1'
            'SqlServerName'   = '[string] Name of the SQL server to use'
            'DatabaseName'    = '[string] Name of the Database to use'
            'WsusContentPath' = '[string] WSUS content directory'
            'AdminUser'       = '[string] Name of admin user'
            'ProductId'       = '[string] Product Key'
        }        
    }
    MandatoryRoleProperties = @{
        ADFSProxy = @(
            'AdfsFullName'
            'AdfsDomainName'
        )
    }
} -Initialize -Description 'Validation settings for lab validation. Please do not modify unless you know what you are doing.'

# Product key file path
$fPath = Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath 'Assets/ProductKeys.xml'
$fcPath = Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath 'Assets/ProductKeysCustom.xml'
if (-not (Test-Path -Path $fPath -ErrorAction SilentlyContinue)) {
    $null = if (-not (Test-Path -Path (Split-Path $fPath -Parent))) { New-Item -Path (Split-Path $fPath -Parent) -ItemType Directory } 
    Copy-Item -Path "$PSScriptRoot/ProductKeys.xml" -Destination $fPath -Force -ErrorAction SilentlyContinue
}
Set-PSFConfig -Module AutomatedLab -Name ProductKeyFilePath -Value $fPath -Initialize -Validation string -Description 'Destination of the ProductKeys file for Windows products'
Set-PSFConfig -Module AutomatedLab -Name ProductKeyFilePathCustom -Value $fcPath -Initialize -Validation string -Description 'Destination of the ProductKeysCustom file for Windows products'

# LabSourcesLocation
# Set-PSFConfig -Module AutomatedLab -Name LabSourcesLocation -Description 'Location of lab sources folder' -Validation string -Value ''

#endregion

#region Linux folder
if ($IsLinux -or $IsMacOs -and -not (Test-Path (Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath 'Stores'))) {
    $null = New-Item -ItemType Directory -Path (Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath 'Stores')
}
#endregion



#download the ProductKeys.xml file if it does not exist. The installer puts the file into 'C:\ProgramData\AutomatedLab\Assets'
#but when installing AL using the PowerShell Gallery, this file is missing.

$productKeyCustomFilePath = Get-PSFConfigValue AutomatedLab.ProductKeyFilePathCustom

if (-not (Test-Path -Path $productKeyCustomFilePath)) {
    $store = New-Object 'AutomatedLab.ListXmlStore[AutomatedLab.ProductKey]'

    $dummyProductKey = New-Object AutomatedLab.ProductKey -Property @{ Key = '123'; OperatingSystemName = 'OS'; Version = '1.0' }
    $store.Add($dummyProductKey)
    $store.Export($productKeyCustomFilePath)
}

#region ArgumentCompleter
Register-PSFTeppScriptblock -Name AutomatedLab-NotificationProviders -ScriptBlock {
    (Get-PSFConfig -Module AutomatedLab -Name Notifications.NotificationProviders*).FullName |
    Foreach-Object { ($_ -split '\.')[3] } | Select-Object -Unique
}

Register-PSFTeppScriptblock -Name AutomatedLab-OperatingSystem -ScriptBlock {
    $lab = if (Get-Lab -ErrorAction SilentlyContinue) {
        Get-Lab -ErrorAction SilentlyContinue
    }
    elseif (Get-LabDefinition -ErrorAction SilentlyContinue) {
        Get-LabDefinition -ErrorAction SilentlyContinue
    }

    $param = @{
        UseOnlyCache = $true
        NoDisplay    = $true
    }

    if (-not $lab -or $lab -and $lab.DefaultVirtualizationEngine -eq 'HyperV') {        
        $param['Path'] = "$labSources/ISOs"
    }
    if ($lab.DefaultVirtualizationEngine -eq 'Azure') {
        $param['Azure'] = $true
    }
    if ($lab.DefaultVirtualizationEngine -eq 'Azure' -and $lab.AzureSettings.DefaultLocation) {
        $param['Location'] = $lab.AzureSettings.DefaultLocation.DisplayName
    }

    if (-not $global:AL_OperatingSystems) {
        $global:AL_OperatingSystems = Get-LabAvailableOperatingSystem @param
    }

    $global:AL_OperatingSystems.OperatingSystemName
}

Register-PSFTeppscriptblock -Name AutomatedLab-Labs -ScriptBlock {
    $path = "$(Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot)/Labs"
    (Get-ChildItem -Path $path -Directory).Name
}

Register-PSFTeppScriptblock -Name AutomatedLab-Roles -ScriptBlock {
    [System.Enum]::GetNames([AutomatedLab.Roles])
}

Register-PSFTeppScriptblock -Name AutomatedLab-Domains -ScriptBlock {
    (Get-LabDefinition -ErrorAction SilentlyContinue).Domains.Name
}

Register-PSFTeppScriptblock -Name AutomatedLab-ComputerName -ScriptBlock {
    (Get-LabVM -All -IncludeLinux -SkipConnectionInfo).Name
}

Register-PSFTeppScriptblock -Name AutomatedLab-VMSnapshot -ScriptBlock {
    (Get-LabVMSnapshot).SnapshotName | Select-Object -Unique
}

Register-PSFTeppScriptblock -Name AutomatedLab-Subscription -ScriptBlock {
    (Get-AzSubscription -WarningAction SilentlyContinue).Name
}

Register-PSFTeppScriptblock -Name AutomatedLab-CustomRole -ScriptBlock {
    (Get-ChildItem -Path (Join-Path -Path (Get-LabSourcesLocationInternal -Local) -ChildPath 'CustomRoles' -ErrorAction SilentlyContinue) -Directory -ErrorAction SilentlyContinue).Name
}

Register-PSFTeppScriptblock -Name AutomatedLab-AzureRoleSize -ScriptBlock {
    $defaultLocation = (Get-LabAzureDefaultLocation -ErrorAction SilentlyContinue).Location
    (Get-AzVMSize -Location $defaultLocation -ErrorAction SilentlyContinue |
    Where-Object -Property Name -notlike *basic* | Sort-Object -Property Name).Name
}

Register-PSFTeppScriptblock -Name AutomatedLab-TimeZone -ScriptBlock {
    [System.TimeZoneInfo]::GetSystemTimeZones().Id | Sort-Object
}

Register-PSFTeppScriptblock -Name AutomatedLab-RhelPackage -ScriptBlock {
    (Get-LabAvailableOperatingSystem -UseOnlyCache -ErrorAction SilentlyContinue |
    Where-Object { $_.OperatingSystemType -eq 'Linux' -and $_.LinuxType -eq 'RedHat' } |
    Sort-Object Version | Select-Object -Last 1).LinuxPackageGroup
}

Register-PSFTeppScriptblock -Name AutomatedLab-SusePackage -ScriptBlock {
    (Get-LabAvailableOperatingSystem -UseOnlyCache -ErrorAction SilentlyContinue |
    Where-Object { $_.OperatingSystemType -eq 'Linux' -and $_.LinuxType -eq 'SuSE' } |
    Sort-Object Version | Select-Object -Last 1).LinuxPackageGroup

}

Register-PSFTeppScriptblock -Name AutomatedLab-UbuntuPackage -ScriptBlock {
    (Get-LabAvailableOperatingSystem -UseOnlyCache -ErrorAction SilentlyContinue |
    Where-Object { $_.OperatingSystemType -eq 'Linux' -and $_.LinuxType -eq 'Ubuntu' } |
    Sort-Object Version | Select-Object -Last 1).LinuxPackageGroup

}

Register-PSFTeppArgumentCompleter -Command Add-LabMachineDefinition -Parameter OperatingSystem -Name 'AutomatedLab-OperatingSystem'
Register-PSFTeppArgumentCompleter -Command Add-LabMachineDefinition -Parameter Roles -Name AutomatedLab-Roles
Register-PSFTeppArgumentCompleter -Command Get-Lab, Remove-Lab, Import-Lab, Import-LabDefinition -Parameter Name -Name AutomatedLab-Labs
Register-PSFTeppArgumentCompleter -Command Connect-Lab -Parameter SourceLab, DestinationLab -Name AutomatedLab-Labs
Register-PSFTeppArgumentCompleter -Command Send-ALNotification -Parameter Provider -Name AutomatedLab-NotificationProviders
Register-PSFTeppArgumentCompleter -Command Add-LabAzureSubscription -Parameter SubscriptionName -Name AutomatedLab-Subscription
Register-PSFTeppArgumentCompleter -Command Get-LabPostInstallationActivity -Parameter CustomRole -Name AutomatedLab-CustomRole
Register-PSFTeppArgumentCompleter -Command Add-LabMachineDefinition -Parameter AzureRoleSize -Name AutomatedLab-AzureRoleSize
Register-PSFTeppArgumentCompleter -Command Add-LabMachineDefinition, Enable-LabMachineAutoShutdown -Parameter TimeZone -Name AutomatedLab-TimeZone
Register-PSFTeppArgumentCompleter -Command Add-LabAzureSubscription -Parameter AutoShutdownTimeZone -Name AutomatedLab-TimeZone
Register-PSFTeppArgumentCompleter -Command Add-LabMachineDefinition -Parameter RhelPackage -Name AutomatedLab-RhelPackage
Register-PSFTeppArgumentCompleter -Command Add-LabMachineDefinition -Parameter SusePackage -Name AutomatedLab-SusePackage
Register-PSFTeppArgumentCompleter -Command Add-LabMachineDefinition -Parameter SusePackage -Name AutomatedLab-UbuntuPackage
Register-PSFTeppArgumentCompleter -Command Get-LabVMSnapshot, Checkpoint-LabVM, Restore-LabVMSnapshot -Parameter SnapshotName -Name AutomatedLab-VMSnapshot
#endregion


$dynamicLabSources = New-Object AutomatedLab.DynamicVariable 'global:labSources', { Get-LabSourcesLocationInternal }, { $null }
$executioncontext.SessionState.PSVariable.Set($dynamicLabSources)
Set-Alias -Name ?? -Value Invoke-Ternary -Option AllScope -Description "Ternary Operator like '?' in C#"
