function Add-LabAzureAppServicePlanDefinition
{


    [CmdletBinding()]
    [OutputType([AutomatedLab.Azure.AzureRmService])]
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$ResourceGroup,

        [string]$Location,

        [ValidateSet('Basic', 'Free', 'Premium', 'Shared', 'Standard')]
        [string]$Tier = 'Free',

        [ValidateSet('ExtraLarge', 'Large', 'Medium', 'Small')]
        [string]$WorkerSize = 'Small',

        [int]$NumberofWorkers,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $script:lab = & $MyInvocation.MyCommand.Module { $script:lab }

    if ($Script:lab.AzureResources.ServicePlans | Where-Object Name -eq $Name)
    {
        Write-Error "There is already an Azure App Service Plan with the name $'$Name'"
        return
    }

    if (-not $ResourceGroup)
    {
        $ResourceGroup = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
    }
    if (-not $Location)
    {
        $Location = $lab.AzureSettings.DefaultLocation.DisplayName
    }

    $servicePlan = New-Object AutomatedLab.Azure.AzureRmServerFarmWithRichSku
    $servicePlan.Name = $Name
    $servicePlan.ResourceGroup = $ResourceGroup
    $servicePlan.Location = $Location
    $servicePlan.Tier = $Tier
    $servicePlan.WorkerSize = $WorkerSize
    $servicePlan.NumberofWorkers = $NumberofWorkers

    $Script:lab.AzureResources.ServicePlans.Add($servicePlan)

    Write-LogFunctionExit
}
