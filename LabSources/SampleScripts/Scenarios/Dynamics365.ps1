[CmdletBinding()]
param
(
    # Select platform, defaults to HyperV
    [AutomatedLab.VirtualizationHost]
    $Hypervisor = 'HyperV',

    # Indicates that the installation of Dynamics should be split
    # into its three components
    [switch]
    $IndividualComponents
)

New-LabDefinition -name dynamics -DefaultVirtualizationEngine $Hypervisor

Add-LabDomainDefinition contoso.com -AdminU Install -AdminP Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1

Add-LabIsoImageDefinition -name SQLServer2017 -Path $labsources/ISOs/en_sql_server_2017_enterprise_x64_dvd_11293666.iso

Add-LabMachineDefinition -Name DDC1 -Memory 4GB -Roles RootDc, CARoot -Domain contoso.com -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)'
Add-LabMachineDefinition -Name DDB1 -Memory 8GB -Roles SQLServer2017 -Domain contoso.com -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)'

if ($IndividualComponents.IsPresent)
{
    Add-LabMachineDefinition -Name DDYF1 -Memory 6GB -Roles DynamicsFrontend -Domain contoso.com -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)'
    Add-LabMachineDefinition -Name DDYB1 -Memory 6GB -Roles DynamicsBackend -Domain contoso.com -OperatingSystem 'Windows Server 2019 Datacenter'
    Add-LabMachineDefinition -Name DDYA1 -Memory 4GB -Roles DynamicsAdmin -Domain contoso.com -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)'
}
else
{
    Add-LabMachineDefinition -Name DDY1 -Memory 16GB -Roles DynamicsFull -Domain contoso.com -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)'
}

Install-Lab
