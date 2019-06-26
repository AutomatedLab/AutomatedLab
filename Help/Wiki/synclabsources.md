While creating an Azure-based lab is very easy and only requires to set the default virtualization engine to Azure instead of HyperV not all features are readily available from the start. To fully make use of Azure, you should also synch your lab sources with Azure.  
Doing so only requires a single line of code:  
`
Sync-LabAzureLabSources
`

This by default will synchronize your entire local lab sources folder with a pre-created Azure file share called labsources in the resource group AutomatedLabSources and the lab's randomly-named storage account. This file share will automatically be mapped on each virtual machine.  
Operating system images are automatically skipped in the synchronization process as they are readily available on Azure and are not being used.

During the lab initialization the builtin variable $labsources will be automatically updated to point to your Azure lab sources location if you are deploying an Azure-based lab. There is no need to declare the variable in any script, as it is dynamically calculated to match the default virtualization engine.

To skip large files or entire ISOs for certain products like e.g. Exchange or Skype for Business the following parameters are available:
* SkipIsos: This switch parameter indicates that all ISO files should be skipped.
* MaxFileSizeInMb: This parameter takes an integer value indicating the maximum size of the files to synch.

Now you can simply use the other cmdlets provided by AutomatedLab to access files from the file share:  
* `$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain`
* `Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob`