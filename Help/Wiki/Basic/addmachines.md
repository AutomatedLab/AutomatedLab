Adding machines to a lab ranges from extremely easy to fairly complicated. Both is achieved with one cmdlet though, Add-LabMachineDefinition.

```powershell
# Add the root domain controller for the domain contoso.com
# Network, memory, ... will all be handled automatically
Add-LabMachineDefinition -Name DC1 -Roles RootDC -OperatingSystem 'Windows Server 2019 Datacenter' -Domain contoso.com
```

When you are using the automatic machine definitions, the memory requirements will be calculated based on the machines' roles.

## Deploying a lab with Linux VMs
With AutomatedLab Linux VMs can be deployed just as easily as Windows VMs. The current implementation should take care of the following distributions:
- RHEL 7 (*)
- CentOS 7
- Fedora 27
- SLES 12.3 (*)
- OpenSuSE

At the moment the machines do not support any of AutomatedLab's roles since our roles are Windows-based. However, your VMs should come up domain-joined and capable of receiving WinRM requests. AutomatedLab uses kickstart (RHEL-based) or AutoYAST (SLES-based) to configure everything that would be configured in the unattend file of a Windows machine.

WinRM support is spotty with distributions like OpenSuSE and Fedora. Fedora being too cutting-edge does not allow PowerShell and omi-psrp-server to be installed, while OpenSuSE currently has the wrong package dependencies and fails installing PowerShell as well.

## Simple Linux lab
You can find the Linux lab here: [AL Loves Linux](https://github.com/AutomatedLab/AutomatedLab/blob/develop/LabSources/SampleScripts/HyperV/AL%20Loves%20Linux.ps1)
As you can see, integrating Linux clients is very simple in general:  
```powershell
Add-LabMachineDefinition -Name LINCN2 -OperatingSystem 'CentOS 7.4'
```  
If you want to add additional package groups to be installed during setup, you can do so by specifying them:  
```powershell
Add-LabMachineDefinition -RhelPackage domain-client -Name LINCN1 -OperatingSystem 'CentOS 7.4' -DomainName contoso.com
```  
You can find all available packages with ```Get-LabAvailableOperatingSystem | Select-Object -Expand LinuxPackageGroup```. However, the basics should be fine for most cases.  
At them moment, your Linux-based labs need an internet connection (i.e. a routing VM) so that the PowerShell and omi-psrp-server can be downloaded during setup. Without omid running on the Linux machines, your lab will run into a timeout during installation. While this will not break things, it will certainly cause a long wait.

## Azure-specific properties

There are several properties that can be used with the `AzureProperties` parameter of the `Add-LabMachineDefinition` cmdlet.

- ResourceGroupName - Resource group this machine is deployed into, if it should be different
- UseAllRoleSizes - Use a random role size of the available role sizes
- RoleSize - Use specific role size like Standard_D2_v2
- LoadBalancerRdpPort - Use a different port for the inbound NAT rule. Needs to be unique in your lab!
- LoadBalancerWinRmHttpPort - Use a different port for the inbound NAT rule. Needs to be unique in your lab!
- LoadBalancerWinRmHttpsPort - Use a different port for the inbound NAT rule. Needs to be unique in your lab!
- LoadBalancerAllowedIp - A comma-separated string (NOT an array) containing IP addresses allowed to connect, e.g. "$(Get-PublicIpAddress), 1.2.3.4"
- SubnetName - The subnet name this machine is deployed into
- UseByolImage - Boolean as string indicating that BYOL licensing is used
- AutoshutdownTime - The timespan as string when the machines shut be shut down
- AutoshutdownTimezoneId - The time zone ID as string for the auto shutdown time
- StorageSku - The storage SKU for additional disks. OS disks are managed disks. Either 'Standard_LRS', 'Premium_LRS' or 'StandardSSD_LRS'