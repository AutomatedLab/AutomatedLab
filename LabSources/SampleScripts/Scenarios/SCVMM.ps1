#Requires -Module AutomatedLab
param
(
    [AutomatedLab.VirtualizationHost]
    $Engine = 'HyperV',

    [string]
    $LabName = 'SCVMM'
)

New-LabDefinition -Name $LabName -DefaultVirtualizationEngine $Engine
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $LabName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
}

if ($Engine -eq 'Azure')
{
    Sync-LabAzureLabSources -Filter *mu_system_center_virtual_machine_manager_2019_x64_dvd_06c18108*
    Sync-LabAzureLabSources -Filter *en_sql_server_2017_enterprise_x64_dvd_11293666*
}
Add-LabIsoImageDefinition -Name Scvmm2019 -Path $labSources\ISOs\mu_system_center_virtual_machine_manager_2019_x64_dvd_06c18108.iso
Add-LabIsoImageDefinition -Name SQLServer2017 -Path $labSources\ISOs\en_sql_server_2017_enterprise_x64_dvd_11293666.iso

Add-LabMachineDefinition -DomainName contoso.com -Name DC1 -Memory 4GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles RootDC
Add-LabMachineDefinition -DomainName contoso.com -Name DB1 -Memory 4GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles SQLServer2017

# Plain SCVMM
Add-LabMachineDefinition -DomainName contoso.com -Name VMM1 -Memory 8GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles Scvmm2019

# Customized Setup, here: Only deploy Console
$role = Get-LabMachineRoleDefinition -Role Scvmm2019 -Properties @{
    SkipServer = 'true'
    # UserName                    = 'Administrator'
    # CompanyName                 = 'AutomatedLab'
    # ProgramFiles                = 'C:\Program Files\Microsoft System Center\Virtual Machine Manager {0}'
    # CreateNewSqlDatabase        = '1'
    # RemoteDatabaseImpersonation = '0'
    # SqlMachineName              = 'REPLACE'
    # IndigoTcpPort               = '8100'
    # IndigoHTTPSPort             = '8101'
    # IndigoNETTCPPort            = '8102'
    # IndigoHTTPPort              = '8103'
    # WSManTcpPort                = '5985'
    # BitsTcpPort                 = '443'
    # CreateNewLibraryShare       = '1'
    # LibraryShareName            = 'MSSCVMMLibrary'
    # LibrarySharePath            = 'C:\ProgramData\Virtual Machine Manager Library Files'
    # LibraryShareDescription     = 'Virtual Machine Manager Library Files'
    # SQMOptIn                    = '0'
    # MUOptIn                     = '0'
    # VmmServiceLocalAccount      = '0'
}
Add-LabMachineDefinition -DomainName contoso.com -Name VMC1 -Memory 8GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles $role
Install-Lab
if ($Engine -eq 'Azure')
{
    Stop-LabVm -All
}
Show-LabDeploymentSummary -Detailed