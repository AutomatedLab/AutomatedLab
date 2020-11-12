#region Add-LabAzureWebAppDefinition
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
#endregion Add-LabAzureWebAppDefinition

#region Get-LabAzureWebAppDefinition
function Get-LabAzureWebAppDefinition
{


    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([AutomatedLab.Azure.AzureRmService])]

        param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )

    begin
    {
        Write-LogFunctionEntry

        $script:lab = & $MyInvocation.MyCommand.Module { $script:lab }

        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $lab.AzureResources.Services
            break
        }
    }

    process
    {
        $sp = $lab.AzureResources.Services | Where-Object Name -eq $Name

        if (-not $sp)
        {
            Write-Error "The Azure App Service '$Name' does not exist."
        }
        else
        {
            $sp
        }
    }

    end
    {
        Write-LogFunctionExit
    }
}
#endregion Get-LabAzureWebAppDefinition

#region Add-LabAzureAppServicePlanDefinition
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
#endregion Add-LabAzureAppServicePlanDefinition

#region Get-LabAzureAppServicePlanDefinition
function Get-LabAzureAppServicePlanDefinition
{


    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([AutomatedLab.Azure.AzureRmServerFarmWithRichSku])]

        param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )

    begin
    {
        Write-LogFunctionEntry

        $script:lab = & $MyInvocation.MyCommand.Module { $script:lab }

        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $lab.AzureResources.ServicePlans
            break
        }
    }

    process
    {
        $sp = $lab.AzureResources.ServicePlans | Where-Object Name -eq $Name

        if (-not $sp)
        {
            Write-Error "The Azure App Service Plan '$Name' does not exist."
        }
        else
        {
            $sp
        }
    }

    end
    {
        Write-LogFunctionExit
    }
}
#endregion Get-LabAzureAppServicePlanDefinition
