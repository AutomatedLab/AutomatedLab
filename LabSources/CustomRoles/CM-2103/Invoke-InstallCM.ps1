param (

    [Parameter(Mandatory)]
    [String]$ComputerName,

    [Parameter(Mandatory)]
    [String]$CMBinariesDirectory,

    [Parameter(Mandatory)]
    [String]$CMPreReqsDirectory,

    [Parameter(Mandatory)]
    [String]$CMSiteCode,

    [Parameter(Mandatory)]
    [String]$CMSiteName,

    [Parameter(Mandatory)]
    [String]$CMProductId,

    [Parameter(Mandatory)]
    [String[]]$CMRoles,

    [Parameter(Mandatory)]
    [String]$LogViewer,

    [Parameter(Mandatory)]
    [String]$Branch,

    [Parameter(Mandatory)]
    [String]$AdminUser,

    [Parameter(Mandatory)]
    [String]$AdminPass,
    
    [Parameter(Mandatory)]
    [String]$ALLabName

)

#region Define functions
function Install-CMSite {
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

        [Parameter(Mandatory)]
        [String]$CMProductId,

        [Parameter(Mandatory)]
        [String[]]$CMRoles,

        [Parameter(Mandatory)]
        [String]$AdminUser,
    
        [Parameter(Mandatory)]
        [String]$AdminPass,
        
        [Parameter(Mandatory)]
        [String]$ALLabName
    )

    #region Initialise
    Import-Lab -Name $LabName -NoValidation -NoDisplay
    
    $CMServer = Get-LabVM -ComputerName $CMServerName
    $CMServerFqdn = $CMServer.FQDN
    $DCServerName = Get-LabVM -Role RootDC | Where-Object { $_.DomainName -eq  $CMServer.DomainName } | Select-Object -ExpandProperty Name
    $downloadTargetDirectory = "{0}\SoftwarePackages" -f $labSources
    $VMInstallDirectory = "C:\Install"
    $LabVirtualNetwork = Get-LabVirtualNetwork | Where-Object { $_.Name -eq $ALLabName } | Select-Object -ExpandProperty "AddressSpace"
    $CMBoundaryIPRange = "{0}-{1}" -f $LabVirtualNetwork.FirstUsable.AddressAsString, $LabVirtualNetwork.LastUsable.AddressAsString
    $VMCMBinariesDirectory = "{0}\CM-{1}" -f $VMInstallDirectory, $Branch
    $VMCMPreReqsDirectory = "{0}\CM-PreReqs-{1}" -f $VMInstallDirectory, $Branch
    $CMComputerAccount = '{0}\{1}$' -f $CMServer.DomainName.Substring(0, $CMServer.DomainName.IndexOf('.')), $CMServerName
    $AVExcludedPaths = @(
        $VMInstallDirectory
        '{0}\ADK\adksetup.exe' -f $VMInstallDirectory
        '{0}\WinPE\adkwinpesetup.exe' -f $VMInstallDirectory
        '{0}\SMSSETUP\BIN\X64\setup.exe' -f $VMCMBinariesDirectory
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
        'G:\SMS_DP$'
        'G:\SMSPKGG$'
        'G:\SMSPKG'
        'G:\SMSPKGSIG'
        'G:\SMSSIG$'
        'G:\RemoteInstall'
        'G:\WSUS'
        'F:\Microsoft SQL Server'
    )
    $AVExcludedProcesses = @(
        '{0}\ADK\adksetup.exe' -f $VMInstallDirectory
        '{0}\WinPE\adkwinpesetup.exe' -f $VMInstallDirectory
        '{0}\SMSSETUP\BIN\X64\setup.exe' -f $VMCMBinariesDirectory
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

    $PSDefaultParameterValues = @{
        "Invoke-LabCommand:ComputerName"            = $CMServerName
        "Invoke-LabCommand:AsJob"                   = $true
        "Invoke-LabCommand:PassThru"                = $true
        "Invoke-LabCommand:NoDisplay"               = $true
        "Invoke-LabCommand:Retries"                 = 1
        "Copy-LabFileItem:ComputerName"             = $CMServerName
        "Copy-LabFileItem:Recurse"                  = $true
        "Copy-LabFileItem:ErrorVariable"            = "CopyLabFileItem"
        "Install-LabSoftwarePackage:ComputerName"   = $CMServerName
        "Install-LabSoftwarePackage:AsJob"          = $true
        "Install-LabSoftwarePackage:PassThru"       = $true
        "Install-LabSoftwarePackage:NoDisplay"      = $true
        "Install-LabWindowsFeature:ComputerName"    = $CMServerName
        "Install-LabWindowsFeature:AsJob"           = $true
        "Install-LabWindowsFeature:PassThru"        = $true
        "Install-LabWindowsFeature:NoDisplay"       = $true
        "Wait-LWLabJob:NoDisplay"                   = $true
    }

    $CMSetupConfig = @(
        [ordered]@{
            "Title" = "Identification"
            "Action" = "InstallPrimarySite"
        }

        [ordered]@{
            "Title"                       = "Options"
            "ProductID"                   = $CMProductId
            "SiteCode"                    = $CMSiteCode
            "SiteName"                    = $CMSiteName
            "SMSInstallDir"               = "C:\Program Files\Microsoft Configuration Manager"
            "SDKServer"                   = $CMServerFqdn
            "RoleCommunicationProtocol"   = "HTTPorHTTPS"
            "ClientsUsePKICertificate"    = "0"
            "PrerequisiteComp"            = switch ($Branch) {
                "TP" { "0" }
                "CB" { "1" }
            }
            "PrerequisitePath"            = $VMCMPreReqsDirectory
            "AdminConsole"                = "1"
            "JoinCEIP"                    = "0"
        }

        [ordered]@{
            "Title"         = "SQLConfigOptions"
            "SQLServerName" = $CMServerFqdn
            "DatabaseName"  = "CM_{0}" -f $CMSiteCode
        }

        [ordered]@{
            "Title"                = "CloudConnectorOptions"
            "CloudConnector"       = "1"
            "CloudConnectorServer" = $CMServerFqdn
            "UseProxy"             = "0"
            "ProxyName"            = $null
            "ProxyPort"            = $null
        }

        [ordered]@{
            "Title" = "SystemCenterOptions"
        }

        [ordered]@{
            "Title" = "HierarchyExpansionOption"
        }
    )

    if ($CMRoles -contains "Management Point") {
        $CMSetupConfig[1]["ManagementPoint"] = $CMServerFqdn
        $CMSetupConfig[1]["ManagementPointProtocol"] = "HTTP"
    }

    if ($CMRoles -contains "Distribution Point") {
        $CMSetupConfig[1]["DistributionPoint"] = $CMServerFqdn
        $CMSetupConfig[1]["DistributionPointProtocol"] = "HTTP"
        $CMSetupConfig[1]["DistributionPointInstallIIS"] = "1"
    }

    # The "Preview" key can not exist in the .ini at all if installing CB
    if ($Branch -eq "TP") {
        $CMSetupConfig.Where{$_.Title -eq "Identification"}[0]["Preview"] = 1
    }

    $CMSetupConfigIni = "{0}\ConfigurationFile-CM.ini" -f $downloadTargetDirectory
    
    ConvertTo-Ini -Content $CMSetupConfig -SectionTitleKeyName "Title" | Out-File -FilePath $CMSetupConfigIni -Encoding "ASCII" -ErrorAction "Stop"
    #endregion
    
    #region Pre-req checks
    Write-ScreenInfo -Message "Running pre-req checks" -TaskStart

    Write-ScreenInfo -Message "Checking if site is already installed" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Checking if site is already installed" -Variable (Get-Variable -Name "CMSiteCode") -ScriptBlock {
        $Query = "SELECT * FROM SMS_Site WHERE SiteCode='{0}'" -f $CMSiteCode
        $Namespace = "ROOT/SMS/site_{0}" -f $CMSiteCode
        Get-CimInstance -Namespace $Namespace -Query $Query -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try {
        $InstalledSite = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        switch -Regex ($ReceiveJobErr.Message) {
            "Invalid namespace" {
                Write-ScreenInfo -Message "No site found, continuing"
            }
            default {
                Write-ScreenInfo -Message ("Could not query SMS_Site to check if site is already installed ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
                throw $ReceiveJobErr
            }
        }
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd

    if ($InstalledSite.SiteCode -eq $CMSiteCode) {
        Write-ScreenInfo -Message ("Site '{0}' already installed on '{1}', skipping installation" -f $CMSiteCode, $CMServerName) -Type "Warning" -TaskEnd
        return
    }
    
    if (-not (Test-Path -Path "$downloadTargetDirectory\ADK")) {
        $Message = "ADK Installation files are not located in '{0}\ADK'" -f $downloadTargetDirectory
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    else {
        Write-ScreenInfo -Message ("Found ADK directory '{0}\ADK'" -f $downloadTargetDirectory)
    }

    if (-not (Test-Path -Path "$downloadTargetDirectory\WinPE")) {
        $Message = "WinPE Installation files are not located in '{0}\WinPE'" -f $downloadTargetDirectory
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    else {
        Write-ScreenInfo -Message ("Found WinPE directory '{0}\WinPE'" -f $downloadTargetDirectory)
    }

    if (-not (Test-Path -Path $CMBinariesDirectory)) {
        $Message = "CM installation files are not located in '{0}'" -f $CMBinariesDirectory
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    else {
        Write-ScreenInfo -Message ("Found CM install directory in '{0}'" -f $CMBinariesDirectory)
    }

    if (-not (Test-Path -Path $CMPreReqsDirectory)) {
        $Message = "CM prerequisite directory does not exist '{0}'" -f $CMPreReqsDirectory
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    else {
        Write-ScreenInfo -Message ("Found CM pre-reqs directory in '{0}'" -f $CMPreReqsDirectory)
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Add Windows Defender exclusions
    # https://docs.microsoft.com/en-us/troubleshoot/mem/configmgr/recommended-antivirus-exclusions
    # https://docs.microsoft.com/en-us/powershell/module/defender/add-mppreference?view=win10-ps
    # https://docs.microsoft.com/en-us/powershell/module/defender/set-mppreference?view=win10-ps
    Write-ScreenInfo -Message "Adding Windows Defender exclusions" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Adding Windows Defender exclusions" -Variable (Get-Variable "AVExcludedPaths", "AVExcludedProcesses") -ScriptBlock {
        Add-MpPreference -ExclusionPath $AVExcludedPaths -ExclusionProcess $AVExcludedProcesses -ErrorAction "Stop"
        Set-MpPreference -RealTimeScanDirection "Incoming" -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to add Windows Defender exclusions ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Bringing online additional disks
    Write-ScreenInfo -Message "Bringing online additional disks" -TaskStart
    #Bringing all available disks online (this is to cater for the secondary drive)
    #For some reason, cant make the disk online and RW in the one command, need to perform two seperate actions
    
    $job = Invoke-LabCommand -ActivityName "Bringing online additional online" -ScriptBlock {
        $dataVolume = Get-Disk -ErrorAction "Stop" | Where-Object -Property OperationalStatus -eq Offline
        $dataVolume | Set-Disk -IsOffline $false -ErrorAction "Stop"
        $dataVolume | Set-Disk -IsReadOnly $false -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to bring disks online ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Saving NO_SMS_ON_DRIVE.SMS file on C: and F:
    Write-ScreenInfo -Message "Saving NO_SMS_ON_DRIVE.SMS file on C: and F:" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Place NO_SMS_ON_DRIVE.SMS file on C: and F:" -ScriptBlock {
        foreach ($drive in "C:","F:") {
            $Path = "{0}\NO_SMS_ON_DRIVE.SMS" -f $drive
            if (-not (Test-Path $Path)) {
                New-Item -Path $Path -ItemType "File" -ErrorAction "Stop"
            }
        }
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to create NO_SMS_ON_DRIVE.SMS ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Create directory for WSUS
    Write-ScreenInfo -Message "Creating directory for WSUS" -TaskStart
    if ($CMRoles -contains "Software Update Point") {
        $job = Invoke-LabCommand -ActivityName "Creating directory for WSUS" -Variable (Get-Variable -Name "CMComputerAccount") -ScriptBlock {
            New-Item -Path 'G:\WSUS\' -ItemType Directory -Force -ErrorAction "Stop" | Out-Null
        }
        Wait-LWLabJob -Job $job
        try {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch {
            Write-ScreenInfo -Message ("Failed to create directory for WSUS ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else {
        Write-ScreenInfo -Message "Software Update Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion
    
    #region Copy CM binaries, pre-reqs, SQL Server Native Client, ADK and WinPE files
    Write-ScreenInfo -Message "Copying files" -TaskStart
    try {
        Copy-LabFileItem -Path $CMBinariesDirectory/* -DestinationFolderPath $VMCMBinariesDirectory
    }
    catch {
        $Message = "Failed to copy '{0}' to '{1}' on server '{2}' ({2})" -f $CMBinariesDirectory, $VMInstallDirectory, $CMServerName, $CopyLabFileItem.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }

    try {
        Copy-LabFileItem -Path $CMPreReqsDirectory/* -DestinationFolderPath $VMCMPreReqsDirectory
    }
    catch {
        $Message = "Failed to copy '{0}' to '{1}' on server '{2}' ({2})" -f $CMPreReqsDirectory, $VMInstallDirectory, $CMServerName, $CopyLabFileItem.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }

    $Paths = @(
        "{0}\ConfigurationFile-CM.ini" -f $downloadTargetDirectory
        "{0}\sqlncli.msi" -f $downloadTargetDirectory
        "{0}\WinPE" -f $downloadTargetDirectory
        "{0}\ADK" -f $downloadTargetDirectory
    )

    foreach ($Path in $Paths) {
        # Put CM ini file in same location as SQL ini, just for consistency. Placement of SQL ini from SQL role isn't configurable.
        switch -Regex ($Path) {
            "Configurationfile-CM\.ini$" {
                $TargetDir = "C:\"
            }
            default {
                $TargetDir = $VMInstallDirectory
            }
        }
        try {
            Copy-LabFileItem -Path $Path -DestinationFolderPath $TargetDir
        }
        catch {
            $Message = "Failed to copy '{0}' to '{1}' on server '{2}' ({2})" -f $Path, $TargetDir, $CMServerName, $CopyLabFileItem.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $Message
        }
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Install SQL Server Native Client
    Write-ScreenInfo -Message "Installing SQL Server Native Client" -TaskStart
    $Path = "{0}\sqlncli.msi" -f $VMInstallDirectory
    $job = Install-LabSoftwarePackage -LocalPath $Path -CommandLine "/qn /norestart IAcceptSqlncliLicenseTerms=Yes" -ExpectedReturnCodes 0
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to install SQL Server Native Client ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Restart computer
    Write-ScreenInfo -Message "Restarting server" -TaskStart
    Restart-LabVM -ComputerName $CMServerName -Wait -ErrorAction "Stop"
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Extend the AD Schema
    Write-ScreenInfo -Message "Extending the AD Schema" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Extending the AD Schema" -Variable (Get-Variable -Name "VMCMBinariesDirectory") -ScriptBlock {
        $Path = "{0}\SMSSETUP\BIN\X64\extadsch.exe" -f $VMCMBinariesDirectory
        Start-Process $Path -Wait -PassThru -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
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
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to configure the Systems Management Container" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
    
    #region Install ADK
    Write-ScreenInfo -Message "Installing ADK" -TaskStart
    $Path = "{0}\ADK\adksetup.exe" -f $VMInstallDirectory
    $job = Install-LabSoftwarePackage -LocalPath $Path -CommandLine "/norestart /q /ceip off /features OptionId.DeploymentTools OptionId.UserStateMigrationTool OptionId.ImagingAndConfigurationDesigner" -ExpectedReturnCodes 0
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to install ADK ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Install WinPE
    Write-ScreenInfo -Message "Installing WinPE" -TaskStart
    $Path = "{0}\WinPE\adkwinpesetup.exe" -f $VMInstallDirectory
    $job = Install-LabSoftwarePackage -LocalPath $Path -CommandLine "/norestart /q /ceip off /features OptionId.WindowsPreinstallationEnvironment" -ExpectedReturnCodes 0
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to install WinPE ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion 

    #region Install WSUS
    Write-ScreenInfo -Message "Installing WSUS" -TaskStart
    if ($CMRoles -contains "Software Update Point") {
        $job = Install-LabWindowsFeature -FeatureName "UpdateServices-Services,UpdateServices-DB" -IncludeManagementTools
        Wait-LWLabJob -Job $job
        try {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch {
            Write-ScreenInfo -Message ("Failed installing WSUS ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else {
        Write-ScreenInfo -Message "Software Update Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Run WSUS post configuration tasks
    Write-ScreenInfo -Message "Running WSUS post configuration tasks" -TaskStart
    if ($CMRoles -contains "Software Update Point") {
        $job = Invoke-LabCommand -ActivityName "Running WSUS post configuration tasks" -Variable (Get-Variable "CMServerFqdn") -ScriptBlock {
            Start-Process -FilePath "C:\Program Files\Update Services\Tools\wsusutil.exe" -ArgumentList "postinstall","SQL_INSTANCE_NAME=`"$CMServerFqdn`"", "CONTENT_DIR=`"G:\WSUS`"" -Wait -ErrorAction "Stop"
        }
        Wait-LWLabJob -Job $job
        try {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch {
            Write-ScreenInfo -Message ("Failed running WSUS post configuration tasks ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else {
        Write-ScreenInfo -Message "Software Update Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Install additional features
    Write-ScreenInfo -Message "Installing additional features (1/2)" -TaskStart
    $job = Install-LabWindowsFeature -FeatureName "FS-FileServer,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Web-WMI,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Static-Content,Web-Http-Redirect,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-Asp-Net,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter"
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed installing additional features (1/2) ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    
    Write-ScreenInfo -Message "Installing additional features (2/2)" -TaskStart
    $job = Install-LabWindowsFeature -FeatureName "NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-Framework-45-ASPNET,NET-WCF-HTTP-Activation45,BITS,RDC"
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
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
    $iniPath = "C:\ConfigurationFile-CM.ini"
    $cmd = "/Script `"{0}`" /NoUserInput" -f $iniPath
    $job = Install-LabSoftwarePackage -LocalPath $exePath -CommandLine $cmd -ProgressIndicator 2 -ExpectedReturnCodes 0
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
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
    $job = Invoke-LabCommand -ActivityName "Validating install" -Variable (Get-Variable -Name "CMSiteCode") -ScriptBlock {
        $Query = "SELECT * FROM SMS_Site WHERE SiteCode='{0}'" -f $CMSiteCode
        $Namespace = "ROOT/SMS/site_{0}" -f $CMSiteCode
        Get-CimInstance -Namespace $Namespace -Query $Query -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        $Message = "Failed to validate install, could not find site code '{0}' in SMS_Site class ({1})" -f $CMSiteCode, $ReceiveJobErr.ErrorRecord.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Install PXE Responder
    Write-ScreenInfo -Message "Installing PXE Responder" -TaskStart
    if ($CMRoles -contains "Distribution Point") {
        New-LoopAction -LoopTimeout 15 -LoopTimeoutType "Minutes" -LoopDelay 60 -ScriptBlock {
            $job = Invoke-LabCommand -ActivityName "Installing PXE Responder" -Variable (Get-Variable "CMServerFqdn","CMServerName") -Function (Get-Command "Import-CMModule") -ScriptBlock {
                Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
                Set-CMDistributionPoint -SiteSystemServerName $CMServerFqdn -AllowPxeResponse $true -EnablePxe $true -EnableNonWdsPxe $true -ErrorAction "Stop"
                do {
                    Start-Sleep -Seconds 5
                } while ((Get-Service).Name -notcontains "SccmPxe")
                Write-Output "Installed"
            }
            Wait-LWLabJob -Job $job
            try {
                $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
            }
            catch {
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
    else {
        Write-ScreenInfo -Message "Distribution Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Configuring Distribution Point group
    Write-ScreenInfo -Message "Configuring Distribution Point group" -TaskStart
    if ($CMRoles -contains "Distribution Point") {
        $job = Invoke-LabCommand -ActivityName "Configuring boundary and boundary group" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            $DPGroup = New-CMDistributionPointGroup -Name "All DPs" -ErrorAction "Stop"
            Add-CMDistributionPointToGroup -DistributionPointGroupId $DPGroup.GroupId -DistributionPointName $CMServerFqdn -ErrorAction "Stop"
        }
        Wait-LWLabJob -Job $job
        try {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch {
            $Message = "Failed while configuring Distribution Point group ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else {
        Write-ScreenInfo -Message "Distribution Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Install Sofware Update Point
    Write-ScreenInfo -Message "Installing Software Update Point" -TaskStart
    if ($CMRoles -contains "Software Update Point") {
        $job = Invoke-LabCommand -ActivityName "Installing Software Update Point" -Variable (Get-Variable "CMServerFqdn","CMServerName","CMSiteCode") -Function (Get-Command "Import-CMModule") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            Add-CMSoftwareUpdatePoint -WsusIisPort 8530 -WsusIisSslPort 8531 -SiteSystemServerName $CMServerFqdn -SiteCode $CMSiteCode -ErrorAction "Stop"
        }
        Wait-LWLabJob -Job $job
        try {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch {
            $Message = "Failed to install Software Update Point ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else {
        Write-ScreenInfo -Message "Software Update Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Add CM account to use for Reporting Service Point
    Write-ScreenInfo -Message ("Adding new CM account '{0}' to use for Reporting Service Point" -f $AdminUser) -TaskStart
    if ($CMRoles -contains "Reporting Services Point") {
        $job = Invoke-LabCommand -ActivityName ("Adding new CM account '{0}' to use for Reporting Service Point" -f $AdminUser) -Variable (Get-Variable "CMServerName", "CMSiteCode", "AdminUser", "AdminPass") -Function (Get-Command "Import-CMModule") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            $Account = "{0}\{1}" -f $env:USERDOMAIN, $AdminUser
            $Secure = ConvertTo-SecureString -String $AdminPass -AsPlainText -Force
            New-CMAccount -Name $Account -Password $Secure -SiteCode $CMSiteCode -ErrorAction "Stop"
        }
        Wait-LWLabJob -Job $job
        try {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch {
            $Message = "Failed to add new CM account ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else {
        Write-ScreenInfo -Message "Reporting Services Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Install Reporting Service Point
    Write-ScreenInfo -Message "Installing Reporting Service Point" -TaskStart
    if ($CMRoles -contains "Reporting Services Point") {
        $job = Invoke-LabCommand -ActivityName "Installing Reporting Service Point" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode", "AdminUser") -Function (Get-Command "Import-CMModule") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            $Account = "{0}\{1}" -f $env:USERDOMAIN, $AdminUser
            Add-CMReportingServicePoint -SiteCode $CMSiteCode -SiteSystemServerName $CMServerFqdn -ReportServerInstance "SSRS" -UserName $Account -ErrorAction "Stop"
        }
        Wait-LWLabJob -Job $job
        try {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch {
            $Message = "Failed to install Reporting Service Point ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else {
        Write-ScreenInfo -Message "Reporting Services Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Install Endpoint Protection Point
    Write-ScreenInfo -Message "Installing Endpoint Protection Point" -TaskStart
    if ($CMRoles -contains "Endpoint Protection Point") {
        $job = Invoke-LabCommand -ActivityName "Installing Endpoint Protection Point" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode") -ScriptBlock {
            Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
            Add-CMEndpointProtectionPoint -ProtectionService "DoNotJoinMaps" -SiteCode $CMSiteCode -SiteSystemServerName $CMServerFqdn -ErrorAction "Stop"
        }
        Wait-LWLabJob -Job $job
        try {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch {
            $Message = "Failed to install Endpoint Protection Point ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else {
        Write-ScreenInfo -Message "Endpoint Protection Point not included in -CMRoles, skipping" -TaskEnd
    }
    #endregion

    #region Configure boundary and boundary group
    Write-ScreenInfo -Message "Configuring boundary and boundary group" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Configuring boundary and boundary group" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode", "CMSiteName", "CMBoundaryIPRange") -ScriptBlock {
        Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode -ErrorAction "Stop"
        $Boundary = New-CMBoundary -DisplayName $CMSiteName -Type "IPRange" -Value $CMBoundaryIPRange -ErrorAction "Stop"
        $BoundaryGroup = New-CMBoundaryGroup -Name $CMSiteName -AddSiteSystemServerName $CMServerFqdn -ErrorAction "Stop"
        Add-CMBoundaryToGroup -BoundaryGroupId $BoundaryGroup.GroupId -BoundaryId $Boundary.BoundaryId -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        $Message = "Failed configuring boundary and boundary group ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
}
#endregion

$InstallCMSiteSplat = @{
    CMServerName          = $ComputerName
    CMBinariesDirectory   = $CMBinariesDirectory
    Branch                = $Branch
    CMPreReqsDirectory    = $CMPreReqsDirectory
    CMSiteCode            = $CMSiteCode
    CMSiteName            = $CMSiteName
    CMProductId           = $CMProductId
    CMRoles               = $CMRoles
    AdminUser             = $AdminUser
    AdminPass             = $AdminPass
    ALLabName             = $ALLabName
}

Write-ScreenInfo -Message "Starting site install process" -TaskStart
Install-CMSite @InstallCMSiteSplat
Write-ScreenInfo -Message "Finished site install process" -TaskEnd
