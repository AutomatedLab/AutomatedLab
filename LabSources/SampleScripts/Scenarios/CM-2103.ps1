<#
.SYNOPSIS
    An AutomatedLab script for Configuration Manager 2103 with support for installing updates.
.DESCRIPTION
    An AutomatedLab script for Configuration Manager 2103 with support for installing updates.
.PARAMETER LabName
    The name of the AutomatedLab lab created by this script.
.PARAMETER VMPath
    The path where you would like to save the VM data (.vhdx and .vmcx files) for this lab. 
    The scripts appends the lab name to the path you give. For example, if -LabName is "CMLab01" and -VMPath is "C:\VMs" then the VMs will be saved in "C:\VMs\CMLab01".
.PARAMETER Domain
    The Active Directory domain for this lab.
    If the domain resolves to an IP address, a terminating error is thrown. Use the -SkipDomainCheck switch to continue even if the domain resolves to an IP address.
.PARAMETER AdminUser
    The username of a Domain Administrator within your lab. Also the account used for installing Active Directory and other software packages in this lab.
.PARAMETER AdminPass
    The password for the AdminUser.
.PARAMETER AddressSpace
    The IP subnet this lab uses, accepted syntax for the value is slash notation, for example 192.168.1.0/24.
    Omitting this parameter forces AutomatedLab to find new subnets by simply increasing 192.168.1.0 until a free network is found. Free means that there is no virtual network switch with an IP address in the range of the subnet and the subnet is not routable. If these conditions are not met, the subnet is incremented again.
.PARAMETER ExternalVMSwitchName
    The name of the External Hyper-V switch. The given name must be of an existing Hyper-V switch and it must be of 'External' type. 
    "Default Switch" is also an acceptable value, this way the lab can still form an independent network and have access to the host's network using NAT.
    If you do not want this lab to have physical network access, use the -NoInternetAccess switch.
    You cannot use this parameter with -NoInternetAccess.
.PARAMETER SiteCode
    Configuration Manager site code.
.PARAMETER SiteName
    Configuration Manager site name.
.PARAMETER CMVersion
    The target Configuration version you wish to install.
    This script first installs 2103 baseline and then installs updates. If -CMVersion is "2103" then the update process is skipped.
    Acceptable values are controlled via the parameter attribute ValidateSet(), meaning you can tab complete the options available.
.PARAMETER Branch
    Specify the branch of Configuration Manager you want to install: "CB" (Current Branch) or "TP" (Technical Preview).
    If you specify Technical Preview, note that the -NoInternetAccess switch cannot be used.
.PARAMETER OSVersion
    Operating System version for all VMs in this lab.
    The names match those that Get-WindowsImage returns by property "ImageName".
    Acceptable values are controlled via the parameter attribute ValidateSet(), meaning you can tab complete the options available.
    Ensure you have the corresponding ISO media in your LabSources\ISOs folder.
.PARAMETER DCHostname
    Hostname for this lab's Domain Controller.
.PARAMETER DCCPU
    Number of vCPUs to assign the Domain Controller.
.PARAMETER DCMemory
    Maximum memory capacity to assign the Domain Controller.
    Must be greater than 1GB.
.PARAMETER CMHostname
    Hostname for this lab's Configuration Manager server.
.PARAMETER CMCPU
    Number of vCPUs to assign the Domain Controller.
.PARAMETER CMMemory
    Maximum memory capacity to assign the Configuration Manager server.
    Must be greater than 1GB.
.PARAMETER SQLServer2017ISO
    The path to a SQL Server 2017 ISO used for SQL Server 2017 installation. Omitting this parameter downloads the evaluation version of SQL Server 2017 (first downloads a small binary in to LabSources\SoftwarePackages, which the binary then downloads the ISO in to LabSources\ISOs)
.PARAMETER LogViewer
    The default .log and .lo_ file viewer for only the Configuration Manager server.
    OneTrace was introduced in 1906 so if -LogViewer is "OneTrace" and -CMVersion is "2103" or -NoInternetAccess is specified, then -LogViewer will revert to "CMTrace".
    Acceptable values are controlled via the parameter attribute ValidateSet(), meaning you can tab complete the options available.
