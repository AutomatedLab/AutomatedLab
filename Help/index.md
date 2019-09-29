# AutomatedLab

![Image](AutomatedLab-GIF250-whitebg-lossy25.gif)

AutomatedLab (AL) enables you to setup test and lab environments on Hyper-v or Azure with multiple products or just a single VM in a very short time. There are only two requirements you need to make sure: You need the DVD ISO images and a Hyper-V host or an Azure subscription.

Build | Status | Last Commit | Latest Release
--- | --- | --- | ---
Develop | [![Build status dev](https://ci.appveyor.com/api/projects/status/9yynk81k3k05nasp/branch/develop?svg=true)](https://ci.appveyor.com/project/automatedlab/automatedlab) | [![GitHub last commit](https://img.shields.io/github/last-commit/AutomatedLab/AutomatedLab/develop.svg)](https://github.com/AutomatedLab/AutomatedLab/tree/develop/)
Master | [![Build status](https://ci.appveyor.com/api/projects/status/9yynk81k3k05nasp/branch/master?svg=true)](https://ci.appveyor.com/project/automatedlab/automatedlab) | [![GitHub last commit](https://img.shields.io/github/last-commit/AutomatedLab/AutomatedLab/master.svg)](https://github.com/AutomatedLab/AutomatedLab/tree/master/) | [![GitHub release](https://img.shields.io/github/release/AutomatedLab/AutomatedLab.svg)](https://github.com/AutomatedLab/AutomatedLab/releases)[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/AutomatedLab.svg)](https://www.powershellgallery.com/packages/AutomatedLab/)

[![GitHub issues](https://img.shields.io/github/issues/AutomatedLab/AutomatedLab.svg)](https://github.com/AutomatedLab/AutomatedLab/issues)
[![Downloads](https://img.shields.io/github/downloads/AutomatedLab/AutomatedLab/total.svg?label=Downloads&maxAge=999)](https://github.com/AutomatedLab/AutomatedLab/releases)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/AutomatedLab.svg)](https://www.powershellgallery.com/packages/AutomatedLab/)

## Requirements

Apart from the module itself your system needs to meet the following requirements:

- Windows Management Framework 5+
- Windows Server 2012 R2+/Windows 8.1+
- Recommended OS language is en-us
- Admin privileges are required
- ISO files for all operating systems and roles to be deployed
- Intel VT-x or AMD/V capable CPU
- A decent amount of RAM
- An SSD for your machines is highly recommended as many issues arise from slow HDDs

## Supported products

This solution supports setting up virtual machines with the following products

- Windows 7, 2008 R2, 8 / 8.1 and 2012 / 2012 R2, 10 / 2016, 2019
- SQL Server 2008, 2008R2, 2012, 2014, 2016, 2017
- Visual Studio 2012, 2013, 2015
- Team Foundation Services 2018, Azure DevOps
- Exchange 2013, Exchange 2016
- System Center Orchestrator 2012
- System Center Configuration Manager 1809
- MDT
- ProGet (Private PowerShell Gallery)
- Office 2013, 2016
- DSC Pull Server (with SQL Reporting)

## Feature List

- AutomatedLab (AL) makes the setup of labs extremely easy. Setting up a lab with just a single machine is [only 3 lines](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Introduction/01%20Single%20Win10%20Client.ps1). And even [complex labs](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/HyperV/BigLab%202012R2%20EX%20SQL%20ORCH%20VS%20OFF.ps1) can be defined with about 100 lines (see [sample scripts](https://github.com/AutomatedLab/AutomatedLab/tree/master/LabSources/SampleScripts)).
- Labs on Azure can be connected to each other or connected to a Hyper-V lab [using a single command](/Wiki/connectlabs.md).
- AL can be used to setup scenarios to demo a [PowerShell Gallery using Inedo ProGet](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Scenarios/ProGet%20Lab%20-%20HyperV.ps1), [PowerShell DSC Pull Server scenarios](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Scenarios/DSC%20Pull%20Scenario%201%20(Pull%20Configuration).ps1), ADFS or a lab with [3 Active Directory forests trusting each other](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Scenarios/Multi-AD%20Forest%20with%20Trusts.ps1).
- Create, restore and remove snapshots of some or all lab machines with one cmdlet (Checkpoint-LabVM, Restore-LabVMSnapshot, Remove-LabVMSnapshot).
- Install Windows Features on one, some or all lab machines with one line of code (Install-LabWindowsFeature).
- Install software to a bunch of lab machines with just one cmdlet (Install-LabSoftwarePackages). You only need to know the argument to make the MSI or EXE go into silent installation mode. This can also work in parallel thanks to PowerShell workflows.
- Run any custom activity (Script or ScriptBlock) on a number of lab machines (Invoke-LabCommand). You do not have to care about credentials or double-hop authentication issues as CredSsp is always enabled and can be used with the UseCredSsp switch.
- Creating a [virtual environment that is connected to the internet](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Introduction/05%20Single%20domain-joined%20server%20(internet%20facing).ps1) was never easier. The only requirements are defining an external facing virtual switch and a machine with two network cards that acts as the router. AL takes care about all the configuration details like setting the getaway on all machines and also the DNS settings (see introduction script [05 Single domain-joined server (internet facing).ps1](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Introduction/05%20Single%20domain-joined%20server%20(internet%20facing).ps1)).
- AL offers offline patching with a single command. As all machines a based on one disk per OS, it is much more efficient to patch the ISO files that are used to create the base images (Update-LabIsoImage). See script [11 ISO Offline Patching.ps1](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Introduction/11%20ISO%20Offline%20Patching.ps1) for more details.
- If a lab is no longer required, one command is enough to remove everything to be ready to start from scratch (Remove-Lab)

## Telemetry

Starting with AutomatedLab version 5 we are collecting telemetry. To see what you guys deliver, we are sharing the resulting Power BI report with you. The [full report] can be viewed at your leisure.

We are collecting the following with Azure Application Insights:
- Your country and city (IP addresses are by default set to 0.0.0.0 after the location is extracted)
- Your number of lab machines
- The roles you used
- The time it took your lab to finish
- Your AutomatedLab version, OS Version and the lab's Hypervisor type
- The lifetime of your lab once you remove it

We collect no personally identifiable information, ever.

If you change your mind later on, you can always set the environment
variable AUTOMATEDLAB_TELEMETRY_OPTIN to no, false or 0 in order to opt out or to yes,true or 1 to opt in.
Alternatively you can use Enable-LabTelemetry and Disable-LabTelemetry to accomplish the same.

We will not ask you again while $env:AUTOMATEDLAB_TELEMETRY_OPTIN exists.

Take a look at the following samples to see what is transmitted. These are actual events. Notice that the IP address defaults
to 0.0.0.0, and we overwrite any PII with 'nope'.

### LabStarted event - transmitted data sample  

```json
{
    "event":  [
                  {
                      "name":  "LabStarted",
                      "count":  1
                  }
              ],
    "internal":  {
                     "data":  {
                                  "id":  "abe26991-dd13-11e9-b08a-8102ecc783ba",
                                  "documentVersion":  "1.61"
                              }
                 },
    "context":  {
                    "data":  {
                                 "eventTime":  "2019-09-22T08:33:35.1951198Z",
                                 "isSynthetic":  false,
                                 "samplingRate":  100.0
                             },
                    "cloud":  {

                              },
                    "device":  {
                                   "type":  "PC",
                                   "roleName":  "nope",
                                   "roleInstance":  "nope",
                                   "screenResolution":  ""
                               },
                    "session":  {
                                    "isFirst":  false
                                },
                    "operation":  {

                                  },
                    "location":  {
                                     "clientip":  "0.0.0.0",
                                     "continent":  "Europe",
                                     "country":  "Germany"
                                 },
                    "custom":  {
                                   "dimensions":  "   ",
                                   "metrics":  ""
                               }
                }
}
```

### LabFinished event - transmitted data sample  

```json
{
    "event":  [
                  {
                      "name":  "LabFinished",
                      "count":  1
                  }
              ],
    "internal":  {
                     "data":  {
                                  "id":  "c4edb2a0-dd13-11e9-817d-49de0b58223d",
                                  "documentVersion":  "1.61"
                              }
                 },
    "context":  {
                    "data":  {
                                 "eventTime":  "2019-09-22T08:34:17.1963486Z",
                                 "isSynthetic":  false,
                                 "samplingRate":  100.0
                             },
                    "cloud":  {

                              },
                    "device":  {
                                   "type":  "PC",
                                   "roleName":  "nope",
                                   "roleInstance":  "nope",
                                   "screenResolution":  ""
                               },
                    "session":  {
                                    "isFirst":  false
                                },
                    "operation":  {

                                  },
                    "location":  {
                                     "clientip":  "0.0.0.0",
                                     "continent":  "Europe",
                                     "country":  "Germany"
                                 },
                    "custom":  {
                                   "dimensions":  "",
                                   "metrics":  ""
                               }
                }
}
```

### LabRemoved event - transmitted data sample  

```json
{
    "event":  [
                  {
                      "name":  "LabRemoved",
                      "count":  1
                  }
              ],
    "internal":  {
                     "data":  {
                                  "id":  "c52bcd10-dd13-11e9-b94e-bbbcc152ed38",
                                  "documentVersion":  "1.61"
                              }
                 },
    "context":  {
                    "data":  {
                                 "eventTime":  "2019-09-22T08:34:17.5926954Z",
                                 "isSynthetic":  false,
                                 "samplingRate":  100.0
                             },
                    "cloud":  {

                              },
                    "device":  {
                                   "type":  "PC",
                                   "roleName":  "nope",
                                   "roleInstance":  "nope",
                                   "screenResolution":  ""
                               },
                    "session":  {
                                    "isFirst":  false
                                },
                    "operation":  {

                                  },
                    "location":  {
                                     "clientip":  "0.0.0.0",
                                     "continent":  "Europe",
                                     "country":  "Germany"
                                 },
                    "custom":  {
                                   "metrics":  ""
                               }
                }
}
```

### Role event - transmitted data sample  

```json
{
    "event":  [
                  {
                      "name":  "Role",
                      "count":  1
                  }
              ],
    "internal":  {
                     "data":  {
                                  "id":  "aba95830-dd13-11e9-8c80-71afcdf3720b",
                                  "documentVersion":  "1.61"
                              }
                 },
    "context":  {
                    "data":  {
                                 "eventTime":  "2019-09-22T08:33:34.7148692Z",
                                 "isSynthetic":  false,
                                 "samplingRate":  100.0
                             },
                    "cloud":  {

                              },
                    "device":  {
                                   "type":  "PC",
                                   "roleName":  "nope",
                                   "roleInstance":  "nope",
                                   "screenResolution":  ""
                               },
                    "session":  {
                                    "isFirst":  false
                                },
                    "operation":  {

                                  },
                    "location":  {
                                     "clientip":  "0.0.0.0",
                                     "continent":  "Europe",
                                     "country":  "Germany"
                                 },
                    "custom":  {
                                   "dimensions":  ""
                               }
                }
}
```

### Facts and figures

<iframe width="100%" height="600" src="https://msit.powerbi.com/view?r=eyJrIjoiN2Q3ZTU5Y2QtMjUyMi00YmFhLTkxNTMtZDBmYTA3MzcyYWQxIiwidCI6IjcyZjk4OGJmLTg2ZjEtNDFhZi05MWFiLTJkN2NkMDExZGI0NyIsImMiOjV9&pageName=ReportSection67b5abc401bbec55e899" frameborder="0" allowFullScreen="true"></iframe>

### Country distribution

<iframe width="100%" height="600" src="https://msit.powerbi.com/view?r=eyJrIjoiN2Q3ZTU5Y2QtMjUyMi00YmFhLTkxNTMtZDBmYTA3MzcyYWQxIiwidCI6IjcyZjk4OGJmLTg2ZjEtNDFhZi05MWFiLTJkN2NkMDExZGI0NyIsImMiOjV9&pageName=ReportSectiona46e290f733ccaa8ef5f" frameborder="0" allowFullScreen="true"></iframe>

### Role distribution

<iframe width="100%" height="600" src="https://msit.powerbi.com/view?r=eyJrIjoiN2Q3ZTU5Y2QtMjUyMi00YmFhLTkxNTMtZDBmYTA3MzcyYWQxIiwidCI6IjcyZjk4OGJmLTg2ZjEtNDFhZi05MWFiLTJkN2NkMDExZGI0NyIsImMiOjV9&pageName=ReportSectionae759e8d989baffad8d4" frameborder="0" allowFullScreen="true"></iframe>

### Version distribution

<iframe width="100%" height="600" src="https://msit.powerbi.com/view?r=eyJrIjoiN2Q3ZTU5Y2QtMjUyMi00YmFhLTkxNTMtZDBmYTA3MzcyYWQxIiwidCI6IjcyZjk4OGJmLTg2ZjEtNDFhZi05MWFiLTJkN2NkMDExZGI0NyIsImMiOjV9&pageName=ReportSection3edbf550bbd6493af421" frameborder="0" allowFullScreen="true"></iframe>

[AutomatedLab]: https://github.com/AutomatedLab/AutomatedLab
[wiki]: https://github.com/AutomatedLab/AutomatedLab/wiki
[full report]: https://msit.powerbi.com/view?r=eyJrIjoiN2Q3ZTU5Y2QtMjUyMi00YmFhLTkxNTMtZDBmYTA3MzcyYWQxIiwidCI6IjcyZjk4OGJmLTg2ZjEtNDFhZi05MWFiLTJkN2NkMDExZGI0NyIsImMiOjV9

### [1. Installation](https://automatedlab.org/en/latest/Wiki/install/)

### [2. Getting started](https://automatedlab.org/en/latest/Wiki/gettingstarted/)

### [3. Contributing](https://github.com/AutomatedLab/AutomatedLab/blob/master/CONTRIBUTING.md)

### [Version History](https://github.com/AutomatedLab/AutomatedLab/blob/master/CHANGELOG.md)

