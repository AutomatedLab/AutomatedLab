[hashtable]$configurationContent = @{
    '[Identification]'           = @{
        Action = 'InstallPrimarySite'
    }          
    '[Options]'                  = @{
        ProductID                 = 'EVAL'
        SiteCode                  = 'AL1'
        SiteName                  = 'AutomatedLab-01'
        SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
        SDKServer                 = ''
        RoleCommunicationProtocol = 'HTTPorHTTPS'
        ClientsUsePKICertificate  = 0
        PrerequisiteComp          = 1
        PrerequisitePath          = 'C:\Install\CM-Prereqs'
        AdminConsole              = 1
        JoinCEIP                  = 0
    }
           
    '[SQLConfigOptions]'         = @{
        SQLServerName = ''
        DatabaseName  = ''
    }
           
    '[CloudConnectorOptions]'    = @{
        CloudConnector       = 1
        CloudConnectorServer = ''
        UseProxy             = 0
    }
           
    '[SystemCenterOptions]'      = @{}
           
    '[HierarchyExpansionOption]' = @{}
}

$AVExcludedPaths = @(
    $VMInstallDirectory
    'C:\Install\ADK\adksetup.exe'
    'C:\Install\WinPE\adkwinpesetup.exe'
    'C:\InstallCM\SMSSETUP\BIN\X64\setup.exe'
    'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Binn\sqlservr.exe'
    'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer\bin\ReportingServicesService.exe'
    'C:\Program Files\Microsoft Configuration Manager'
    'C:\Program Files\Microsoft Configuration Manager\Inboxes'
    'C:\Program Files\Microsoft Configuration Manager\Logs'
    'C:\Program Files\Microsoft Configuration Manager\EasySetupPayload'
    'C:\Program Files\Microsoft Configuration Manager\MP\OUTBOXES'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Smsexec.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Sitecomp.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Smswriter.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Smssqlbkup.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Cmupdate.exe'
    'C:\Program Files\SMS_CCM'
    'C:\Program Files\SMS_CCM\Logs'
    'C:\Program Files\SMS_CCM\ServiceData'
    'C:\Program Files\SMS_CCM\PolReqStaging\POL00000.pol'
    'C:\Program Files\SMS_CCM\ccmexec.exe'
    'C:\Program Files\SMS_CCM\Ccmrepair.exe'
    'C:\Program Files\SMS_CCM\RemCtrl\CmRcService.exe'
    'C:\Windows\CCMSetup'
    'C:\Windows\CCMSetup\ccmsetup.exe'
    'C:\Windows\CCMCache'
)
$AVExcludedProcesses = @(
    'C:\Install\ADK\adksetup.exe'
    'C:\Install\WinPE\adkwinpesetup.exe'
    'C:\Install\CM\SMSSETUP\BIN\X64\setup.exe'
    'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Binn\sqlservr.exe'
    'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer\bin\ReportingServicesService.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Smsexec.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Sitecomp.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Smswriter.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Smssqlbkup.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Cmupdate.exe'
    'C:\Program Files\SMS_CCM\ccmexec.exe'
    'C:\Program Files\SMS_CCM\Ccmrepair.exe'
    'C:\Program Files\SMS_CCM\RemCtrl\CmRcService.exe'
    'C:\Windows\CCMSetup\ccmsetup.exe'
)

