# Renaming used resources

AutomatedLab offers the ability to select different resource names for your lab machines as well as virtual switches.
While this feature is mainly intended for on-premises hypervisors like Hyper-V, Azure-based labs can also make
use of the new resource naming.

This feature is very useful for classroom deployments if students are using a shared hypervisor, as the same lab
can be deployed multiple times.

Both `Add-LabVirtualNetworkDefinition` as well as `Add-LabMachineDefinition` can use the `ResourceName` parameter.

***Important: This feature does not overcome the boundaries of networking on Hyper-V. Remember to use non-overlapping address
spaces for each lab network, as shown in the example.  
For various reasons, AutomatedLab uses Internal virtual switches on Hyper-V.***

## Example

```powershell
foreach ($studentNumber in (1..10))
{
    New-LabDefinition -Name "$($studentNumber)POSH" -DefaultVirtualizationEngine HyperV
    Add-LabVirtualNetworkDefinition -Name VMNet -ResourceName "$($studentNumber)VMNet" -AddressSpace "192.168.$($studentNumber).0/24"
    Add-LabMachineDefinition -Name DC01 -ResourceName "$($studentNumber)DC01" -Roles RootDC -Domain contoso.com -OperatingSystem 'Windows Server 2016 Datacenter'
    Install-Lab
}
```

In the sample, the resources deployed on Hyper-V will be prefixed with Studentxx, while each student uses
the VM host name to interact with the machine. Specifying a resource name for the virtual network adapter
in this case would not be necessary, as the default adapter name is equal to the lab name.
