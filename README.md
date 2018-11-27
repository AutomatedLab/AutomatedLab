# AutomatedLab

Build | Status | Last Commit | Latest Release
--- | --- | --- | ---
Develop | [![Build status dev](https://ci.appveyor.com/api/projects/status/9yynk81k3k05nasp/branch/develop?svg=true)](https://ci.appveyor.com/project/automatedlab/automatedlab) | [![GitHub last commit](https://img.shields.io/github/last-commit/AutomatedLab/AutomatedLab/develop.svg)](https://github.com/AutomatedLab/AutomatedLab/tree/develop/)
Master | [![Build status](https://ci.appveyor.com/api/projects/status/9yynk81k3k05nasp/branch/master?svg=true)](https://ci.appveyor.com/project/automatedlab/automatedlab) | [![GitHub last commit](https://img.shields.io/github/last-commit/AutomatedLab/AutomatedLab/master.svg)](https://github.com/AutomatedLab/AutomatedLab/tree/master/) | [![GitHub release](https://img.shields.io/github/release/AutomatedLab/AutomatedLab.svg)](https://github.com/AutomatedLab/AutomatedLab/releases)[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/AutomatedLab.svg)](https://www.powershellgallery.com/packages/AutomatedLab/)

[![GitHub issues](https://img.shields.io/github/issues/AutomatedLab/AutomatedLab.svg)](https://github.com/AutomatedLab/AutomatedLab/issues)
[![Downloads](https://img.shields.io/github/downloads/AutomatedLab/AutomatedLab/total.svg?label=Downloads&maxAge=999)](https://github.com/AutomatedLab/AutomatedLab/releases)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/AutomatedLab.svg)](https://www.powershellgallery.com/packages/AutomatedLab/)

## Project Summary

AutomatedLab (AL) enables you to setup test and lab environments on Hyper-v or Azure with multiple products or just a single VM in a very short time. There are only two requirements you need to make sure: You need the DVD ISO images and a Hyper-V host or Azure subscription machine.

### Requirements


Apart from the module itself your system needs to meet the following requirements:
Hacker theme
Hacker is a theme for GitHub Pages.

Download as .zip Download as .tar.gz View on GitHub
Text can be bold, italic, strikethrough or keyword.

Link to another page.

There should be whitespace between paragraphs.

There should be whitespace between paragraphs. We recommend including a README, or a file with information about your project.

Header 1

This is a normal paragraph following a header. GitHub is a code hosting platform for version control and collaboration. It lets you and others work together on projects from anywhere.

Header 2

This is a blockquote following a header.

When something is important enough, you do it even if the odds are not in your favor.

Header 3

// Javascript code with syntax highlighting.
var fun = function lang(l) {
  dateformat.i18n = require('./lang/' + l)
  return true;
}
# Ruby code with syntax highlighting
GitHubPages::Dependencies.gems.each do |gem, version|
  s.add_dependency(gem, "= #{version}")
end
Header 4

This is an unordered list following a header.
This is an unordered list following a header.
This is an unordered list following a header.
HEADER 5
This is an ordered list following a header.
This is an ordered list following a header.
This is an ordered list following a header.
HEADER 6
head1	head two	three
ok	good swedish fish	nice
out of stock	good and plenty	nice
ok	good oreos	hmm
ok	good zoute drop	yumm
There’s a horizontal rule below this.

Here is an unordered list:

Item foo
Item bar
Item baz
Item zip
And an ordered list:

Item one
Item two
Item three
Item four
And a nested list:

level 1 item
level 2 item
level 2 item
level 3 item
level 3 item
level 1 item
level 2 item
level 2 item
level 2 item
level 1 item
level 2 item
level 2 item
level 1 item
Small image

Octocat

Large image

Branching


- Windows Management Framework 5+
- Windows Server 2012 R2+/Windows 8.1+
- Required OS language is en-us
- Admin privileges are required
- ISO files for all operating systems and roles to be deployed
- Intel VT-x or AMD/V capable CPU
- A decent amount of RAM
- An SSD for your machines is highly recommended as many issues arise from slow HDDs

### Download AutomatedLab (latest version 5.0.4 released on August 3 2018)

There are two options installing AutomatedLab:
- You can use the [MSI installer](https://github.com/AutomatedLab/AutomatedLab/releases) published on GitHub.
- Or you install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/AutomatedLab/) using the cmdlet Install-Module. Please refer to the wiki for some details.

### [1. Installation](https://github.com/AutomatedLab/AutomatedLab/wiki/1.-Installation)

### [2. Getting started](https://github.com/AutomatedLab/AutomatedLab/wiki/2.-Getting-Started)

### [3. Contributing](https://github.com/AutomatedLab/AutomatedLab/blob/master/CONTRIBUTING.md)

### [Version History](https://github.com/AutomatedLab/AutomatedLab/wiki/Version-History)

### Supported products

This solution supports setting up virtual machines with the following products

- Windows 7, 2008 R2, 8 / 8.1 and 2012 / 2012 R2, 10 / 2016, 2019
- SQL Server 2008, 2008R2, 2012, 2014, 2016, 2017
- Visual Studio 2012, 2013, 2015
- Exchange 2013, Exchange 2016
- System Center Orchestrator 2012
- System Center Configuration Manager 1703
- MDT
- ProGet (Private PowerShell Gallery)
- Office 2013, 2016
- DSC Pull Server

### Feature List

- AutomatedLab (AL) makes the setup of labs extremely easy. Setting up a lab with just a single machine is [only 3 lines](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Introduction/01%20Single%20Win10%20Client.ps1). And even [complex labs](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/HyperV/BigLab%202012R2%20EX%20SQL%20ORCH%20VS%20OFF.ps1) can be defined with about 100 lines (see [sample scripts](https://github.com/AutomatedLab/AutomatedLab/tree/master/LabSources/SampleScripts)).
- Labs on Azure can be connected to each other or connected to a Hyper-V lab [using a single command](https://github.com/AutomatedLab/AutomatedLab/wiki/Connect-on-premises-and-cloud-labs).
- AL can be used to setup scenarios to demo a [PowerShell Gallery using Inedo ProGet](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Scenarios/ProGet%20Lab%20-%20HyperV.ps1), [PowerShell DSC Pull Server scenarios](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Scenarios/DSC%20Pull%20Scenario%201%20(Pull%20Configuration).ps1), ADFS or a lab with [3 Active Directory forests trusting each other](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Scenarios/Multi-AD%20Forest%20with%20Trusts.ps1).
- Create, restore and remove snapshots of some or all lab machines with one cmdlet (Checkpoint-LabVM, Restore-LabVMSnapshot, Remove-LabVMSnapshot).
- Install Windows Features on one, some or all lab machines with one line of code (Install-LabWindowsFeature).
- Install software to a bunch of lab machines with just one cmdlet (Install-LabSoftwarePackages). You only need to know the argument to make the MSI or EXE go into silent installation mode. This can also work in parallel thanks to PowerShell workflows.
- Run any custom activity (Script or ScriptBlock) on a number of lab machines (Invoke-LabCommand). You do not have to care about credentials or double-hop authentication issues as CredSsp is always enabled and can be used with the UseCredSsp switch.
- Creating a [virtual environment that is connected to the internet](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Introduction/05%20Single%20domain-joined%20server%20(internet%20facing).ps1) was never easier. The only requirements are defining an external facing virtual switch and a machine with two network cards that acts as the router. AL takes care about all the configuration details like setting the getaway on all machines and also the DNS settings (see introduction script [05 Single domain-joined server (internet facing).ps1](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Introduction/05%20Single%20domain-joined%20server%20(internet%20facing).ps1)).
- AL offers offline patching with a single command. As all machines a based on one disk per OS, it is much more efficient to patch the ISO files that are used to create the base images (Update-LabIsoImage). See script [11 ISO Offline Patching.ps1](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Introduction/11%20ISO%20Offline%20Patching.ps1) for more details.
- If a lab is no longer required, one command is enough to remove everything to be ready to start from scratch (Remove-Lab)

## Project Management Dashboard
[![Throughput Graph](https://graphs.waffle.io/AutomatedLab/AutomatedLab/throughput.svg)](https://waffle.io/AutomatedLab/AutomatedLab/metrics/throughput

From 655328817e4e772633ac668f325eab5ec9a2a356 Mon Sep 17 00:00:00 2001
From: "azure-pipelines[bot]" <azure-pipelines[bot]@users.noreply.github.com>
Date: Mon, 29 Oct 2018 12:11:34 +0000
Subject: [PATCH 1/9] Set up CI with Azure Pipelines

---
 azure-pipelines.yml | 30 ++++++++++++++++++++++++++++++
 1 file changed, 30 insertions(+)
 create mode 100644 azure-pipelines.yml

diff --git a/azure-pipelines.yml b/azure-pipelines.yml
new file mode 100644
index 0000000..f05be06
--- /dev/null
+++ b/azure-pipelines.yml
@@ -0,0 +1,30 @@
+# .NET Desktop
+# Build and run tests for .NET Desktop or Windows classic desktop solutions.
+# Add steps that publish symbols, save build artifacts, and more:
+# https://docs.microsoft.com/azure/devops/pipelines/apps/windows/dot-net
+
+pool:
+  vmImage: 'VS2017-Win2016'
+
+variables:
+  solution: '**/*.sln'
+  buildPlatform: 'Any CPU'
+  buildConfiguration: 'Release'
+
+steps:
+- task: NuGetToolInstaller@0
+
+- task: NuGetCommand@2
+  inputs:
+    restoreSolution: '$(solution)'
+
+- task: VSBuild@1
+  inputs:
+    solution: '$(solution)'
+    platform: '$(buildPlatform)'
+    configuration: '$(buildConfiguration)'
+
+- task: VSTest@2
+  inputs:
+    platform: '$(buildPlatform)'
+    configuration: '$(buildConfiguration)'

From 4c7b91203f296a615b4875921666b236a474bc81 Mon Sep 17 00:00:00 2001
From: Oscar Gomez <42280574+oscarg933@users.noreply.github.com>
Date: Mon, 29 Oct 2018 05:20:13 -0700
Subject: [PATCH 2/9] Create maxprofs

---
 maxprofs | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 maxprofs

diff --git a/maxprofs b/maxprofs
new file mode 100644
index 0000000..30b6d40
--- /dev/null
+++ b/maxprofs
@@ -0,0 +1,2 @@
+.travis
+git@github.com:oscarg933/cordova-admob-pro.git

From ea227dca8ec3cab744e4dbbbeef51f99962a02ab Mon Sep 17 00:00:00 2001
From: Oscar Gomez <42280574+oscarg933@users.noreply.github.com>
Date: Mon, 29 Oct 2018 05:21:41 -0700
Subject: [PATCH 3/9] Update maxprofs

---
 maxprofs | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/maxprofs b/maxprofs
index 30b6d40..3cf211c 100644
--- a/maxprofs
+++ b/maxprofs
@@ -1,2 +1,5 @@
 .travis
 git@github.com:oscarg933/cordova-admob-pro.git
+.json
+.yaml
+.cirlceci

From 024e00c88f7940d352a55f8c4280b0d158fe58d8 Mon Sep 17 00:00:00 2001
From: Oscar Gomez <42280574+oscarg933@users.noreply.github.com>
Date: Fri, 9 Nov 2018 08:34:14 -0700
Subject: [PATCH 4/9] Create .iot

:1st_place_medal:
---
 .iot | 76 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 76 insertions(+)
 create mode 100644 .iot

diff --git a/.iot b/.iot
new file mode 100644
index 0000000..d3d4387
--- /dev/null
+++ b/.iot
@@ -0,0 +1,76 @@
+.gemfile
+.estrongs
+.patch
+.email
+.wps
+.stream
+.checksum
+.nuget
+.kubernetes
+.docker
+.js
+.php
+.drive
+.storage
+.ftp
+.vlc
+.beautify
+.diff
+.md
+.license
+.legacy
+.0
+.sdcard
+.sdcard1
+.typeapp
+.evernote
+greendot.direct_deposit
+.chat
+.sms
+.officesuite
+.pdf
+.doc
+.docx
+.jit
+.test
+.ibm
+.blockchain
+.desktop
+.picasso
+.api
+.redux
+.firedl
+.Bluetooth
+.foolscap
+.ledger
+.png
+.jpg
+.npm
+.copyright
+.liabiity
+.oxps
+.txt
+.notebook
+.uphold
+.go
+.ruby
+.c
+.faq
+.issues
+.typeapp
+.csv
+.xls
+.xsls
+.desktop
+.dropbox
+.onedrive
+.fire
+.amazon
+.cosmos
+.Live
+Google.drive
+.apk
+.wallet
+.manifest
+.mp4
+

From 784d432c2010606d8466e82787680afb9392c0c8 Mon Sep 17 00:00:00 2001
From: Oscar Gomez <42280574+oscarg933@users.noreply.github.com>
Date: Fri, 9 Nov 2018 08:40:27 -0700
Subject: [PATCH 5/9] Update issue templates

.ci
---
 .github/ISSUE_TEMPLATE/bug_report.md      | 35 +++++++++++++++++++++++
 .github/ISSUE_TEMPLATE/custom.md          |  7 +++++
 .github/ISSUE_TEMPLATE/feature_request.md | 17 +++++++++++
 3 files changed, 59 insertions(+)
 create mode 100644 .github/ISSUE_TEMPLATE/bug_report.md
 create mode 100644 .github/ISSUE_TEMPLATE/custom.md
 create mode 100644 .github/ISSUE_TEMPLATE/feature_request.md

diff --git a/.github/ISSUE_TEMPLATE/bug_report.md b/.github/ISSUE_TEMPLATE/bug_report.md
new file mode 100644
index 0000000..b735373
--- /dev/null
+++ b/.github/ISSUE_TEMPLATE/bug_report.md
@@ -0,0 +1,35 @@
+---
+name: Bug report
+about: Create a report to help us improve
+
+---
+
+**Describe the bug**
+A clear and concise description of what the bug is.
+
+**To Reproduce**
+Steps to reproduce the behavior:
+1. Go to '...'
+2. Click on '....'
+3. Scroll down to '....'
+4. See error
+
+**Expected behavior**
+A clear and concise description of what you expected to happen.
+
+**Screenshots**
+If applicable, add screenshots to help explain your problem.
+
+**Desktop (please complete the following information):**
+ - OS: [e.g. iOS]
+ - Browser [e.g. chrome, safari]
+ - Version [e.g. 22]
+
+**Smartphone (please complete the following information):**
+ - Device: [e.g. iPhone6]
+ - OS: [e.g. iOS8.1]
+ - Browser [e.g. stock browser, safari]
+ - Version [e.g. 22]
+
+**Additional context**
+Add any other context about the problem here.
diff --git a/.github/ISSUE_TEMPLATE/custom.md b/.github/ISSUE_TEMPLATE/custom.md
new file mode 100644
index 0000000..99bb9a0
--- /dev/null
+++ b/.github/ISSUE_TEMPLATE/custom.md
@@ -0,0 +1,7 @@
+---
+name: Custom issue template
+about: Describe this issue template's purpose here.
+
+---
+
+
diff --git a/.github/ISSUE_TEMPLATE/feature_request.md b/.github/ISSUE_TEMPLATE/feature_request.md
new file mode 100644
index 0000000..066b2d9
--- /dev/null
+++ b/.github/ISSUE_TEMPLATE/feature_request.md
@@ -0,0 +1,17 @@
+---
+name: Feature request
+about: Suggest an idea for this project
+
+---
+
+**Is your feature request related to a problem? Please describe.**
+A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]
+
+**Describe the solution you'd like**
+A clear and concise description of what you want to happen.
+
+**Describe alternatives you've considered**
+A clear and concise description of any alternative solutions or features you've considered.
+
+**Additional context**
+Add any other context or screenshots about the feature request here.

From 3cf896bef79e1da4a17b7059b5700c16f3a75984 Mon Sep 17 00:00:00 2001
From: Oscar Gomez <42280574+oscarg933@users.noreply.github.com>
Date: Fri, 9 Nov 2018 09:22:53 -0700
Subject: [PATCH 6/9] Create .iota

---
 .iota | 64 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 64 insertions(+)
 create mode 100644 .iota

diff --git a/.iota b/.iota
new file mode 100644
index 0000000..d9d73a4
--- /dev/null
+++ b/.iota
@@ -0,0 +1,64 @@
+.Chromecast
+.forecast
+.wpsffice
+.plex
+.$
+Lbry.io
+.typescript
+.xamarin
+Node.js
+.cryptography
+.utf
+.outlook
+.ang
+Multi.scanner
+.qr
+.dna
+.SpL
+.forkhub
+.jenk
+.jayno
+.andro100
+.orbit
+.presentation
+.spreadsheet
+.autosign
+.conveyor
+Optimal.cache
+Devops.journey
+Big.query
+Google.services
+.angular
+Static.sites
+.research
+Trending.niche
+Innovative.thinking
+Max.profits
+.rakuten
+.Partnerize
+Massive.linkshare
+.assets
+Any.Lang
+Webmaster.tools
+Embed.manifests
+.appstore
+Upsell.integration
+.sandbox
+Collect.oldgemfiles
+Currency.converter
+Double.check
+.Allfile 
+DO NOT FORGET DIRECT DEPOSIT A$AP GREENDOT BANK UNCOOSK@HOTMAIL.COM
+ROUTING 124303120
+Account Number 99910108283768333
+Btcdeposit.uphold
+Ultimate.api
+Ultimate.ui
+Openload.co
+amazonAPP.factory
+Googleapp.factory
+$power.house
+Enterprize.corp
+Block.hunter
+Block.salesman
+Gemfile.gemfile.

From aeb8d1d5aa3f47f8ed329d4142a3ae432464df54 Mon Sep 17 00:00:00 2001
From: Oscar Gomez <42280574+oscarg933@users.noreply.github.com>
Date: Fri, 9 Nov 2018 09:31:27 -0700
Subject: [PATCH 7/9] Create Oscarg933.github.io

---
 Oscarg933.github.io | 9 +++++++++
 1 file changed, 9 insertions(+)
 create mode 100644 Oscarg933.github.io

diff --git a/Oscarg933.github.io b/Oscarg933.github.io
new file mode 100644
index 0000000..97cb7a0
--- /dev/null
+++ b/Oscarg933.github.io
@@ -0,0 +1,9 @@
+Microsoft.github.io
+Gazebo
+Jenkins.io
+Cronjobs
+.coveralls
+Jira.attlasian
+Circle.ci
+complex.parallels
+template_container_blob.generators

From ba18bb1722097918a4e3b426729efebbe876c856 Mon Sep 17 00:00:00 2001
From: Oscar Gomez <42280574+oscarg933@users.noreply.github.com>
Date: Sat, 10 Nov 2018 06:55:18 -0700
Subject: [PATCH 8/9] Create 365sharepoint.engineer

---
 365sharepoint.engineer | 354 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 354 insertions(+)
 create mode 100644 365sharepoint.engineer

diff --git a/365sharepoint.engineer b/365sharepoint.engineer
new file mode 100644
index 0000000..cc2907e
--- /dev/null
+++ b/365sharepoint.engineer
@@ -0,0 +1,354 @@
+Skip to content
+Office 365 CLI Home	
+#
+##
+###
+Ss
+Search
+ 
+Type to start searching
+Office 365 CLI
+ GitHub
+167 Stars54 Forks
+ 
+Home
+Table of contents
+Installation
+Getting started
+SharePoint Patterns and Practices
+User Guide
+User Guide
+Installing the CLI
+Using the CLI
+Logging in to Office 365
+CLI output mode
+Commands
+Commands
+SharePoint Online (spo)
+SharePoint Online (spo)
+login
+logout
+status
+app
+app
+app add
+app deploy
+app get
+app install
+app list
+app remove
+app retract
+app uninstall
+app upgrade
+cdn
+cdn
+cdn get
+cdn origin add
+cdn origin list
+cdn origin remove
+cdn policy list
+cdn policy set
+cdn set
+contenttype
+contenttype
+contenttype add
+contenttype get
+contenttype field set
+customaction
+customaction
+customaction add
+customaction clear
+customaction get
+customaction list
+customaction remove
+customaction set
+externaluser
+externaluser
+externaluser list
+field
+field
+field add
+field get
+file
+file
+file checkin
+file checkout
+file copy
+file get
+file list
+file remove
+folder
+folder
+folder add
+folder copy
+folder get
+folder list
+folder remove
+folder rename
+hidedefaultthemes
+hidedefaultthemes
+hidedefaultthemes get
+hidedefaultthemes set
+hubsite
+hubsite
+hubsite connect
+hubsite data get
+hubsite disconnect
+hubsite get
+hubsite list
+hubsite register
+hubsite rights grant
+hubsite rights revoke
+hubsite set
+hubsite theme sync
+hubsite unregister
+list
+list
+list add
+list get
+list list
+list remove
+list set
+list webhook get
+list webhook list
+listitem
+listitem
+listitem add
+listitem get
+listitem list
+listitem remove
+listitem set
+navigation
+navigation
+navigation node add
+navigation node list
+navigation node remove
+page
+page
+page add
+page get
+page list
+page remove
+page set
+page clientsidewebpart add
+page column get
+page column list
+page control get
+page control list
+page section add
+page section get
+page section list
+propertybag
+propertybag
+propertybag get
+propertybag list
+propertybag remove
+propertybag set
+serviceprincipal
+serviceprincipal
+serviceprincipal grant list
+serviceprincipal grant revoke
+serviceprincipal permissionrequest approve
+serviceprincipal permissionrequest deny
+serviceprincipal permissionrequest list
+serviceprincipal set
+site
+site
+site add
+site get
+site list
+site set
+site appcatalog add
+site appcatalog remove
+site classic add
+site classic list
+site classic remove
+site classic set
+site o365group set
+sitedesign
+sitedesign
+sitedesign add
+sitedesign apply
+sitedesign get
+sitedesign list
+sitedesign remove
+sitedesign set
+sitedesign rights grant
+sitedesign rights list
+sitedesign rights revoke
+sitescript
+sitescript
+sitescript add
+sitescript get
+sitescript list
+sitescript remove
+sitescript set
+storageentity
+storageentity
+storageentity get
+storageentity list
+storageentity remove
+storageentity set
+tenant
+tenant
+tenant appcatalogurl get
+tenant settings list
+tenant settings set
+term
+term
+term add
+term get
+term list
+term group add
+term group get
+term group list
+term set add
+term set get
+term set list
+theme
+theme
+theme apply
+theme get
+theme list
+theme remove
+theme set
+web
+web
+web add
+web clientsidewebpart list
+web get
+web list
+web remove
+web set
+SharePoint Framework (spfx)
+SharePoint Framework (spfx)
+project
+project
+project upgrade
+Microsoft Graph (graph)
+Microsoft Graph (graph)
+login
+logout
+status
+groupsetting
+groupsetting
+groupsetting add
+groupsetting get
+groupsetting list
+groupsetting remove
+groupsetting set
+groupsettingtemplate
+groupsettingtemplate
+groupsettingtemplate get
+groupsettingtemplate list
+o365group
+o365group
+o365group add
+o365group get
+o365group list
+o365group remove
+o365group restore
+o365group set
+siteclassification
+siteclassification
+siteclassification disable
+siteclassification enable
+siteclassification get
+teams
+teams
+teams list
+teams channel add
+user
+user
+user get
+user list
+user sendmail
+Azure Management Service (azmgmt)
+Azure Management Service (azmgmt)
+login
+logout
+status
+flow
+flow
+flow environment get
+flow environment list
+flow export
+flow get
+flow list
+flow run get
+flow run list
+Azure Active Directory Graph (aad)
+Azure Active Directory Graph (aad)
+login
+logout
+status
+oauth2grant
+oauth2grant
+oauth2grant add
+oauth2grant list
+oauth2grant remove
+oauth2grant set
+service principal (sp)
+service principal (sp)
+sp get
+Concepts
+Concepts
+Persisting connection
+Authorization and access tokens
+Command completion
+Communication with Office 365
+About
+About
+Why this CLI
+Comparison to SharePoint PowerShell
+Release notes
+License
+
+Office 365 CLI¶
+Using the Office 365 CLI, you can manage your Microsoft Office 365 tenant and SharePoint Framework projects on any platform. No matter if you are on Windows, macOS or Linux, using Bash, Cmder or PowerShell, using the Office 365 CLI you can configure Office 365, manage SharePoint Framework projects and build automation scripts.
+
+
+Installation¶
+The Office 365 CLI is distributed as an NPM package. To use it, install it globally using:
+
+
+npm i -g @pnp/office365-cli
+or using yarn:
+
+
+yarn global add @pnp/office365-cli
+Getting started¶
+Start the Office 365 CLI by typing in the command line:
+
+
+$ office365
+
+o365$ _
+Running the office365 command will start the immersive CLI with its own command prompt.
+
+Start managing the settings of your Office 365 tenant by logging in to it, using the spo login <url> site, for example:
+
+
+o365$ spo login https://contoso-admin.sharepoint.com
+Depending on which settings you want to manage you might need to log in either to your tenant admin site (URL with -admin in it), or to a regular SharePoint site. For more information refer to the help of the command you want to use.
+
+To list all available commands, type in the Office 365 CLI prompt help:
+
+
+o365$ help
+To exit the CLI, type exit:
+
+
+o365$ exit
+See the User Guide to learn more about the Office 365 CLI and its capabilities.
+
+SharePoint Patterns and Practices¶
+Office 365 CLI is an open-source project driven by the SharePoint Patterns and Practices initiative. The project is built and managed publicly on GitHub at https://github.com/pnp/office365-cli and accepts community contributions. We would encourage you to try it and tell us what you think. We would also love your help! We have a number of feature requests that are a good starting point to contribute to the project.
+
+“Sharing is caring”
+
+SharePoint PnP team
+
+Next Installing the CLI	
+powered by MkDocs and Material for MkDocs
+  

From eacfa53f2edc0279136a3b04464244022386b92e Mon Sep 17 00:00:00 2001
From: Oscar Gomez <42280574+oscarg933@users.noreply.github.com>
Date: Sat, 10 Nov 2018 07:15:36 -0700
Subject: [PATCH 9/9] Create Ci.bookmarka

---
 Ci.bookmarka | 14 ++++++++++++++
 1 file changed, 14 insertions(+)
 create mode 100644 Ci.bookmarka

diff --git a/Ci.bookmarka b/Ci.bookmarka
new file mode 100644
index 0000000..8928012
--- /dev/null
+++ b/Ci.bookmarka
@@ -0,0 +1,14 @@
+Lbryio.infiite
+self.taught
+Heatmap.crm
+.patch
+Andro100.auto
+Multi platform performance.exe
+Agile.int
+Artempire.ftvangoh
+Starrynight.iot
+
+sounds.arevisible
+Teamwork.mastered
+Peacock.emperor
+Ci