function Install-LabConfigurationManager
{
    [CmdletBinding()]
    param ()

    $vms = Get-LabVm -Role ConfigurationManager
    Start-LabVm -Role ConfigurationManager -Wait

    #region Prereq: ADK, CM binaries, stuff
    Write-ScreenInfo -Message "Installing Prerequisites on $($vms.Count) machines"
    $adkUrl = Get-LabConfigurationItem -Name WindowsAdk
    $adkPeUrl = Get-LabConfigurationItem -Name WindowsAdkPe
    $adkFile = Get-LabInternetFile -Uri $adkUrl -Path $labsources\SoftwarePackages -FileName adk.exe -PassThru -NoDisplay
    $adkpeFile = Get-LabInternetFile -Uri $adkPeUrl -Path $labsources\SoftwarePackages -FileName adkpe.exe -PassThru -NoDisplay
    
    if ($(Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        Install-LabSoftwarePackage -Path $adkFile.FullName -ComputerName $vms -CommandLine '/quiet /layout c:\ADKoffline' -NoDisplay
        Install-LabSoftwarePackage -Path $adkpeFile.FullName -ComputerName $vms -CommandLine '/quiet /layout c:\ADKPEoffline' -NoDisplay
    }
    else
    {
        Start-Process -FilePath $adkFile.FullName -ArgumentList "/quiet /layout $(Join-Path $labSources Tools/ADKoffline)" -Wait -NoNewWindow
        Start-Process -FilePath $adkpeFile.FullName -ArgumentList " /quiet /layout $(Join-Path $labSources Tools/ADKPEoffline)" -Wait -NoNewWindow
        Copy-LabFileItem -Path (Join-Path $labSources Tools/ADKoffline) -ComputerName $vms
        Copy-LabFileItem -Path (Join-Path $labSources Tools/ADKPEoffline) -ComputerName $vms
    }
    
    Install-LabSoftwarePackage -LocalPath C:\ADKOffline\adksetup.exe -ComputerName $vms -CommandLine '/norestart /q /ceip off /features OptionId.DeploymentTools OptionId.UserStateMigrationTool OptionId.ImagingAndConfigurationDesigner' -NoDisplay
    Install-LabSoftwarePackage -LocalPath C:\ADKPEOffline\adkwinpesetup.exe -ComputerName $vms -CommandLine '/norestart /q /ceip off /features OptionId.WindowsPreinstallationEnvironment' -NoDisplay

    $ncliUrl = Get-LabConfigurationItem -Name SqlServerNativeClient2012
    try
    {
        $ncli = Get-LabInternetFile -Uri $ncliUrl -Path "$labSources/SoftwarePackages" -FileName sqlncli.msi -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr" -PassThru
    }
    catch
    {
        $Message = "Failed to download SQL Native Client from '{0}' ({1})" -f $ncliUrl, $GetLabInternetFileErr.ErrorRecord.Exception.Message
        Write-LogFunctionExitWithError -Message $Message
    }

    Install-LabSoftwarePackage -Path $ncli.FullName -ComputerName $vms -CommandLine "/qn /norestart IAcceptSqlncliLicenseTerms=Yes" -ExpectedReturnCodes 0

    $WMIv2Zip = "{0}\WmiExplorer.zip" -f (Get-LabSourcesLocation -Local)
    $WMIv2Exe = "{0}\WmiExplorer.exe" -f (Get-LabSourcesLocation -Local)
    $wmiExpUrl = Get-LabConfigurationItem -Name ConfigurationManagerWmiExplorer

    try
    {
        Get-LabInternetFile -Uri $wmiExpUrl -Path (Split-Path -Path $WMIv2Zip -Parent) -FileName (Split-Path -Path $WMIv2Zip -Leaf) -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Could not download from '{0}' ({1})" -f $wmiExpUrl, $GetLabInternetFileErr.ErrorRecord.Exception.Message) -Type "Warning"
    }

    Expand-Archive -Path $WMIv2Zip -DestinationPath "$(Get-LabSourcesLocation -Local)/Tools" -ErrorAction "Stop" -Force
    try
    {
        Remove-Item -Path $WMIv2Zip -Force -ErrorAction "Stop" -ErrorVariable "RemoveItemErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Failed to delete '{0}' ({1})" -f $WMIZip, $RemoveItemErr.ErrorRecord.Exception.Message) -Type "Warning"
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure') { Sync-LabAzureLabSources -Filter WmiExplorer.exe }

    # ConfigurationManager
    foreach ($vm in $vms)
    {
        $role = $vm.Roles.Where( { $_.Name -eq 'ConfigurationManager' })
        $cmVersion = if ($role.Properties.ContainsKey('Version')) { $role.Properties.Version } else { '2103' }
        $cmBranch = if ($role.Properties.ContainsKey('Branch')) { $role.Properties.Branch } else { 'CB' }

        $VMInstallDirectory = 'C:\Install'
        $CMBinariesDirectory = "$labSources\SoftwarePackages\CM-$($cmVersion)-$cmBranch"
        $CMPreReqsDirectory = "$labSources\SoftwarePackages\CM-Prereqs-$($cmVersion)-$cmBranch"
        $VMCMBinariesDirectory = "{0}\CM" -f $VMInstallDirectory
        $VMCMPreReqsDirectory = "{0}\CM-PreReqs" -f $VMInstallDirectory

        $cmDownloadUrl = Get-LabConfigurationItem -Name "ConfigurationManagerUrl$($cmVersion)$($cmBranch)"

        if (-not $cmDownloadUrl)
        {
            Write-LogFunctionExitWithError -Message "No URI configuration for CM version $cmVersion, branch $cmBranch."
        }

        #region CM binaries
        $CMZipPath = "{0}\SoftwarePackages\{1}" -f $labsources, ((Split-Path $CMDownloadURL -Leaf) -replace "\.exe$", ".zip")

        try
        {
            $CMZipObj = Get-LabInternetFile -Uri $CMDownloadURL -Path (Split-Path -Path $CMZipPath -Parent) -FileName (Split-Path -Path $CMZipPath -Leaf) -PassThru -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr"
        }
        catch
        {
            $Message = "Failed to download from '{0}' ({1})" -f $CMDownloadURL, $GetLabInternetFileErr.ErrorRecord.Exception.Message
            Write-LogFunctionExitWithError -Message $Message
        }
        #endregion

        #region Extract CM binaries
        try
        {
            if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
            {
                Invoke-LabCommand -Computer $vm -ScriptBlock {    
                    $null = mkdir -Force $VMCMBinariesDirectory        
                    Expand-Archive -Path $CMZipObj.FullName -DestinationPath $VMCMBinariesDirectory -Force
                } -Variable (Get-Variable VMCMBinariesDirectory, CMZipObj)
            }
            else
            {
                Expand-Archive -Path $CMZipObj.FullName -DestinationPath $CMBinariesDirectory -Force -ErrorAction "Stop" -ErrorVariable "ExpandArchiveErr"
                Copy-LabFileItem -Path $CMBinariesDirectory/* -Destination $VMCMBinariesDirectory -ComputerName $vm -Recurse
            }
        
        }
        catch
        {
            $Message = "Failed to initiate extraction to '{0}' ({1})" -f $CMBinariesDirectory, $ExpandArchiveErr.ErrorRecord.Exception.Message
            Write-LogFunctionExitWithError -Message $Message
        }
        #endregion

        #region Download CM prerequisites
        switch ($cmBranch)
        {
            "CB"
            {
                if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
                {
                    Install-LabSoftwarePackage -ComputerName $vm -LocalPath $VMCMBinariesDirectory\SMSSETUP\BIN\X64\setupdl.exe -CommandLine "/NOUI $VMCMPreReqsDirectory" -UseShellExecute -AsScheduledJob
                    break       
                }
                
                try
                {
                    $p = Start-Process -FilePath $CMBinariesDirectory\SMSSETUP\BIN\X64\setupdl.exe -ArgumentList "/NOUI", $CMPreReqsDirectory -PassThru -ErrorAction "Stop" -ErrorVariable "StartProcessErr" -Wait
                    Copy-LabFileItem -Path $CMPreReqsDirectory/* -Destination $VMCMPreReqsDirectory -Recurse -ComputerName $vm
                }
                catch
                {
                    $Message = "Failed to initiate download of CM pre-req files to '{0}' ({1})" -f $CMPreReqsDirectory, $StartProcessErr.ErrorRecord.Exception.Message
                    Write-LogFunctionExitWithError -Message $Message
                }
            }
            "TP"
            {
                $Messages = @(
                    "Directory '{0}' is intentionally empty." -f $CMPreReqsDirectory
                    "The prerequisites will be downloaded by the installer within the VM."
                    "This is a workaround due to a known issue with TP 2002 baseline: https://twitter.com/codaamok/status/1268588138437509120"
                )

                try
                {
                    $CMPreReqsDirectory = "$(Get-LabSourcesLocation -Local)\SoftwarePackages\CM-Prereqs-$($cmVersion)-$cmBranch"
                    $PreReqDirObj = New-Item -Path $CMPreReqsDirectory -ItemType "Directory" -Force -ErrorAction "Stop" -ErrorVariable "CreateCMPreReqDir"
                    Set-Content -Path ("{0}\readme.txt" -f $PreReqDirObj.FullName) -Value $Messages -ErrorAction "SilentlyContinue"
                }
                catch
                {
                    $Message = "Failed to create CM prerequisite directory '{0}' ({1})" -f $CMPreReqsDirectory, $CreateCMPreReqDir.ErrorRecord.Exception.Message
                    Write-LogFunctionExitWithError -Message $Message
                }
            }
        }

        $siteParameter = @{
            CMServerName        = $vm
            CMBinariesDirectory = $CMBinariesDirectory
            Branch              = $cmBranch
            CMPreReqsDirectory  = $CMPreReqsDirectory
            CMSiteCode          = 'AL1'
            CMSiteName          = 'AutomatedLab-01'
            CMRoles             = 'Management Point', 'Distribution Point'
            DatabaseName        = 'ALCMDB'
        }

        if ($role.Properties.ContainsKey('SiteCode'))
        {
            $siteParameter.CMSiteCode = $role.Properties.SiteCode
        }

        if ($role.Properties.ContainsKey('SiteName'))
        {
            $siteParameter.CMSiteName = $role.Properties.SiteName
        }

        if ($role.Properties.ContainsKey('ProductId'))
        {
            $siteParameter.CMProductId = $role.Properties.ProductId
        }

        $validRoles = @(
            "None",
            "Management Point", 
            "Distribution Point", 
            "Software Update Point", 
            "Reporting Services Point", 
            "Endpoint Protection Point"
        )
        if ($role.Properties.ContainsKey('Roles'))
        {
            $siteParameter.CMRoles = if ($role.Properties.Roles -contains 'None')
            {
                'None'
            }
            else
            {
                $role.Properties.Roles | Where-Object { $_ -in $validRoles } | Sort-Object -Unique
            }
        }

        if ($role.Properties.ContainsKey('SqlServerName'))
        {
            $sql = $role.Properties.SqlServerName

            if (-not (Get-LabVm -ComputerName $sql.Split('.')[0]))
            {
                Write-ScreenInfo -Type Warning -Message "No SQL server called $sql found in lab. If you wanted to use an existing instance, don't forget to add it with the -SkipDeployment parameter"
            }

            $siteParameter.SqlServerName = $sql
        }
        else
        {
            $sql = (Get-LabVM -Role SQLServer2014, SQLServer2016, SQLServer2017, SQLServer2019 | Select-Object -First 1).Fqdn

            if (-not $sql)
            {
                Write-LogFunctionExitWithError -Message "No SQL server found in lab. Cannot install SCCM"
            }

            $siteParameter.SqlServerName = $sql
        }

        if ($role.Properties.ContainsKey('DatabaseName'))
        {
            $siteParameter.DatabaseName = $role.Properties.DatabaseName
        }

        if ($role.Properties.ContainsKey('WsusContentPath'))
        {
            $siteParameter.WsusContentPath = $role.Properties.WsusContentPath
        }
        Install-CMSite @siteParameter

        Restart-LabVM -ComputerName $vm

        $updateParameter = Sync-Parameter -Command (Get-Command Update-CMSite) -Parameters $siteParameter
        Update-CMSite @updateParameter
    }
    #endregion
}

function Install-CMSite
{
    Param (
        [Parameter(Mandatory)]
        [String]$CMServerName,

        [Parameter(Mandatory)]
        [String]$CMBinariesDirectory,

        [Parameter(Mandatory)]
        [String]$Branch,

        [Parameter(Mandatory)]
        [String]$CMPreReqsDirectory,

        [Parameter(Mandatory)]
        [String]$CMSiteCode,

        [Parameter(Mandatory)]
        [String]$CMSiteName,

        [Parameter()]
        [String]$CMProductId = 'EVAL',

        [Parameter(Mandatory)]
        [String[]]$CMRoles,

        [Parameter(Mandatory)]
        [string]
        $SqlServerName,

        [Parameter()]
        [string] $DatabaseName = 'ALCMDB',

        [Parameter()]
        [string] $WsusContentPath = 'C:\WsusContent'
    )

    #region Initialise
    $CMServer = Get-LabVM -ComputerName $CMServerName
    $CMServerFqdn = $CMServer.FQDN
    $DCServerName = Get-LabVM -Role RootDC | Where-Object { $_.DomainName -eq $CMServer.DomainName } | Select-Object -ExpandProperty Name
    $downloadTargetDirectory = "{0}\SoftwarePackages" -f $(Get-LabSourcesLocation -Local)
    $VMInstallDirectory = "C:\Install"
    $LabVirtualNetwork = (Get-Lab).VirtualNetworks.Where( { $_.ResourceName -eq $CMServer.Network }, 'First', 1).AddressSpace
    $CMBoundaryIPRange = "{0}-{1}" -f $LabVirtualNetwork.FirstUsable.AddressAsString, $LabVirtualNetwork.LastUsable.AddressAsString
    $VMCMBinariesDirectory = "C:\Install\CM"
    $VMCMPreReqsDirectory = "C:\Install\CM-Prereqs"
    $CMComputerAccount = '{0}\{1}$' -f $CMServer.DomainName.Substring(0, $CMServer.DomainName.IndexOf('.')), $CMServerName
    $CMSetupConfig = $configurationContent.Clone()

    $CMSetupConfig['[Options]'].SDKServer = $CMServer.FQDN
    $CMSetupConfig['[CloudConnectorOptions]'].CloudConnectorServer = $CMServer.FQDN
    $CMSetupConfig['[SQLConfigOptions]'].SQLServerName = $SqlServerName
    $CMSetupConfig['[SQLConfigOptions]'].DatabaseName = $DatabaseName

    if ($CMRoles -contains "Management Point")
    {
        $CMSetupConfig["[Options]"].ManagementPoint = $CMServerFqdn
        $CMSetupConfig["[Options]"].ManagementPointProtocol = "HTTP"
    }

    if ($CMRoles -contains "Distribution Point")
    {
        $CMSetupConfig["[Options]"]["DistributionPoint"] = $CMServerFqdn
        $CMSetupConfig["[Options]"]["DistributionPointProtocol"] = "HTTP"
        $CMSetupConfig["[Options]"]["DistributionPointInstallIIS"] = "1"
    }

    # The "Preview" key can not exist in the .ini at all if installing CB
    if ($Branch -eq "TP")
    {
        $CMSetupConfig["[Identification]"]["Preview"] = 1
    }

    $CMSetupConfigIni = "{0}\ConfigurationFile-CM-$CMServer.ini" -f $downloadTargetDirectory
    $null = New-Item -ItemType File -Path $CMSetupConfigIni -Force
    
    foreach ($kvp in $CMSetupConfig.GetEnumerator())
    {
        $kvp.Key | Add-Content -Path $CMSetupConfigIni -Encoding ASCII
        foreach ($configKvp in $kvp.Value.GetEnumerator())
        {
            "$($configKvp.Key) = $($configKvp.Value)" | Add-Content -Path $CMSetupConfigIni -Encoding ASCII
        }
    }

    # Put CM ini file in same location as SQL ini, just for consistency. Placement of SQL ini from SQL role isn't configurable.
    try
    {
        Copy-LabFileItem -Path $("{0}\ConfigurationFile-CM-$CMServer.ini" -f $downloadTargetDirectory) -DestinationFolderPath 'C:\Install' -ComputerName $CMServer
    }
    catch
    {
        $Message = "Failed to copy '{0}' to '{1}' on server '{2}' ({2})" -f $Path, $TargetDir, $CMServerName, $CopyLabFileItem.Exception.Message
        Write-LogFunctionExitWithError -Message $Message
    }
    #endregion
    
    #region Pre-req checks
    Write-ScreenInfo -Message "Checking if site is already installed" -TaskStart
    $cim = New-LabCimSession -ComputerName $CMServer
    $Query = "SELECT * FROM SMS_Site WHERE SiteCode='{0}'" -f $CMSiteCode
    $Namespace = "ROOT/SMS/site_{0}" -f $CMSiteCode

    try
    {
        $InstalledSite = Get-CimInstance -Namespace $Namespace -Query $Query -ErrorAction "Stop" -CimSession $cim -ErrorVariable ReceiveJobErr
    }
    catch
    {
        if ($ReceiveJobErr.ErrorRecord.CategoryInfo.Category -eq 'ObjectNotFound')
        {
            Write-ScreenInfo -Message "No site found, continuing"
        }
        else
        {
            Write-ScreenInfo -Message ("Could not query SMS_Site to check if site is already installed ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
            throw $ReceiveJobErr
        }
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd

    if ($InstalledSite.SiteCode -eq $CMSiteCode)
    {
        Write-ScreenInfo -Message ("Site '{0}' already installed on '{1}', skipping installation" -f $CMSiteCode, $CMServerName) -Type "Warning" -TaskEnd
        return
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Add Windows Defender exclusions
    # https://docs.microsoft.com/en-us/troubleshoot/mem/configmgr/recommended-antivirus-exclusions
    # https://docs.microsoft.com/en-us/powershell/module/defender/add-mppreference?view=win10-ps
    # https://docs.microsoft.com/en-us/powershell/module/defender/set-mppreference?view=win10-ps
    [char]$root = [IO.Path]::GetPathRoot($WsusContentPath).Substring(0, 1)
    $paths = @(
        '{0}:\SMS_DP$' -f $root
        '{0}:\SMSPKGG$' -f $root
        '{0}:\SMSPKG' -f $root
        '{0}:\SMSPKGSIG' -f $root
        '{0}:\SMSSIG$' -f $root
        '{0}:\RemoteInstall' -f $root
        '{0}:\WSUS' -f $root
    )
    foreach ($p in $paths) { $AVExcludedPaths += $p }
    Write-ScreenInfo -Message "Adding Windows Defender exclusions" -TaskStart
    $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Adding Windows Defender exclusions" -Variable (Get-Variable "AVExcludedPaths", "AVExcludedProcesses") -ScriptBlock {
        Add-MpPreference -ExclusionPath $AVExcludedPaths -ExclusionProcess $AVExcludedProcesses -ErrorAction "Stop"
        Set-MpPreference -RealTimeScanDirection "Incoming" -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try
    {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Failed to add Windows Defender exclusions ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Bringing online additional disks
    Write-ScreenInfo -Message "Bringing online additional disks" -TaskStart
    #Bringing all available disks online (this is to cater for the secondary drive)
    #For some reason, cant make the disk online and RW in the one command, need to perform two seperate actions
    
    $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Bringing online additional online" -ScriptBlock {
        $dataVolume = Get-Disk -ErrorAction "Stop" | Where-Object -Property OperationalStatus -eq Offline
        $dataVolume | Set-Disk -IsOffline $false -ErrorAction "Stop"
        $dataVolume | Set-Disk -IsReadOnly $false -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try
    {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Failed to bring disks online ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Saving NO_SMS_ON_DRIVE.SMS file on C: and F:
    $job = Invoke-LabCommand -ComputerName $CMServer -Variable (Get-Variable WsusContentPath) -ActivityName "Place NO_SMS_ON_DRIVE.SMS file" -ScriptBlock {
        [char]$root = [IO.Path]::GetPathRoot($WsusContentPath).Substring(0, 1)
        foreach ($volume in (Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveLetter -ne $root }))
        {
            $Path = "{0}:\NO_SMS_ON_DRIVE.SMS" -f $volume.DriveLetter
            New-Item -Path $Path -ItemType "File" -ErrorAction "Stop" -Force
        }
    }
    Wait-LWLabJob -Job $job
    try
    {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Failed to create NO_SMS_ON_DRIVE.SMS ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    #endregion

    #region Create directory for WSUS
    Write-ScreenInfo -Message "Creating directory for WSUS" -TaskStart
    if ($CMRoles -contains "Software Update Point")
    {
        $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Creating directory for WSUS" -Variable (Get-Variable -Name "CMComputerAccount", WsusContentPath) -ScriptBlock {
            New-Item -Path $WsusContentPath -ItemType Directory -Force -ErrorAction "Stop" | Out-Null
        }
        Wait-LWLabJob -Job $job
        try
        {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch
        {
            Write-ScreenInfo -Message ("Failed to create directory for WSUS ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Software Update Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion
    
    

    #region Restart computer
    Write-ScreenInfo -Message "Restarting server" -TaskStart
    Restart-LabVM -ComputerName $CMServerName -Wait -ErrorAction "Stop"
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Extend the AD Schema
    Write-ScreenInfo -Message "Extending the AD Schema" -TaskStart
    $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Extending the AD Schema" -Variable (Get-Variable -Name "VMCMBinariesDirectory") -ScriptBlock {
        $Path = "{0}\SMSSETUP\BIN\X64\extadsch.exe" -f $VMCMBinariesDirectory
        Start-Process $Path -Wait -PassThru -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try
    {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Failed to extend the AD Schema ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Configure CM Systems Management Container
    #Need to execute this command on the Domain Controller, since it has the AD Powershell cmdlets available
    #Create the Necessary OU and permissions for the CM container in AD
    Write-ScreenInfo -Message "Configuring CM Systems Management Container" -TaskStart
    $job = Invoke-LabCommand -ComputerName $DCServerName -ActivityName "Configuring CM Systems Management Container" -ArgumentList $CMServerName -ScriptBlock {
        Param (
            [Parameter(Mandatory)]
            [String]$CMServerName
        )

        Import-Module ActiveDirectory
        # Figure out our domain
        $rootDomainNc = (Get-ADRootDSE).defaultNamingContext

        # Get or create the System Management container
        $ou = $null
        try
        {
            $ou = Get-ADObject "CN=System Management,CN=System,$rootDomainNc"
        }
        catch
        {   
            Write-Verbose "System Management container does not currently exist."
            $ou = New-ADObject -Type Container -name "System Management" -Path "CN=System,$rootDomainNc" -Passthru
        }

        # Get the current ACL for the OU
        $acl = Get-ACL -Path "ad:CN=System Management,CN=System,$rootDomainNc"

        # Get the computer's SID (we need to get the computer object, which is in the form <ServerName>$)
        $CMComputer = Get-ADComputer "$CMServerName$"
        $CMServerSId = [System.Security.Principal.SecurityIdentifier] $CMComputer.SID

        $ActiveDirectoryRights = "GenericAll"
        $AccessControlType = "Allow"
        $Inherit = "SelfAndChildren"
        $nullGUID = [guid]'00000000-0000-0000-0000-000000000000'

        # Create a new access control entry to allow access to the OU
        $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $CMServerSId, $ActiveDirectoryRights, $AccessControlType, $Inherit, $nullGUID
        
        # Add the ACE to the ACL, then set the ACL to save the changes
        $acl.AddAccessRule($ace)
        Set-ACL -AclObject $acl "ad:CN=System Management,CN=System,$rootDomainNc"
    }
    Wait-LWLabJob -Job $job
    try
    {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Failed to configure the Systems Management Container" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Install WSUS
    Write-ScreenInfo -Message "Installing WSUS" -TaskStart
    if ($CMRoles -contains "Software Update Point")
    {
        $job = Install-LabWindowsFeature -FeatureName "UpdateServices-Services,UpdateServices-DB" -IncludeManagementTools -ComputerName $CMServer
        Wait-LWLabJob -Job $job
        try
        {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch
        {
            Write-ScreenInfo -Message ("Failed installing WSUS ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Software Update Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Run WSUS post configuration tasks
    Write-ScreenInfo -Message "Running WSUS post configuration tasks" -TaskStart
    if ($CMRoles -contains "Software Update Point")
    {
        $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Running WSUS post configuration tasks" -Variable (Get-Variable "SqlServerName", WsusContentPath) -ScriptBlock {
            Start-Process -FilePath "C:\Program Files\Update Services\Tools\wsusutil.exe" -ArgumentList "postinstall", "SQL_INSTANCE_NAME=`"$SqlServerName`"", "CONTENT_DIR=`"$WsusContentPath`"" -Wait -ErrorAction "Stop"
        }
        Wait-LWLabJob -Job $job
        try
        {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch
        {
            Write-ScreenInfo -Message ("Failed running WSUS post configuration tasks ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Software Update Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Install additional features
    Write-ScreenInfo -Message "Installing additional features (1/2)" -TaskStart
    $job = Install-LabWindowsFeature -ComputerName $CMServer -FeatureName "FS-FileServer,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Web-WMI,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Static-Content,Web-Http-Redirect,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-Asp-Net,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter"
    Wait-LWLabJob -Job $job
    try
    {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Failed installing additional features (1/2) ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    
    Write-ScreenInfo -Message "Installing additional features (2/2)" -TaskStart
    $job = Install-LabWindowsFeature -ComputerName $CMServer -FeatureName "NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-Framework-45-ASPNET,NET-WCF-HTTP-Activation45,BITS,RDC"
    Wait-LWLabJob -Job $job
    try
    {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Failed installing additional features (2/2) ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Restart
    Write-ScreenInfo -Message "Restarting server" -TaskStart
    Restart-LabVM -ComputerName $CMServerName -Wait -ErrorAction "Stop"
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
    
    #region Install Configuration Manager
    Write-ScreenInfo "Installing Configuration Manager" -TaskStart
    $exePath = "{0}\SMSSETUP\BIN\X64\setup.exe" -f $VMCMBinariesDirectory
    $iniPath = "C:\Install\ConfigurationFile-CM-$CMServer.ini"
    $cmd = "/Script `"{0}`" /NoUserInput" -f $iniPath
    $job = Install-LabSoftwarePackage -LocalPath $exePath -CommandLine $cmd -ProgressIndicator 2 -ExpectedReturnCodes 0 -ComputerName $CMServer
    Wait-LWLabJob -Job $job
    try
    {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Failed to install Configuration Manager ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Restart
    Write-ScreenInfo -Message "Restarting server" -TaskStart
    Restart-LabVM -ComputerName $CMServerName -Wait -ErrorAction "Stop"
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Validating install
    Write-ScreenInfo -Message "Validating install" -TaskStart
    $cim = New-LabCimSession -ComputerName $CMServer
    $Query = "SELECT * FROM SMS_Site WHERE SiteCode='{0}'" -f $CMSiteCode
    $Namespace = "ROOT/SMS/site_{0}" -f $CMSiteCode

    try
    {
        $result = Get-CimInstance -Namespace $Namespace -Query $Query -ErrorAction "Stop" -CimSession $cim -ErrorVariable ReceiveJobErr
    }
    catch
    {
        $Message = "Failed to validate install, could not find site code '{0}' in SMS_Site class ({1})" -f $CMSiteCode, $ReceiveJobErr.ErrorRecord.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Install PXE Responder
    Write-ScreenInfo -Message "Installing PXE Responder" -TaskStart
    if ($CMRoles -contains "Distribution Point")
    {
        New-LoopAction -LoopTimeout 15 -LoopTimeoutType "Minutes" -LoopDelay 60 -ScriptBlock {
            $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Installing PXE Responder" -Variable (Get-Variable "CMServerFqdn", "CMServerName") -Function (Get-Command "Import-CMModule") -ScriptBlock {
                Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
                Set-CMDistributionPoint -SiteSystemServerName $CMServerFqdn -AllowPxeResponse $true -EnablePxe $true -EnableNonWdsPxe $true -ErrorAction "Stop"
                do
                {
                    Start-Sleep -Seconds 5
                } while ((Get-Service).Name -notcontains "SccmPxe")
                Write-Output "Installed"
            }
            Wait-LWLabJob -Job $job
            try
            {
                $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
            }
            catch
            {
                $Message = "Failed to install PXE Responder ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
                Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
                throw $ReceiveJobErr
            }
        } -IfTimeoutScript {
            $Message = "Timed out waiting for PXE Responder to install"
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $Message
        } -ExitCondition {
            $result -eq "Installed"
        } -IfSucceedScript {
            Write-ScreenInfo -Message "Activity done" -TaskEnd
        }
    }
    else
    {
        Write-ScreenInfo -Message "Distribution Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Configuring Distribution Point group
    Write-ScreenInfo -Message "Configuring Distribution Point group" -TaskStart
    if ($CMRoles -contains "Distribution Point")
    {
        $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Configuring boundary and boundary group" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            $DPGroup = New-CMDistributionPointGroup -Name "All DPs" -ErrorAction "Stop"
            Add-CMDistributionPointToGroup -DistributionPointGroupId $DPGroup.GroupId -DistributionPointName $CMServerFqdn -ErrorAction "Stop"
        }
        Wait-LWLabJob -Job $job
        try
        {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch
        {
            $Message = "Failed while configuring Distribution Point group ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Distribution Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Install Sofware Update Point
    Write-ScreenInfo -Message "Installing Software Update Point" -TaskStart
    if ($CMRoles -contains "Software Update Point")
    {
        $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Installing Software Update Point" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode") -Function (Get-Command "Import-CMModule") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            Add-CMSoftwareUpdatePoint -WsusIisPort 8530 -WsusIisSslPort 8531 -SiteSystemServerName $CMServerFqdn -SiteCode $CMSiteCode -ErrorAction "Stop"
        }
        Wait-LWLabJob -Job $job
        try
        {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch
        {
            $Message = "Failed to install Software Update Point ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Software Update Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Add CM account to use for Reporting Service Point
    Write-ScreenInfo -Message ("Adding new CM account '{0}' to use for Reporting Service Point" -f $AdminUser) -TaskStart
    if ($CMRoles -contains "Reporting Services Point")
    {
        $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName ("Adding new CM account '{0}' to use for Reporting Service Point" -f $AdminUser) -Variable (Get-Variable "CMServerName", "CMSiteCode", "AdminUser", "AdminPass") -Function (Get-Command "Import-CMModule") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            $Account = "{0}\{1}" -f $env:USERDOMAIN, $AdminUser
            $Secure = ConvertTo-SecureString -String $AdminPass -AsPlainText -Force
            New-CMAccount -Name $Account -Password $Secure -SiteCode $CMSiteCode -ErrorAction "Stop"
        }
        Wait-LWLabJob -Job $job
        try
        {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch
        {
            $Message = "Failed to add new CM account ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Reporting Services Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Install Reporting Service Point
    Write-ScreenInfo -Message "Installing Reporting Service Point" -TaskStart
    if ($CMRoles -contains "Reporting Services Point")
    {
        $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Installing Reporting Service Point" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode", "AdminUser") -Function (Get-Command "Import-CMModule") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            $Account = "{0}\{1}" -f $env:USERDOMAIN, $AdminUser
            Add-CMReportingServicePoint -SiteCode $CMSiteCode -SiteSystemServerName $CMServerFqdn -ReportServerInstance "SSRS" -UserName $Account -ErrorAction "Stop"
        }
        Wait-LWLabJob -Job $job
        try
        {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch
        {
            $Message = "Failed to install Reporting Service Point ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Reporting Services Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Install Endpoint Protection Point
    Write-ScreenInfo -Message "Installing Endpoint Protection Point" -TaskStart
    if ($CMRoles -contains "Endpoint Protection Point")
    {
        $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Installing Endpoint Protection Point" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            Add-CMEndpointProtectionPoint -ProtectionService "DoNotJoinMaps" -SiteCode $CMSiteCode -SiteSystemServerName $CMServerFqdn -ErrorAction "Stop"
        }
        Wait-LWLabJob -Job $job
        try
        {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch
        {
            $Message = "Failed to install Endpoint Protection Point ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Endpoint Protection Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Configure boundary and boundary group
    Write-ScreenInfo -Message "Configuring boundary and boundary group" -TaskStart
    $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Configuring boundary and boundary group" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode", "CMSiteName", "CMBoundaryIPRange") -ScriptBlock {
        Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
        $Boundary = New-CMBoundary -DisplayName $CMSiteName -Type "IPRange" -Value $CMBoundaryIPRange -ErrorAction "Stop"
        $BoundaryGroup = New-CMBoundaryGroup -Name $CMSiteName -AddSiteSystemServerName $CMServerFqdn -ErrorAction "Stop"
        Add-CMBoundaryToGroup -BoundaryGroupId $BoundaryGroup.GroupId -BoundaryId $Boundary.BoundaryId -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try
    {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch
    {
        $Message = "Failed configuring boundary and boundary group ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
}

function Update-CMSite
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String]$CMSiteCode,

        [Parameter(Mandatory)]
        [String]$CMServerName,

        [Parameter(Mandatory)]
        [String]$Version
    )

    #region Initialise
    $CMServer = Get-LabVM -ComputerName $CMServerName
    $CMServerFqdn = $CMServer.FQDN
    #endregion

    #region Define enums
    enum SMS_CM_UpdatePackages_State
    {
        AvailableToDownload = 327682
        ReadyToInstall = 262146
        Downloading = 262145
        Installed = 196612
        Failed = 262143
    }
    #endregion

    #region Ensuring CONFIGURATION_MANAGER_UPDATE service is running
    Write-ScreenInfo -Message "Ensuring CONFIGURATION_MANAGER_UPDATE service is running" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Ensuring CONFIGURATION_MANAGER_UPDATE service is running" -ScriptBlock {
        $service = "CONFIGURATION_MANAGER_UPDATE"
        if ((Get-Service $service | Select-Object -ExpandProperty Status) -ne "Running")
        {
            Start-Service "CONFIGURATION_MANAGER_UPDATE" -ErrorAction "Stop"
        }
    }
    Wait-LWLabJob -Job $job
    try
    {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Could not start CONFIGURATION_MANAGER_UPDATE service ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Finding update for target version
    Write-ScreenInfo -Message "Waiting for updates to appear in console" -TaskStart
    $Update = New-LoopAction -LoopTimeout 30 -LoopTimeoutType "Minutes" -LoopDelay 60 -LoopDelayType "Seconds" -ExitCondition {
        $Update
    } -IfTimeoutScript {
        # Writing dot because of -NoNewLine in Wait-LWLabJob
        Write-ScreenInfo -Message "."
        Write-ScreenInfo -Message "No updates available" -TaskEnd
        # Exit rather than throw, so we can resume with whatever else is in HostStart.ps1
        exit
    } -IfSucceedScript {
        return $Update
    } -ScriptBlock {
        $cim = New-LabCimSession -ComputerName $CMServer
        $Query = "SELECT * FROM SMS_CM_UpdatePackages WHERE Impact = '31'"
            
        try
        {
            $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction "Stop" -ErrorVariable ReceiveJobErr -CimSession $cim | Sort-object -Property FullVersion -Descending
        }
        catch
        {
            Write-ScreenInfo -Message ("Could not query SMS_CM_UpdatePackages to find latest update ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
            throw $ReceiveJobErr
        }
    }
    
    if ($Version -eq "Latest")
    {
        # https://github.com/PowerShell/PowerShell/issues/9185
        $Update = $Update[0]
    }
    else
    {
        $Update = $Update | Where-Object { $_.Name -like "*$Version*" }
    }

    # Writing dot because of -NoNewLine in Wait-LWLabJob
    Write-ScreenInfo -Message "."
    Write-ScreenInfo -Message ("Found update: '{0}' {1} ({2})" -f $Update.Name, $Update.FullVersion, $Update.PackageGuid)
    $UpdatePackageGuid = $Update.PackageGuid
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Initiate download and wait for state to change to Downloading
    if ($Update.State -eq [SMS_CM_UpdatePackages_State]::AvailableToDownload)
    {

        Write-ScreenInfo -Message "Initiating download" -TaskStart
        if ($Update.State -eq [SMS_CM_UpdatePackages_State]::AvailableToDownload)
        {
            $job = Invoke-LabCommand -ActivityName "Initiating download" -Variable (Get-Variable -Name "Update") -ScriptBlock {
                Invoke-CimMethod -InputObject $Update -MethodName "SetPackageToBeDownloaded" -ErrorAction "Stop"
            }
            Wait-LWLabJob -Job $job
            try
            {
                $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
            }
            catch
            {
                Write-ScreenInfo -Message ("Failed to initiate download ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
                throw $ReceiveJobErr
            }
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd

        # If State doesn't change after 15 minutes, restart SMS_EXECUTIVE service and repeat this 3 times, otherwise quit.
        Write-ScreenInfo -Message "Verifying update download initiated OK" -TaskStart
        $Update = New-LoopAction -Iterations 3 -LoopDelay 1 -ExitCondition {
            [SMS_CM_UpdatePackages_State]::Downloading, [SMS_CM_UpdatePackages_State]::ReadyToInstall -contains $Update.State
        } -IfTimeoutScript {
            $Message = "Could not initiate download (timed out)"
            Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
            throw $Message
        } -IfSucceedScript {
            return $Update
        } -ScriptBlock {
            $Update = New-LoopAction -LoopTimeout 15 -LoopTimeoutType "Minutes" -LoopDelay 5 -LoopDelayType "Seconds" -ExitCondition {
                [SMS_CM_UpdatePackages_State]::Downloading, [SMS_CM_UpdatePackages_State]::ReadyToInstall -contains $Update.State
            } -IfSucceedScript {
                return $Update
            } -IfTimeoutScript {
                # Writing dot because of -NoNewLine in Wait-LWLabJob
                Write-ScreenInfo -Message "."
                Write-ScreenInfo -Message "Download did not start, restarting SMS_EXECUTIVE" -TaskStart -Type "Warning"
                try
                {
                    Restart-ServiceResilient -ComputerName $CMServerName -ServiceName "SMS_EXECUTIVE" -ErrorAction "Stop" -ErrorVariable "RestartServiceResilientErr"
                }
                catch
                {
                    $Message = "Could not restart SMS_EXECUTIVE ({0})" -f $RestartServiceResilientErr.ErrorRecord.Exception.Message
                    Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
                    throw $Message
                }
                Write-ScreenInfo -Message "Activity done" -TaskEnd
            } -ScriptBlock {
                $cim = New-LabCimSession -ComputerName $CMServer
                $Query = "SELECT * FROM SMS_CM_UPDATEPACKAGES WHERE PACKAGEGUID = '{0}'" -f $UpdatePackageGuid
                    
                try
                {
                    $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction "Stop" -ErrorVariable ReceiveJobErr -CimSession $cim
                }
                catch
                {
                    Write-ScreenInfo -Message ("Failed to query SMS_CM_UpdatePackages after initiating download (2) ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
                    throw $ReceiveJobErr
                }
            }
        }
        # Writing dot because of -NoNewLine in Wait-LWLabJob
        Write-ScreenInfo -Message "."
        Write-ScreenInfo -Message "Activity done" -TaskEnd

    }
    #endregion
    
    #region Wait for update to finish download
    if ($Update.State -eq [SMS_CM_UpdatePackages_State]::Downloading)
    {

        Write-ScreenInfo -Message "Waiting for update to finish downloading" -TaskStart
        $Update = New-LoopAction -LoopTimeout 604800 -LoopTimeoutType "Seconds" -LoopDelay 15 -LoopDelayType "Seconds" -ExitCondition {
            $Update.State -eq [SMS_CM_UpdatePackages_State]::ReadyToInstall
        } -IfTimeoutScript {
            # Writing dot because of -NoNewLine in Wait-LWLabJob
            Write-ScreenInfo -Message "."
            $Message = "Download timed out"
            Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
            throw $Message
        } -IfSucceedScript {
            # Writing dot because of -NoNewLine in Wait-LWLabJob
            Write-ScreenInfo -Message "."
            return $Update
        } -ScriptBlock {
            $cim = New-LabCimSession -ComputerName $CMServer
            $Query = "SELECT * FROM SMS_CM_UPDATEPACKAGES WHERE PACKAGEGUID = '{0}'" -f $Update.PackageGuid
                
            try
            {
                $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction "Stop" -ErrorVariable ReceiveJobErr -CimSession $cim
            }
            catch
            {
                Write-ScreenInfo -Message ("Failed to query SMS_CM_UpdatePackages waiting for download to complete ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
                throw $ReceiveJobErr
            }
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd

    }
    #endregion
    
    #region Initiate update install and wait for state to change to Installed
    if ($Update.State -eq [SMS_CM_UpdatePackages_State]::ReadyToInstall)
    {

        Write-ScreenInfo -Message "Waiting for SMS_SITE_COMPONENT_MANAGER to enter an idle state" -TaskStart
        $ServiceState = New-LoopAction -LoopTimeout 30 -LoopTimeoutType "Minutes" -LoopDelay 1 -LoopDelayType "Minutes" -ExitCondition {
            $sitecomplog -match '^Waiting for changes' -as [bool] -eq $true
        } -IfTimeoutScript {
            # Writing dot because of -NoNewLine in Wait-LWLabJob
            Write-ScreenInfo -Message "."
            $Message = "Timed out waiting for SMS_SITE_COMPONENT_MANAGER"
            Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
            throw $Message
        } -IfSucceedScript {
            # Writing dot because of -NoNewLine in Wait-LWLabJob
            Write-ScreenInfo -Message "."
            return $Update
        } -ScriptBlock {
            $job = Invoke-LabCommand -ActivityName "Reading sitecomp.log to determine SMS_SITE_COMPONENT_MANAGER state" -ScriptBlock {
                Get-Content -Path "C:\Program Files\Microsoft Configuration Manager\Logs\sitecomp.log" -Tail 2 -ErrorAction "Stop"
            }
            Wait-LWLabJob -Job $job -NoNewLine
            try
            {
                $sitecomplog = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
            }
            catch
            {
                Write-ScreenInfo -Message ("Failed to read sitecomp.log to ({0})" -f $ReceiveJobErr.ErrorRecord.ExceptionMessage) -TaskEnd -Type "Error"
                throw $ReceiveJobErr
            }
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd

        Write-ScreenInfo -Message "Initiating update" -TaskStart
        $job = Invoke-LabCommand -ActivityName "Initiating update" -Variable (Get-Variable -Name "Update") -ScriptBlock {
            Invoke-CimMethod -InputObject $Update -MethodName "InitiateUpgrade" -Arguments @{PrereqFlag = 2 }
        }
        Wait-LWLabJob -Job $job
        try
        {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch
        {
            Write-ScreenInfo -Message ("Could not initiate update ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd

        Write-ScreenInfo -Message "Waiting for update to finish installing" -TaskStart
        $Update = New-LoopAction -LoopTimeout 43200 -LoopTimeoutType "Seconds" -LoopDelay 5 -LoopDelayType "Seconds" -ExitCondition {
            $Update.State -eq [SMS_CM_UpdatePackages_State]::Installed
        } -IfTimeoutScript {
            # Writing dot because of -NoNewLine in Wait-LWLabJob
            Write-ScreenInfo -Message "."
            $Message = "Install timed out"
            Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
            throw $Message
        } -IfSucceedScript {
            return $Update
        } -ScriptBlock {
            # No error handling since WMI can become unavailabile with "generic error" exception multiple times throughout the update. Not ideal
            $cim = New-LabCimSession -ComputerName $CMServer
            $Query = "SELECT * FROM SMS_CM_UPDATEPACKAGES WHERE PACKAGEGUID = '{0}'" -f $UpdatePackageGuid
            $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction SilentlyContinue -CimSession $cim

            if ($Update.State -eq [SMS_CM_UpdatePackages_State]::Failed)
            {
                Write-ScreenInfo -Message "."
                $Message = "Update failed, check CMUpdate.log"
                Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
                throw $Message
            }
        }
        # Writing dot because of -NoNewLine in Wait-LWLabJob
        Write-ScreenInfo -Message "."
        Write-ScreenInfo -Message "Activity done" -TaskEnd
        
    }
    #endregion

    #region Validate update
    Write-ScreenInfo -Message "Validating update" -TaskStart
    $cim = New-LabCimSession -ComputerName $CMServer
    try
    {
        $InstalledSite = Get-CimInstance -Namespace "ROOT/SMS/site_$($CMSiteCode)" -ClassName "SMS_Site" -ErrorAction "Stop" -CimSession $cim
    }
    catch
    {
        Write-ScreenInfo -Message ("Could not query SMS_Site to validate update install ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
        throw $ReceiveJobErr
    }
    if ($InstalledSite.Version -ne $Update.FullVersion)
    {
        $Message = "Update validation failed, installed version is '{0}' and the expected version is '{1}'" -f $InstalledSite.Version, $Update.FullVersion
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Update console
    Write-ScreenInfo -Message "Updating console" -TaskStart
    $cmd = "/q TargetDir=`"C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole`" DefaultSiteServerName={0}" -f $CMServerFqdn
    $job = Install-LabSoftwarePackage -ComputerName $CMServer -LocalPath "C:\Program Files\Microsoft Configuration Manager\tools\ConsoleSetup\ConsoleSetup.exe" -CommandLine $cmd -ExpectedReturnCodes 0 -ErrorAction "Stop" -ErrorVariable "InstallLabSoftwarePackageErr"
    Wait-LWLabJob -Job $job
    try
    {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Console update failed ({0}) " -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Warning"
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
}
