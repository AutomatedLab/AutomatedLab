# Introduction - 05 Single domain-joined server (internet facing)

INSERT TEXT HERE

```powershell
#This intro script is pretty almost the same like the previous one. But this lab is connected to the internet over the external virtual switch.
#The IP addresses are assigned automatically like in the previous samples but AL also assignes the gateway and the DNS servers to all machines
#that are part of the lab. AL does that if it finds a machine with the role 'Routing' in the lab.

New-LabDefinition -Name Lab0 -DefaultVirtualizationEngine HyperV

Add-LabVirtualNetworkDefinition -Name Lab0
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }

Add-LabMachineDefinition -Name DC1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles RootDC -Network Lab0 -DomainName contoso.com

$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch Lab0
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name Router1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles Routing -NetworkAdapter $netAdapter -DomainName contoso.com

Add-LabMachineDefinition -Name Client1 -Memory 1GB -Network Lab0 -OperatingSystem 'Windows 10 Pro' -DomainName contoso.com

Install-Lab

Show-LabDeploymentSummary -Detailed

```
