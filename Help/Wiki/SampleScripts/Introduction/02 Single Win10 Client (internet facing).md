# Introduction - 02 Single Win10 Client (internet facing)

INSERT TEXT HERE

```powershell
#It cannot be easier again. These 4 lines install a lab with just one single Windows 10 machine.
#This time AL creates an 'Default Switch' virtual switch that is connected to the interface named 'Ethernet'.
#Hence the machine is connected to the internet.

New-LabDefinition -Name Win10 -DefaultVirtualizationEngine HyperV

Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }

Add-LabMachineDefinition -Name Client1 -Memory 1GB -OperatingSystem 'Windows 10 Pro' -Network 'Default Switch'

Install-Lab

```
