$labName = 'DSCLab1'

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------

$labSources = Get-LabSourcesLocation

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.135.0/24
Add-LabVirtualNetworkDefinition -Name Internet -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name contoso.com -AdminUser install -AdminPassword Somepass1

#these credentials are used for connecting to the machines. As this is a lab we use clear-text passwords
Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:IsDomainJoined' = $true
    'Add-LabMachineDefinition:Memory' = 1GB
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2012 R2 SERVERDATACENTER'
}

#The PostInstallationActivity is just creating some users
$postInstallActivity = @()
#$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name DDC1 -Roles RootDC -IpAddress 192.168.135.10 -PostInstallationActivity $postInstallActivity

#file server and router
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.135.50
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch Internet -UseDhcp
Add-LabMachineDefinition -Name DRouter -Roles FileServer, Routing -NetworkAdapter $netAdapter

#CA
Add-LabMachineDefinition -Name DCA1 -Roles CaRoot

#DSC Pull Server
Add-LabMachineDefinition -Name DPull1 -Roles DSCPullServer

#DSC Pull Clients
Add-LabMachineDefinition -Name DServer1
Add-LabMachineDefinition -Name DServer2

Install-Lab

#Install software to all lab machines
$machines = Get-LabMachine
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\ClassicShell.exe -CommandLine '/quiet ADDLOCAL=ClassicStartMenu' -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Install-LabWindowsFeature -ComputerName (Get-LabMachine) -FeatureName RSAT -IncludeAllSubFeature -AsJob -PassThru | Wait-Job | Out-Null

#Setup DSC Pull Clients
$pullServers = Get-LabMachine -Role DSCPullServer
#Clients are all lab machines except DCs and the pull servers itself
$pullClients = Get-LabMachine | Where-Object { $_.Roles.Name -notin 'DC', 'RootDC', 'FirstChildDC' -and $_.Name -ne $pullServers.Name }

#region Setup Dsc Pull Client
Copy-LabFileItem -Path $labSources\PostInstallationActivities\SetupDscClients\SetupDscClients.ps1 -ComputerName $pullClients

Invoke-LabCommand -ActivityName 'Setup DSC Pull Clients' -ComputerName $pullClients -ScriptBlock {
    param  
    (
        [Parameter(Mandatory)]
        [string[]]$PullServer,

        [Parameter(Mandatory)]
        [string[]]$RegistrationKey
    )
    
    C:\SetupDscClients.ps1 -PullServer $PullServer -RegistrationKey $RegistrationKey
} -ArgumentList $pullServers, $pullServers.Notes.DscRegistrationKey -PassThru -ThrottleLimit 1 #increasing the ThrottleLimit results in errors

Show-LabInstallationTime