<#
This demo creates a failover cluster with 2 nodes, and 2 shared disks
that can be added to cluster roles.
#>

$labname = 'FailOverLab1'
New-LabDefinition -Name $labname -DefaultVirtualizationEngine HyperV

Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

Set-LabInstallationCredential -Username Install -Password Somepass1

Add-LabVirtualNetworkDefinition -Name $labname -AddressSpace 192.168.50.0/24

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Network'         = $labname
    'Add-LabMachineDefinition:DomainName'      = 'contoso.com'
    'Add-LabMachineDefinition:Memory'          = 1GB
}

Add-LabMachineDefinition -Name foDC1 -Roles RootDC

# Integrate an iSCSI Target into your machines
$storageRole = Get-LabMachineRoleDefinition -Role FailoverStorage
Add-LabDiskDefinition -Name LunDrive -DiskSizeInGb 26 -DriveLetter D
Add-LabDiskDefinition -Name SqlDataDrive -DiskSizeInGb 10 -DriveLetter E
Add-LabDiskDefinition -Name SqlLogDrive -DiskSizeInGb 10 -DriveLetter F
Add-LabMachineDefinition -Name foCLS1 -Roles $storageRole -DiskName LunDrive, SqlDataDrive, SqlLogDrive

# create a cluster role
$cluster1 = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'Clu1'; ClusterIp = '192.168.50.111' }

# add two nodes for the cluster
Add-LabMachineDefinition -name foCLN1 -Roles $cluster1
Add-LabMachineDefinition -name foCLN2 -Roles $cluster1

Install-Lab

Show-LabDeploymentSummary