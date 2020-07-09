AutomatedLab can do more than just create an on-premises or a cloud lab - you can also connect your labs through an IPSEC VPN.
## Prerequisites  
- Two labs. At least one lab needs to be an Azure-based lab. The second lab can be on-premises or on Azure
- OR: One lab and one IPSEC VPN Gateway using a pre-shared key, e.g. to accommodate your environment at another cloud provider
- If using an on-premises lab: A machine with the Routing role (```Get-LabVm -Role Routing```)
- Non-overlapping address spaces for each lab and (at the moment) different domains for each lab
- 10-30 minutes of time to wait for the connection to be made

## How does it work  
Connecting the labs is very simple. There are three cmdlets related to lab connections:  
```powershell
Connect-Lab
Restore-LabConnection
Disconnect-Lab
```  
### Connect-Lab
The first cmdlet allows you to actually connect two labs together. You simply need the lab names for this to work.  
```powershell
Get-Lab -List
Connect-Lab -SourceLab OnPremTest -DestinationLab AzureTest -Verbose
```  
Assuming your labs are OnPremTest and AzureTest Connect-Lab will now attempt to do the following:
- Extend your Azure address spaces to accommodate gateway subnets
- Create Virtual Network Gateways and Local Network Gateways, Gateway Connections and the necessary public IP address
- Configure your on-premises routing VM with a site-to-site interface that connects to the Local Network Gateway on Azure using a pre-shared key
- Configure a static route to your destination address spaces
- Configure a DNS conditional forwarder for your remote lab domain  
All this can take between 10 and 15 minutes, depending on how long it takes to create the Gateway resources on Azure.  

Connecting two Azure-based labs works similarly with the only difference being that you do not need a routing machine. Instead, the appropriate network gateways will be created in both resource groups, allowing you to automatically configure a VPN connection across subscription and region boundaries.  

In order to connect your on-premises lab to any IPSEC VPN gateway with a pre-shared key, use the second parameter set:  
```powershell
Connect-Lab -SourceLab OnPremises -DestinationIpAddress 1.2.3.4 -PreSharedKey "SomePsk!" -AddressSpace "10.10.0.0/16","192.168.27.0/24"
```  
The destination IP needs to be either a static public IP or a resolvable hostname of your remote VPN gateway. The pre-shared key needs to match you gateway's key. For any address spaces that should be routed through your VPN connection originating in your lab, just specify them comma-separated.  
### Restore-LabConnection
If your own public IP address changes or you experience connectivity issues within your lab environment, chances are that either the public IP of your Azure gateway or of your on-premises lab have changed. Using the cmdlet Restore-LabConnection, we take measures to correct these basic issues:  
```powershell
Restore-LabConnection -SourceLab OnPremisesLab -DestinationLab AzureLab
```  
Restore-LabConnection will reconfigure any IP addresses that might have changed in order to restore the connection.  
### Disconnect-Lab  
If you want to disconnect your lab and discard the resources that have been created, just call the cmdlet Disconnect-Lab. This will undo all steps that were previously taken in Connect-Lab.
