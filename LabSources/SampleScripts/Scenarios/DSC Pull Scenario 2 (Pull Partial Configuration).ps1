<#
This scenario demos a DSC pull server confuguration using 3 pull servers. Each pull server publishes a configuration and the clients are
pulling the configurations from all three servers (see "partial configuration').

The lab must have an internet connection in order to download additional required bits. PowerShell 5.0
or greater is required on all DSC pull servers or clients. Please take a look at introduction script '10 ISO Offline Patching.ps1' if you
want to create a Windows Server 2012 base image with PowerShell 5.

After the first a domain controller is setup, AutomatedLab (AL) configures the routing, two web servers and the CA. This scenario demos
multiple DSC pull servers that is encrypting the network communication using SSL. For this AL creates a new certificate template
(DSC Pull Server SSL. The DSC pull server requests a certificate using this template and configures DSC accordingly.

AL also creates a default DSC configuration that creates a test file on each DSC client. The name of the file is TestFile_<PullServer>.
The pull server the configuration is coming from is part of the file name as a client can have multiple pull servers (partial configuraion).
#>
$labName = 'DSCLab2'

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------


#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name contoso.com -AdminUser install -AdminPassword Somepass1

#these credentials are used for connecting to the machines. As this is a lab we use clear-text passwords
Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:Memory' = 768MB
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2012 R2 Datacenter (Server with a GUI)'
}

$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name DDC1 -Roles RootDC -PostInstallationActivity $postInstallActivity

#file server and router
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name DRouter -Roles FileServer, Routing -NetworkAdapter $netAdapter

#CA
Add-LabMachineDefinition -Name DCA1 -Roles CaRoot

#DSC Pull Servers
Add-LabMachineDefinition -Name DPull1 -Roles DSCPullServer
Add-LabMachineDefinition -Name DPull2 -Roles DSCPullServer
Add-LabMachineDefinition -Name DPull3 -Roles DSCPullServer

#Web Servers
Add-LabMachineDefinition -Name DWeb1 -Roles WebServer
Add-LabMachineDefinition -Name DWeb2 -Roles WebServer

Add-LabMachineDefinition -Name DServer1
Add-LabMachineDefinition -Name DServer2
Add-LabMachineDefinition -Name DServer3

Install-Lab

#Install software to all lab machines
$machines = Get-LabVM
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Install-LabDscClient -All

Show-LabDeploymentSummary -Detailed