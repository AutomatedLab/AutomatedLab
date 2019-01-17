#It couldn't be easier. These 3 lines install a lab with just a single Windows 10 machine.
#AL takes care of configuring network settings like creating a virtual switch and finding a suitable IP range.

New-LabDefinition -Name Win10 -DefaultVirtualizationEngine HyperV
Add-LabMachineDefinition -Name Client1 -Memory 1GB -OperatingSystem 'Windows 10 Pro'
Install-Lab
