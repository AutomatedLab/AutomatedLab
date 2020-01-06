<#
.SYNOPSIS
    An AutomatedLab script for Configuration Manager 1902 with support for installing updates.
.DESCRIPTION
    An AutomatedLab script for Configuration Manager 1902 with support for installing updates.
.EXAMPLE
    PS C:\> .\CM-1902.ps1 

    Builds a lab with the following properties:
        - 1x AutomatedLab:
            Name: "CMLab01"
            VMPath: <drive>:\AutomatedLab-VMs where <drive> is the fastest drive available
        - 1x Active Directory domain:
            Domain: "winadmins.lab"
            Username: "Administrator"
            Password: "Somepass1"
            AddressSpace: An unused and available subnet increasing 192.168.1.0 by 1 until one is found.
            ExternalVMSwitch: Allows physical network access via Hyper-V external switch named "Internet".
        - 2x virtual machines:
            Operating System: Windows Server 2019 (Desktop Experience)
            1x Domain Controller:
                Name: "DC01"
                vCPU: 2
                Max memory: 2GB
                Roles: "RootDC", "Routing"
            1x Configuration Manager:
                Name: "CM01"
                vCPU: 4
                Max memory: 8GB
                Roles: "SQLServer2017"
                CustomRoles: "CM-1902"
                SiteCode: "P01"
                SiteName: "CMLab01"
                Version: "Latest"
                LogViewer: "OneTrace"

    The following customsations are applied to the ConfigMgr server post install:
        - The ConfigMgr console is updated
        - Shortcuts on desktop:
            - Console
            - Logs directory
            - Tools directory
            - Support Center

.EXAMPLE
    PS C:\> .\CM-1902.ps1 -ExcludePostInstallations

    Builds a lab with the the same properties as the first example, with the exception that it does not install Configuration Manager. 
    
    In other words, the VMs DC01 and CM01 will be created, Windows installed, AD installed on DC01 and SQL installed on CM01 and that's it.
    
    This is useful if you want the opportunity the snapshot/checkpoint the laptop VMs before installing Configuration Manager on CM01.

    See the next example on how to trigger the remainder of the isntall tasks.

.EXAMPLE
    PS C:\> .\CM-1902.ps1 -SkipDomainCheck -SkipLabNameCheck -SkipHostnameCheck -PostInstallations

    Following on from the previous example, this executes the post installation tasks which is to execute the CustomRole CM-1902 scripts on CM01.

.PARAMETER LabName
    The name of the AutomatedLab lab created by this script.
.PARAMETER VMPath
    The path where you would like to save the VM data (.vhdx and .vmcx files) for this lab. 
    The scripts appends the lab name to the path you give. For example, if -LabName is "CMLab01" and -VMPath is "C:\VMs" then the VMs will be saved in "C:\VMs\CMLab01".
.PARAMETER Domain
    The Active Directory domain for this lab.
    If the domain resolves to an IP address, a terminating error is thrown. Use the -SkipDomainCheck switch to continue even if the domain resolves to an IP address.
.PARAMETER AdminUser
    The username of a Domain Administratior within your lab. Also the account used for installing Active Directory and other software packages in this lab.
.PARAMETER AdminPass
    The password for the AdminUser.
.PARAMETER AddressSpace
    The IP subnet this lab uses, accepted syntax for the value is slash notation, for example 192.168.1.0/24.
    Omitting this parameter forces AutomatedLab to find new subnets by simply increasing 192.168.1.0 until a free network is found. Free means that there is no virtual network switch with an IP address in the range of the subnet and the subnet is not routable. If these conditions are not met, the subnet is incremented again.
.PARAMETER ExternalVMSwitchName
    The name of the External Hyper-V switch. The given name must be of an existing Hyper-V switch and it must be of 'External' type.
    If you do not want this lab to have physical network access, use the -NoInternetAccess switch.
    You cannot use this parameter with -NoInternetAccess.
.PARAMETER SiteCode
    Configuration Manager site code.
.PARAMETER SiteName
    Configuration Manager site name.
.PARAMETER CMVersion
    The target Configuration version you wish to install.
    This script first installs 1902 baseline and then installs updates. If -CMVersion is "1902" then the update process is skipped.
    Acceptable values are "1902", "1906", "1910" or "Latest".
.PARAMETER OSVersion
    Operating System version for all VMs in this lab.
    Acceptable values are "2016" or "2019". Ensure you have the corresponding ISO media in your LabSources\ISOs folder.
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
.PARAMETER LogViewer
    The default .log and .lo_ file viewer for only the Configuration Manager server.
    OneTrace was introduced in 1906 so if -LogViewer is "OneTrace" and -CMVersion is "1902" or -NoInternetAccess is specified, then -LogViewer will revert to "CMTrace".
    Acceptable values are "CMTrace" or "OneTrace".
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
.NOTES
    Author:       Adam Cook (@codaamok)
    Date created: 2019-01-05
    Source:       https://github.com/codaamok/PoSH/AutomatedLab
