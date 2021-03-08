# Scenarios - WindowsAdminCenter-OnPrem

This sample script extends the WindowsAdminCenter sample
by onboarding your lab nodes to an existing WAC deployment.

This could be an existing server like WACWAC2 in this example,
or it could be a local deployment, for which we use localhost
as the lab machine name. Both existing deployments are taken
care of using the SkipDeployment parameter, which means that
no new VM is deployment and no alterations are made apart from
the onboarding of new nodes in this case.

```powershell
$labName = 'WACLab'
$domainName = 'contoso.com'

New-LabDefinition -Name $labname -DefaultVirtualizationEngine HyperV

Add-LabDomainDefinition -Name $domainName -AdminUser Install -AdminPassword Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter'
}

# Domain
$postInstallActivity = @()
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name WACDC1 -Memory 1GB -Roles RootDC -PostInstallationActivity $postInstallActivity

# CA
Add-LabMachineDefinition -Name WACCA1 -Memory 1GB -Roles CARoot

# WAC Server in lab
$role = Get-LabMachineRoleDefinition -Role WindowsAdminCenter <#-Properties @{
    # Optional, defaults to 443
    Port = 8080
    # Optional, indicates that the developer mode should be enabled, i.e. to develop extensions
    EnableDevMode   = 'True'
    # Optional, defaults to all lab VMs except the WAC host. Needs to be JSON string!
    ConnectedNode = '["WACHO1","WACHO3"]'
}#>
Add-LabMachineDefinition -Name WACWAC1 -Memory 1GB -Roles $role

# WAC server on-prem -SkipDeployment means it is not removed when the lab is removed, but we will connect other Lab VMs to it
$role = Get-LabMachineRoleDefinition -Role WindowsAdminCenter -Properties @{
    Port = '4711'
    UseSsl = 'False'
    ConnectedNode = '["WACHO1","WACHO3"]'
}
$instCred = [pscredential]::new('fabrikam\OtherUser' , ('Other Password' | ConvertTo-SecureString -AsPlain -Force)
Add-LabMachineDefinition -Name WACWAC2.fabrikam.com -SkipDeployment -Roles $role -InstallationUserCredential $instCred

# or to connect to your local installation
$role = Get-LabMachineRoleDefinition -Role WindowsAdminCenter -Properties @{
    Port = '6516'
    UseSsl = 'False'
    ConnectedNode = '["WACHO1","WACHO3"]'
}
$instCred = Get-Credential -UserName $env:USERNAME
Add-LabMachineDefinition -Name localhost -SkipDeployment -Roles $role -InstallationUserCredential $instCred

# Some managed hosts
foreach ($i in 1..4)
{
    Add-LabMachineDefinition -Name WACHO$i -Memory 1GB
}

Install-Lab

Show-LabDeploymentSummary

```
