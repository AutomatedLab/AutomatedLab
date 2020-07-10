# AutomatedLab

Build | Status | Last Commit | Latest Release
--- | --- | --- | ---
Develop | [![Build status dev](https://ci.appveyor.com/api/projects/status/9yynk81k3k05nasp/branch/develop?svg=true)](https://ci.appveyor.com/project/automatedlab/automatedlab) | [![GitHub last commit](https://img.shields.io/github/last-commit/AutomatedLab/AutomatedLab/develop.svg)](https://github.com/AutomatedLab/AutomatedLab/tree/develop/)
Master | [![Build status](https://ci.appveyor.com/api/projects/status/9yynk81k3k05nasp/branch/master?svg=true)](https://ci.appveyor.com/project/automatedlab/automatedlab) | [![GitHub last commit](https://img.shields.io/github/last-commit/AutomatedLab/AutomatedLab/master.svg)](https://github.com/AutomatedLab/AutomatedLab/tree/master/) | [![GitHub release](https://img.shields.io/github/release/AutomatedLab/AutomatedLab.svg)](https://github.com/AutomatedLab/AutomatedLab/releases)[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/AutomatedLab.svg)](https://www.powershellgallery.com/packages/AutomatedLab/)

[![GitHub issues](https://img.shields.io/github/issues/AutomatedLab/AutomatedLab.svg)](https://github.com/AutomatedLab/AutomatedLab/issues)
[![Downloads](https://img.shields.io/github/downloads/AutomatedLab/AutomatedLab/total.svg?label=Downloads&maxAge=999)](https://github.com/AutomatedLab/AutomatedLab/releases)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/AutomatedLab.svg)](https://www.powershellgallery.com/packages/AutomatedLab/)

## Project Summary

AutomatedLab (AL) enables you to setup test and lab environments on Hyper-v or Azure with multiple products or just a single VM in a very short time. There are only two requirements you need to make sure: You need the DVD ISO images and a Hyper-V host or an Azure subscription.

### Requirements

Apart from the module itself your system needs to meet the following requirements:

- Windows Management Framework 5+ (Windows)
- .NET 4.7.1 (Windows PowerShell) or .NET Core 2.x (PowerShell 6+)
- Windows Server 2012 R2+/Windows 8.1+ (Hyper-V, Azure) or Linux (Azure)
- Recommended OS language is en-us
- Admin privileges are required
- ISO files for all operating systems and roles to be deployed
- Intel VT-x or AMD/V capable CPU
- A decent amount of RAM
- Low-Latency high-throughput storage (No spinning disks please, as there are issues related to them)

#### Windows

- Windows Management Framework 5+
- Windows Server 2012 R2+/Windows 8.1+
- Recommended OS language is en-us
- Admin privileges are required

#### Linux

- WSL supported, Azure Cloud Shell supported
- Tested on Fedora and Ubuntu, should run on any system capable of running PowerShell
- PowerShell 6+
- gss-ntlmssp to enable remoting (mandatory - no remoting, no way for AutomatedLab to do its thing)
- ip and route commands available
- Azure subscription - At the moment, AutomatedLab only works using Azure. KVM is planned for a later date.

### Download AutomatedLab

There are two options installing AutomatedLab:

- You can use the [MSI installer](https://github.com/AutomatedLab/AutomatedLab/releases) published on GitHub.
- Or you install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/AutomatedLab/) using the cmdlet Install-Module. Please refer to the wiki for some details.

### [1. Installation](https://github.com/AutomatedLab/AutomatedLab/wiki/1.-Installation)

### [2. Getting started](https://github.com/AutomatedLab/AutomatedLab/wiki/2.-Getting-Started)

### [3. Contributing](/CONTRIBUTING.md)

### [Version History](/CHANGELOG.md)

### Supported products

This solution supports setting up virtual machines with the following products

- Windows 7, 2008 R2, 8 / 8.1 and 2012 / 2012 R2, 10 / 2016, 2019
- SQL Server 2008, 2008R2, 2012, 2014, 2016, 2017
- Visual Studio 2012, 2013, 2015
- Team Foundation Services 2018, Azure DevOps Server
- Exchange 2013, 2016, 2019
- System Center Orchestrator 2012
- Microsoft Endpoint Manager Configuration Manager 1902 (and newer)
- MDT
- ProGet (Private PowerShell Gallery)
- Office 2013, 2016, 2019
- DSC Pull Server (with SQL Reporting)

### Feature List

- AutomatedLab (AL) makes the setup of labs extremely easy. Setting up a lab with just a single machine is [only 3 lines](/LabSources/SampleScripts/Introduction/01%20Single%20Win10%20Client.ps1). And even [complex labs](/LabSources/SampleScripts/HyperV/BigLab%202012R2%20EX%20SQL%20ORCH%20VS%20OFF.ps1) can be defined with about 100 lines (see [sample scripts](https://github.com/AutomatedLab/AutomatedLab/tree/master/LabSources/SampleScripts)).
- Labs on Azure can be connected to each other or connected to a Hyper-V lab [using a single command](https://github.com/AutomatedLab/AutomatedLab/wiki/Connect-on-premises-and-cloud-labs).
- AL can be used to setup scenarios to demo a [PowerShell Gallery using Inedo ProGet](/LabSources/SampleScripts/Scenarios/ProGet%20Lab%20-%20HyperV.ps1), [PowerShell DSC Pull Server scenarios](/LabSources/SampleScripts/Scenarios/DSC%20Pull%20Scenario%201%20(Pull%20Configuration).ps1), ADFS or a lab with [3 Active Directory forests trusting each other](/LabSources/SampleScripts/Scenarios/Multi-AD%20Forest%20with%20Trusts.ps1).
- Create, restore and remove snapshots of some or all lab machines with one cmdlet (Checkpoint-LabVM, Restore-LabVMSnapshot, Remove-LabVMSnapshot).
- Install Windows Features on one, some or all lab machines with one line of code (Install-LabWindowsFeature).
- Install software to a bunch of lab machines with just one cmdlet (Install-LabSoftwarePackages). You only need to know the argument to make the MSI or EXE go into silent installation mode. This can also work in parallel thanks to PowerShell workflows.
- Run any custom activity (Script or ScriptBlock) on a number of lab machines (Invoke-LabCommand). You do not have to care about credentials or double-hop authentication issues as CredSsp is always enabled and can be used with the UseCredSsp switch.
- Creating a [virtual environment that is connected to the internet](/LabSources/SampleScripts/Introduction/05%20Single%20domain-joined%20server%20(internet%20facing).ps1) was never easier. The only requirements are defining an external facing virtual switch and a machine with two network cards that acts as the router. AL takes care about all the configuration details like setting the gateway on all machines and also the DNS settings (see introduction script [05 Single domain-joined server (internet facing).ps1](/LabSources/SampleScripts/Introduction/05%20Single%20domain-joined%20server%20(internet%20facing).ps1)).
- AL offers offline patching with a single command. As all machines a based on one disk per OS, it is much more efficient to patch the ISO files that are used to create the base images (Update-LabIsoImage). See script [11 ISO Offline Patching.ps1](/LabSources/SampleScripts/Introduction/11%20ISO%20Offline%20Patching.ps1) for more details.
- If a lab is no longer required, one command is enough to remove everything to be ready to start from scratch (Remove-Lab)
