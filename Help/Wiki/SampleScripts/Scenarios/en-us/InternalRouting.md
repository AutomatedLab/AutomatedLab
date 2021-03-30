# Scenarios - InternalRouting

This sample creates a lab with multiple networks which are connected
using Routing role VMs and their shared network "RoutingPlane".

Clients on each network can communicate with each other.

This also enables advanced scenarios that call Install-Lab -Routing
before deploying the Domains in order to test multiple segmented AD
sites and more.

```powershell
New-LabDefinition -Name Connected -DefaultVirtualizationEngine HyperV

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter'
    'Add-LabMachineDefinition:Memory' = 4gb
}

Add-LabVirtualNetworkDefinition -Name RoutingPlane -AddressSpace 192.168.112.0/24
Add-LabVirtualNetworkDefinition -Name Site1 -AddressSpace 192.168.113.0/24
Add-LabVirtualNetworkDefinition -Name Site2 -AddressSpace 192.168.114.0/24
Add-LabVirtualNetworkDefinition -Name Site3 -AddressSpace 192.168.115.0/24

$r1adap = @(
    New-LabNetworkAdapterDefinition -InterfaceName Routing -VirtualSwitch RoutingPlane -Ipv4Address 192.168.112.10
    New-LabNetworkAdapterDefinition -InterfaceName Site1 -VirtualSwitch Site1 -Ipv4Address 192.168.113.10
    New-LabNetworkAdapterDefinition -InterfaceName Site3 -VirtualSwitch Site3 -Ipv4Address 192.168.115.10
)
Add-LabMachineDefinition -Name R1 -Roles Routing -NetworkAdapter $r1adap

$r2adap = @(
    New-LabNetworkAdapterDefinition -InterfaceName Routing -VirtualSwitch RoutingPlane -Ipv4Address 192.168.112.11
    New-LabNetworkAdapterDefinition -InterfaceName Site2 -VirtualSwitch Site2 -Ipv4Address 192.168.114.10
)
Add-LabMachineDefinition -Name R2 -Roles Routing -NetworkAdapter $r2adap

Add-LabMachineDefinition -Name C1 -Network Site1 -Gateway 192.168.113.10 -IpAddress 192.168.113.50
Add-LabMachineDefinition -Name C2 -Network Site2 -Gateway 192.168.114.10 -IpAddress 192.168.114.50

Install-Lab

Enable-LabInternalRouting -RoutingNetworkName RoutingPlane -Verbose

Invoke-LabCommand C1 -ScriptBlock { 
    Test-Connection -Count 1 -ComputerName 192.168.115.10, 192.168.113.10, 192.168.114.10, 192.168.113.50, 192.168.114.50
} -PassThru

Show-LabDeploymentSummary
```