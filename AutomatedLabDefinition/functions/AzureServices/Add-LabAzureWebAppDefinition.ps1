function Add-LabAzureWebAppDefinition
{


    [CmdletBinding()]
    [OutputType([AutomatedLab.Azure.AzureRmService])]
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$ResourceGroup,

        [string]$Location,

        [string]$AppServicePlan,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $script:lab = & $MyInvocation.MyCommand.Module { $script:lab }

    if ($Script:lab.AzureResources.Services | Where-Object Name -eq $Name)
    {
        Write-Error "There is already a Azure Web App with the name $'$Name'"
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
    if (-not $AppServicePlan)
    {
        $AppServicePlan = $Name
    }

    if (-not ($lab.AzureResources.ServicePlans | Where-Object Name -eq $AppServicePlan))
    {
        Write-ScreenInfo "The Azure Application Service plan '$AppServicePlan' does not exist, creating it with default settings."
        Add-LabAzureAppServicePlanDefinition -Name $Name -ResourceGroup $ResourceGroup -Location $Location -Tier Free -WorkerSize Small
    }

    $webApp = New-Object AutomatedLab.Azure.AzureRmService
    $webApp.Name = $Name
    $webApp.ResourceGroup = $ResourceGroup
    $webApp.Location = $Location
    $webApp.ApplicationServicePlan = $AppServicePlan

    $Script:lab.AzureResources.Services.Add($webApp)

    Write-LogFunctionExit
}
