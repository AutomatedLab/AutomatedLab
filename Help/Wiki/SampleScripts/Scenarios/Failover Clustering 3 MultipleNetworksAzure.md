# Scenarios - Failover Clustering 3 MultipleNetworksAzure

INSERT TEXT HERE

```powershell
# Checkout the other parameters for Add-LabAzureSubscription! Get-Command -Syntax Add-LabAzureSubscription
$subscriptionName = 'Your subscription'
$labname = 'FailOverLab3'
New-LabDefinition -Name $labname -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -SubscriptionName $subscriptionName

Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1

# On Azure, VMs cannot have multiple NICs in multiple VNETs
# Thus, we create one big VNET with three subnets
Add-LabVirtualNetworkDefinition -Name $labname -AddressSpace 192.168.0.0/16 -AzureProperties @{
    Subnets = @{
        Management = '192.168.30.0/24'
        Cluster1   = '192.168.50.0/24'
        Cluster2   = '192.168.60.0/24'
    }
}

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Network'         = $labname
    'Add-LabMachineDefinition:DomainName'      = 'contoso.com'
    'Add-LabMachineDefinition:Memory'          = 1GB
    'Add-LabMachineDefinition:DnsServer1'      = '192.168.30.100'
    'Add-LabMachineDefinition:AzureRoleSize'   = 'Standard_D8_v3'
}

Add-LabMachineDefinition -Name foDC1 -Roles RootDC -IPAddress 192.168.30.100

# Multiple IPs for the cluster - requires nodes to be connected to these cluster networks
# In order to connect to all necessary cluster networks, an adapter is added for each
$cluster1 = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'Clu1'; ClusterIp = '192.168.50.111,192.168.60.111' }

# Each cluster node needs to be connected to all necessary cluster networks
$node1nics = @(
    New-LabNetworkAdapterDefinition -VirtualSwitch $labname -IPv4Address 192.168.30.121
    New-LabNetworkAdapterDefinition -VirtualSwitch $labname -Ipv4Address 192.168.50.121
    New-LabNetworkAdapterDefinition -VirtualSwitch $labname -Ipv4Address 192.168.60.121
)
Add-LabMachineDefinition -name foCLN1 -Roles $cluster1 -NetworkAdapter $node1nics
$node2nics = @(
    New-LabNetworkAdapterDefinition -VirtualSwitch $labname -IPv4Address 192.168.30.122
    New-LabNetworkAdapterDefinition -VirtualSwitch $labname -Ipv4Address 192.168.50.122
    New-LabNetworkAdapterDefinition -VirtualSwitch $labname -Ipv4Address 192.168.60.122
)
Add-LabMachineDefinition -name foCLN2 -Roles $cluster1 -NetworkAdapter $node2nics
$node3nics = @(
    New-LabNetworkAdapterDefinition -VirtualSwitch $labname -IPv4Address 192.168.30.123
    New-LabNetworkAdapterDefinition -VirtualSwitch $labname -Ipv4Address 192.168.50.123
    New-LabNetworkAdapterDefinition -VirtualSwitch $labname -Ipv4Address 192.168.60.123
)
Add-LabMachineDefinition -name foCLN3 -Roles $cluster1 -NetworkAdapter $node3nics

Install-Lab

Show-LabDeploymentSummary
```