.PARAMETER ADKDownloadURL
    URL to the ADK executable.
.PARAMETER WinPEDownloadURL
    URL to the WinPE addon executable.
.PARAMETER SkipDomainCheck
    While there's nothing technically stopping you from installing Active Directory using a domain that already exists and is out of your control, you probably shouldn't. So I've implemented blocks in case -Domain does resolve.
    Specifying this switch skips the check and continues to build the lab.
.PARAMETER SkipLabNameCheck
    AutomatedLab lab names must be unique. If -LabName is equal to a lab name that already exists, a terminating error is thrown.
    Specifying this switch skips the check and continues to build the lab.
.PARAMETER SkipHostnameCheck
    If a DNS record exists and resolves to an IP address for either $CMHostname or $DCHostname, a terminating error is thrown.
    Specifying this switch skips the check and continues to build the lab.
.PARAMETER DoNotDownloadWMIEv2
    By default, this scripts downloads WmiExplorer V2 to LabSources\Tools directory so it's available on all lab VMs.
    Specifying this skips the download.
    See https://github.com/vinaypamnani/wmie2
.PARAMETER PostInstallations
    Specifying this switch passes the -PostInstallations and -NoValidation switches to Install-Lab.
    See the examples for how and why you would use this.
    You cannot use this parameter with -ExcludePostInstallations.
.PARAMETER ExcludePostInstallations
    Specifying this switch creates the Domain Controller and Configuration Manager VMs, installs Active Directory on the DC and SQL on the CM server but not Configuration Manager.
    See the examples for how and why you would use this.
    You cannot use this parameter with -PostInstallations.
.PARAMETER NoInternetAccess
    Specifying this switch keeps lab traffic local with no access to the external/physical network.
    You cannot use this parameter with -ExternalVMSwitchName.
.PARAMETER AutoLogon
    Specify this to enable auto logon for all VMs in this lab.
.EXAMPLE
    PS C:\> .\CM-2103.ps1 

    Builds a lab with the following properties:
        - 1x AutomatedLab:
            - Name: "CMLab01"
            - VMPath: \<drive\>:\AutomatedLab-VMs where \<drive\> is the fastest drive available
            - AddressSpace: An unused and available subnet increasing 192.168.1.0 by 1 until one is found.
            - ExternalVMSwitch: Allows physical network access via Hyper-V external switch named "Internet".
        - 1x Active Directory domain:
            - Domain: "sysmansquad.lab"
            - Username: "Administrator"
            - Password: "Somepass1"
        - 2x virtual machines:
            - Operating System: Windows Server 2019 (Desktop Experience)
            - 1x Domain Controller:
                - Name: "DC01"
                - vCPU: 2
                - Max memory: 2GB
                - Disks: 1 x 100GB (OS, dynamic)
                - Roles: "RootDC", "Routing"
            - 1x Configuration Manager primary site server:
                - Name: "CM01"
                - vCPU: 4
                - Max memory: 8GB
                - Disks: 1 x 100GB (OS, dynamic), 1x 30GB (SQL, dynamic), 1x 50GB (DATA, dynamic)
                - Roles: "SQLServer2017"
                - CustomRoles: "CM-2103"
                - SiteCode: "P01"
                - SiteName: "CMLab01"
                - Version: "Latest"
                - LogViewer: "OneTrace"
                - Site system roles: MP, DP, SUP (inc WSUS), RSP, EP

    The following customisations are applied to the ConfigMgr server post install:
        - The ConfigMgr console is updated
        - Shortcuts on desktop:
            - Console
            - Logs directory
            - Tools directory
            - Support Center
.EXAMPLE
    PS C:\> .\CM-2103.ps1 -ExcludePostInstallations

    Builds a lab with the the same properties as the first example, with the exception that it does not install Configuration Manager. 
    
    In other words, the VMs DC01 and CM01 will be created, Windows installed, AD installed on DC01 and SQL installed on CM01 and that's it.
    
    This is useful if you want the opportunity the snapshot/checkpoint the laptop VMs before installing Configuration Manager on CM01.

    See the next example on how to trigger the remainder of the install tasks.
