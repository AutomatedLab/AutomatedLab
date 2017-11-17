$labname = 'failover'
New-LabDefinition -Name $labname -DefaultVirtualizationEngine HyperV

Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

Set-LabInstallationCredential -Username Install -Password Somepass1

Add-LabVirtualNetworkDefinition -Name $labname -AddressSpace 192.168.50.0/24

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 SERVERDATACENTER'
    'Add-LabMachineDefinition:Network'         = $labname
    'Add-LabMachineDefinition:DomainName'      = 'contoso.com'
    'Add-LabMachineDefinition:Memory'          = 1GB
}

Add-LabMachineDefinition -Name foDC1 -Roles RootDC

# Integrate an iSCSI Target into your machines
$storageRole = Get-LabMachineRoleDefinition -Role FailoverStorage -Properties @{LunDrive = 'D' }
Add-LabDiskDefinition -Name LunDisk -DiskSizeInGb 26
Add-LabMachineDefinition -Name foCLS1 -Roles $storageRole -DiskName LunDisk

# Integrate one or more clusters
$cluster1 = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'Clu1'; ClusterIp = '192.168.50.111' }
$cluster2 = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'Clu2'; ClusterIp = '192.168.50.121' }
foreach ( $i in 1..4 )
{
    if ($i % 2)
    {
        Add-LabMachineDefinition -name foCLN$i -Roles $cluster1
    }
    else
    {
        Add-LabMachineDefinition -name foCLN$i -Roles $cluster2
    }
    
}

Install-Lab

Show-LabDeploymentSummary