#>
#Requires -Version 5.1 -Modules "AutomatedLab", "Hyper-V"
[Cmdletbinding()]
Param (
    [Parameter()]
    [String]$LabName = "CMLab01",

    [Parameter()]
    [ValidateScript({
        if (!([System.IO.Directory]::Exists($_))) { throw "Invalid path or access denied" } elseif (!($_ | Test-Path -PathType Container)) { throw "Value must be a directory, not a file" }; return $true
    })]
    [String]$VMPath,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$Domain = "winadmins.lab",

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
    [ValidateSet("1902","1906","1910","Latest")]
    [String]$CMVersion = "Latest",

    [Parameter()]
    [ValidateSet("2016","2019")]
    [String]$OSVersion = "2019",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$DCHostname = "DC01",

    [Parameter()]
    [ValidateScript({
        if ($_ -lt 0) { throw "Invalid number of CPUs" }; return $true
    })]
    [Int]$DCCPU = 2,

    [Parameter()]
    [ValidateScript({
        if ($_ -lt [Double]128MB -or $_ -gt [Double]128GB) { throw "Memory for VM must be more than 128MB and less than 128GB" }; $true
        if ($_ -lt [Double]1GB) { throw "Please specify more than 1GB of memory" }
    })]
    [Double]$DCMemory = 2GB,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$CMHostname = "CM01",

    [Parameter()]
    [ValidateScript({
        if ($_ -lt 0) { throw "Invalid number of CPUs" }; return $true
    })]
    [Int]$CMCPU = 4,

    [Parameter()]
    [ValidateScript({
        if ($_ -lt [Double]128MB -or $_ -gt [Double]128GB) { throw "Memory for VM must be more than 128MB and less than 128GB" }
        if ($_ -lt [Double]1GB) { throw "Please specify more than 1GB of memory" }
        return $true
    })]
    [Double]$CMMemory = 8GB,

    [Parameter()]
    [ValidateSet("CMTrace", "OneTrace")]
    [String]$LogViewer = "OneTrace",

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
        ForEach ($Hostname in @($DCHostname,$CMHostname)) {
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
    ((Get-VMSwitch).Name -notcontains $ExternalVMSwitchName) { 
        throw ("Hyper-V virtual switch '{0}' does not exist" -f $ExternalVMSwitchName)
    }
    ((Get-VMSwitch -Name $ExternalVMSwitchName).SwitchType -ne "External") { 
        throw ("Hyper-V virtual switch '{0}' is not of External type" -f $ExternalVMSwitchName)
    }
}
#endregion

#region Initialise
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:OperatingSystem' = "Windows Server $OSVersion Standard (Desktop Experience)"
    'Add-LabMachineDefinition:DomainName'      = $Domain
    'Add-LabMachineDefinition:Network'         = $LabName
    'Add-LabMachineDefinition:ToolsPath'       = "$labSources\Tools"
    'Add-LabMachineDefinition:MinMemory'       = 1GB
    'Add-LabMachineDefinition:Memory'          = 1GB
}

if ($AutoLogon.IsPresent) {
    $PSDefaultParameterValues['Add-LabMachineDefinition:AutoLogonDomainName'] = $Domain
    $PSDefaultParameterValues['Add-LabMachineDefinition:AutoLogonUserName']   = $AdminUser
    $PSDefaultParameterValues['Add-LabMachineDefinition:AutoLogonPassword']   = $AdminPass
}

# Changing the below doesn't actually do anything at the moment. One day I will test vmware.
$Engine = "HyperV"
#endregion

#region New-LabDefinition
$NewLabDefinitionSplat = @{
    Name                        = $LabName
    DefaultVirtualizationEngine = $Engine
    ReferenceDiskSizeInGB       = 100
    ErrorAction                 = "Stop"
}
if ($PSBoundParameters.ContainsKey("VMPath")) { 
    $Path = Join-Path -Path $VMPath -ChildPath $LabName
    $NewLabDefinitionSplat.Add("VMPath",$Path)
}
New-LabDefinition @NewLabDefinitionSplat
#endregion

#region Set credentials
Add-LabDomainDefinition -Name $domain -AdminUser $AdminUser -AdminPassword $AdminPass
Set-LabInstallationCredential -Username $AdminUser -Password $AdminPass
#endregion

