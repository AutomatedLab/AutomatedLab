<#
.SYNOPSIS
    Install a functional SCCM Primary Site using the Automated-Lab tookit with SCCM being installed using the "CustomRoles" approach
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
#>
[CmdletBinding()]
Param (

    [Parameter(Mandatory)]
    [String]$ComputerName,

    [Parameter(Mandatory)]
    [String]$SccmBinariesDirectory,

    [Parameter(Mandatory)]
    [String]$SccmPreReqsDirectory,

    [Parameter(Mandatory)]
    [String]$SccmSiteCode,

    [Parameter(Mandatory)]
    [String]$SccmSiteName,

    [Parameter(Mandatory)]
    [String]$SccmProductId,

    [Parameter(Mandatory)]
    [String]$LogViewer,

    [Parameter(Mandatory)]
    [String]$Version,
        
    [Parameter(Mandatory)]
    [String]$SqlServerName

)

#region Define functions
function New-LoopAction {
    <#
    .SYNOPSIS
        Function to loop a specified scriptblock until certain conditions are met
    .DESCRIPTION
        This function is a wrapper for a ForLoop or a DoUntil loop. This allows you to specify if you want to exit based on a timeout, or a number of iterations.
            Additionally, you can specify an optional delay between loops, and the type of dealy (Minutes, Seconds). If needed, you can also perform an action based on
            whether the 'Exit Condition' was met or not. This is the IfTimeoutScript and IfSucceedScript. 
    .PARAMETER LoopTimeout
        A time interval integer which the loop should timeout after. This is for a DoUntil loop.
    .PARAMETER LoopTimeoutType
         Provides the time increment type for the LoopTimeout, defaulting to Seconds. ('Seconds', 'Minutes', 'Hours', 'Days')
    .PARAMETER LoopDelay
        An optional delay that will occur between each loop.
    .PARAMETER LoopDelayType
        Provides the time increment type for the LoopDelay between loops, defaulting to Seconds. ('Milliseconds', 'Seconds', 'Minutes')
    .PARAMETER Iterations
        Implies that a ForLoop is wanted. This will provide the maximum number of Iterations for the loop. [i.e. "for ($i = 0; $i -lt $Iterations; $i++)..."]
    .PARAMETER ScriptBlock
        A script block that will run inside the loop. Recommend encapsulating inside { } or providing a [scriptblock]
    .PARAMETER ExitCondition
        A script block that will act as the exit condition for the do-until loop. Will be evaluated each loop. Recommend encapsulating inside { } or providing a [scriptblock]
    .PARAMETER IfTimeoutScript
        A script block that will act as the script to run if the timeout occurs. Recommend encapsulating inside { } or providing a [scriptblock]
    .PARAMETER IfSucceedScript
        A script block that will act as the script to run if the exit condition is met. Recommend encapsulating inside { } or providing a [scriptblock]
    .EXAMPLE
        C:\PS> $newLoopActionSplat = @{
                    LoopTimeoutType = 'Seconds'
                    ScriptBlock = { 'Bacon' }
                    ExitCondition = { 'Bacon' -Eq 'eggs' }
                    IfTimeoutScript = { 'Breakfast'}
                    LoopDelayType = 'Seconds'
                    LoopDelay = 1
                    LoopTimeout = 10
                }
                New-LoopAction @newLoopActionSplat
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Breakfast
    .EXAMPLE
        C:\PS> $newLoopActionSplat = @{
                    ScriptBlock = { if($Test -eq $null){$Test = 0};$TEST++ }
                    ExitCondition = { $Test -eq 4 }
                    IfTimeoutScript = { 'Breakfast' }
                    IfSucceedScript = { 'Dinner'}
                    Iterations  = 5
                    LoopDelay = 1
                }
                New-LoopAction @newLoopActionSplat
                Dinner
        C:\PS> $newLoopActionSplat = @{
                    ScriptBlock = { if($Test -eq $null){$Test = 0};$TEST++ }
                    ExitCondition = { $Test -eq 6 }
                    IfTimeoutScript = { 'Breakfast' }
                    IfSucceedScript = { 'Dinner'}
                    Iterations  = 5
                    LoopDelay = 1
                }
                New-LoopAction @newLoopActionSplat
                Breakfast
    .NOTES
            Play with the conditions a bit. I've tried to provide some examples that demonstrate how the loops, timeouts, and scripts work!
            Author: @CodyMathis123
            Link: https://github.com/CodyMathis123/CM-Ramblings
    #>
    param
    (
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [Int32]$LoopTimeout,
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [ValidateSet('Seconds', 'Minutes', 'Hours', 'Days')]
        [String]$LoopTimeoutType,
        [parameter(Mandatory = $true)]
        [Int32]$LoopDelay,
        [parameter(Mandatory = $false, ParameterSetName = 'DoUntil')]
        [ValidateSet('Milliseconds', 'Seconds', 'Minutes')]
        [String]$LoopDelayType = 'Seconds',
        [parameter(Mandatory = $true, ParameterSetName = 'ForLoop')]
        [Int32]$Iterations,
        [parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [parameter(Mandatory = $false, ParameterSetName = 'ForLoop')]
        [scriptblock]$ExitCondition,
        [parameter(Mandatory = $false)]
        [scriptblock]$IfTimeoutScript,
        [parameter(Mandatory = $false)]
        [scriptblock]$IfSucceedScript
    )
    begin {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                $paramNewTimeSpan = @{
                    $LoopTimeoutType = $LoopTimeout
                }    
                $TimeSpan = New-TimeSpan @paramNewTimeSpan
                $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
                $FirstRunDone = $false        
            }
        }
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                do {
                    switch ($FirstRunDone) {
                        $false {
                            $FirstRunDone = $true
                        }
                        Default {
                            $paramStartSleep = @{
                                $LoopDelayType = $LoopDelay
                            }
                            Start-Sleep @paramStartSleep
                        }
                    }
                    . $ScriptBlock
                }
                until ((. $ExitCondition) -or $StopWatch.Elapsed -ge $TimeSpan)
            }
            'ForLoop' {
                for ($i = 0; $i -lt $Iterations; $i++) {
                    switch ($FirstRunDone) {
                        $false {
                            $FirstRunDone = $true
                        }
                        Default {
                            $paramStartSleep = @{
                                $LoopDelayType = $LoopDelay
                            }
                            Start-Sleep @paramStartSleep
                        }
                    }
                    . $ScriptBlock
                    if ($PSBoundParameters.ContainsKey('ExitCondition')) {
                        if (. $ExitCondition) {
                            break
                        }
                    }
                }
            }
        }
    }
    end {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                if ((-not (. $ExitCondition)) -and $StopWatch.Elapsed -ge $TimeSpan -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                    . $IfTimeoutScript
                }
                if ((. $ExitCondition) -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                    . $IfSucceedScript
                }
                $StopWatch.Reset()
            }
            'ForLoop' {
                if ($PSBoundParameters.ContainsKey('ExitCondition')) {
                    if ((-not (. $ExitCondition)) -and $i -ge $Iterations -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                        . $IfTimeoutScript
                    }
                    elseif ((. $ExitCondition) -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                        . $IfSucceedScript
                    }
                }
                else {
                    if ($i -ge $Iterations -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                        . $IfTimeoutScript
                    }
                    elseif ($i -lt $Iterations -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                        . $IfSucceedScript
                    }
                }
            }
        }
    }
}