.EXAMPLE
    PS C:\> .\CM-2103.ps1 -SkipDomainCheck -SkipLabNameCheck -SkipHostnameCheck -PostInstallations

    Following on from the previous example, this executes the post installation tasks which is to execute the CustomRole CM-2103 scripts on CM01.
.NOTES
    Author: Adam Cook (@codaamok)
    Source: https://github.com/codaamok/PoSH/AutomatedLab
#>
#Requires -Version 5.1 -Modules "AutomatedLab", "Hyper-V", @{ ModuleName = "Pester"; ModuleVersion = "5.0" }
[Cmdletbinding()]
Param (
    [Parameter()]
    [String]$LabName = "CMLab01",

    [Parameter()]
    [ValidateScript({
        if (-not ([System.IO.Directory]::Exists($_))) { 
            throw "Invalid path or access denied" 
        } 
        elseif (-not ($_ | Test-Path -PathType Container)) { 
            throw "Value must be a directory, not a file" 
        }
        $true
    })]
    [String]$VMPath,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$Domain = "sysmansquad.lab",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$AdminUser = "Administrator",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$AdminPass = "Somepass1",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [AutomatedLab.IPNetwork]$AddressSpace,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$ExternalVMSwitchName = "Internet",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[a-zA-Z0-9]{3}$')]
    [String]$SiteCode = "P01",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$SiteName = $LabName,

    [Parameter()]
    [ValidateSet("2103", "Latest")]
    [String]$CMVersion = "Latest",

    [Parameter()]
    [ValidateSet(
        "None",
        "Management Point", 
        "Distribution Point", 
        "Software Update Point", 
        "Reporting Services Point", 
        "Endpoint Protection Point"
    )]
    [String[]]$CMRoles = @(
        "None",
        "Management Point", 
        "Distribution Point", 
        "Software Update Point", 
        "Reporting Services Point", 
        "Endpoint Protection Point"
    ),

    [Parameter()]
    [ValidateSet("CB","TP")]
    [String]$Branch = "CB",

    [Parameter()]
    [ValidateSet(
        "Windows Server 2016 Standard Evaluation (Desktop Experience)",
        "Windows Server 2016 Datacenter Evaluation (Desktop Experience)",
        "Windows Server 2019 Standard Evaluation (Desktop Experience)",
        "Windows Server 2019 Datacenter Evaluation (Desktop Experience)",
        "Windows Server 2016 Standard (Desktop Experience)",
        "Windows Server 2016 Datacenter (Desktop Experience)",
        "Windows Server 2019 Standard (Desktop Experience)",
        "Windows Server 2019 Datacenter (Desktop Experience)"
    )]
    [String]$OSVersion = "Windows Server 2019 Standard Evaluation (Desktop Experience)",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$DCHostname = "DC01",

    [Parameter()]
    [ValidateScript({
        if ($_ -lt 0) { throw "Invalid number of CPUs" }; $true
    })]
    [Int]$DCCPU = 2,

    [Parameter()]
    [ValidateScript({
        if ($_ -lt [Double]128MB -or $_ -gt [Double]128GB) { 
            throw "Memory for VM must be more than 128MB and less than 128GB" 
        }
        if ($_ -lt [Double]1GB) { 
            throw "Please specify more than 1GB of memory" 
        }
        $true
    })]
    [Double]$DCMemory = 2GB,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$CMHostname = "CM01",

    [Parameter()]
    [ValidateScript({
        if ($_ -lt 0) { throw "Invalid number of CPUs" }; $true
    })]
    [Int]$CMCPU = 4,

    [Parameter()]
    [ValidateScript({
        if ($_ -lt [Double]128MB -or $_ -gt [Double]128GB) { throw "Memory for VM must be more than 128MB and less than 128GB" }
        if ($_ -lt [Double]1GB) { throw "Please specify more than 1GB of memory" }
        $true
    })]
    [Double]$CMMemory = 8GB,

    [Parameter()]
    [ValidateScript({
        if (-not [System.IO.File]::Exists($_) -And ($_ -notmatch "\.iso$")) {
            throw "File '$_' does not exist or is not of type '.iso'"
        }
        elseif (-not $_.StartsWith($labSources)) {
            throw "Please move SQL ISO to your Lab Sources folder '$labSources\ISOs'"
        }
        $true
    })]
    [String]$SQLServer2017ISO,

    [Parameter()]
    [ValidateSet("CMTrace", "OneTrace")]
    [String]$LogViewer = "OneTrace",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$ADKDownloadUrl = "https://go.microsoft.com/fwlink/?linkid=2086042",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$WinPEDownloadURL = "https://go.microsoft.com/fwlink/?linkid=2087112",

    [Parameter()]
    [Switch]$SkipDomainCheck,

    [Parameter()]
    [Switch]$SkipLabNameCheck,

    [Parameter()]
    [Switch]$SkipHostnameCheck,

    [Parameter()]
    [Switch]$DoNotDownloadWMIEv2,

    [Parameter()]
    [Switch]$PostInstallations,

    [Parameter()]
    [Switch]$ExcludePostInstallations,

    [Parameter()]
    [Switch]$NoInternetAccess,

    [Parameter()]
    [Switch]$AutoLogon
)

