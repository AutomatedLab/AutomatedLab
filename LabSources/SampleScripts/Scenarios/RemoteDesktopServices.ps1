[CmdletBinding()]
param
(
    # Select platform, defaults to HyperV
    [AutomatedLab.VirtualizationHost]
    $Hypervisor = 'HyperV'
)

New-LabDefinition -Name RDS -DefaultVirtualizationEngine $Hypervisor

Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath'       = "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName'      = 'contoso.com'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Memory'          = 4gb
}

# Base infra: Domain and Certificate Authority
Add-LabMachineDefinition -Name RDSDC01 -Role RootDc -Domain contoso.com -OperatingSystem 'Windows Server 2019 Datacenter'
Add-LabMachineDefinition -Name RDSCA01 -Role CaRoot -Domain contoso.com -OperatingSystem 'Windows Server 2019 Datacenter'

# Gateway and Web
Add-LabMachineDefinition -Name RDSGW01 -Role RemoteDesktopGateway, RemoteDesktopWebAccess

# Connection Broker and Licensing
Add-LabMachineDefinition -Name RDSCB01 -Role RemoteDesktopConnectionBroker, RemoteDesktopLicensing

# Session Host Pool, automatically assigned to collection AutomatedLab
foreach ($count in 1..2)
{
    Add-LabMachineDefinition -Name RDSSH0$count -Roles RemoteDesktopSessionHost
}

Install-Lab
Show-LabDeploymentSummary