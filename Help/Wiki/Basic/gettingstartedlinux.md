# Getting started on Linux

As the creators of AutomatedLab did not have Linux in mind from the beginning, Linux as the host system is still slightly behind on capabilites.
Nevertheless, you very much can use Linux to deploy labs, provided you have access to an Azure subscription and are allowed to
create resource groups. One will contain a storage account that is reused and contains your otherwise local lab sources.

If you are not allowed to create resource groups, you need to have one resource group per lab that is being deployed with you being the resource
group's contributor. The name of the resource group is to be the name of the lab.

## Install and configure AutomatedLab

Installation on Linux is recommended using the PowerShell Gallery.

```powershell
Install-Module AutomatedLab
```

If you did not run PowerShell as root (`su pwsh`), please customize and run the following command to set up the required folder structure:
```powershell
mkdir $home/automatedlab
Set-PSFConfig -FullName AutomatedLab.LabAppDataRoot -Value $home/automatedlab -PassThru | Register-PSFConfig
```

At the time of writing, only Azure-based labs are available on Linux. In order to use AutomatedLab, the following commands should be run after installing AutomatedLab.

```powershell
Install-LabAzureRequiredModule
Connect-AzAccount -UseDeviceAuthentication
```

Optionally, you can scaffold the lab sources directory containing sample scripts and other content. Some roles as well as custom roles require
content from this directory anyways.

```powershell
mkdir $home/labsources
Set-PSFConfig -FullName AutomatedLab.LabSourcesLocation -Value $home/labsources -PassThru | Register-PSFConfig
New-LabSourcesFolder -Force
```


## Install the first lab

To install a very basic lab with one VM, run the following commands in PowerShell

***
``` powershell
New-LabDefinition -Name GettingStarted -DefaultVirtualizationEngine Azure

Add-LabMachineDefinition -Name FirstServer -OperatingSystem 'Windows Server 2019 Datacenter'

Install-Lab

Show-LabDeploymentSummary
```
***

> **Warning**
> AutomatedLab can only work if remoting is configured properly. This seems to be highly difficult on Linux.
> Should you have issues with remoting, please first of all try to `Install-Module PSWSMAN; Install-WSMAN`
> If this does not work for you, you can specify public and private key to connect. This will however
> not work in all scenarios: A double hop is required for many roles like SQL, Azure DevOps or Certificate Authorities.

## Install lab using SSH remoting

To install the same basic lab with SSH remoting, run the following commands in PowerShell, using your own
private and public keys.

``` powershell
New-LabDefinition -Name GettingStarted -DefaultVirtualizationEngine Azure

Add-LabMachineDefinition -Name FirstServer -OperatingSystem 'Windows Server 2019 Datacenter' -SshPublicKeyPath $home/.ssh/MyPubKey.pub -SshPrivateKeyPath $home/.ssh/MyPrivKey

Install-Lab

Show-LabDeploymentSummary
```

All connections will use your key pair instead of a password. That however means that no second hop will be possible. The combination
of `-K` and `-i` does not work together, as stated here: <https://www.man7.org/linux/man-pages/man1/ssh.1.html#AUTHENTICATION>

## Next steps

Now that you have deployed your first lab, what comes next? Would you like to connect to the machines and run remote commands without you knowing the password? Then start with [the docs on lab management](./invokelabcommand.md).

Wondering how to transfer data to your new lab? Then start with [the docs on data exchange](./exchangedata.md).

If you - like us - like to tinker around with things, check out the [possible settings](../Advanced/automatedlabconfig.md).