#region New-LabDefinition
$NewLabDefinitionSplat = @{
    Name                        = $LabName
    DefaultVirtualizationEngine = "HyperV"
    ReferenceDiskSizeInGB       = 100
    ErrorAction                 = "Stop"
}
if ($PSBoundParameters.ContainsKey("VMPath")) { 
    $Path = "{0}\{1}" -f $VMPath, $LabName
    $NewLabDefinitionSplat["VMPath"] = $Path
}
New-LabDefinition @NewLabDefinitionSplat
#endregion

#region Initialise
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:OperatingSystem' = $OSVersion
    'Add-LabMachineDefinition:DomainName'      = $Domain
    'Add-LabMachineDefinition:Network'         = $LabName
    'Add-LabMachineDefinition:ToolsPath'       = "{0}\Tools" -f $labSources
    'Add-LabMachineDefinition:MinMemory'       = 1GB
    'Add-LabMachineDefinition:Memory'          = 1GB
}

if ($AutoLogon.IsPresent) {
    $PSDefaultParameterValues['Add-LabMachineDefinition:AutoLogonDomainName'] = $Domain
    $PSDefaultParameterValues['Add-LabMachineDefinition:AutoLogonUserName']   = $AdminUser
    $PSDefaultParameterValues['Add-LabMachineDefinition:AutoLogonPassword']   = $AdminPass
}

$DataDisk = "{0}-DATA-01" -f $CMHostname
$SQLDisk = "{0}-SQL-01" -f $CMHostname

$SQLConfigurationFile = "{0}\CustomRoles\CM-2103\ConfigurationFile-SQL.ini" -f $labSources
#endregion

