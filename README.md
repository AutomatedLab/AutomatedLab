# AutomatedLab
Summary
AutomatedLab enables you to setup test and lab environments with multiple products or just a single VM in a very short time. There are only two requirements you need to make sure: You need the DVD ISO images (with product keys) and a Hyper-V host machine.

Version History

Supported products
This solution supports setting up virtual machines with the following products
- Windows 7, 2008 R2, 8 / 8.1 and 2012 / 2012 R2, 10 / 2016 TP4
- SQL Server 2008, 2008R2, 2012, 2014
- Visual Studio 2012, 2013, 2015
- Exchange 2013
- System Center Orchestrator 2012
- Office 2013, 2016

Some interesting features
- Create, restore and remove snapshots of some or all lab machines with one cmdlet (Checkpoint-LabVM, Restore-LabVMSnapshot, Remove-LabVM).
- Install Windows Features on one, some or all lab machines with one line of code (Install-LabWindowsFeature).
- Install software to a bunch of lab machines with just one cmdlet (Install-LabSoftwarePackages). You only need to know the argument to make the MSI or EXE go into silent installation mode. This can also work in parallel thanks to PowerShell workflows.
- Run any custom activity (Script or ScriptBlock) on a number of lab machines (Invoke-LabPostInstallActivity)
