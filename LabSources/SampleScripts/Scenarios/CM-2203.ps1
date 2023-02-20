<#
Deploy ConfigurationManager in a lab
#>
param
(
    # Lab Name
    [string]
    $LabName = 'cm2203',

    # Hypervisor to use
    [ValidateSet('Azure', 'HyperV')]
    [string]
    $Engine = 'HyperV',

    # Domain FQDn
    [string]
    $DomainName = 'contoso.com',

    # Path to SQL 2019, leave empty to auto-select
    [string]
    $SqlServerIsoPath,

    # Azure region, if used
    [string]
    $AzureRegionDisplayName = 'west europe',

    # Azure subscription name. Leave empty to use current subscription
    [string]
    $AzureSubscriptionName,

    # OS Name, refer to Get-LabAvailableOperatingSystem to select
    [string]
    $OSName = 'Windows Server 2022 Datacenter Evaluation (Desktop Experience)'
)

if ($Engine -eq 'Azure' -and -not $AzureSubscriptionName)
{
    Write-ScreenInfo -Type Warning -Message "No Azure subscription selected. Using '$($(Get-AzContext).Subscription.Name)'"
}

New-LabDefinition -Name $LabName -DefaultVirtualizationEngine $Engine

if ($Engine -eq 'Azure')
{
    Add-LabAzureSubscription -DefaultLocationName $AzureRegionDisplayName -SubscriptionName $AzureSubscriptionName
}

if (-not $SqlServerIsoPath)
{
    $iso = Get-ChildItem -File -Filter *SQL*2019* -Path "$(Get-LabSourcesLocation -Local)\ISOs"
    if (-not $iso)
    {
        Write-Error -Message 'No SQL server ISO available.'
        return
    }

    $SqlServerIsoPath = $iso.Fullname
    
    if ($Engine -eq 'Azure')
    {
        $SqlServerIsoPath = $SqlServerIsoPath.Replace((Get-LabSourcesLocation -Local), $labSources)
    }
}

Add-LabIsoImageDefinition -Path $SqlServerIsoPath -Name SQLServer2019
if ($Engine -eq 'Azure')
{
    Sync-LabAzureLabSources -Filter ([IO.Path]::GetFileName($SqlServerIsoPath)) -Verbose
}

Add-LabDomainDefinition -Name $DomainName -AdminUser install -AdminPassword Somepass1
Set-LabInstallationCredential -Username install -Password Somepass1

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Memory'          = 4GB
    'Add-LabMachineDefinition:OperatingSystem' = $OSName
    'Add-LabMachineDefinition:DomainName'      = $DomainName
}

Add-LabMachineDefinition -Name CMDC01 -Roles RootDC, CaRoot -OperatingSystem 'Windows Server 2022 Datacenter'

$dbRole = Get-LabMachineRoleDefinition -Role SQLServer2019 -Properties @{
    Collation = 'SQL_Latin1_General_CP1_CI_AS'
}
Add-LabMachineDefinition -Name CMDB01 -Roles $dbRole

<#
For possible Syntax, refer to Get-LabMachineRoleDefinition -Role ConfigurationManager -Syntax
Valid CM roles need to be passed as a single (!) comma-separated string in Roles property, for example:
 Get-LabMachineRoleDefinition -Role ConfigurationManager -Properties @{
    Roles = 'Reporting Services Point,Endpoint Protection Point'
}
Valid roles: None,Management Point,Distribution Point,Software Update Point,Reporting Services Point,Endpoint Protection Point
#>
$cmRole = Get-LabMachineRoleDefinition -Role ConfigurationManager -Properties @{
    Version = '2203'
}
Add-LabMachineDefinition -Name CMCM01 -Roles $cmRole

Install-Lab
