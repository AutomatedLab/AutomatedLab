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

# WAC Server
$role = Get-LabMachineRoleDefinition -Role WindowsAdminCenter <#-Properties @{
    # Optional, defaults to 443
    Port = 8080
    # Optional, indicates that the developer mode should be enabled, i.e. to develop extensions
    EnableDevMode   = 'True'
    # Optional, defaults to all lab VMs except the WAC host. Needs to be JSON string!
    ConnectedNode = '["WACHO1","WACHO3"]'
}#>
Add-LabMachineDefinition -Name WACWAC1 -Memory 1GB -Roles $role

# Some managed hosts
foreach ($i in 1..4)
{
    Add-LabMachineDefinition -Name WACHO$i -Memory 1GB
}

Install-Lab

Show-LabDeploymentSummary
