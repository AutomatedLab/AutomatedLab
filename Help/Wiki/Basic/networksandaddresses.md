AutomatedLab can handle everything about networking and IP addresses automatically for you. But, if you prefer, you can define everything by your own. AL supported also working with multiple subnets and internet connected labs. It takes care about the routing if a machine with the role 'Routing' is defined in the network.

## Fully automated

AutomatedLab tries to make defining and deploying labs as easy as possible. Quite often you need some machines that can talk to each other but you are not interested in the IP configuration. In this case you do not have to care about networking and IP addresses at all. AL defines the virtual switch for you and also finds a free subnet for you.

If you take a look at the introduction script [[04 Single domain-joined server.ps1](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Introduction/04%20Single%20domain-joined%20server.ps1) you will not find anything that defines a network. When deploying the lab AL tells you the subnet that was chosen.

AL tries to find new subnets by simply increasing 192.168.1.0 until a free network is found. Free means that there is no virtual network switch with an IP address in the range of the subnet and the subnet is not routable. If these conditions are not met, the subnet is incremented again. 

## Simple network definition

To manually create network definitions in order to have specific network address ranges available, the cmdlet ``Add-LabVirtualNetworkDefinition`` can be used for both HyperV- and Azure-based labs.

```powershell
    # Adds a virtual network with no special options
    Add-LabVirtualNetworkDefinition -Name 'MySimpleNetwork' -AddressSpace 10.1.0.0/16  
```

Additionally, the parameters AzureProperties and HyperVProperties can be used to pass parameter hashtables. The following are valid keys that can be used as properties for AzureProperties:
* SubnetName: The name of the subnet to create in the virtual network. AL does not segment virtual networks into subnets. One virtual network per network definition will be created
* SubnetAddressPrefix: The address prefix (e.g. 24) of the subnet that will be created.
* LocationName: The Azure location name (e.g. westeurope). Bear in mind that this should not differ from your lab's default location.
* DnsServers: Comma-separated DNS servers for the network.
* ConnectToVnets: Connections to other VNETs by leveraging VNET peering. When connecting two or more lab networks through this parameter, please also specifiy this for all additional network definitions

For HyperV, the following properties are valid:
* SwitchType: Internal or External. Defaults to internal. If External is specified, AdapterName needs to be set as well
* AdapterName: The network adapter of the OS that will bridge the connection to the external network

## Simple internet connected

Reviewing the HyperV and Azure properties for ``Add-LabVirtualNetworkDefinition`` we can see that internet-connected virtual networks can easily be created.

To enable HyperV labs to have an internet connection, the following syntax can be used:  
```powershell
    Add-LabVirtualNetworkDefinition -Name 'MySimpleConnectedNetwork' -AddressSpace 10.1.0.0/16 -HyperVProperties @{SwitchType = 'External'; AdapterName = 'Ethernet'}
```

This is all it takes for machines to connect to the internet.

Azure networks by default are connected to the internet through a load balancer that initially only gives access to WinRM and RDP. Through NAT rules random external ports are mapped to the ports 5985, 5986 and 3389 on each machine. The random ports are stored for each machine, so that all connection-related cmdlets like ``Enter-LabPSSession`` or ``Connect-LabVm`` work transparently.

Additionally, Azure RDP files can be created by using ``Get-AzureRmRemoteDesktopFile``.

## Complex internet connected

here be dragons.