#region Download WMIExplorer v2
if (-not $DoNotDownloadWMIEv2.IsPresent) {
    $WMIv2Zip = Join-Path -Path $labSources -ChildPath "Tools\WmiExplorer_2.0.0.2.zip"
    $WMIv2Exe = Join-Path -Path $labSources -ChildPath "Tools\WmiExplorer.exe"
    if (-not (Test-Path $WMIv2Zip) -And (-not (Test-Path $WMIv2Exe))) {
        Write-ScreenInfo -Message "Downloading WMIExplorer v2" -TaskStart
        try {
            Get-LabInternetFile -Uri "https://github.com/vinaypamnani/wmie2/releases/download/v2.0.0.2/WmiExplorer_2.0.0.2.zip" -Path $WMIv2Zip -ErrorAction Stop -ErrorVariable GetLabInternetFileErr
        }
        catch {
            Write-ScreenInfo -Message ("Could not download WmiExplorer ({0})" -f $GetLabInternetFileErr.Exception.Message) -Type "Warning"
        }
        if (Test-Path -Path $WMIv2Zip) {
            Expand-Archive -Path $WMIv2Zip -DestinationPath $labSources\Tools -ErrorAction Stop
            try {
                Remove-Item -Path $WMIv2Zip -Force -ErrorAction Stop -ErrorVariable RemoveItemErr
            }
            catch {
                Write-ScreenInfo -Message ("Failed to delete '{0}' ({1})" -f $WMIZip, $RemoveItemErr.Exception.Message) -Type "Warning"
            }
        } 
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else {
        Write-ScreenInfo -Message "WmiExplorer.exe already exists, skipping the download. Delete the file '{0}' if you want to download again."
    }
}
#endregion

#region Forcing 1902 is -NoInternetAccess is passed
if ($NoInternetAccess.IsPresent -And $CMVersion -ne "1902") {
    Write-ScreenInfo -Message "Switch -NoInternetAccess is passed therefore will not be able to update ConfigMgr, forcing target version to be '1902' to skip checking for updates later"
    $CMVersion = "1902"
}
#endregion

#region Forcing $LogViewer = CMTrace if $CMVersion -eq 1902
if ($CMVersion -eq 1902 -and $LogViewer -eq "OneTrace") {
    Write-ScreenInfo -Message "Setting LogViewer to 'CMTrace' as OneTrace is only availale in 1906 or newer" -Type "Warning"
    $LogViewer = "CMTrace"
}
#endregion

#region Build AutomatedLab
$netAdapter = @()
$AddLabVirtualNetworkDefinitionSplat = @{
    Name                   = $LabName
    VirtualizationEngine   = $Engine
}
$NewLabNetworkAdapterDefinitionSplat = @{
    VirtualSwitch = $LabName
}
if ($PSBoundParameters.ContainsKey("AddressSpace")) {
    $AddLabVirtualNetworkDefinitionSplat.Add("AddressSpace", $AddressSpace)
    $NewLabNetworkAdapterDefinitionSplat.Add("Ipv4Address", $AddressSpace)
}
Add-LabVirtualNetworkDefinition @AddLabVirtualNetworkDefinitionSplat
$netAdapter += New-LabNetworkAdapterDefinition @NewLabNetworkAdapterDefinitionSplat

if (-not $NoInternetAccess.IsPresent) {
    Add-LabVirtualNetworkDefinition -Name "Internet" -VirtualizationEngine $Engine -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Internet' }
    $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch "Internet" -UseDhcp
}

Add-LabMachineDefinition -Name $DCHostname -Processors $DCCPU -Roles RootDC,Routing -NetworkAdapter $netAdapter -MaxMemory $DCMemory

Add-LabIsoImageDefinition -Name SQLServer2017 -Path "$labSources\ISOs\en_sql_server_2017_standard_x64_dvd_11294407.iso"

$sqlRole = Get-LabMachineRoleDefinition -Role SQLServer2017 -Properties @{ 
    Collation = 'SQL_Latin1_General_CP1_CI_AS'
}

Add-LabDiskDefinition -Name "CM01-DATA-01" -DiskSizeInGb 50 -Label "DATA01" -DriveLetter "G"
Add-LabDiskDefinition -Name "CM01-SQL-01" -DiskSizeInGb 30 -Label "SQL01" -DriveLetter "F"

if ($ExcludePostInstallations.IsPresent) {
    Add-LabMachineDefinition -Name $CMHostname -Processors $CMCPU -Roles $sqlRole -MaxMemory $CMMemory -DiskName "CM01-DATA-01","CM01-SQL-01"
}
else {
    $sccmRole = Get-LabPostInstallationActivity -CustomRole "CM-1902" -Properties @{
        SccmSiteCode            = $SiteCode
        SccmSiteName            = $SiteName
        SccmBinariesDirectory   = "$labSources\SoftwarePackages\CM1902"
        SccmPreReqsDirectory    = "$labSources\SoftwarePackages\CMPreReqs"
        SccmProductId           = "Eval" # Can be "Eval" or a product key
        Version                 = $CMVersion
        AdkDownloadPath         = "$labSources\SoftwarePackages\ADK"
        WinPEDownloadPath       = "$labSources\SoftwarePackages\WinPE"
        LogViewer               = $LogViewer
        SqlServerName           = $CMHostname
    }
    Add-LabMachineDefinition -Name $CMHostname -Processors $CMCPU -Roles $sqlRole -MinMemory 2GB -MaxMemory 8GB -Memory 4GB -DiskName "CM01-DATA-01","CM01-SQL-01" -PostInstallationActivity $sccmRole
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