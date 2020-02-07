#The is almost the same like '05 SQL Server and client, domain joined.ps1' but installs an Exchange 2016 server instead
#of a SQL Server.
#
# IMPORTANT NOTE: Make sure you have installed at least the CU KB3206632 before installing Exchange 2016, this is a requirement.
# Refer to the introduction script '11 ISO Offline Patching.ps1' for creating a new ISO that contains patches or install
# it it with Install-LabSoftwarePackage like below.

New-LabDefinition -Name LabEx2016 -DefaultVirtualizationEngine HyperV

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
}

Add-LabMachineDefinition -Name Lab2016DC1 -Roles RootDC -Memory 1GB

$role = Get-LabPostInstallationActivity -CustomRole Exchange2016 -Properties @{ OrganizationName = 'Test1' }
Add-LabMachineDefinition -Name Lab2016EX1 -Memory 6GB -PostInstallationActivity $role

Add-LabMachineDefinition -Name Lab2016Client1 -OperatingSystem 'Windows 10 Pro' -Memory 2GB

#Exchange 2016 required at least kb3206632. Hence before installing Exchange 2016, the update is applied
#Alternativly, you can create an updated ISO as described in the introduction script '11 ISO Offline Patching.ps1' or download an updates image that
#has the fix already included.
Install-Lab -NetworkSwitches -BaseImages -VMs -Domains -StartRemainingMachines

Install-LabSoftwarePackage -Path $labSources\OSUpdates\2016\windows10.0-kb3206632-x64_b2e20b7e1aa65288007de21e88cd21c3ffb05110.msu -ComputerName Lab2016EX1 -Timeout 60

Restart-LabVM -ComputerName Lab2016EX1 -Wait

Install-Lab -PostInstallations

Show-LabDeploymentSummary -Detailed
