[![Krihelimeter](http://krihelinator.xyz/badge/AutomatedLab/AutomatedLab)](http://krihelinator.xyz/repositories/AutomatedLab/AutomatedLab)
## Project Summary
AutomatedLab (AL) enables you to setup test and lab environments on Hyper-v or Azure with multiple products or just a single VM in a very short time. There are only two requirements you need to make sure: You need the DVD ISO images and a Hyper-V host or Azure subscription machine.

### Download AutomatedLab (lateset version 4.1.0 released on May 4 2017)
You can find an [MSI installer](https://github.com/AutomatedLab/AutomatedLab/releases) right here in GitHub if you do not want to compile your own version of AutomatedLab.

### [1. Installation](https://github.com/AutomatedLab/AutomatedLab/wiki/1.-Installation)
### [2. Getting started](https://github.com/AutomatedLab/AutomatedLab/wiki/2.-Getting-Started)
### [3. Contributing](https://github.com/AutomatedLab/AutomatedLab/blob/master/CONTRIBUTING.md)
### [Version History](https://github.com/AutomatedLab/AutomatedLab/wiki/Version-History)

### Supported products
This solution supports setting up virtual machines with the following products
* Windows 7, 2008 R2, 8 / 8.1 and 2012 / 2012 R2, 10 / 2016
* SQL Server 2008, 2008R2, 2012, 2014, 2016
* Visual Studio 2012, 2013, 2015
* Exchange 2013, Exchange 2016
* System Center Orchestrator 2012
* Office 2013, 2016

### Feature List
* AutomatedLab (AL) makes the setup of labs extremely easy. Setting up a lab with just a single machine is [only 3 lines](https://github.com/AutomatedLab/AutomatedLab/blob/master/SampleScripts/Introduction/01%20Single%20Win10%20Client.ps1). And even [complex labs](https://github.com/AutomatedLab/AutomatedLab/blob/master/SampleScripts/HyperV/BigLab%202012R2%20EX%20SQL%20ORCH%20VS%20OFF.ps1) can be defined with about 100 lines (see [sample scripts](https://github.com/AutomatedLab/AutomatedLab/tree/master/SampleScripts)).
* AL can be used to setup scenarios to demo a [PowerShell Gallery using Inedo ProGet](https://github.com/AutomatedLab/AutomatedLab/blob/master/SampleScripts/Scenarios/ProGet%20Lab%20-%20HyperV.ps1), [PowerShell DSC Pull Server scenarios](https://github.com/AutomatedLab/AutomatedLab/blob/master/SampleScripts/Scenarios/DSC%20Pull%20Scenario%201%20(Pull%20Configuration).ps1), ADFS or a lab with [3 Active Directory forests trusting each other](https://github.com/AutomatedLab/AutomatedLab/blob/master/SampleScripts/Scenarios/Multi-AD%20Forest%20with%20Trusts.ps1).
* Create, restore and remove snapshots of some or all lab machines with one cmdlet (Checkpoint-LabVM, Restore-LabVMSnapshot, Remove-LabVMSnapshot).
* Install Windows Features on one, some or all lab machines with one line of code (Install-LabWindowsFeature).
* Install software to a bunch of lab machines with just one cmdlet (Install-LabSoftwarePackages). You only need to know the argument to make the MSI or EXE go into silent installation mode. This can also work in parallel thanks to PowerShell workflows.
* Run any custom activity (Script or ScriptBlock) on a number of lab machines (Invoke-LabCommand). You do not have to care about credentials or double-hop authentication issues as CredSsp is always enabled and can be used with the UseCredSsp switch.
* Creating a [virtual environment that is connected to the internet](https://github.com/AutomatedLab/AutomatedLab/blob/master/SampleScripts/Introduction/05%20Single%20domain-joined%20server%20(internet%20facing).ps1) was never easier. The only requirements are defining an external facing virtual switch and a machine with two network cards that acts as the router. AL takes care about all the configuration details like setting the getaway on all machines and also the DNS settings (see introduction script [05 Single domain-joined server (internet facing).ps1](https://github.com/AutomatedLab/AutomatedLab/blob/master/SampleScripts/Introduction/05%20Single%20domain-joined%20server%20(internet%20facing).ps1)).
* AL offers offline patching with a single command. As all machines a based on one disk per OS, it is much more efficient to patch the ISO files that are used to create the base images (Update-LabIsoImage). See script [11 ISO Offline Patching.ps1](https://github.com/AutomatedLab/AutomatedLab/blob/master/SampleScripts/Introduction/11%20ISO%20Offline%20Patching.ps1) for more details.
* If a lab is no longer required, one command is enough to remove everything to be ready to start from scratch (Remove-Lab)
