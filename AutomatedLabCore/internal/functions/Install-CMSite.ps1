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
        [string] $WsusContentPath = 'C:\WsusContent',

        [Parameter()]
        [string] $AdminUser
    )

    #region Initialise
    $CMServer = Get-LabVM -ComputerName $CMServerName
    $CMServerFqdn = $CMServer.FQDN
    $DCServerName = Get-LabVM -Role RootDC | Where-Object { $_.DomainName -eq $CMServer.DomainName } | Select-Object -ExpandProperty Name
    $downloadTargetDirectory = "{0}\SoftwarePackages" -f $(Get-LabSourcesLocation -Local)
    $VMInstallDirectory = "C:\Install"
    $LabVirtualNetwork = (Get-Lab).VirtualNetworks.Where( { $_.SwitchType -ne 'External' -and $_.ResourceName -in $CMServer.Network }, 'First', 1).AddressSpace
    $CMBoundaryIPRange = "{0}-{1}" -f $LabVirtualNetwork.FirstUsable.AddressAsString, $LabVirtualNetwork.LastUsable.AddressAsString
    $VMCMBinariesDirectory = "C:\Install\CM"
    $VMCMPreReqsDirectory = "C:\Install\CM-Prereqs"
    $CMComputerAccount = '{0}\{1}$' -f $CMServer.DomainName.Substring(0, $CMServer.DomainName.IndexOf('.')), $CMServerName
    $CMSetupConfig = $configurationManagerContent.Clone()
    $labCred = $CMServer.GetCredential((Get-Lab))
    if (-not $AdminUser)
    {
        $AdminUser = $labCred.UserName.Split('\')[1]
    }
    $AdminPass = $labCred.GetNetworkCredential().Password

    Invoke-LabCommand -ComputerName $DCServerName -Variable (Get-Variable labCred, AdminUser) -ScriptBlock {
        try
        {
            $usr = Get-ADUser -Identity $AdminUser -ErrorAction Stop
        }
        catch { }

        if ($usr) { return }

        New-ADUser -SamAccountName $AdminUser -Name $AdminUser -AccountPassword $labCred.Password -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Enabled $true
    }

    $CMSetupConfig['[Options]'].SDKServer = $CMServer.FQDN
    $CMSetupConfig['[Options]'].SiteCode = $CMSiteCode
    $CMSetupConfig['[Options]'].SiteName = $CMSiteName
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
    foreach ($p in $paths) { $configurationManagerAVExcludedPaths += $p }
    Write-ScreenInfo -Message "Adding Windows Defender exclusions" -TaskStart

    try
    {
        $result = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Adding Windows Defender exclusions" -Variable (Get-Variable "configurationManagerAVExcludedPaths", "configurationManagerAVExcludedProcesses") -ScriptBlock {
            Add-MpPreference -ExclusionPath $configurationManagerAVExcludedPaths -ExclusionProcess $configurationManagerAVExcludedProcesses -ErrorAction "Stop"
            Set-MpPreference -RealTimeScanDirection "Incoming" -ErrorAction "Stop"
        } -ErrorAction Stop
    }
    catch
    {
        Write-ScreenInfo -Message ("Failed to add Windows Defender exclusions ({0})" -f $_.Exception.Message) -Type "Error" -TaskEnd
        throw $_
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Saving NO_SMS_ON_DRIVE.SMS file on C: and F:
    Invoke-LabCommand -ComputerName $CMServer -Variable (Get-Variable WsusContentPath) -ActivityName "Place NO_SMS_ON_DRIVE.SMS file" -ScriptBlock {
        [char]$root = [IO.Path]::GetPathRoot($WsusContentPath).Substring(0, 1)
        foreach ($volume in (Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -and $_.DriveLetter -ne $root }))
        {
            $Path = "{0}:\NO_SMS_ON_DRIVE.SMS" -f $volume.DriveLetter
            New-Item -Path $Path -ItemType "File" -ErrorAction "Stop" -Force
        }
    }
    #endregion

    #region Create directory for WSUS
    Write-ScreenInfo -Message "Creating directory for WSUS" -TaskStart
    if ($CMRoles -contains "Software Update Point")
    {
        $job = Invoke-LabCommand -ComputerName $CMServer -ActivityName "Creating directory for WSUS" -Variable (Get-Variable -Name "CMComputerAccount", WsusContentPath) -ScriptBlock {
            $null = New-Item -Path $WsusContentPath -Force -ItemType Directory
        }
    }
    else
    {
        Write-ScreenInfo -Message "Software Update Point not included in Roles, skipping" -TaskEnd
    }
    #endregion
    
    

    #region Restart computer
    Write-ScreenInfo -Message "Restarting server" -TaskStart
    Restart-LabVM -ComputerName $CMServerName -Wait -ErrorAction "Stop"
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Extend the AD Schema
    Write-ScreenInfo -Message "Extending the AD Schema" -TaskStart
    Install-LabSoftwarePackage -LocalPath "$VMCMBinariesDirectory\SMSSETUP\BIN\X64\extadsch.exe" -ComputerName $CMServerName
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Configure CM Systems Management Container
    #Need to execute this command on the Domain Controller, since it has the AD Powershell cmdlets available
    #Create the Necessary OU and permissions for the CM container in AD
    Write-ScreenInfo -Message "Configuring CM Systems Management Container" -TaskStart
    Invoke-LabCommand -ComputerName $DCServerName -ActivityName "Configuring CM Systems Management Container" -ArgumentList $CMServerName -ScriptBlock {
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
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Install WSUS
    Write-ScreenInfo -Message "Installing WSUS" -TaskStart
    if ($CMRoles -contains "Software Update Point")
    {
        Install-LabWindowsFeature -FeatureName "UpdateServices-Services,UpdateServices-DB" -IncludeManagementTools -ComputerName $CMServer
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Software Update Point not included in Roles, skipping" -TaskEnd
    }
    #endregion

    #region Run WSUS post configuration tasks
    Write-ScreenInfo -Message "Running WSUS post configuration tasks" -TaskStart
    if ($CMRoles -contains "Software Update Point")
    {
        Invoke-LabCommand -ComputerName $CMServer -ActivityName "Running WSUS post configuration tasks" -Variable (Get-Variable "SqlServerName", WsusContentPath) -ScriptBlock {
            Start-Process -FilePath "C:\Program Files\Update Services\Tools\wsusutil.exe" -ArgumentList "postinstall", "SQL_INSTANCE_NAME=`"$SqlServerName`"", "CONTENT_DIR=`"$WsusContentPath`"" -Wait -ErrorAction "Stop"
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Software Update Point not included in Roles, skipping" -TaskEnd
    }
    #endregion

    #region Install additional features
    Write-ScreenInfo -Message "Installing additional features (1/2)" -TaskStart
    Install-LabWindowsFeature -ComputerName $CMServer -FeatureName "FS-FileServer,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Web-WMI,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Static-Content,Web-Http-Redirect,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-Asp-Net,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter"
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    
    Write-ScreenInfo -Message "Installing additional features (2/2)" -TaskStart
    Install-LabWindowsFeature -ComputerName $CMServer -FeatureName "NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-Framework-45-ASPNET,NET-WCF-HTTP-Activation45,BITS,RDC"
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
    $timeout = Get-LabConfigurationItem -Name Timeout_ConfigurationManagerInstallation -Default 60
    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure') { $timeout = $timeout + 30 }
    Install-LabSoftwarePackage -LocalPath $exePath -CommandLine $cmd -ProgressIndicator 10 -ExpectedReturnCodes 0 -ComputerName $CMServer -Timeout $timeout
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
        Write-PSFMessage -Message "====ConfMgrSetup log content===="
        Invoke-LabCommand -ComputerName $CMServer -PassThru -ScriptBlock { Get-Content -Path C:\ConfigMgrSetup.log } | Write-PSFMessage
        return
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Install PXE Responder
    Write-ScreenInfo -Message "Installing PXE Responder" -TaskStart
    if ($CMRoles -contains "Distribution Point")
    {
        Invoke-LabCommand -ComputerName $CMServer -ActivityName "Installing PXE Responder" -Variable (Get-Variable CMSiteCode, CMServerFqdn, CMServerName) -Function (Get-Command "Import-CMModule") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            Set-CMDistributionPoint -SiteSystemServerName $CMServerFqdn -AllowPxeResponse $true -EnablePxe $true -EnableNonWdsPxe $true -ErrorAction "Stop"
            $start = Get-Date
            do
            {
                Start-Sleep -Seconds 5
            } while (-not (Get-Service -Name SccmPxe -ErrorAction SilentlyContinue) -and ((Get-Date) - $start) -lt '00:10:00')
        }
    }
    else
    {
        Write-ScreenInfo -Message "Distribution Point not included in Roles, skipping" -TaskEnd
    }
    #endregion

    #region Configuring Distribution Point group
    Write-ScreenInfo -Message "Configuring Distribution Point group" -TaskStart
    if ($CMRoles -contains "Distribution Point")
    {
        Invoke-LabCommand -ComputerName $CMServer -ActivityName "Configuring boundary and boundary group" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            $DPGroup = New-CMDistributionPointGroup -Name "All DPs" -ErrorAction "Stop"
            Add-CMDistributionPointToGroup -DistributionPointGroupId $DPGroup.GroupId -DistributionPointName $CMServerFqdn -ErrorAction "Stop"
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Distribution Point not included in Roles, skipping" -TaskEnd
    }
    #endregion

    #region Install Sofware Update Point
    Write-ScreenInfo -Message "Installing Software Update Point" -TaskStart
    if ($CMRoles -contains "Software Update Point")
    {
        Invoke-LabCommand -ComputerName $CMServer -ActivityName "Installing Software Update Point" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode") -Function (Get-Command "Import-CMModule") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            Add-CMSoftwareUpdatePoint -WsusIisPort 8530 -WsusIisSslPort 8531 -SiteSystemServerName $CMServerFqdn -SiteCode $CMSiteCode -ErrorAction "Stop"
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Software Update Point not included in Roles, skipping" -TaskEnd
    }
    #endregion

    #region Add CM account to use for Reporting Service Point
    Write-ScreenInfo -Message ("Adding new CM account '{0}' to use for Reporting Service Point" -f $AdminUser) -TaskStart
    if ($CMRoles -contains "Reporting Services Point")
    {
        Invoke-LabCommand -ComputerName $CMServer -ActivityName ("Adding new CM account '{0}' to use for Reporting Service Point" -f $AdminUser) -Variable (Get-Variable "CMServerName", "CMSiteCode", "AdminUser", "AdminPass") -Function (Get-Command "Import-CMModule") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            $Account = "{0}\{1}" -f $env:USERDOMAIN, $AdminUser
            $Secure = ConvertTo-SecureString -String $AdminPass -AsPlainText -Force
            New-CMAccount -Name $Account -Password $Secure -SiteCode $CMSiteCode -ErrorAction "Stop"
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Reporting Services Point not included in Roles, skipping" -TaskEnd
    }
    #endregion

    #region Install Reporting Service Point
    Write-ScreenInfo -Message "Installing Reporting Service Point" -TaskStart
    if ($CMRoles -contains "Reporting Services Point")
    {
        Invoke-LabCommand -ComputerName $CMServer -ActivityName "Installing Reporting Service Point" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode", "AdminUser") -Function (Get-Command "Import-CMModule") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            $Account = "{0}\{1}" -f $env:USERDOMAIN, $AdminUser
            Add-CMReportingServicePoint -SiteCode $CMSiteCode -SiteSystemServerName $CMServerFqdn -ReportServerInstance "SSRS" -UserName $Account -ErrorAction "Stop"
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Reporting Services Point not included in Roles, skipping" -TaskEnd
    }
    #endregion

    #region Install Endpoint Protection Point
    Write-ScreenInfo -Message "Installing Endpoint Protection Point" -TaskStart
    if ($CMRoles -contains "Endpoint Protection Point")
    {
        Invoke-LabCommand -ComputerName $CMServer -ActivityName "Installing Endpoint Protection Point" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            Add-CMEndpointProtectionPoint -ProtectionService "DoNotJoinMaps" -SiteCode $CMSiteCode -SiteSystemServerName $CMServerFqdn -ErrorAction "Stop"
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Endpoint Protection Point not included in Roles, skipping" -TaskEnd
    }
    #endregion

    #region Configure boundary and boundary group
    Write-ScreenInfo -Message "Configuring boundary and boundary group" -TaskStart
    Invoke-LabCommand -ComputerName $CMServer -ActivityName "Configuring boundary and boundary group" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode", "CMSiteName", "CMBoundaryIPRange") -ScriptBlock {
        Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
        $Boundary = New-CMBoundary -DisplayName $CMSiteName -Type "IPRange" -Value $CMBoundaryIPRange -ErrorAction "Stop"
        $BoundaryGroup = New-CMBoundaryGroup -Name $CMSiteName -AddSiteSystemServerName $CMServerFqdn -ErrorAction "Stop"
        Add-CMBoundaryToGroup -BoundaryGroupId $BoundaryGroup.GroupId -BoundaryId $Boundary.BoundaryId -ErrorAction "Stop"
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
}