function Install-CMSite {
    Param (
        [Parameter(Mandatory)]
        [String]$SccmServerName,

        [Parameter(Mandatory)]
        [String]$SccmBinariesDirectory,

        [Parameter(Mandatory)]
        [String]$SccmPreReqsDirectory,

        [Parameter(Mandatory)]
        [String]$SccmSiteCode,

        [Parameter(Mandatory)]
        [String]$SccmSiteName,

        [Parameter(Mandatory)]
        [String]$SccmProductId,
        
        [Parameter(Mandatory)]
        [String]$SqlServerName
    )

    #region Initialise
    $sccmServer = Get-LabVM -ComputerName $SccmServerName
    $sccmServerFqdn = $sccmServer.FQDN
    $sqlServer = Get-LabVM -Role SQLServer | Where-Object Name -eq $SqlServerName
    $sqlServerFqdn = $sqlServer.FQDN
    $DCServerName = Get-LabVM -Role RootDC | Where-Object { $_.DomainName -eq  $sccmServer.DomainName } | Select-Object -ExpandProperty Name
    $downloadTargetFolder = "$labSources\SoftwarePackages"
    $VMInstallDirectory = "C:\Install"
    $VMSccmBinariesDirectory = Join-Path -Path $VMInstallDirectory -ChildPath (Split-Path -Leaf $SccmBinariesDirectory)
    $VMSccmPreReqsDirectory = Join-Path -Path $VMInstallDirectory -ChildPath (Split-Path -Leaf $SccmPreReqsDirectory)
    $sccmComputerAccount = '{0}\{1}$' -f @(
        $sccmServer.DomainName.Substring(0, $sccmServer.DomainName.IndexOf('.')),
        $SccmServerName
    )

    $PSDefaultParameterValues = @{
        "Invoke-LabCommand:ComputerName"            = $SccmServerName
        "Invoke-LabCommand:AsJob"                   = $true
        "Invoke-LabCommand:PassThru"                = $true
        "Invoke-LabCommand:NoDisplay"               = $true
        "Invoke-LabCommand:Retries"                 = 1
        "Copy-LabFileItem:ComputerName"             = $SccmServerName
        "Copy-LabFileItem:Recurse"                  = $true
        "Copy-LabFileItem:ErrorVariable"            = "CopyLabFileItem"
        "Install-LabSoftwarePackage:ComputerName"   = $SccmServerName
        "Install-LabSoftwarePackage:AsJob"          = $true
        "Install-LabSoftwarePackage:PassThru"       = $true
        "Install-LabSoftwarePackage:NoDisplay"      = $true
        "Install-LabWindowsFeature:ComputerName"    = $SccmServerName
        "Install-LabWindowsFeature:AsJob"           = $true
        "Install-LabWindowsFeature:PassThru"        = $true
        "Install-LabWindowsFeature:NoDisplay"       = $true
        "Wait-LWLabJob:NoDisplay"                   = $true
    }

    $setupConfigFileContent = @"
[Identification]
Action=InstallPrimarySite
      
[Options]
ProductID=$SccmProductId
SiteCode=$SccmSiteCode
SiteName=$SccmSiteName
SMSInstallDir=C:\Program Files\Microsoft Configuration Manager
SDKServer=$sccmServerFqdn
RoleCommunicationProtocol=HTTPorHTTPS
ClientsUsePKICertificate=0
PrerequisiteComp=1
PrerequisitePath=$VMSccmPreReqsDirectory
MobileDeviceLanguage=0
ManagementPoint=$sccmServerFqdn
ManagementPointProtocol=HTTP
DistributionPoint=$sccmServerFqdn
DistributionPointProtocol=HTTP
DistributionPointInstallIIS=1
AdminConsole=1
JoinCEIP=0
       
[SQLConfigOptions]
SQLServerName=$SqlServerFqdn
DatabaseName=CM_$SccmSiteCode
SQLDataFilePath=F:\DATA\
SQLLogFilePath=F:\LOGS\
       
[CloudConnectorOptions]
CloudConnector=1
CloudConnectorServer=$sccmServerFqdn
UseProxy=0
       
[SystemCenterOptions]
       
[HierarchyExpansionOption]
"@
    
    $setupConfigFileContent | Out-File -FilePath "$($downloadTargetFolder)\ConfigMgrUnattend.ini" -Encoding ascii -ErrorAction "Stop"
    #endregion
    
    # Pre-req checks
    Write-ScreenInfo -Message "Running pre-req checks" -TaskStart
    if (-not $sqlServer) {
        $Message = "The specified SQL Server '{0}' does not exist in the lab." -f $SqlServerName
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }

    Write-ScreenInfo -Message "Checking if site is already installed" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Checking if site is already installed" -Variable (Get-Variable -Name "SccmSiteCode") -ScriptBlock {
        $Query = "SELECT * FROM SMS_Site WHERE SiteCode='{0}'" -f $SccmSiteCode
        Get-CimInstance -Namespace "ROOT/SMS/site_$($SccmSiteCode)" -Query $Query -ErrorAction "Stop"
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

    if ($InstalledSite.SiteCode -eq $SccmSiteCode) {
        Write-ScreenInfo -Message ("Site '{0}' already installed on '{1}', skipping installation" -f $SccmSiteCode, $SccmServerName) -Type "Warning" -TaskEnd
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

    if (-not (Test-Path -Path $SccmBinariesDirectory)) {
        $Message = "CM installation files are not located in '{0}'" -f $SccmBinariesDirectory
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    else {
        Write-ScreenInfo -Message ("Found CM install folder in '{0}'" -f $SccmBinariesDirectory)
    }

    if (-not (Test-Path -Path $SccmPreReqsDirectory)) {
        $Message = "CM pre-requisite files are not located in '{0}'" -f $SccmPreReqsDirectory
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    else {
        Write-ScreenInfo -Message ("Found CM pre-reqs folder in '{0}'" -f $SccmPreReqsDirectory)
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Bringing online additional online
    Write-ScreenInfo -Message "Bringing online additional online" -TaskStart
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

    #region Create folders for SQL db
    Write-ScreenInfo -Message "Creating folders for SQL db" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Creating folders for SQL db" -Variable (Get-Variable -Name "sccmComputerAccount") -ScriptBlock {
        New-Item -Path 'F:\DATA\' -ItemType Directory -Force -ErrorAction "Stop" | Out-Null
        New-Item -Path 'F:\LOGS\' -ItemType Directory -Force -ErrorAction "Stop" | Out-Null
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to create folders for SQL db ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
    
    #region Copy CM binaries, pre-reqs, ADK and WinPE
    Write-ScreenInfo -Message "Copying CM binaries, pre-reqs, ADK and WinPE" -TaskStart
    try {
        Copy-LabFileItem -Path $SccmBinariesDirectory -DestinationFolderPath $VMInstallDirectory
    }
    catch {
        $Message = "Failed to copy '{0}' to '{1}' on server '{2}' ({2})" -f $SccmBinariesDirectory, $VMInstallDirectory, $SccmServerName, $CopyLabFileItem.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    try {
        Copy-LabFileItem -Path $SccmPreReqsDirectory -DestinationFolderPath $VMInstallDirectory
    }
    catch {
        $Message = "Failed to copy '{0}' to '{1}' on server '{2}' ({2})" -f $SccmPreReqsDirectory, $VMInstallDirectory, $SccmServerName, $CopyLabFileItem.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    $Paths = @(
        (Join-Path -Path $downloadTargetFolder -ChildPath "ADK"),
        (Join-Path -Path $downloadTargetFolder -ChildPath "WinPE"),
        (Join-Path -Path $downloadTargetFolder -ChildPath "ConfigMgrUnattend.ini")
    )
    ForEach ($Path in $Paths) {
        try {
            Copy-LabFileItem -Path $Path -DestinationFolderPath $VMInstallDirectory
        }
        catch {
            $Message = "Failed to copy '{0}' to '{1}' on server '{2}' ({2})" -f $Path, $VMInstallDirectory, $SccmServerName, $CopyLabFileItem.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $Message
        }
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Extend the AD Schema
    Write-ScreenInfo -Message "Extending the AD Schema" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Extending the AD Schema" -Variable (Get-Variable -Name VMSccmBinariesDirectory) -ScriptBlock {
        $path = Join-Path -Path $VMSccmBinariesDirectory -ChildPath "SMSSETUP\BIN\X64\extadsch.exe"
        Start-Process $path -Wait -PassThru -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $InstalledSite = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
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
    $job = Invoke-LabCommand -ComputerName $DCServerName -ActivityName "Configuring CM Systems Management Container" -ArgumentList $SccmServerName -ScriptBlock {
        Param (
            [Parameter(Mandatory)]
            [String]$SCCMServerName
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
        $sccmComputer = Get-ADComputer "$SCCMServerName$"
        $sccmServerSId = [System.Security.Principal.SecurityIdentifier] $sccmComputer.SID

        $ActiveDirectoryRights = "GenericAll"
        $AccessControlType = "Allow"
        $Inherit = "SelfAndChildren"
        $nullGUID = [guid]'00000000-0000-0000-0000-000000000000'

        # Create a new access control entry to allow access to the OU
        $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $sccmServerSId, $ActiveDirectoryRights, $AccessControlType, $Inherit, $nullGUID
        
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
    Write-ScreenInfo -Message "Installing WinPE on" -TaskStart
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
    Write-ScreenInfo -Message "Installing WDS on '$SccmServerName'" -TaskStart
    $job = Install-LabWindowsFeature -ComputerName $SccmServerName -FeatureName WDS
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
            Restart-LabVM -ComputerName $SccmServerName -Wait -ErrorAction "Stop"
            Write-ScreenInfo -Message "Activity done" -TaskEnd
        }
        "Available" {
            $Message = "WDS install verification failed, reporting as not installed"
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $Message
        }
        "Installed" {
            Write-ScreenInfo -Message "WDS is installed"
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
    Restart-LabVM -ComputerName $SccmServerName -Wait -ErrorAction "Stop"
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
    
    #region Add CM system account to local adminsitrators group
    # Initially used for testing where SQL was remote from CM
    if ($SccmServerName -ne $sqlServerName) {
        Write-ScreenInfo -Message "Adding CM system account to local adminsitrators group" -TaskStart
        $job = Invoke-LabCommand -ActivityName "Adding CM system account to local adminsitrators group" -Variable (Get-Variable -Name "sccmComputerAccount") -ScriptBlock {
            if (-not (Get-LocalGroupMember -Group Administrators -Member $sccmComputerAccount -ErrorAction "Stop"))
            {
                Add-LocalGroupMember -Group Administrators -Member $sccmComputerAccount -ErrorAction "Stop"
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
    $exePath = Join-Path -Path $VMSccmBinariesDirectory -ChildPath "SMSSETUP\BIN\X64\setup.exe"
    $iniPath = Join-Path -Path $VMInstallDirectory -ChildPath "ConfigMgrUnattend.ini"
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

    #region Validating install
    Write-ScreenInfo "Validating install" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Validating install" -Variable (Get-Variable -Name "SccmSiteCode") -PassThru -ScriptBlock {
        $Query = "SELECT * FROM SMS_Site WHERE SiteCode='{0}'" -f $SccmSiteCode
        Get-CimInstance -Namespace "ROOT/SMS/site_$($SccmSiteCode)" -Query $Query -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try {
        $InstalledSite = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        $Message = "Failed to validate install, could not find site code '{0}' in SMS_Site class ({1})" -f $SccmSiteCode, $ReceiveJobErr.ErrorRecord.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Restart
    Write-ScreenInfo -Message "Restarting server" -TaskStart
    Restart-LabVM -ComputerName $SccmServerName -Wait -ErrorAction "Stop"
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
}
#endregion

Import-Lab -Name $data.Name -NoValidation -NoDisplay -PassThru

$InstallCMSiteSplat = @{
    SccmServerName          = $ComputerName
    SccmBinariesDirectory   = $SCCMBinariesDirectory
    SccmPreReqsDirectory    = $SCCMPreReqsDirectory
    SccmSiteCode            = $SccmSiteCode
    SccmSiteName            = $SccmSiteName
    SccmProductId           = $SccmProductId
    SqlServerName           = $SqlServerName
}

Write-ScreenInfo -Message "Starting site install process" -TaskStart
Install-CMSite @InstallCMSiteSplat
Write-ScreenInfo -Message "Finished site install process" -TaskEnd