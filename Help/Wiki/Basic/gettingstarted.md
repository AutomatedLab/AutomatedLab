# Getting started

## Placing ISO files
Of course AutomatedLab (AL) cannot install an operating system without actually having the bits. Hence you need to download an ISO file from MSDN, TechNet Evaluation Center or somewhere else. These files need to go to your folder "ISOs" located in the "LabSoures" folder.

The "ISOs" folder contains only one file after the installation of AL: "_Put all ISO images in here.txt". I have downloaded Windows Server 2016 from the TechNet Evaluation Center and put the file like shown below.

![ISOs](https://cloud.githubusercontent.com/assets/11280760/19439031/e13ab3a0-947c-11e6-9148-39f25078629a.png)

## Testing the ISO files
To make sure that AL can read the file, try to get a list of available operating systems. Open an **elevated** PowerShell ISE and call the following command (make sure you point to the right location for the LabSources folder:

``` powershell
Get-LabAvailableOperatingSystem -Path E:\LabSources
```

This returns a list of all operating system images found on the ISO file (of course this works also if there are a bunch of different OS ISOS in the folder).

![OSList](https://cloud.githubusercontent.com/assets/11280760/19439375/227bebee-947e-11e6-97fc-b402e91c91a3.png)

## Install the first lab
Please open an **elevated** PowerShell ISE and create a new empty document (CTRL+N) if not already open.

Copy and paste the following lines into the ISE:

***
``` powershell
New-LabDefinition -Name GettingStarted -DefaultVirtualizationEngine HyperV

Add-LabMachineDefinition -Name FirstServer -OperatingSystem 'Windows Server 2016 SERVERSTANDARD'

Install-Lab

Show-LabDeploymentSummary
```
***

The just press the run button or hit F5 to start the deployment.

This is what is going to happen. Many things happen automatically but can be customized:
* AutomatedLab starts a new lab named "GettingStarted". The lab defininition will be stored in C:\ProgramData\AutomatedLab\Labs\GettingStarted. The location can be [customized](automatedlabconfig.md) with the setting LabAppDataRoot.
* AL will update download the SysInternals tools and put them into the LabSources folder.
* AL looks for an ISO file that contains the specified OS. If the ISO file cannot be found, the deployment stops.
* AL adds the one and only machine to the lab and recognizes that no network was defined. In this case, AL creates a virtual switch automatically and uses an free IP range.
* The AL measures the disk speed and chooses the fastet drive for the lab, as no location is defined in the call to "New-LabDefinition". In my case, it chooses D. Measuring is done only once and the result is cached.
* Then the actual deployment starts. AL creates  
    1. The virtual switch
    2. Then it creates the a base image for the operating system that is shared among all machines with the same OS.
    3. Afterwards the VM is created and started
    4. AL waits for the machine to become ready and shows the overall installation time.

## Removing a Lab
If you want to get rid of the lab, just call Remove-Lab. The cmdlet removes the VMs including the disks and the virtual switches, and leaves the base disks for the next deployment.

If you have closed the ISE in the meantime, either specify the lab name or import it first.

![Remove1](https://cloud.githubusercontent.com/assets/11280760/19446945/93a01a26-949b-11e6-9aeb-1fb2933033dd.png)

## Summary
With AutomatedLab it is extremely easy to create various kinds of labs. The more you define your lab by code, the easier it is to re-deploy it and the less time you invest in the long term.

If you like what you have seen, take a look at the folder ["LabSources\Sample Scripts\Introduction"](https://github.com/AutomatedLab/AutomatedLab/tree/master/LabSources/SampleScripts/Introduction). These scripts demo how to create domains, internet facing labs, PKI, etc.

Please provide feedback if something does not work as expected. If you are missing a feature or have some great ideas, please open an [issue](https://github.com/AutomatedLab/AutomatedLab/issues).

## Next steps

Now that you have deployed your first lab, what comes next? Would you like to connect to the machines and run remote commands without you knowing the password? Then start with [the docs on lab management](invokelabcommand.md).

Wondering how to transfer data to your new lab? Then start with [the docs on data exchange](exchangedata.md).

If you - like us - like to tinker around with things, check out the [possible settings](automatedlabconfig.md).