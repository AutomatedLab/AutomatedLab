# Introduction - 04 Single domain-joined server

INSERT TEXT HERE

```powershell
#Here AL installs a lab with one domain controller and one client. The OS can be configured quite easily as well as
#the domain name or memory. AL takes care about network settings like in the previous samples.

New-LabDefinition -Name Lab1 -DefaultVirtualizationEngine HyperV

Add-LabMachineDefinition -Name DC1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles RootDC -DomainName contoso.com
Add-LabMachineDefinition -Name Client1 -Memory 1GB -OperatingSystem 'Windows 10 Pro' -DomainName contoso.com

Install-Lab

Show-LabDeploymentSummary -Detailed

```