#region Preflight checks
switch ($true) {
    (-not $SkipLabNameCheck.IsPresent) {
        if ((Get-Lab -List -ErrorAction SilentlyContinue) -contains $_) { 
            throw ("Lab already exists with the name '{0}'" -f $LabName)
        }
    }
    (-not $SkipDomainCheck.IsPresent) {
        try {
            [System.Net.Dns]::Resolve($Domain) | Out-Null
            throw ("Domain '{0}' resolves, choose a different domain" -f $Domain)
        }
        catch {
            # resume
        }
    }
    (-not $SkipHostnameCheck.IsPresent) {
        foreach ($Hostname in @($DCHostname,$CMHostname)) {
            try {
                [System.Net.Dns]::Resolve($Hostname) | Out-Null
                throw ("Host '{0}' resolves, choose a different hostname" -f $Hostname)
            }
            catch {
                continue
            }
        }
    }
    # I know I can use ParameterSets, but I want to be able to execute this script without any parameters too, so this is cleaner.
    ($PostInstallations.IsPresent -And $ExcludePostInstallations.IsPresent) {
        throw "Can not use -PostInstallations and -ExcludePostInstallations together"
    }
    ($NoInternetAccess.IsPresent -And $PSBoundParameters.ContainsKey("ExternalVMSwitchName")) {
        throw "Can not use -NoInternetAccess and -ExternalVMSwitchName together"
    }
    ($NoInternetAccess.IsPresent -And $Branch -eq "TP") {
        throw "Can not install Technical Preview with -NoInternetAccess"
    }
    ((-not $NoInternetAccess.IsPresent) -And $ExternalVMSwitchName -eq 'Default Switch') { 
        break
    }
    ((-not $NoInternetAccess.IsPresent) -And (Get-VMSwitch).Name -notcontains $ExternalVMSwitchName) { 
        throw ("Hyper-V virtual switch '{0}' does not exist" -f $ExternalVMSwitchName)
    }
    ((-not $NoInternetAccess.IsPresent) -And (Get-VMSwitch -Name $ExternalVMSwitchName).SwitchType -ne "External") { 
        throw ("Hyper-V virtual switch '{0}' is not of External type" -f $ExternalVMSwitchName)
    }
    (-not(Test-Path $SQLConfigurationFile)) {
        throw ("Can't find '{0}'" -f $SQLConfigurationFile)
    }
}
#endregion

#region Set credentials
Add-LabDomainDefinition -Name $domain -AdminUser $AdminUser -AdminPassword $AdminPass
Set-LabInstallationCredential -Username $AdminUser -Password $AdminPass
#endregion

