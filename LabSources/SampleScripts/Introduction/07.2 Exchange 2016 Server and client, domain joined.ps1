#The is almost the same like '05 SQL Server and client, domain joined.ps1' but installs an Exchange 2013 server instead
#of a SQL Server.
#
# IMPORTANT NOTE: Make sure you have installed at least the CU KB3206632 before installing Exchange 2016, this is a requirement.
# Refer to the introduction script '11 ISO Offline Patching.ps1' for creating a new ISO that contains patches or install
# it it with Install-LabSoftwarePackage like below.
#
# You can download the Exchange 2016 ISO from https://www.microsoft.com/en-us/download/details.aspx?id=55953

New-LabDefinition -Name 'LabEx1' -DefaultVirtualizationEngine HyperV

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 SERVERDATACENTER'
}

Add-LabIsoImageDefinition -Name Exchange2016 -Path $labSources\ISOs\ExchangeServer2016-x64-cu7.iso

Add-LabMachineDefinition -Name Lab1DC1 -Roles RootDC -Memory 1GB
Add-LabMachineDefinition -Name Lab1EX1 -Roles Exchange2016 -Memory 4GB
Add-LabMachineDefinition -Name Lab1Client1 -OperatingSystem 'Windows 10 Pro' -Memory 1GB

#Exchange 2016 required at least kb3206632. Hence before installing Exchange 2016, the update is applied
#Alternativly, you can create an updated ISO as described in the introduction script '11 ISO Offline Patching.ps1'.
Install-Lab -NetworkSwitches -BaseImages -VMs -Domains -StartRemainingMachines

Install-LabSoftwarePackage -Path $labSources\OSUpdates\2016\windows10.0-kb3206632-x64_b2e20b7e1aa65288007de21e88cd21c3ffb05110.msu -ComputerName (Get-LabVM -Role Exchange2016) -Timeout 60

Invoke-LabCommand -ComputerName (Get-LabVM -Role Exchange2016) -ScriptBlock {restart-computer -force}

Install-Lab -Exchange2016

Show-LabDeploymentSummary -Detailed
