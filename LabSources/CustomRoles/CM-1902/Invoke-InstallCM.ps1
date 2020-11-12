Param (

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
    [String]$LogViewer,

    [Parameter(Mandatory)]
    [String]$Version,
        
    [Parameter(Mandatory)]
    [String]$SqlServerName,

    [Parameter(Mandatory)]
    [String]$AdminUser,

    [Parameter(Mandatory)]
    [String]$AdminPass

)

#region Define functions
function Import-CMModule {
    Param(
        [String]$ComputerName,
        [String]$SiteCode
    )
    if(-not(Get-Module ConfigurationManager)) {
        try {
            Import-Module ("{0}\..\ConfigurationManager.psd1" -f $ENV:SMS_ADMIN_UI_PATH) -ErrorAction "Stop" -ErrorVariable "ImportModuleError"
        }
        catch {
            throw ("Failed to import ConfigMgr module: {0}" -f $ImportModuleError.ErrorRecord.Exception.Message)
        }
    }
    try {
        if(-not(Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $ComputerName -Scope "Script" -ErrorAction "Stop" | Out-Null
        }
        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"    
    } 
    catch {
        if(Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue") {
            Remove-PSDrive -Name $SiteCode -Force
        }
        throw ("Failed to create New-PSDrive with site code `"{0}`" and server `"{1}`"" -f $SiteCode, $ComputerName)
    }
}

function Install-CMSite {
    Param (
        [Parameter(Mandatory)]
        [String]$CMServerName,

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
        [String]$SqlServerName,

        [Parameter(Mandatory)]
        [String]$AdminUser,
    
        [Parameter(Mandatory)]
        [String]$AdminPass
    )

    #region Initialise
    $CMServer = Get-LabVM -ComputerName $CMServerName
    $CMServerFqdn = $CMServer.FQDN
    $sqlServer = Get-LabVM -Role SQLServer | Where-Object Name -eq $SqlServerName
    $sqlServerFqdn = $sqlServer.FQDN
    $DCServerName = Get-LabVM -Role RootDC | Where-Object { $_.DomainName -eq  $CMServer.DomainName } | Select-Object -ExpandProperty Name
    $downloadTargetFolder = "$labSources\SoftwarePackages"
    $VMInstallDirectory = "C:\Install"
    $VMCMBinariesDirectory = Join-Path -Path $VMInstallDirectory -ChildPath (Split-Path -Leaf $CMBinariesDirectory)
    $VMCMPreReqsDirectory = Join-Path -Path $VMInstallDirectory -ChildPath (Split-Path -Leaf $CMPreReqsDirectory)
    $CMComputerAccount = '{0}\{1}$' -f @(
        $CMServer.DomainName.Substring(0, $CMServer.DomainName.IndexOf('.')),
        $CMServerName
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

    $setupConfigFileContent = @"
[Identification]
Action=InstallPrimarySite
      
[Options]
ProductID=$CMProductId
SiteCode=$CMSiteCode
SiteName=$CMSiteName
SMSInstallDir=C:\Program Files\Microsoft Configuration Manager
SDKServer=$CMServerFqdn
RoleCommunicationProtocol=HTTPorHTTPS
ClientsUsePKICertificate=0
PrerequisiteComp=1
PrerequisitePath=$VMCMPreReqsDirectory
MobileDeviceLanguage=0
ManagementPoint=$CMServerFqdn
ManagementPointProtocol=HTTP
DistributionPoint=$CMServerFqdn
DistributionPointProtocol=HTTP
DistributionPointInstallIIS=1
AdminConsole=1
JoinCEIP=0
       
[SQLConfigOptions]
SQLServerName=$SqlServerFqdn
DatabaseName=CM_$CMSiteCode
       
[CloudConnectorOptions]
CloudConnector=1
CloudConnectorServer=$CMServerFqdn
UseProxy=0
       
[SystemCenterOptions]
       
[HierarchyExpansionOption]
"@
    
    $setupConfigFileContent | Out-File -FilePath "$($downloadTargetFolder)\ConfigurationFile-CM.ini" -Encoding ascii -ErrorAction "Stop"
    #endregion
    
    # Pre-req checks
    Write-ScreenInfo -Message "Running pre-req checks" -TaskStart
    if (-not $sqlServer) {
        $Message = "The specified SQL Server '{0}' does not exist in the lab." -f $SqlServerName
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }

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
    
    if (-not (Test-Path -Path "$downloadTargetFolder\ADK")) {
        $Message = "ADK Installation files are not located in '{0}\ADK'" -f $downloadTargetFolder
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    else {
        Write-ScreenInfo -Message ("Found ADK folder '{0}\ADK'" -f $downloadTargetFolder)
    }

    if (-not (Test-Path -Path "$downloadTargetFolder\WinPE")) {
        $Message = "WinPE Installation files are not located in '{0}\WinPE'" -f $downloadTargetFolder
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    else {
        Write-ScreenInfo -Message ("Found WinPE folder '{0}\WinPE'" -f $downloadTargetFolder)
    }

    if (-not (Test-Path -Path $CMBinariesDirectory)) {
        $Message = "CM installation files are not located in '{0}'" -f $CMBinariesDirectory
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    else {
        Write-ScreenInfo -Message ("Found CM install folder in '{0}'" -f $CMBinariesDirectory)
    }

    if (-not (Test-Path -Path $CMPreReqsDirectory)) {
        $Message = "CM pre-requisite files are not located in '{0}'" -f $CMPreReqsDirectory
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    else {
        Write-ScreenInfo -Message ("Found CM pre-reqs folder in '{0}'" -f $CMPreReqsDirectory)
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
        New-Item -Path "C:\" -Name "NO_SMS_ON_DRIVE.SMS" -ItemType "File" -ErrorAction "Stop"
        New-Item -Path "F:\" -Name "NO_SMS_ON_DRIVE.SMS" -ItemType "File" -ErrorAction "Stop"
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

    #region Create folder for WSUS
    Write-ScreenInfo -Message "Creating folder for WSUS" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Creating folder for WSUS" -Variable (Get-Variable -Name "CMComputerAccount") -ScriptBlock {
        New-Item -Path 'G:\WSUS\' -ItemType Directory -Force -ErrorAction "Stop" | Out-Null
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to create folder for WSUS ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
    
    #region CM binaries, pre-reqs, SQL native client installer, ADK and WinPE files
    Write-ScreenInfo -Message "Copying files" -TaskStart
    try {
        Copy-LabFileItem -Path $CMBinariesDirectory -DestinationFolderPath $VMInstallDirectory
    }
    catch {
        $Message = "Failed to copy '{0}' to '{1}' on server '{2}' ({2})" -f $CMBinariesDirectory, $VMInstallDirectory, $CMServerName, $CopyLabFileItem.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    try {
        Copy-LabFileItem -Path $CMPreReqsDirectory -DestinationFolderPath $VMInstallDirectory
    }
    catch {
        $Message = "Failed to copy '{0}' to '{1}' on server '{2}' ({2})" -f $CMPreReqsDirectory, $VMInstallDirectory, $CMServerName, $CopyLabFileItem.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    $Paths = @(
        (Join-Path -Path $downloadTargetFolder -ChildPath "ADK"),
        (Join-Path -Path $downloadTargetFolder -ChildPath "WinPE"),
        (Join-Path -Path $downloadTargetFolder -ChildPath "ConfigurationFile-CM.ini")
        (Join-Path -Path $downloadTargetFolder -ChildPath "sqlncli.msi")
    )
    ForEach ($Path in $Paths) {
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
    $Path = Join-Path -Path $VMInstallDirectory -ChildPath "sqlncli.msi"
    $job = Install-LabSoftwarePackage -LocalPath $Path -CommandLine "/qn /norestart" -ExpectedReturnCodes 0
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
        $path = Join-Path -Path $VMCMBinariesDirectory -ChildPath "SMSSETUP\BIN\X64\extadsch.exe"
        Start-Process $path -Wait -PassThru -ErrorAction "Stop"
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
    $Path = Join-Path -Path $VMInstallDirectory -ChildPath "ADK\adksetup.exe"
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
    $Path = Join-Path $VMInstallDirectory -ChildPath "WinPE\adkwinpesetup.exe"
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

    #region Install .NET 3.5
    Write-ScreenInfo -Message "Installing .NET 3.5 on" -TaskStart
    $job = Install-LabWindowsFeature -FeatureName NET-Framework-Core
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to install .NET 3.5 ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
    
    #region Install WDS
    Write-ScreenInfo -Message "Installing WDS" -TaskStart
    $job = Install-LabWindowsFeature -ComputerName $CMServerName -FeatureName WDS
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to install WDS ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Verify WDS is installed
    # Sometimes, not always, I noticed WDS state was "InstallPending" and reboot resolved.
    Write-ScreenInfo -Message "Verifying WDS is installed" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Verifying WDS is installed" -ScriptBlock {
        Get-WindowsFeature -Name "WDS-Deployment" -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try {
        $WDS = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to verify WDS is installed ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    switch ($WDS.InstallState) {
        "InstallPending" {
            Write-ScreenInfo -Message "Restart required, restarting server" -TaskStart
            Restart-LabVM -ComputerName $CMServerName -Wait -ErrorAction "Stop"
            Write-ScreenInfo -Message "Activity done" -TaskEnd
        }
        "Available" {
            $Message = "WDS install verification failed, reporting as not installed"
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $Message
        }
        "Installed" {
            #Write-ScreenInfo -Message "WDS is installed"
        }
        default {
            Write-ScreenInfo -Message "Could not determine WDS's install state" -Type "Warning"
        }
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
    
    #region Configure WDS
    Write-ScreenInfo -Message "Configuring WDS" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Configuring WDS" -ScriptBlock {
        Start-Process -FilePath "C:\Windows\System32\WDSUTIL.EXE" -ArgumentList "/Initialize-Server /RemInst:G:\RemoteInstall" -Wait -ErrorAction "Stop"
        Start-Sleep -Seconds 10
        Start-Process -FilePath "C:\Windows\System32\WDSUTIL.EXE" -ArgumentList "/Set-Server /AnswerClients:All" -Wait -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to configure WDS ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Install WSUS
    Write-ScreenInfo -Message "Installing WSUS" -TaskStart
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
    #endregion

    #region Run WSUS post configuration tasks
    Write-ScreenInfo -Message "Running WSUS post configuration tasks" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Running WSUS post configuration tasks" -Variable (Get-Variable "sqlServerFqdn") -ScriptBlock {
        Start-Process -FilePath "C:\Program Files\Update Services\Tools\wsusutil.exe" -ArgumentList "postinstall","SQL_INSTANCE_NAME=`"$sqlServerFqdn`"", "CONTENT_DIR=`"G:\WSUS`"" -Wait -ErrorAction "Stop"
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
    
    #region Add CM system account to local adminsitrators group
    # Initially used for testing where SQL was remote from CM
    if ($CMServerName -ne $sqlServerName) {
        Write-ScreenInfo -Message "Adding CM system account to local adminsitrators group" -TaskStart
        $job = Invoke-LabCommand -ActivityName "Adding CM system account to local adminsitrators group" -Variable (Get-Variable -Name "CMComputerAccount") -ScriptBlock {
            if (-not (Get-LocalGroupMember -Group Administrators -Member $CMComputerAccount -ErrorAction "Stop"))
            {
                Add-LocalGroupMember -Group Administrators -Member $CMComputerAccount -ErrorAction "Stop"
            }
        }
        Wait-LWLabJob -Job $job
        try {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch {
            Write-ScreenInfo -Message ("Failed to add CM system account to '{0}' ({1})" -f $sqlServerFqdn, $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    #endregion
    
    #region Install Configuration Manager
    Write-ScreenInfo "Installing Configuration Manager" -TaskStart
    $exePath = Join-Path -Path $VMCMBinariesDirectory -ChildPath "SMSSETUP\BIN\X64\setup.exe"
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

    #region Install SUP
    Write-ScreenInfo -Message "Installing Software Update Point" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Installing Software Update Point" -Variable (Get-Variable "CMServerFqdn","CMServerName","CMSiteCode") -Function (Get-Command "Import-CMModule") -ScriptBlock {
        Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode
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
    #endregion

    #region Add CM account to use for Reporting Service Point
    Write-ScreenInfo -Message ("Creating CM user account '{0}'" -f $AdminUser) -TaskStart
    $job = Invoke-LabCommand -ActivityName ("Adding new CM account '{0}' to use for Reporting Service Point" -f $AdminUser) -Variable (Get-Variable "CMServerName", "CMSiteCode", "AdminUser", "AdminPass") -Function (Get-Command "Import-CMModule") -ScriptBlock {
        Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode
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
    #endregion

    #region Install Reporting Service Point
    Write-ScreenInfo -Message "Installing Reporting Service Point" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Installing Reporting Service Point" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode", "AdminUser") -Function (Get-Command "Import-CMModule") -ScriptBlock {
        Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode
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
    #endregion

    #region Install Endpoint Protection Point
    Write-ScreenInfo -Message "Installing Endpoint Protection Point" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Installing Endpoint Protection Point" -Variable (Get-Variable "CMServerFqdn", "CMServerName", "CMSiteCode") -ScriptBlock {
        Import-CMModule -ComputerName $CMServerName -SiteCode $CMSiteCode
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
    #endregion
}
#endregion

#Import-Lab -Name $data.Name -NoValidation -NoDisplay -PassThru

$InstallCMSiteSplat = @{
    CMServerName          = $ComputerName
    CMBinariesDirectory   = $CMBinariesDirectory
    CMPreReqsDirectory    = $CMPreReqsDirectory
    CMSiteCode            = $CMSiteCode
    CMSiteName            = $CMSiteName
    CMProductId           = $CMProductId
    SqlServerName         = $SqlServerName
    AdminUser             = $AdminUser
    AdminPass             = $AdminPass
}

Write-ScreenInfo -Message "Starting site install process" -TaskStart
Install-CMSite @InstallCMSiteSplat
Write-ScreenInfo -Message "Finished site install process" -TaskEnd
