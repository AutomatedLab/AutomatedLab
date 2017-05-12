**Table of contents**
- [Usage and Overview](#usage-and-overview)
    - [Summary](#summary)
        - [Supported products](#supported-products)
        - [Some interesting features](#some-interesting-features)
    - [Quick start](#quick-start)
        - [Sample Scripts](#sample-scripts)
            - SmallLab1 2012R2.ps1 (about 10 minutes)
            - SmallLab1 2012R2 SQL.ps1 (about 40 minutes)
            - SmallLab1 2012R2 EX.ps1 (about 90 minutes)
            - Single Win81 Client.ps1 (about 10 minutes)
            - Single Win81 Client VS OFF.ps1 (about 20 minutes)
            - MediumLab1 2012R2 SQL EX.ps1 (about 150 minutes)
            - BigLab 2012R2 EX SQL ORCH VS OFF.ps1 (about 230 - 300 minutes)
    - [Technical Summary](#technical-summary)
        - [PowerShell Modules](#powershell-modules)
        - [Network and PowerShell Remoting](#network-and-powershell-remoting)
        - [Hyper-V Virtual Machines and VHDs](#hyper-v-virtual-machines-and-vhds)
        - [Role installation](#role-installation)
        - [PostInstallationActivity](#postinstallationactivity)
        - [Software Installation](#software-installation)
            - [On a single machine](#on-a-single-machine)
            - [On multiple machines](#on-multiple-machines)
        - [Creating the lab definition](#creating-the-lab-definition)
    - [Work in Progress](#work-in-progress)
        - [Patching](#patching)
        - [System Center Configuration Manager 2012](#system-center-configuration-manager-2012)
        - [Active Directory Replication Topology](#active-directory-replication-topology)
    - [Known Issues](#known-issues)
        - [Virtual Machine Creation](#virtual-machine-creation)
        - [Network](#network)
        - [Credential Handling](#credential-handling)
        - [Domain setup](#domain-setup)
        - [PostInstallationActivities](#postinstallationactivities)
        - [Documentation](#documentation)
    - [Version History](#version-history)
    - [Appendix](#appendix)
        - [Reference structure of a lab source folder](#reference-structure-of-a-lab-source-folder)


Usage and Overview
==================

Summary
-------

AutomatedLab is a hydration solution that enables you to setup test and
lab environments with multiple products or just a single VM in a very
short time. There are only two requirements you need to make sure: You
need the DVD ISO images (with product keys) and a Hyper-V host machine.

### Supported products

This solution supports setting up Windows 8 / 8.1 and Windows Server
2012 / 2012 R2 machines with the following products

-   Windows 8 / 8.1 and 2012 / 2012 R2

-   SQL Server 2012

-   Visual Studio 2012 / 2013

-   Exchange 2013

-   System Center Orchestrator 2012

-   Office 2013

### Some interesting features

-   Create, restore and remove snapshots of some or all lab machines
    with one cmdlet (Checkpoint-LabVM, Restore-LabVMSnapshot,
    Remove-LabVM).

-   Install Windows Features on one, some or all lab machines with one
    line of code (Install-LabWindowsFeature).

-   Install software to a bunch of lab machines with just one cmdlet
    (Install-LabSoftwarePackages). You only need to know the argument to
    make the MSI or EXE go into silent installation mode. This can also
    work in parallel thanks to PowerShell workflows.

-   Run any custom activity (Script or ScriptBlock) on a number of lab
    machines (Invoke-LabPostInstallActivity)

Quick start
-----------

The AutomatedLab.msi has three components: Modules, Documentation and
Sample Scripts. The modules are installed in your private module
directory: C:\\Users\\&lt;username&gt;
\\Documents\\WindowsPowerShell\\Modules by default and the documentation
and samples scripts in your personal documents folder. You can change
all the locations if you want to.

The sample scripts will give you a quick start. There is a script for
setting up just a single Windows 8.1 machine, a small single domain with
just one DC and one server up to the full blown scenario with 12
machines and all products listed in the summary above. You have just to
set the paths inside the scripts and put in your product keys. Before
the lab gets installed all paths will be checked and you get an error
message with further information if there is something wrong.

Just pick one of the sample scripts and set the paths according to your
system. Make sure that the ISO images are available. Then just invoke
the script in an elevated PowerShell. The installation takes 5 minutes
up to several hours depending on the script you choose and the speed of
your drives.

**If you want to see some details about the installation process, turn
on PowerShell verbose logging using \$VerbosePreference = ‘continue’
(always recommended for this solution).**

**The sample scripts are based on a collection in the Post Installation
Activities. The installation puts these custom scripts into the lab
source folder.**

### Sample Scripts

All given installation times are measured on a SSD RAID 0.

#### SmallLab1 2012R2.ps1 (about 10 minutes)

This lab provides:

-   One domain controller in one domain

For this lab for example you need just one ISO image:

-   en\_windows\_server\_2012\_r2\_x64\_dvd\_2707946.iso

#### SmallLab1 2012R2 SQL.ps1 (about 40 minutes)

This lab provides:

-   One domain controller in one domain

-   A SQL 2012 server

For this lab for example you need just one ISO image:

-   en\_windows\_server\_2012\_r2\_x64\_dvd\_2707946.iso

-   en\_sql\_server\_2012\_standard\_edition\_with\_sp1\_x64\_dvd\_1228198.iso

#### SmallLab1 2012R2 EX.ps1 (about 90 minutes)

This lab provides:

-   One domain controller in one domain. About 7.000 users are added to
    the domain

-   An Exchange 2013 organization with one server

For this lab for example you need just one ISO image:

-   en\_windows\_server\_2012\_r2\_x64\_dvd\_2707946.iso

-   mu\_exchange\_server\_2013\_x64\_dvd\_1112105.iso

The domain controller has defined two PostInstallationActivities. A
LabPostInstallationActivity can run a script or executable to customize
the machine after installation. The used PostInstallationActivities are
available for download and should be in a separate folder named
“PostInstallationActivities” under the lab sources. The first script
PrepareRootDomain.ps1 creates just a couple of users for working with
the environment. New-ADLabAccounts 1.0.ps1 creates about 7.000 accounts
in a quite complex hierarchy for a pure lab.

#### Single Win81 Client.ps1 (about 10 minutes)

This lab provides:

-   A single non-domain joined Windows 8.1 client

For this lab for example you need just one ISO image:

-   en\_windows\_8\_1\_x64\_dvd\_2707217.iso

#### Single Win81 Client VS OFF.ps1 (about 20 minutes)

This lab provides:

-   A single non-domain joined Windows 8.1 client with Visual Studio
    2013 and Office 2013 (no key provided and not activated)

For this lab for example you need just one ISO image:

-   en\_windows\_8\_1\_x64\_dvd\_2707217.iso

-   en\_visual\_studio\_ultimate\_2013\_x86\_dvd\_3009107.iso

-   en\_office\_professional\_plus\_2013\_x86\_dvd\_1123673.iso

#### MediumLab1 2012R2 SQL EX.ps1 (about 150 minutes)

This lab provides:

-   Two domain controller in two domains. 7.000 users are added to the
    child domain

-   An Exchange 2013 organization with one server in the child domain

-   A SQL 2012 server in the child domain with sample databases added
    after installation

-   A Windows 8.1 client with Visual Studio 2013 and .net 3.5 installed.

For this lab for example you need just one ISO image:

-   en\_windows\_server\_2012\_r2\_x64\_dvd\_2707946.iso

-   en\_windows\_8\_1\_x64\_dvd\_2707217.iso

-   mu\_exchange\_server\_2013\_x64\_dvd\_1112105.iso

-   en\_sql\_server\_2012\_standard\_edition\_with\_sp1\_x64\_dvd\_1228198.iso

-   en\_visual\_studio\_ultimate\_2013\_x86\_dvd\_3009107.iso

There are three PostInstallationActivities defined here:

-   The root domain get prepared by PrepareRootDomain.ps1

-   Users are created in the child domain by New-ADLabAccounts 1.0.ps1

-   Sample databases are installed and added to the SQL server by
    InstallSampleDBs.ps1

-   .net Framework 3.5 is installed onto the client by
    DotNet35Client.ps1

#### BigLab 2012R2 EX SQL ORCH VS OFF.ps1 (about 230 – 300 minutes)

This lab provides:

-   6 domain controller in 3 domains. 7.000 users are added to the first
    child domain

-   An Exchange 2013 organization with one server in the first child
    domain

-   A SQL 2012 server in the first child domain with sample databases
    added after installation

-   Orchestrator 2012 is installed in the first child domain

-   A simple file server in the first child domain

-   2 Windows 8.1 clients with Office 2013. One client also gets Visual
    Studio 2013 and .net Framework 3.5

For this lab for example you need just one ISO image:

-   en\_windows\_server\_2012\_r2\_x64\_dvd\_2707946.iso

-   en\_windows\_8\_1\_x64\_dvd\_2707217.iso

-   mu\_exchange\_server\_2013\_x64\_dvd\_1112105.iso

-   en\_sql\_server\_2012\_standard\_edition\_with\_sp1\_x64\_dvd\_1228198.iso

-   en\_visual\_studio\_ultimate\_2013\_x86\_dvd\_3009107.iso

There are three PostInstallationActivities defined here:

-   The root domain get prepared by PrepareRootDomain.ps1

-   Users are created in the child domain by New-ADLabAccounts 1.0.ps1

-   Sample databases are installed and added to the SQL server by
    InstallSampleDBs.ps1

-   .net Framework 3.5 is installed onto the client by
    DotNet35Client.ps1

After the machines are set up, some additional software packages are
installed. These need to be in folder “SoftwarePackages” also under the
lab sources folder. If you download the current version please update
the filename in the script accordingly. The command line parameters to
install the software silently will pretty likely no change.

The scripts install the following software to all machines:

-   Classic Shell

-   Notepad++

-   WinRAR

Technical Summary
-----------------

### PowerShell Modules

This solution consists of 6 PowerShell modules that are automating the
creation VHD Base Images, Hyper-V VMs with differential disks,
configuring the unattended XML file, installing software and doing some
final customization.

The lab configuration is saved in XML.

-   AutomatedLabDefinition

    This module provides cmdlets for setting up the lab configuration
    like virtual network switches, Active Directory domains, ISO images
    and machines with roles. After setting up your lab you can export it
    to XML for installation or as a template for later use.

-   AutomatedLabUnattended

    A standard unattended Xml is used for setting up the machines.
    Certain values like domain, IP settings, product key and other
    settings can be changed. The changed unattended Xml file is then
    copied to the machine.

-   AutomatedLab

    This module is the key module and the front end to start the lab
    creation process. It lets you create the machines defined previously
    and also install all the defined roles. After the roles are
    installed further customization can be done
    (PostInstallationActivities, some demos are included and explained
    later).

-   AutomatedLabWorker

    The backend module that does the actual work. It does not depend on
    the Xml files and should not be used directly.

-   PSLog

    Redirects verbose and debug messages to log files and is also
    available here:
    <http://gallery.technet.microsoft.com/scriptcenter/PSLog-Send-messages-to-a-db389927>

-   PSFileTransfer

    Provides a way to copy files and folders to other machines using
    WinRM

### Network and PowerShell Remoting

One of the first things to do is creating a virtual network switch so
the host can connect to the virtual machines. For that reason the
network switch is of type internal and set to the specified IP address.

To create the virtual network switch use the cmdlet Install-Lab with the
switch ‘NetworkSwitches’.

Windows Remoting does not allow to connect to an untrusted computer. In
this case all the lab machines are untrusted and we need to relax the
security (TrustedHots = \*). This is done by the cmdlet
Set-LabHostRemoting. After the lab setup is finished you can set
TrustedHosts back to an empty value.

Some installations require a second authentication hop, like the
Exchange 2013 installation. This means that the installation user’s
credentials need to be forwarded to another machine. By default
PowerShell remoting does not give the remote computer the password so
there is nothing to forward. If CredSsp is used the actual credentials
are given to the remote computer and the remote computer can use them to
create another remote connection to any other box. Your host system
needs to allow credentials to be forwarded. The function
Set-LabHostRemoting checks if the policy is configured correctly and
prints an error message if not.

### Hyper-V Virtual Machines and VHDs

Creating the machines is done by the cmdlet Install-Lab and the switches
‘BaseImages’ and ‘VMs’

The virtual machines are created using the cmdlets provided with
Hyper-V. Before creating the VMs reference VHDs are created per OS
(New-LabBaseImages) and the operating system image is applied to the
reference disk (DISM). BCDBoot.exe is used to make the disk bootable.
When creating a new VM it is always based on one of the reference disks.

For each machine a Unattended.xml file is created with the settings you
provided (Computer name, IP address, domain name, etc.) and copied to
the VHD. When the machine is started the settings made in that file are
applied to the machine.

### Role installation

The installation of roles is done using the Install-Lab cmdlet. It
provides a switch for each role.

The role installation is done by PowerShell scripts provided in these
modules. They are invoked on the VM using PowerShell Remoting. Hence it
is very important that the machines are reachable. The virtual switch
created for each lab needs to have an IP address in the same subnet as
the VMs. Some basic validation checks are done prior to the lab
installation.

Name resolution is also an issue. The solution works with the IP address
as long as the machines have static ones. If not the process relies on
finding the machine by name. If the installation complains that a
machine cannot be reached (have \$VerbosePreference set to ‘Continue’ to
see this), make sure that name resolution works.

### PostInstallationActivity

Each machine can be assigned a number of PostInstallationActivities.
These are invoked after everything else has been done.

A PostInstallationActivity consists of two things:

-   A script to run

-   A file dependency, either an ISO image or a folder

If you have chosen ISO image dependency the script to invoke has to be
on the hos machine and given by the full path. The cmdlet
Invoke-LabPostInstallActivity invokes the script using the cmdlet
Invoke-Command which copies it over to the remote machine. Before that
the ISO image is mounted to the VM.

If you go for a folder dependency, the script to execute needs to be
part of the folder. The folder gets copied to the VMs root drive and the
script is invoked there. By using the switch ‘KeepFolder;

This can be either an ISO image that gets mounted before invoking the
script or a folder. If you have specified a folder, it will be copied to
the VM. In this case the script is not expected to be on the local
machine but inside the folder copied to the VM.

### Software Installation

AutomatedLab provides an easy solution to install software to some or
all lab machines. The software that you want to install must provide a
silent way.

#### On a single machine

One way is using the cmdlet Install-LabSoftwarePackage that required
three parameters

-   Path: Takes the local path of the exe or msi

-   CommandLine: The command line arguments to tell the exe or msi that
    you want to install it silently and other parameters that you find
    necessary

-   ComputerName: The machine of the computer to install the software

#### On multiple machines

If you want to install something on some or even all lab machines you
can use the function (actually a workflow) Install-LabSoftwarePackages.
This function installs the software asynchronously on all given
machines.

Install-LabSoftwarePackages takes a list of LabSoftwarePackages. You can
create a software package using the cmdlet Get-LabSoftwarePackage
(requires the local path of and the arguments to install the application
silenty). A sample how that works can be found in the BigLab sample
script.

### Creating the lab definition

The module AutomatedLabDefinition is designed for that. It allows you to
create the lab definition using cmdlets and export the result to XML. Of
course you can create the XML file manually as well if this seems more
flexible or comfortable.

The available cmdlets are:

-   New-LabDefinition

    This creates a new empty container for the lab. You have to specify
    the path to store the XML files and another path for storing the VMs

-   Add-LabVirtualNetworkDefinition

    This adds the virtual network switch to the lab. Required are the
    parameters Name, IpAddress and PrefixLength.

    *Note: At the moment there is just one virtual network switch
    supported in a lab. The prefix parameter is not working and the
    subnet will be always 255.255.255.0, 24 bits.*

-   Add-LabDomainDefinition

    Each domain has to be specified here. If there are machines
    belonging to a non-specified domain, the installation process will
    not start. This means that all domains have to be added, the forest
    root as well as all child domains. You need to specify the AdminUser
    and the AdminPassword. These credentials are used for installing the
    domain controllers.

-   Add-LabIsoImageDefinition

    All images used as a source need to be added with this cmdlet.
    Required is the path to the ISO image and the name that is used
    internally to refer to the ISO.

    If the ISO is an OS images the OS image name is required (parameter
    OsName) as well as the ImageType (Client or Server) and the name of
    the reference or base image (parameter ReferenceDisk).

    The names of the ISOs image are hard-coded for the following roles:

    -   SQL Server (SQL Server 2012)

    -   Exchange (Exchange 2012)

    -   DevTools (Visual Studio 2012)

    -   Orchestrator (System Center Orchestrator 2012)

    -   ConfigManager (System Center Configuration Manager 2012)

-   Add-LabMachineDefinition

    This cmdlet adds machines to the lab definition. Most of the
    parameters are quite self-explaining:

    -   DiskSizeInGb

    -   DnsServer1

    -   DnsServer2

    -   DomainName

        The domain has to be specified using the cmdlet
        Add-LabDomainDefinition first.

    -   Gateway

    -   InstallationUserCredential

        A PSCredential Object like Get-Credential returns it.

    -   IpAddress

    -   IsDomainJoined

    -   MemoryInMb

    -   Name

    -   Network

        The name of the virtual network that already has been added
        using the cmdlet Add- LabVirtualNetworkDefinition.

    -   PassThru

    -   PostInstallationActivity

    -   Processors

        The number of processors

    -   ProductKey

    -   Roles

        The roles are not defined as a string but as a role object. To
        get a role object use the cmdlet

    -   Type

        Client or Server

        UnattendedXml\
        The name of the unattended Xml file for this machine.

    -   Tools\
        The folder specified here is copied to the Windows directory of
        the VM. If you have a set of tools you want to have on all
        machines just put them in one folder and point to it.

-   Get-LabMachineRoleDefinition

    The create a role object that you can pass to the
    Add-LabMachineDefinition cmdlet’s role parameter

-   Get-PostInstallationActivity

    This creates a custom Activity to be that be passed to the parameter
    PostInstallationActivity of the cmdlet Add-LabMachineDefinition

Work in Progress
----------------

### Patching

It is planned to provide an offline patching of the base images so all
machines will be up to date with the latest security fixes

### System Center Configuration Manager 2012

A guide that explains how to use the PowerShell Doployment Toolkit
(<http://blogs.technet.com/b/privatecloud/archive/2013/02/08/deployment-introducing-powershell-deployment-toolkit.aspx>)
with the AutomatedLab solution would be nice.

### Active Directory Replication Topology

At the moment a PowerShell script has to be used to create a replication
topology. It is planned to provide this as part of the lab definition.

Known Issues
------------

### Virtual Machine Creation

-   For installation VHDs are mounted to the host machine to copy date
    to the virtual drives. Therefore the explorer pops up and may show
    access denied errors and “Format Drive” dialogs. Just ignore them,
    they don’t interrupt the installation process.

### Network

-   The setup process is based on PowerShell Remoting. The host needs to
    be able to connect to the virtual machines. If the virtual machine
    does not have a fixed IPv4 address the normal name resolution
    process has to resolve the name to the right machine. If there is
    another machine with the same name in your organization the setup
    does not work as DNS overrules other name resolution processes.
    Machines with static IP addresses are contacted by IP address and
    not by name.

-   The network subnet mask is ways 24 bits. Defining other subnet masks
    is going to work in the next release.

-   Windows 8 Clients need quite a long time until they can be contacted
    after the OS is installed. Please be patient. Windows Server 2012
    does not cause this delay.

-   If a machine has a not a static IP address and you do not have a
    DHCP server set up, the machine gets an APIPA address (169.254.x.x).
    In this case the connection is done using IPv6 if not disabled on
    your host.

### Credential Handling

-   All credentials are saved in plain text. As this solution is not
    meant for setting up production environments this should not be a
    big issue.

-   So far this solution has not been tested with different installation
    credentials. All entities – domain controllers, member servers and
    clients – are sharing the same administrative credentials. This will
    change in the next releases.

### Domain setup

-   There is a timing issue setting up the domain controllers. Sometimes
    promoting a second domain controller does not work and the machine
    complains that it cannot contact the domain.

### PostInstallationActivities

-   The implementation needs to be more flexible and is going to be
    redesigned in the next version. There is also some misalignment with
    the parameter set in the AutomatedLab module and the worker module.

### Documentation

-   Unfortunately the cmdlets do lack documentation and this document
    all there is that describes how AutomatedLab works.

Version History
---------------

-   1.0: The initial release August 2013

-   1.4

    -   Rebuild the PostInstallationActivity functions. These are the
        main building block to do custom things on the lab machines.

    -   Introduced a feature to install software
        (Install-LabSoftwarePackage).

    -   Introduced a feature to install software in parallel (workflow
        Install-LabSoftwarePackages).

    -   Introduces cmdlets for managing snapshots for all or some
        machines in a lab.

    -   Provided the setup scripts for Exchange 2013 (single server)

    -   Provided the setup script for Office 2013 installation

    -   This version also installs Visual Studio 2013

-   1.4.1

    -   Fixing bugs in the Exchange Install routine

    -   Support for multi forest environment including cross-forest DNS
        setup and trusts

-   1.5.0

    -   Changed the way how name resolution is done. AutomatedLab now
        updates the hosts file

    -   Introduced Remove-Lab to clean the host if a lab is no longer
        needed

    -   Support for domain trees additionally to child domains

-   1.5.1

    -   Bug Fixing: Using different credentials in inside a lab scenario
        didn’t work and does now.

    -   Added a multi-forest scenario that connects three forests to the
        sample scripts

Appendix
--------

### Reference structure of a lab source folder

Directory: E:\\LabSources

Mode LastWriteTime Length Name

---- ------------- ------ ----

d---- 08.01.2014 16:02 ISOs

d---- 08.01.2014 16:02 PostInstallationActivities

d---- 08.01.2014 17:35 SoftwarePackages

d---- 08.01.2014 16:02 Tools

d---- 29.10.2013 22:59 \_\_old

Directory: E:\\LabSources\\ISOs

Mode LastWriteTime Length Name

---- ------------- ------ ----

-a--- 28.10.2013 12:26 699004928
en\_office\_professional\_plus\_2013\_x86\_dvd\_1123673.iso

-a--- 29.09.2013 14:57 3900762112
en\_sql\_server\_2012\_standard\_edition\_with\_sp1\_x64\_dvd\_1228198.iso

-a--- 06.09.2012 02:34 4509648896
en\_sql\_server\_2012\_standard\_edition\_x86\_x64\_dvd\_813403.iso

-a--- 03.05.2013 17:04 164681728
en\_system\_center\_2012\_orchestrator\_with\_sp1\_x86\_dvd\_1345499.iso

-a--- 01.09.2012 20:45 1594998784
en\_visual\_studio\_ultimate\_2012\_x86\_dvd\_920947.iso

-a--- 28.10.2013 10:23 3024457728
en\_visual\_studio\_ultimate\_2013\_x86\_dvd\_3009107.iso

-a--- 15.09.2013 16:13 3899295744
en\_windows\_8\_1\_x64\_dvd\_2707217.iso

-a--- 01.09.2012 22:10 3581853696 en\_windows\_8\_x64\_dvd\_915440.iso

-a--- 15.09.2013 16:14 4268605440
en\_windows\_server\_2012\_r2\_x64\_dvd\_2707946.iso

-a--- 05.09.2012 10:59 3695179776
en\_windows\_server\_2012\_x64\_dvd\_915478.iso

-a--- 19.02.2013 21:39 255842304 ExchangeDependencies.iso

-a--- 12.02.2013 00:02 3618824192
mu\_exchange\_server\_2013\_x64\_dvd\_1112105.iso

-a--- 23.10.2012 08:11 107034814 Windows6.2-KB2693643-x64.msu

-a--- 01.03.2013 12:55 99918668 Windows6.2-KB2693643-x86.msu

-a--- 31.10.2013 01:49 0 \_Put all ISO images in here.txt

Directory: E:\\LabSources\\PostInstallationActivities

Mode LastWriteTime Length Name

---- ------------- ------ ----

d---- 08.01.2014 16:02 DnsAndTrustSetup

d---- 08.01.2014 16:02 DotNet35Client

d---- 08.01.2014 16:02 PrepareFirstChildDomain

d---- 08.01.2014 16:02 PrepareRootDomain

d---- 08.01.2014 16:02 PrepareSqlServer

-a--- 31.10.2013 01:50 0 \_This is the place for all scripts to
customize the roles after installation.txt

Directory: E:\\LabSources\\PostInstallationActivities\\DnsAndTrustSetup

Mode LastWriteTime Length Name

---- ------------- ------ ----

-a--- 25.12.2013 17:09 6172 DnsAndTrustSetup.ps1

Directory: E:\\LabSources\\PostInstallationActivities\\DotNet35Client

Mode LastWriteTime Length Name

---- ------------- ------ ----

-a--- 04.09.2013 12:30 3217 DotNet35Client.ps1

Directory:
E:\\LabSources\\PostInstallationActivities\\PrepareFirstChildDomain

Mode LastWriteTime Length Name

---- ------------- ------ ----

-a--- 22.05.2013 02:02 1236073 LabUsers.txt

-a--- 22.05.2013 02:04 3382 New-ADLabAccounts 1.0.ps1

Directory: E:\\LabSources\\PostInstallationActivities\\PrepareRootDomain

Mode LastWriteTime Length Name

---- ------------- ------ ----

-a--- 16.10.2013 02:08 1960 PrepareRootDomain.ps1

-a--- 07.05.2007 09:19 209 RepAll.bat

-a--- 30.08.2012 22:21 5162 Sites.txt

-a--- 19.02.2013 22:14 7637 Subnets.txt

-a--- 09.01.2011 16:28 16500 users.csv

Directory: E:\\LabSources\\PostInstallationActivities\\PrepareSqlServer

Mode LastWriteTime Length Name

---- ------------- ------ ----

-a--- 23.05.2013 02:13 208 InstallSampleDBs.ps1

-a--- 23.05.2013 02:03 2115210 instnwnd.sql

-a--- 23.05.2013 02:00 128454 instpubs.sql

-a--- 22.02.2013 02:04 724 Script.txt

-a--- 12.04.2012 12:29 1558016 SQL2000SampleDb.msi

Directory: E:\\LabSources\\SoftwarePackages

Mode LastWriteTime Length Name

---- ------------- ------ ----

-a--- 29.10.2013 20:27 5629632 ClassicShell.exe

-a--- 25.09.2013 15:38 1433865896 Exchange2013-KB2859928-x64-v2.exe

-a--- 19.02.2013 18:47 3695616
filterpack2010sp1-kb2460041-x64-fullfile-en-us.exe

-a--- 23.09.2013 19:56 4065080 FilterPack64bit.exe

-a--- 23.08.2013 14:53 7412233 Notepad++.exe

-a--- 09.07.2013 19:16 9674112 ReflectorInstaller.exe

-a--- 19.02.2013 19:51 251773456 UcmaRuntimeSetup.exe

-a--- 24.09.2013 21:27 1970848 winrar.exe

-a--- 07.10.2013 12:03 27966944 Wireshark-win64-1.10.2.exe

-a--- 31.10.2013 01:49 0 \_Put all software you want to install to the
VMs here.txt

Directory: E:\\LabSources\\Tools

Mode LastWriteTime Length Name

---- ------------- ------ ----

-a--- 31.10.2013 01:48 328384 accesschk.exe

-a--- 31.10.2013 01:48 174968 AccessEnum.exe

-a--- 31.10.2013 01:48 50379 AdExplorer.chm

-a--- 31.10.2013 01:48 479832 ADExplorer.exe

-a--- 31.10.2013 01:48 401616 ADInsight.chm

-a--- 31.10.2013 01:48 1049640 ADInsight.exe

-a--- 31.10.2013 01:48 150328 adrestore.exe

-a--- 31.10.2013 01:48 148856 Autologon.exe

-a--- 31.10.2013 01:48 49518 autoruns.chm

-a--- 31.10.2013 01:48 661184 autoruns.exe

-a--- 31.10.2013 01:48 579264 autorunsc.exe

-a--- 31.10.2013 01:48 847040 Bginfo.exe

-a--- 31.10.2013 01:49 154424 Cacheset.exe

-a--- 31.10.2013 01:49 151936 Clockres.exe

-a--- 31.10.2013 01:49 207960 Contig.exe

-a--- 31.10.2013 01:49 1479256 Coreinfo.exe

-a--- 31.10.2013 01:49 10104 ctrl2cap.amd.sys

-a--- 31.10.2013 01:49 150328 ctrl2cap.exe

-a--- 31.10.2013 01:49 2864 ctrl2cap.nt4.sys

-a--- 31.10.2013 01:49 2832 ctrl2cap.nt5.sys

-a--- 31.10.2013 01:49 68539 dbgview.chm

-a--- 31.10.2013 01:49 468056 Dbgview.exe

-a--- 31.10.2013 01:49 116824 Desktops.exe

-a--- 31.10.2013 01:49 40683 Disk2vhd.chm

-a--- 31.10.2013 01:49 1767104 disk2vhd.exe

-a--- 31.10.2013 01:49 87424 diskext.exe

-a--- 31.10.2013 01:49 224056 Diskmon.exe

-a--- 31.10.2013 01:49 9519 DISKMON.HLP

-a--- 31.10.2013 01:49 580984 DiskView.exe

-a--- 31.10.2013 01:49 11728 DMON.SYS

-a--- 31.10.2013 01:49 223424 du.exe

-a--- 31.10.2013 01:49 146232 efsdump.exe

-a--- 31.10.2013 01:49 7005 Eula.txt

-a--- 31.10.2013 01:49 103216 FindLinks.exe

-a--- 31.10.2013 01:49 462936 handle.exe

-a--- 31.10.2013 01:49 150328 hex2dec.exe

-a--- 31.10.2013 01:49 150392 junction.exe

-a--- 31.10.2013 01:49 154424 ldmdump.exe

-a--- 31.10.2013 01:49 520496 Listdlls.exe

-a--- 31.10.2013 01:49 539736 livekd.exe

-a--- 31.10.2013 01:49 154424 LoadOrd.exe

-a--- 31.10.2013 01:49 261496 logonsessions.exe

-a--- 31.10.2013 01:49 130160 movefile.exe

-a--- 31.10.2013 01:49 122680 ntfsinfo.exe

-a--- 31.10.2013 01:49 215928 pagedfrg.exe

-a--- 31.10.2013 01:49 8419 pagedfrg.hlp

-a--- 26.07.2000 12:00 146704 pdh.dll

-a--- 31.10.2013 01:49 130648 pendmoves.exe

-a--- 31.10.2013 01:49 150328 pipelist.exe

-a--- 31.10.2013 01:49 422 PORTMON.CNT

-a--- 31.10.2013 01:49 451392 portmon.exe

-a--- 31.10.2013 01:49 43428 PORTMON.HLP

-a--- 31.10.2013 01:49 478400 procdump.exe

-a--- 31.10.2013 01:49 72154 procexp.chm

-a--- 31.10.2013 01:49 2799296 procexp.exe

-a--- 31.10.2013 01:49 63582 procmon.chm

-a--- 31.10.2013 01:49 2489024 Procmon.exe

-a--- 31.10.2013 01:49 387776 PsExec.exe

-a--- 31.10.2013 01:49 105264 psfile.exe

-a--- 31.10.2013 01:49 333176 PsGetsid.exe

-a--- 31.10.2013 01:49 390520 PsInfo.exe

-a--- 31.10.2013 01:49 468592 pskill.exe

-a--- 31.10.2013 01:49 232232 pslist.exe

-a--- 31.10.2013 01:49 183160 PsLoggedon.exe

-a--- 31.10.2013 01:49 178040 psloglist.exe

-a--- 31.10.2013 01:49 171608 pspasswd.exe

-a--- 31.10.2013 01:49 167048 psping.exe

-a--- 31.10.2013 01:49 169848 PsService.exe

-a--- 31.10.2013 01:49 207664 psshutdown.exe

-a--- 31.10.2013 01:49 187184 pssuspend.exe

-a--- 31.10.2013 01:49 66582 Pstools.chm

-a--- 31.10.2013 01:49 39 psversion.txt

-a--- 31.10.2013 01:49 560832 RAMMap.exe

-a--- 31.10.2013 01:49 7903 readme.txt

-a--- 31.10.2013 01:49 162616 RegDelNull.exe

-a--- 31.10.2013 01:49 150328 regjump.exe

-a--- 07.05.2007 09:19 209 RepAll.bat

-a--- 31.10.2013 01:49 102160 RootkitRevealer.chm

-a--- 31.10.2013 01:49 334720 RootkitRevealer.exe

-a--- 31.10.2013 01:49 150720 ru.exe

-a--- 31.10.2013 01:49 155736 sdelete.exe

-a--- 31.10.2013 01:49 260976 ShareEnum.exe

-a--- 31.10.2013 01:49 103464 ShellRunas.exe

-a--- 31.10.2013 01:49 293056 sigcheck.exe

-a--- 31.10.2013 01:49 87424 streams.exe

-a--- 31.10.2013 01:49 90304 strings.exe

-a--- 31.10.2013 01:49 150328 sync.exe

-a--- 31.10.2013 01:49 199544 Tcpvcon.exe

-a--- 31.10.2013 01:49 41074 tcpview.chm

-a--- 31.10.2013 01:49 300832 Tcpview.exe

-a--- 31.10.2013 01:49 7983 TCPVIEW.HLP

-a--- 31.10.2013 01:49 51747 Vmmap.chm

-a--- 31.10.2013 01:49 1056392 vmmap.exe

-a--- 31.10.2013 01:49 154424 Volumeid.exe

-a--- 31.10.2013 01:49 144984 whois.exe

-a--- 09.04.2009 10:26 140288 windiff.exe

-a--- 31.10.2013 01:49 729464 Winobj.exe

-a--- 31.10.2013 01:49 7653 WINOBJ.HLP

-a--- 31.10.2013 01:49 596160 ZoomIt.exe

-a--- 31.10.2013 01:51 0 \_The tools folder gets copied into each VMs'
Windows directory.txt

Directory: E:\\LabSources\\\_\_old

Mode LastWriteTime Length Name

---- ------------- ------ ----

d---- 07.10.2013 19:45 RSAT

Directory: E:\\LabSources\\\_\_old\\RSAT

Mode LastWriteTime Length Name

---- ------------- ------ ----

-a--- 24.08.2013 22:53 1987 RSAT.ps1

-a--- 23.10.2012 08:11 107034814 Windows6.2-KB2693643-x64.msu

-a--- 05.09.2013 16:54 0 Windows6.2-KB2693643-x64.msu should be here.txt
