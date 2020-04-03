# Join Lab VMs to an existing domain

AutomatedLab can deploy in your existing infrastructure with very little modifications necessary. At the moment, this is supported for existing domains only, but may be extended in the future.

The `Add-LabMachineDefinition` cmdlet can make use of the `SkipDeployment` parameter in order to add an existing domain controller to your lab. You could for example locate an existing DC to join to:  
```powershell
$DomainName = 'janhendrikpeters.de'
$ctx = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new('Domain', $DomainName)
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ctx)
$dc = $domain.FindDomainController([System.DirectoryServices.ActiveDirectory.LocatorOptions]::WriteableRequired).Name
$dcName = $dc.Replace(".$DomainName", '')
$dcIp = [System.Net.Dns]::GetHostAddresses($dc).IpAddressToString
```  

Now in order to add your domain controller, simply supply the host name and IP address of the system, as well as the domain join credentials:

```powershell
$DomainJoinCredential = Get-Credential
Set-LabInstallationCredential -Username ($DomainJoinCredential.UserName -split '\\')[-1] -Password $DomainJoinCredential.GetNetworkCredential().Password
# We are not using a domain admin as we skip the deployment of the DC. Nevertheless, this credential is used for domain joins.
Add-LabDomainDefinition -Name $DomainName -AdminUser ($DomainJoinCredential.UserName -split '\\')[-1] -AdminPassword $DomainJoinCredential.GetNetworkCredential().Password

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = $DomainName
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server Datacenter'
    'Add-LabMachineDefinition:Memory' = 512MB
}

Add-LabMachineDefinition -Name $dcName -Roles RootDc -SkipDeployment -IpAddress $dcIp
Add-LabMachineDefinition -Name POSHFS01
Add-LabMachineDefinition -Name POSHWEB01

Install-Lab
```

The full sample script can be found in [the SampleScripts folder](https://github.com/AutomatedLab/AutomatedLab/tree/master/LabSources/SampleScripts/Scenarios/ExistingDomainLab.ps1).

Stay tuned!
