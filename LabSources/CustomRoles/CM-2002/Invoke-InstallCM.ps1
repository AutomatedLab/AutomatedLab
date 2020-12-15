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
    [String]$Branch,

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

function ConvertTo-Ini {
    param (
        [Object[]]$Content,
        [String]$SectionTitleKeyName
    )
    begin {
        $StringBuilder = [System.Text.StringBuilder]::new()
        $SectionCounter = 0
    }
    process {
        foreach ($ht in $Content) {
            $SectionCounter++

            if ($ht -is [System.Collections.Specialized.OrderedDictionary] -Or $ht -is [hashtable]) {
                if ($ht.Keys -contains $SectionTitleKeyName) {
                    $null = $StringBuilder.AppendFormat("[{0}]", $ht[$SectionTitleKeyName])
                }
                else {
                    $null = $StringBuilder.AppendFormat("[Section {0}]", $SectionCounter)
                }

                $null = $StringBuilder.AppendLine()

                foreach ($key in $ht.Keys) {
                    if ($key -ne $SectionTitleKeyName) {
                        $null = $StringBuilder.AppendFormat("{0}={1}", $key, $ht[$key])
                        $null = $StringBuilder.AppendLine()
                    }
                }

                $null = $StringBuilder.AppendLine()
            }
        }
    }
    end {
        $StringBuilder.ToString(0, $StringBuilder.Length-4)
    }
}

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
        [String]$AdminUser,
    
        [Parameter(Mandatory)]
        [String]$AdminPass
    )

    #region Initialise
    $CMServer = Get-LabVM -ComputerName $CMServerName
    $CMServerFqdn = $CMServer.FQDN
    $DCServerName = Get-LabVM -Role RootDC | Where-Object { $_.DomainName -eq  $CMServer.DomainName } | Select-Object -ExpandProperty Name
    $downloadTargetDirectory = "{0}\SoftwarePackages" -f $labSources
    $VMInstallDirectory = "C:\Install"
    $VMCMBinariesDirectory = "{0}\{1}" -f $VMInstallDirectory, (Split-Path $CMBinariesDirectory -Leaf)
    $VMCMPreReqsDirectory = "{0}\{1}" -f $VMInstallDirectory, (Split-Path $CMPreReqsDirectory -Leaf)
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
            "ManagementPoint"             = $CMServerFqdn
            "ManagementPointProtocol"     = "HTTP"
            "DistributionPoint"           = $CMServerFqdn
            "DistributionPointProtocol"   = "HTTP"
            "DistributionPointInstallIIS" = "1"
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

    # The "Preview" key can not exist in the .ini at all if installing CB
    if ($Branch -eq "TP") {
        $CMSetupConfig.Where{$_.Title -eq "Identification"}[0]["Preview"] = 1
    }

    $CMSetupConfigIni = "{0}\ConfigurationFile-CM.ini" -f $downloadTargetDirectory
    
    ConvertTo-Ini -Content $CMSetupConfig -SectionTitleKeyName "Title" | Out-File -FilePath $CMSetupConfigIni -Encoding "ASCII" -ErrorAction "Stop"
    #endregion
    
    # Pre-req checks
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

    #region Create directory for WSUS
    Write-ScreenInfo -Message "Creating directory for WSUS" -TaskStart
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
    #endregion
    
    #region Copy CM binaries, pre-reqs, SQL Server Native Client, ADK and WinPE files
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
        "{0}\ADK" -f $downloadTargetDirectory
        "{0}\WinPE" -f $downloadTargetDirectory
        "{0}\ConfigurationFile-CM.ini" -f $downloadTargetDirectory
        "{0}\sqlncli.msi" -f $downloadTargetDirectory
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
    $Path = "{0}\sqlncli.msi" -f $VMInstallDirectory
    $job = Install-LabSoftwarePackage -LocalPath $Path -CommandLine "/qn /norestart IACCEPTSQLNCLILICENSETERMS=YES" -ExpectedReturnCodes 0
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

$InstallCMSiteSplat = @{
    CMServerName          = $ComputerName
    CMBinariesDirectory   = $CMBinariesDirectory
    Branch                = $Branch
    CMPreReqsDirectory    = $CMPreReqsDirectory
    CMSiteCode            = $CMSiteCode
    CMSiteName            = $CMSiteName
    CMProductId           = $CMProductId
    AdminUser             = $AdminUser
    AdminPass             = $AdminPass
}

Write-ScreenInfo -Message "Starting site install process" -TaskStart
Install-CMSite @InstallCMSiteSplat
Write-ScreenInfo -Message "Finished site install process" -TaskEnd
