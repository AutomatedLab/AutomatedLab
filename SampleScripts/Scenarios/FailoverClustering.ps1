$labname = 'failover'
New-LabDefinition -Name $labname -DefaultVirtualizationEngine HyperV

Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

Set-LabInstallationCredential -Username Install -Password Somepass1

Add-LabVirtualNetworkDefinition -Name $labname -AddressSpace 192.168.50.0/24

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 SERVERDATACENTER'
    'Add-LabMachineDefinition:Network' = '$labname'
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:Memory' = 1GB
}

$storageRole = Get-LabMachineRoleDefinition -Role FailoverStorage -Properties @{LunSize = [string]25GB; LunDrive = 'D' }
Add-LabDiskDefinition -Name LunDisk -DiskSizeInGb 26

Add-LabMachineDefinition -Name foDC1 -Roles RootDC
Add-LabMachineDefinition -Name foCLS1 -Roles $storageRole -DiskName $disk.Name

$clusterRole = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'MyCluster'; ClusterIp = '192.168.50.111' }
foreach ( $i in 1..4 )
{
    Add-LabMachineDefinition -name foCLN$i -Roles $clusterRole
}

Install-Lab

Show-LabDeploymentSummary