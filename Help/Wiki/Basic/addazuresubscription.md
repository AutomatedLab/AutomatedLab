Generally speaking AutomatedLab takes care of everything for you when deploying your labs on Azure. Since additional authentication is required it is possible that you need to login to your Azure account before using AutomatedLab.  
AutomatedLab works with Azure Resource Manager, so you can either execute the cmdlet `Connect-AzAccount` before deploying your lab or save your Azure Resource Manager profile.

## Azure

If you choose to login to your Azure account before a lab deployment, your profile is being saved for you to be able to import the lab at a later stage. Since it is possible that your profile expires you might see an error message indicating your profile expiration. In that case, simply login to your Azure account again.

```powershell
New-LabDefinition -Name 'MyLab' -DefaultVirtualizationEngine Azure

# Optional to set e.g. your preferred location
Add-LabAzureSubscription -DefaultLocation 'West Europe'
```

> **Warning**
> Please use VM sizes with a decent number of IOPS! If you opt not to do this,
> you will notice your deployments running into errors, timeouts and the like.

This will enable AutomatedLab to create a lab sources resource group for you as well as a separate resource group for each lab you deploy. Your lab resource group will contain the entire lab deployment and will be removed when you call `Remove-Lab`.

## Azure Stack Hub

To be able to target Azure Stack Hub with its special set of APIs, there is a bit more to do before deploying labs.

To successfully use Azure Stack Hub, there are a few prerequisites:
- A properly configured and registered Azure Stack Hub to connect to!
  - Deploy an SDK here: https://github.com/Azure-Samples/Azure-Stack-Hub-Foundation-Core/tree/master/Tools/ASDKscripts
- Connectivity to the Hub that is being used, for example via VPN
  - Using an SDK and Bastion is too expensive? Try a VPN: https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-rm-ps
- A subscription on Azure Stack Hub!
  - Make sure all relevant resource providers (Compute, Network, Storage, ...) are registered in your subscription - this does *not* happen automatically.
  - Make sure that your lab does not exceed the quota set by your AzS Hub Operator
- Verify (or ask your AzS Operator) that the marketplace is populated with Operating System images compatible with AutomatedLab (i.e. Windows Server, SQL Server)
- Internet connectivity of your host system in order to download the required modules
  - Validate versions yourself: `Test-LabAzureModuleAvailability -Verbose -AzureStack`
  - Required versions: `Get-LabConfigurationItem -Name RequiredAzStackModules`

First of all, ensure that the prehistoric module versions required for Azure Stack Hub are installed:

```powershell
Remove-Module -Name Az.* -Force

if (-not (Test-LabAzureModuleAvailability -AzureStack))
{
    Install-LabAzureRequiredModule -AzureStack
}

if (-not (Test-LabAzureModuleAvailability -AzureStack))
{
    throw "One or more required modules are missing. Please use 'Install-LabAzureRequiredModule -AzureStack' first"
}
```

In addition to very specific PowerShell module versions, the connection to Azure Stack requires you to connect to your
environment.
```powershell
$Environment = 'azs'
$ArmEndpointUrl = 'https://management.local.azurestack.external' # Use your own!
$AzureAd = $true # If using ADFS -> $false
$AADTenantName = 'YourTenantName.onmicrosoft.com' # Use your own!

if (-not (Get-AzEnvironment -Name $Environment))
{
    $null = Add-AzEnvironment -Name $Environment -ArmEndpoint $ArmEndpointUrl
}

if (-not (Get-AzContext) -or (Get-AzContext).Environment.Name -ne $Environment)
{
    if ($AzureAd)
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
```

Lastly, in your lab script, make sure that you use the correct location and environment, as well as the `AzureStack` parameter.



```powershell
New-LabDefinition -Name AzSLab -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -DefaultLocationName local -Environment $Environment -AzureStack
```