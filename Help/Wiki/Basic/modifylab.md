Once installed, a lab can still be modified to some extent. As a general rule of thumb: Changes
that the product does not support, AutomatedLab does not support as well. For example, you cannot
change the domain that has been deployed after the installation without first removing the Domain Controller
VMs.

## Add and remove machines

An AutomatedLab is defined by several XML files we export in the background. Those can
be modified to some extent by AutomatedLab cmdlets.

To remove a VM, import the lab first, then remove it:

```powershell
Import-Lab -Name YourLab -NoValidation # NoValidation - fast import, because we don't need validation to run every time
Remove-LabVm -Name YourMachine # That is enough to remove the resource
```

To modify a deployment, either:
 
```powershell
Import-LabDefinition -Name YourLab
Add-LabMachineDefinition -Name newMachine
Remove-LabMachineDefinition -Name AnotherMachine
Install-Lab
```

or add the machine definitions in your original script - AutomatedLab detects if a role has been deployed and skips it. As long
as you do not intend to change key settings, like the domain that is getting deployed, you can simply rerun the same script after
you have added a couple of machines.

## 2 - Deploy labs that use existing lab infrastructure

Labs can be installed into existing infrastructure. While there is no general way of doing this,
a few pointers are:

- Take care of networking - usually, existing on-premises components will be reached by connecting
  the lab VMs to an external switch. This can be added using `Add-LabVirtualNetworkDefinition -HyperVProperties @{SwitchType = 'External'}
- Add references to roles like Domain Controllers using the `SkipDeployment` parameter
- Include the required credentials to connect to machines referenced using the `SkipDeployment` parameter!

Want to connect a lab using an IPSEC VPN? Maybe take a look at [this sample](../SampleScripts/Azure/en-us/VpnConnectedLab.md).

```powershell
New-LabDefinition -Name ConnectToEnv -DefaultVirtualizationEngine HyperV
Add-LabDomainDefinition -Name contoso.com -AdminUser admin -AdminPassword 'S00perS3cure!'
Add-LabVirtualNetworkDefinition -Name prodnet -AddressSpace 10.0.1.0/24 -HyperVProperties @{SwitchType = 'External'; AdapterName = '10GB'}
Add-LabMachineDefinition -Name DC1 -DomainName contoso.com -Role RootDc -SkipDeployment -IpAddress 10.0.1.101
Add-LabMachineDefinition -Name MS1 -DomainName contoso.com -Network prodnet -IpAddress 10.0.1.10
Install-Lab
```
