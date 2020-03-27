$labName = 'ADRES<SOME UNIQUE DATA>' #THIS NAME MUST BE GLOBALLY UNIQUE

$azureDefaultLocation = 'West Europe' #COMMENT OUT -DefaultLocationName BELOW TO USE THE FASTEST LOCATION

#setting addMemberServer to $true installes an additional server in the lab
$addMemberServer = $false

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -DefaultLocationName $azureDefaultLocation

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.41.0/24

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1
Add-LabDomainDefinition -Name child.contoso.com -AdminUser Install -AdminPassword Somepass1

#these credentials are used for connecting to the machines. As this is a lab we use clear-text passwords
$installationCredential = New-Object PSCredential('Install', ('Somepass1' | ConvertTo-SecureString -AsPlainText -Force))

#Backup disks
Add-LabDiskDefinition -Name BackupRoot -DiskSizeInGb 40
Add-LabDiskDefinition -Name BackupChild -DiskSizeInGb 40

#Set the parameters that are the same for all machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath' = "$labSources\Tools"
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:Processors' = 2
    'Add-LabMachineDefinition:Memory' = 768MB
    'Add-LabMachineDefinition:InstallationUserCredential' = $installationCredential
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:DnsServer1' = '192.168.41.10'
    'Add-LabMachineDefinition:DnsServer2' = '192.168.41.11'
}

#Defining contoso.com machines
Add-LabMachineDefinition -Name ContosoDC1 -IpAddress 192.168.41.10 -DomainName contoso.com -Roles RootDC

Add-LabMachineDefinition -Name ContosoDC2 -DiskName BackupRoot -IpAddress 192.168.41.11 -DomainName contoso.com  -Roles DC

if ($addMemberServer)
{
    Add-LabMachineDefinition -Name ContosoMember1 -IpAddress 192.168.41.12 -DomainName contoso.com
}

#Defining child.contoso.com machines
$role = Get-LabMachineRoleDefinition -Role FirstChildDC -Properties @{ ParentDomain = 'contoso.com'; NewDomain = 'child' }
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
Add-LabMachineDefinition -Name ChildDC1 -IpAddress 192.168.41.20 -DomainName child.contoso.com -Roles $role -PostInstallationActivity $postInstallActivity

Add-LabMachineDefinition -Name ChildDC2 -DiskName BackupChild -IpAddress 192.168.41.21 -DomainName child.contoso.com  -Roles DC

#Now the actual work begins
Install-Lab

#Installs RSAT on ContosoMember1 if the optional machine is part of the lab
if (Get-LabVM -ComputerName ContosoMember1 -ErrorAction SilentlyContinue)
{
    Install-LabWindowsFeature -ComputerName ContosoMember1 -FeatureName RSAT
}

#Install the Windows-Server-Backup feature on all DCs
Install-LabWindowsFeature -ComputerName (Get-LabVM | Where-Object { $_.Disks }) -FeatureName Windows-Server-Backup

#Install software to all lab machines
$machines = Get-LabVM
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Winrar.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Invoke-LabCommand -ActivityName ADReplicationTopology -ComputerName (Get-LabVM -Role RootDC) -ScriptBlock {
    $rootDc = Get-ADDomainController -Discover
    $childDc = Get-ADDomainController -DomainName child.contoso.com -Discover

    $siteDataCenter = New-ADReplicationSite -Name Datacenter -Server $rootDc -PassThru
    $siteDR = New-ADReplicationSite -Name DR -Server $rootDc -PassThru

    Get-ADDomainController -Filter 'Name -like "*DC1"' | Move-ADDirectoryServer -Site $siteDataCenter -Server $rootDc
    Get-ADDomainController -Filter 'Name -like "*DC2"' | Move-ADDirectoryServer -Site $siteDR -Server $rootDc

    Get-ADDomainController -Filter 'Name -like "*DC1"' -Server $childDc | Move-ADDirectoryServer -Site $siteDataCenter -Server $rootDc
    Get-ADDomainController -Filter 'Name -like "*DC2"' -Server $childDc | Move-ADDirectoryServer -Site $siteDR -Server $rootDc

    New-ADReplicationSiteLink -Name 'Datacenter - DR' -Cost 100 -ReplicationFrequencyInMinutes 15 -SitesIncluded $siteDataCenter, $siteDR -OtherAttributes @{ options = 1 } -Server $rootDc

    Remove-ADReplicationSiteLink -Identity 'DEFAULTIPSITELINK' -Confirm:$false -Server $rootDc
    Remove-ADReplicationSite -Identity 'Default-First-Site-Name' -Confirm:$false -Server $rootDc
}

Sync-LabActiveDirectory -ComputerName (Get-LabVM -Role RootDC)

Stop-LabVM -All -Wait

Show-LabDeploymentSummary -Detailed