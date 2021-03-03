# Scenarios - AGPM Lab 1

INSERT TEXT HERE

```powershell
#Lab for working with the Advanced Group Policy Manaement Console (AGMP)
#The following files are required:
# - agpm_403_server_amd64.exe
# - agpm_403_client_amd64.exe
# - agpm4.0-Server-KB3127165-x64.exe

New-LabDefinition -Name AgpmLab10 -DefaultVirtualizationEngine HyperV #Azure

#Add-LabAzureSubscription -SubscriptionName AL1 -DefaultLocationName 'West Europe'

Add-LabMachineDefinition -Name a1DC -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles RootDC -DomainName contoso.com
Add-LabMachineDefinition -Name a1Server -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com
Add-LabMachineDefinition -Name a1AgpmServer -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com

Install-Lab

$agpmServer = Get-LabVM -ComputerName a1AgpmServer
$agpmClient = Get-LabVM -ComputerName a1Server
Install-LabWindowsFeature -ComputerName $agpmServer -FeatureName NET-Framework-Core, NET-Non-HTTP-Activ, GPMC, RSAT-AD-Tools
Install-LabWindowsFeature -ComputerName $agpmClient -FeatureName NET-Non-HTTP-Activ, GPMC, RSAT-AD-Tools

$machines = Get-LabVM
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Checkpoint-LabVM -All -SnapshotName 1

if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
{
    Write-ScreenInfo 'Waiting 15 minutes to make sure the VMs are ready after having created a snapshot...' -NoNewLine
    Start-Sleep -Seconds 1000
    Write-ScreenInfo 'done.'
}

$agpmSettings = @{
    InstallationLog = 'C:\AGPM-Install.log'
    OwnerGroupName = 'AgpmOwners'
    ServiceAccountName = 'AgpmService'
    UsersGroupName = 'AgpmUsers'
    DomainName = $agpmServer.DomainName.Split('.')[0] #NetBIOS name is required
    PasswordPlain = 'Password1'
    Password = 'Password1' | ConvertTo-SecureString -AsPlainText -Force
}

Invoke-LabCommand -ComputerName (Get-LabVM -Role RootDC) -ScriptBlock {

    $ou = New-ADOrganizationalUnit -Name AGPM -ProtectedFromAccidentalDeletion $false -PassThru

    $service = New-ADUser -Name AgpmService -Path $ou -AccountPassword $agpmSettings.Password -Enabled $true -PassThru
    Add-ADGroupMember -Identity 'Group Policy Creator Owners' -Members $service

    New-ADGroup -Name $agpmSettings.OwnerGroupName -GroupScope Global -Path $ou -PassThru | Add-ADGroupMember -Members (Get-ADUser -Identity $env:USERNAME)

    $users = @()
    $users += New-ADUser -Name AgpmUser1 -Path $ou -AccountPassword $agpmSettings.Password -Enabled $true -PassThru
    $users += New-ADUser -Name AgpmUser2 -Path $ou -AccountPassword $agpmSettings.Password -Enabled $true -PassThru
    $group = New-ADGroup -Name $agpmSettings.UsersGroupName -Path $ou -GroupScope Global -PassThru | Add-ADGroupMember -Members $users

} -Variable (Get-Variable -Name agpmSettings)

#Installation of AGPM Server
$agpmCommandLineArgs = '/quiet /log {0} /msicl "VAULT_OWNER={1} SVC_USERNAME={2} SVC_PASSWORD={3} USERRUNASSERVICE={2} DSN={1} ADD_PORT_EXCEPTION=0 BRAZILIAN_PT=0 CHINESE_S=0 CHINESE_T=0 ENGLISH=1 FRENCH=0 GERMAN=0 ITALIAN=0 JAPANESE=0 KOREAN=0 RUSSIAN=0 SPANISH=0"' -f
    $agpmSettings.InstallationLog,
    ('{0}\{1}' -f $agpmSettings.DomainName, $agpmSettings.OwnerGroupName),
    ('{0}\{1}' -f $agpmSettings.DomainName, $agpmSettings.ServiceAccountName),
    $agpmSettings.PasswordPlain
Install-LabSoftwarePackage -Path $labSources\SoftwarePackages\agpm_403_server_amd64.exe -CommandLine $agpmCommandLineArgs -ComputerName $agpmServer -AsScheduledJob -UseExplicitCredentialsForScheduledJob

#Installation of AGPM Client
$agpmCommandLineArgs = '/quiet /msicl "PORT=4600 ARCHIVELOCATION={0} ADD_PORT_EXCEPTION=1 BRAZILIAN_PT=0 CHINESE_S=0 CHINESE_T=0 ENGLISH=1 FRENCH=0 GERMAN=0 ITALIAN=0 JAPANESE=0 KOREAN=0 RUSSIAN=0 SPANISH=0"' -f $agpmServer.FQDN
Install-LabSoftwarePackage -Path $labSources\SoftwarePackages\agpm_403_client_amd64.exe -CommandLine $agpmCommandLineArgs -ComputerName $agpmServer, $agpmClient

Install-LabSoftwarePackage -Path $labSources\SoftwarePackages\agpm4.0-Server-KB3127165-x64.exe -CommandLine /quiet -ComputerName $agpmServer

Invoke-LabCommand -ActivityName 'Correcting ACL' -ComputerName $agpmServer -ScriptBlock {

    Get-Acl -Path (Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\AGPM') | ForEach-Object {
        $sid = (Get-ADUser -Identity $agpmSettings.ServiceAccountName -Properties SID).SID
        $_.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(($sid, 'Modify', 'ContainerInherit, ObjectInherit', 'None', 'Allow'))))
        Set-Acl -Path (Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\AGPM') -AclObject $_

    }
} -Variable (Get-Variable -Name agpmSettings)

Invoke-LabCommand -ActivityName 'Give the AgpmUsers local admin rights on the AgpmClient' -ScriptBlock {

    Add-LocalGroupMember -Group Administrators -Member "contoso\$($agpmSettings.UsersGroupName)"

} -ComputerName $agpmClient -Variable (Get-Variable -Name agpmSettings)

Checkpoint-LabVM -All -SnapshotName 2

Show-LabDeploymentSummary -Detailed
```
