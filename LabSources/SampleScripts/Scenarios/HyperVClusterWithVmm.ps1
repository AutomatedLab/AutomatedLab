$labname = 'SCVMMHV'
New-LabDefinition -Name $labname -DefaultVirtualizationEngine HyperV

Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

Set-LabInstallationCredential -Username Install -Password Somepass1

Add-LabVirtualNetworkDefinition -Name $labname -AddressSpace 192.168.50.0/24

Add-LabIsoImageDefinition -Name Scvmm2019 -Path $labSources\ISOs\mu_system_center_virtual_machine_manager_2019_x64_dvd_06c18108.iso
Add-LabIsoImageDefinition -Name SQLServer2017 -Path $labSources\ISOs\en_sql_server_2017_enterprise_x64_dvd_11293666.iso

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Network'         = $labname
    'Add-LabMachineDefinition:DomainName'      = 'contoso.com'
    'Add-LabMachineDefinition:Memory'          = 1GB
}

Add-LabMachineDefinition -Name VMMDC1 -Roles RootDC

# Integrate an iSCSI Target into your machines
$storageRole = Get-LabMachineRoleDefinition -Role FailoverStorage -Properties @{LunDrive = 'D' }
Add-LabDiskDefinition -Name LunDisk -DiskSizeInGb 26
Add-LabMachineDefinition -Name VMMCLS1 -Roles $storageRole,SQLServer2017 -DiskName LunDisk -Memory 8GB

# Integrate one or more clusters
# This sample will create two named clusters and one automatic cluster called ALCluster with an automatic static IP
$cluster1 = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'Clu1'; ClusterIp = '192.168.50.111' }
Add-LabMachineDefinition -Name HV1 -Roles $cluster1, HyperV -Memory 8GB
Add-LabMachineDefinition -Name HV2 -Roles $cluster1, HyperV -Memory 8GB
$vmmRole = Get-LabMachineRoleDefinition -Role Scvmm2019 -Properties @{
    ConnectClusters             =  'Clu1'
}
Add-LabMachineDefinition -Name VMM -Memory 3gb -Roles $vmmRole

Install-Lab

Show-LabDeploymentSummary
