# Scenarios - SCVMM2022

This sample lab deploys two VMM 2022 instances, one default and
one customized. If you add HyperV roles to this lab, you can already
have those included in your VMM environment as well, using the
role property `ConnectHyperVRoleVms`.

```powershell
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
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2022 Datacenter (Desktop Experience)'
}

if ($Engine -eq 'Azure')
{
    Sync-LabAzureLabSources -Filter *mul_system_center_virtual_machine_manager_2022_x64_dvd_fed2ae0f*
    Sync-LabAzureLabSources -Filter *en_sql_server_2019_enterprise_x64_dvd_5e1ecc6b*
}
Add-LabIsoImageDefinition -Name Scvmm2022 -Path $labSources\ISOs\mul_system_center_virtual_machine_manager_2022_x64_dvd_fed2ae0f.iso
Add-LabIsoImageDefinition -Name SQLServer2019 -Path $labSources\ISOs\en_sql_server_2019_enterprise_x64_dvd_5e1ecc6b.iso

Add-LabMachineDefinition -DomainName contoso.com -Name DC1 -Memory 1GB -OperatingSystem 'Windows Server 2022 Datacenter (Desktop Experience)' -Roles RootDC
Add-LabMachineDefinition -DomainName contoso.com -Name DB1 -Memory 4GB -OperatingSystem 'Windows Server 2022 Datacenter (Desktop Experience)' -Roles SQLServer2019

# Plain SCVMM
Add-LabMachineDefinition -DomainName contoso.com -Name VMM1 -Memory 4GB -OperatingSystem 'Windows Server 2022 Datacenter (Desktop Experience)' -Roles Scvmm2022

# Customized Setup, here: Only deploy Console
$role = Get-LabMachineRoleDefinition -Role Scvmm2022 -Properties @{
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
    # ConnectHyperVRoleVms        = 'VM1, VM2, VM3' # Single string with comma- or semicolon-separated values
}
Add-LabMachineDefinition -DomainName contoso.com -Name VMC1 -Memory 4GB -OperatingSystem 'Windows Server 2022 Datacenter (Desktop Experience)' -Roles $role
Install-Lab
if ($Engine -eq 'Azure')
{
    Stop-LabVm -All
}
Show-LabDeploymentSummary -Detailed
```
