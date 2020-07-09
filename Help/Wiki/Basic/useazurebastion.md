# Using Azure Bastion Hosts

Azure Bastion Hosts are in preview as of 2020-05-19 and allow you to connect to your lab machines
via the Remote Desktop Web Client from an Azure Bastion. Starting with release 5.21 AutomatedLab
supports these as well.

When opting to deploy a bastion, note that this will increase the time your lab deployment takes.
This is due to:
  - The resource provider feature AllowBastionHost takes time to activate, if it is not registered.
    (***This step can take up to 20 minutes!***)
  - The resource group deployment eventually takes up to five minutes longer

## Usage

The easiest way to add a Bastion to your lab is by using the new AllowBastionHost parameter:  

```powershell
New-LabDefinition -Name Bastion1 -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -SubscriptionName JHPaaS -DefaultLocationName 'West Europe' -AllowBastionHost

Add-LabMachineDefinition -Name DC1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles RootDC -DomainName contoso.com

Install-Lab

Show-LabDeploymentSummary -Detailed
```  

Specifying this parameter will mean that your virtual network is extended to accomodate the bastion
host subnet. Additionally, the lab network security group will receive additional rules.

## More control with custom subnets

If you do not want to extend the virtual network you defined in your lab, you can simply add a
bastion subnet called AzureBastionSubnet - AutomatedLab will take care of the rest.

```powershell
New-LabDefinition -Name Bastion2 -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -SubscriptionName JHPaaS -AllowBastionHost -DefaultLocationName 'West Europe'

Add-LabVirtualNetworkDefinition -Name Lab2Vnet -AddressSpace 192.168.10.0/23 -AzureProperties @{ Subnets = @{
    'default' = '192.168.10.0/24'
    'AzureBastionSubnet' = '192.168.11.0/24'
}}
Add-LabMachineDefinition -Name DC1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles RootDC -DomainName contoso.com -Network Bastion2Vnet -IpAddress 192.168.10.11

Install-Lab

Show-LabDeploymentSummary -Detailed
```

## Connecting via the Bastion

At the moment, you need to use the [Azure portal](https://portal.azure.com) to connect to your bastion host. In the future, we might be able to use Connect-LabVm instead.
