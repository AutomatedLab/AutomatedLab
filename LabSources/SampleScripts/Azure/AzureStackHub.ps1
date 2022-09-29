<#
.SYNOPSIS
    Use Azure Stack Hub as a target for AutomatedLab
.DESCRIPTION
    Requires Azure Stack Hub - deploy an SDK here: https://github.com/Azure-Samples/Azure-Stack-Hub-Foundation-Core/tree/master/Tools/ASDKscripts
    Requires that Azure Stack Hub is registered properly.
    Requires connectivity to your Azure Stack Hub ARM APIs, for example via VPN or ExpressRoute.
    Not sure how? https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-rm-ps
    Installs very ancient Azure module versions to interact.

    Simple sample lab is deployed: 1 Root Domain Controller and 1 Member server
.EXAMPLE
    ./AzureStackHub.ps1 -SubscriptionName MySub -AadTenantName MyTenant.onmicrosoft.com

    Deploy sample lab to AAD-connected Stack Hub SDK, using the subscription called MySub
#>
[CmdletBinding(DefaultParameterSetName = 'AAD')]
param
(
    # Azure Stack assigned subscription. Get one from your AzS Hub Operator!
    [Parameter(Mandatory = $true, ParameterSetName = 'AAD')]
    [Parameter(Mandatory = $true, ParameterSetName = 'ADFS')]
    [string]
    $SubscriptionName,

    # Azure Stack region. ASDK defaults to local
    [Parameter(ParameterSetName = 'AAD')]
    [Parameter(ParameterSetName = 'ADFS')]
    [string]
    $Location = 'local',

    # Management enpoint URL - Default set for ASDK, for actual Hubs ask your vendor.
    [Parameter(ParameterSetName = 'AAD')]
    [Parameter(ParameterSetName = 'ADFS')]
    [string]
    $ArmEndpointUrl = 'https://management.local.azurestack.external',

    # Format for example TenantName.onmicrosoft.com
    [Parameter(Mandatory = $true, ParameterSetName = 'AAD')]
    [string]
    $AadTenantName,
  
    # Indicates that Active Directory Federation Services should be used instead of Azure Active Directory
    [Parameter(ParameterSetName = 'ADFS')]
    [Parameter()]
    [switch] $UseAdfs
)

Test-LabAzureModuleAvailability -AzureStack -ErrorAction Stop

if (-not (Get-AzEnvironment -Name AzureStackUser))
{
    $null = Add-AzEnvironment -Name AzureStackUser -ArmEndpoint $ArmEndpointUrl
}

if ($PSCmdlet.ParameterSetName -eq 'AAD')
{
    $AuthEndpoint = (Get-AzEnvironment -Name AzureStackUser).ActiveDirectoryAuthority
    $TenantId = (Invoke-RestMethod "$($AuthEndpoint)$($AADTenantName)/.well-known/openid-configuration").issuer.TrimEnd('/').Split('/')[-1]
    $null = Connect-AzAccount -EnvironmentName AzureStackUser -TenantId $TenantId
}
else
{
    $null = Connect-AzAccount -EnvironmentName AzureStackUser
}

Write-ScreenInfo -Type Info -Message "Azure Stack environment connected and ready to go. Deploying sample lab."

New-LabDefinition -Name AzSLab -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -SubscriptionName $SubscriptionName -DefaultLocationName $Location

Add-LabMachineDefinition -Name ALDCOnAzS -Memory 4GB -Role RootDC -DomainName contoso.com
Add-LabMachineDefinition -Name ALWBOnAzS -Memory 4GB -DomainName contoso.com

Install-Lab

Show-LabDeploymentSummary -Detailed
