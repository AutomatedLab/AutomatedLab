# Azure Stack Hub as the target Azure environment

This sample shows you how to use Azure Stack Hub as a target environment for Azure. This process
was tested using the Azure Stack SDK, and should be applicable to other environments
such as Azure China or Azure US Government. This, however, could not be tested by the AutomatedLab
team.

To successfully use Azure Stack Hub, there are a few prerequisites:
- An Azure Stack Hub to connect to
- Connectivity to the Hub that is being used, for example via VPN
- A subscription!
  - Make sure all relevant resource providers are registered in your subscription - this does *not* happen automatically.
- Verify (or ask your AzS Operator) that the marketplace is populated with Operating System images
- Internet connectivity of your host system in order to download the required modules
  - Validate versions yourself: `Test-LabAzureModuleAvailability -Verbose -AzureStack`
  - Required versions: `Get-LabConfigurationItem -Name RequiredAzStackModules`

```powershell
<#
.SYNOPSIS
    Use Azure Stack Hub as a target for AutomatedLab
.DESCRIPTION
    Requires Azure Stack Hub - deploy an SDK here: https://github.com/Azure-Samples/Azure-Stack-Hub-Foundation-Core/tree/master/Tools/ASDKscripts
    Requires that Azure Stack Hub is registered properly.
    Requires connectivity to your Azure Stack Hub ARM APIs, for example via VPN or ExpressRoute.
      Not sure how? https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-rm-ps
    
    Requires your Operator to have added valid operating systems for use with AutomatedLab!
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

    [Parameter(ParameterSetName = 'AAD')]
    [Parameter(ParameterSetName = 'ADFS')]
    [string]
    $Environment = 'azs',

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

Remove-Module -Name Az.* -Force

if (-not (Test-LabAzureModuleAvailability -AzureStack))
{
    Install-LabAzureRequiredModule -AzureStack
}

if (-not (Test-LabAzureModuleAvailability -AzureStack))
{
    throw "One or more required modules are missing. Please use 'Install-LabAzureRequiredModule -AzureStack' first"
}

if (-not (Get-AzEnvironment -Name $Environment))
{
    $null = Add-AzEnvironment -Name $Environment -ArmEndpoint $ArmEndpointUrl
}

if (-not (Get-AzContext) -or (Get-AzContext).Environment.Name -ne $Environment)
{
    if ($PSCmdlet.ParameterSetName -eq 'AAD')
    {
        $AuthEndpoint = (Get-AzEnvironment -Name $Environment).ActiveDirectoryAuthority
        $TenantId = (Invoke-RestMethod "$($AuthEndpoint)$($AADTenantName)/.well-known/openid-configuration").issuer.TrimEnd('/').Split('/')[-1]
        $null = Connect-AzAccount -EnvironmentName $Environment -TenantId $TenantId
    }
    else
    {
        $null = Connect-AzAccount -EnvironmentName $Environment
    }
}

Write-ScreenInfo -Type Info -Message "Azure Stack environment $Environment connected and ready to go. Deploying sample lab."

New-LabDefinition -Name AzSLab -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -SubscriptionName $SubscriptionName -DefaultLocationName $Location -Environment $Environment -AzureStack

$os = Get-LabAvailableOperatingSystem -UseOnlyCache -Azure -Location $Location | Select-Object -First 1

Add-LabMachineDefinition -Name ALDCOnAzS -Memory 4GB -Role RootDC -DomainName contoso.com -OperatingSystem $os.OperatingSystemName
Add-LabMachineDefinition -Name ALWBOnAzS -Memory 4GB -DomainName contoso.com -OperatingSystem $os.OperatingSystemName

Install-Lab

Show-LabDeploymentSummary -Detailed
```