#region Get SQL Server 2017 Eval if no .ISO given
if (-not $PSBoundParameters.ContainsKey("SQLServer2017ISO")) {
    Write-ScreenInfo -Message "Downloading SQL Server 2017 Evaluation" -TaskStart

    $URL = "https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLServer2017-x64-ENU.iso"
    $SQLServer2017ISO = "{0}\ISOs\SQLServer2017-x64-ENU.iso" -f $labSources

    if (Test-Path $SQLServer2017ISO) {
        Write-ScreenInfo -Message ("SQL Server 2017 Evaluation ISO already exists, delete '{0}' if you want to download again" -f $SQLServer2017ISO)
    }
    else {
        try {
            Write-ScreenInfo -Message "Downloading SQL Server 2017 ISO" -TaskStart
            Get-LabInternetFile -Uri $URL -Path (Split-Path $SQLServer2017ISO -Parent) -FileName (Split-Path $SQLServer2017ISO -Leaf) -ErrorAction "Stop"
            Write-ScreenInfo -Message "Done" -TaskEnd
        }
        catch {
            $Message = "Failed to download SQL Server 2017 ISO ({0})" -f $_.Exception.Message
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $Message
        }
        if (-not (Test-Path $SQLServer2017ISO)) {
            $Message = "Could not find SQL Server 2017 ISO '{0}' after download supposedly complete" -f $SQLServer2017ISO
            Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
            throw $Message
        }
        else {
            Write-ScreenInfo -Message "Download complete" -TaskEnd
        }
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
}
#endregion

#region Evaluate -CMVersion 
if ($NoInternetAccess.IsPresent -And $CMVersion -ne "2103") {
    Write-ScreenInfo -Message "Switch -NoInternetAccess is passed therefore will not be able to update ConfigMgr, forcing target version to be '2103' to skip checking for updates later"
    $CMVersion = "2103"
}
# Forcing site version to be latest for TP if -CMVersion is not baseline or latest
if ($Branch -eq "TP" -And @("2103","Latest") -notcontains $CMVersion) {
    Write-ScreenInfo -Message "-CMVersion should only be '2103 or 'Latest' for Technical Preview, forcing target version to be 'Latest'"
    $CMVersion = "Latest"
}
#endregion

#region Build AutomatedLab
$netAdapter = @()
$Roles = @("RootDC")

$AddLabVirtualNetworkDefinitionSplat = @{
    Name                   = $LabName
    VirtualizationEngine   = "HyperV"
}

$NewLabNetworkAdapterDefinitionSplat = @{
    VirtualSwitch = $LabName
}

if ($PSBoundParameters.ContainsKey("AddressSpace")) {
    $AddLabVirtualNetworkDefinitionSplat["AddressSpace"] = $AddressSpace
    $NewLabNetworkAdapterDefinitionSplat["Ipv4Address"]  = $AddressSpace
}

Add-LabVirtualNetworkDefinition @AddLabVirtualNetworkDefinitionSplat
$netAdapter += New-LabNetworkAdapterDefinition @NewLabNetworkAdapterDefinitionSplat

if (-not $NoInternetAccess.IsPresent) {
    Add-LabVirtualNetworkDefinition -Name $ExternalVMSwitchName -VirtualizationEngine "HyperV" -HyperVProperties @{ SwitchType = 'External'; AdapterName = $ExternalVMSwitchName }
    $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $ExternalVMSwitchName -UseDhcp
    $Roles += "Routing"
}

Add-LabMachineDefinition -Name $DCHostname -Processors $DCCPU -Roles $Roles -NetworkAdapter $netAdapter -MaxMemory $DCMemory

Add-LabIsoImageDefinition -Name SQLServer2017 -Path $SQLServer2017ISO

$sqlRole = Get-LabMachineRoleDefinition -Role SQLServer2017 -Properties @{ 
    ConfigurationFile = [String]$SQLConfigurationFile
    Collation = "SQL_Latin1_General_CP1_CI_AS"
}

Add-LabDiskDefinition -Name $DataDisk -DiskSizeInGb 50 -Label "DATA01" -DriveLetter "G"
Add-LabDiskDefinition -Name $SQLDisk -DiskSizeInGb 30 -Label "SQL01" -DriveLetter "F"

if ($ExcludePostInstallations.IsPresent) {
    Add-LabMachineDefinition -Name $CMHostname -Processors $CMCPU -Roles $sqlRole -MaxMemory $CMMemory -DiskName $DataDisk, $SQLDisk
}
else {
    $CMRole = Get-LabPostInstallationActivity -CustomRole "CM-2103" -Properties @{
        Branch              = $Branch
        Version             = $CMVersion
        ALLabName           = $LabName
        CMSiteCode          = $SiteCode
        CMSiteName          = $SiteName
        CMBinariesDirectory = "{0}\SoftwarePackages\CM2103-{1}" -f $labSources, $Branch
        CMPreReqsDirectory  = "{0}\SoftwarePackages\CM2103-PreReqs-{1}" -f $labSources, $Branch
        CMProductId         = "EVAL" # Can be "Eval" or a product key
        CMDownloadURL       = switch ($Branch) {
            "CB" { 
                "https://download.microsoft.com/download/8/8/8/888d525d-5523-46ba-aca8-4709f54affa8/MEM_Configmgr_2103.exe"
            }
            "TP" { 
                "https://download.microsoft.com/download/D/8/E/D8E795CE-44D7-40B7-9067-D3D1313865E5/Configmgr_TechPreview2103.exe"
            }
        }
        CMRoles             = $CMRoles
        ADKDownloadURL      = $ADKDownloadUrl
        ADKDownloadPath     = "{0}\SoftwarePackages\ADK" -f $labSources
        WinPEDownloadURL    = $WinPEDownloadURL
        WinPEDownloadPath   = "{0}\SoftwarePackages\WinPE" -f $labSources
        LogViewer           = $LogViewer
        DoNotDownloadWMIEv2 = $DoNotDownloadWMIEv2.IsPresent.ToString()
        AdminUser           = $AdminUser
        AdminPass           = $AdminPass
    }

    Add-LabMachineDefinition -Name $CMHostname -Processors $CMCPU -Roles $sqlRole -MaxMemory $CMMemory -DiskName $DataDisk, $SQLDisk -PostInstallationActivity $CMRole
}
#endregion

#region Install
if ($PostInstallations.IsPresent) {
    Install-Lab -PostInstallations -NoValidation
}
else {
    Install-Lab
}
Show-LabDeploymentSummary -Detailed
#endregion
