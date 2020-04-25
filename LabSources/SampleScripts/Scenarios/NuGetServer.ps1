param
(
    [Parameter()]
    [string]
    $LabName = 'nuget',

    [Parameter()]
    [string]
    [ValidateSet('Azure', 'HyperV')]
    $Engine = 'HyperV'
)

New-LabDefinition -Name $LabName -DefaultVirtualizationEngine $Engine
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.30.0/24
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network'         = $labName
    'Add-LabMachineDefinition:ToolsPath'       = "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName'      = 'contoso.com'
    'Add-LabMachineDefinition:DnsServer1'      = '192.168.30.10'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
}

Add-LabMachineDefinition -Name NUGDC1 -Memory 2gB -Roles RootDC, CARoot -IpAddress 192.168.30.10
$role = Get-LabPostInstallationActivity -CustomRole NuGetServer -Properties @{
    Package              = 'PSFramework','PSTranslate' # "Mandatory" if PackagePath is not used
    #PackagePath          = "D:\tmp\Packages" # Optional - only if Packages is not used, define a directory containing nuget files to publish
    #SourceRepositoryName = 'PSGallery' # Optional, valid if Packages is not used - if you want to download your packages from a different upstream gallery than PSGallery
    #ApiKey               = 'MySecureApiKey' # Optional - defaults to lab installation password, e.g. Somepass1
    #Port                 = '8080' # Optional - defaults to 80 if no CA is present or 443, if a CA is present in the lab
    #UseSsl               = 'true' # Optional - use only if a CA is present in the lab
}

Add-LabMachineDefinition -Name NUG01 -Memory 2GB -Roles WebServer -PostInstallationActivity $role

Install-Lab

Show-LabDeploymentSummary -Detailed