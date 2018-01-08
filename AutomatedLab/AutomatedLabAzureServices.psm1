function Install-LabAzureServices
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding()]
    param ()
    
    Write-LogFunctionEntry
    $lab = Get-Lab

    if (-not $lab)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    Write-ScreenInfo -Message "Starting Azure Services Deplyment"
    
    $services = Get-LabAzureWebApp
    
    if (-not $services)
    {
        Write-ScreenInfo "No Azure service defined, exiting."
        Write-LogFunctionExit
        break
    }
    
    Write-ScreenInfo "There are $($services.Count) Azure services defined."
    
        
}

#region New-LabAzureAppServicePlan
function New-LabAzureAppServicePlan
{
    # .ExternalHelp AutomatedLab.Help.xml
    
    [OutputType([AutomatedLab.Azure.AzureRmService])]
    
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        
        [switch]$PassThru
    )
    
    begin
    {
        Write-LogFunctionEntry
        
        $script:lab = & $MyInvocation.MyCommand.Module { $script:lab }
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
    }

    process
    {
        foreach ($planName in $Name)
        {

            $plan = Get-LabAzureWebApp -Name $planName
            
            if (-not (Get-LabAzureResourceGroup -ResourceGroupName $plan.ResourceGroup))
            {
                New-LabAzureRmResourceGroup -ResourceGroupNames $plan.ResourceGroup -LocationName $plan.Location
            }
            
            if ((Get-AzureRmWebApp -Name $plan.Name -ResourceGroupName $plan.ResourceGroup))
            {
                Write-Error "The Azure Application Service Plan '$planName' does already exist in $($plan.ResourceGroup)"
                return
                
            }

            New-AzureRmAppServicePlan -Name $plan.Name -Location $plan.Location -ResourceGroupName $plan.ResourceGroup -Tier $plan.Tier -NumberofWorkers $plan.NumberofWorkers -WorkerSize $plan.WorkerSize
            $plan = Get-AzureRmAppServicePlan -Name $plan.Name -ResourceGroupName $plan.ResourceGroup
            $plan = [AutomatedLab.Azure.AzureRmServerFarmWithRichSku]::Create($plan)
            
            Remove-LabAzureAppServicePlan -Name $plan.Name -ErrorAction SilentlyContinue
            $lab.AzureResources.ServicePlans.Add($plan)
            
            if ($PassThru)
            {
                $webApp
            }
        }
    
        end
        {
            Write-LogFunctionExit
        }
    }
}
#endregion New-LabAzureAppServicePlan

#region New-LabAzureWebApp
function New-LabAzureWebApp
{
    # .ExternalHelp AutomatedLab.Help.xml
    
    [OutputType([AutomatedLab.Azure.AzureRmService])]
    
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        
        [switch]$PassThru
    )
    
    begin
    {
        Write-LogFunctionEntry
        
        $script:lab = & $MyInvocation.MyCommand.Module { $script:lab }
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
    }

    process
    {
        foreach ($serviceName in $Name)
        {

            $app = Get-LabAzureWebApp -Name $serviceName
            
            if (-not (Get-LabAzureResourceGroup -ResourceGroupName $app.ResourceGroup))
            {
                New-LabAzureRmResourceGroup -ResourceGroupNames $app.ResourceGroup -LocationName $app.Location
            }
            
            if (-not (Get-LabAzureAppServicePlan -Name $app.ApplicationServicePlan))
            {
                New-LabAzureAppServicePlan -Name $app.ApplicationServicePlan
            }

            New-AzureRmWebApp -Name $app.Name -Location $app.Location -AppServicePlan $app.Name -ResourceGroupName $app.ResourceGroup
            $webApp = Get-AzureRmWebApp -Name $app.Name -ResourceGroupName $app.ResourceGroup
            $webApp = [AutomatedLab.Azure.AzureRmService]::Create($webApp)
            
            Remove-LabAzureWebApp -Name $webApp.Name -ErrorAction SilentlyContinue
            $lab.AzureResources.Services.Add($webApp)
            
            if ($PassThru)
            {
                $webApp
            }
        }
    
        end
        {
            Write-LogFunctionExit
        }
    }
}
#endregion New-LabAzureWebApp

#region Get-LabAzureAppServicePlan
function Get-LabAzureAppServicePlan
{
    # .ExternalHelp AutomatedLab.Help.xml
    
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([AutomatedLab.Azure.AzureRmServerFarmWithRichSku])]
    
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )
    
    begin
    {
        Write-LogFunctionEntry

        $lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            break
        }
        
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
#endregion Get-LabAzureAppServicePlan

#region Get-LabAzureWebApp
function Get-LabAzureWebApp
{
    # .ExternalHelp AutomatedLab.Help.xml
    
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
        $sa = $lab.AzureResources.Services | Where-Object Name -eq $Name
        
        if (-not $sa)
        {
            Write-Error "The Azure App Service '$Name' does not exist."
        }
        else
        {
            $sa
        }
    }
    
    end
    {
        Write-LogFunctionExit
    }
}
#endregion Get-LabAzureWebApp

#region Remove-LabAzureWebApp
function Remove-LabAzureWebApp
{
    # .ExternalHelp AutomatedLab.Help.xml
    
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )
    
    begin
    {
        Write-LogFunctionEntry
        
        $script:lab = & $MyInvocation.MyCommand.Module { $script:lab }
    }
    
    process
    {
        $sa = $lab.AzureResources.Services | Where-Object Name -eq $Name
        
        if (-not $sa)
        {
            Write-Error "The Azure App Service '$Name' does not exist."
        }
        else
        {
            $lab.AzureResources.Services.Remove($sa)
        }
    }
    
    end
    {
        Write-LogFunctionExit
    }
}
#endregion Remove-LabAzureWebApp

#region Remove-LabAzureAppServicePlan
function Remove-LabAzureAppServicePlan
{
    # .ExternalHelp AutomatedLab.Help.xml

    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )
    
    begin
    {
        Write-LogFunctionEntry
        
        $script:lab = & $MyInvocation.MyCommand.Module { $script:lab }
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
            $lab.AzureResources.ServicePlans.Remove($sp)
        }
    }
    
    end
    {
        Write-LogFunctionExit
    }
}
#endregion Remove-LabAzureAppServicePlan