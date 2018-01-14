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
    $servicePlans = Get-LabAzureAppServicePlan
    
    if (-not $services)
    {
        Write-ScreenInfo "No Azure service defined, exiting."
        Write-LogFunctionExit
        return
    }

    Write-ScreenInfo "There are $($servicePlans.Count) Azure App Services Plans defined. Starting deployment." -TaskStart
    $servicePlans | New-LabAzureAppServicePlan
    Write-ScreenInfo 'Finished creating Azure App Services Plans.' -TaskEnd

    Write-ScreenInfo "There are $($services.Count) Azure Web Apps defined. Starting deployment." -TaskStart
    $services | New-LabAzureWebApp
    Write-ScreenInfo 'Finished creating Azure Web Apps.' -TaskEnd

    Write-LogFunctionExit
}

#region New-LabAzureAppServicePlan
function New-LabAzureAppServicePlan
{
    # .ExternalHelp AutomatedLab.Help.xml
    
    [OutputType([AutomatedLab.Azure.AzureRmServerFarmWithRichSku])]
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        
        [switch]$PassThru
    )
    
    begin
    {
        Write-LogFunctionEntry
        $script:lab = Get-Lab
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
            $plan = Get-LabAzureAppServicePlan -Name $planName
            
            if (-not (Get-LabAzureResourceGroup -ResourceGroupName $plan.ResourceGroup))
            {
                New-LabAzureRmResourceGroup -ResourceGroupNames $plan.ResourceGroup -LocationName $plan.Location
            }
            
            if ((Get-AzureRmAppServicePlan -Name $plan.Name -ResourceGroupName $plan.ResourceGroup -ErrorAction SilentlyContinue))
            {
                Write-Error "The Azure Application Service Plan '$planName' does already exist in $($plan.ResourceGroup)"
                return
                
            }

            $plan = New-AzureRmAppServicePlan -Name $plan.Name -Location $plan.Location -ResourceGroupName $plan.ResourceGroup -Tier $plan.Tier -NumberofWorkers $plan.NumberofWorkers -WorkerSize $plan.WorkerSize

            if ($plan)
            {
                $plan = [AutomatedLab.Azure.AzureRmServerFarmWithRichSku]::Create($plan)
                $existingPlan = Get-LabAzureAppServicePlan -Name $plan.Name
                $existingPlan.Merge($plan)

                if ($PassThru)
                {
                    $plan
                }
            }
        }
    }
    
    end
    {
        Export-Lab
        Write-LogFunctionExit
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
        
        $script:lab = Get-Lab
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

            $webApp = New-AzureRmWebApp -Name $app.Name -Location $app.Location -AppServicePlan $app.ApplicationServicePlan -ResourceGroupName $app.ResourceGroup

            if ($webApp)
            {
                $webApp = [AutomatedLab.Azure.AzureRmService]::Create($webApp)
                $existingWebApp = Get-LabAzureWebApp -Name $webApp.Name
                $existingWebApp.Merge($webApp)
            
                if ($PassThru)
                {
                    $webApp
                }
            }
        }
    }
    
    end
    {
        Export-Lab
        Write-LogFunctionExit
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
    }
    
    process
    {
        if (-not $Name) { return }
        
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
        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $lab.AzureResources.ServicePlans
        }
        
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
        
        $script:lab = Get-Lab
    }
    
    process
    {
        if (-not $Name) { return }
        
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
        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $lab.AzureResources.Services
        }
            
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
        
        $script:lab = Get-Lab
    }
    
    process
    {
        $service = $lab.AzureResources.Services | Where-Object Name -eq $Name
        
        if (-not $service)
        {
            Write-Error "The Azure App Service '$Name' does not exist in the lab."
        }
        else
        {
            $s = Get-AzureRmWebApp -Name $service.Name -ResourceGroupName $service.ResourceGroup -ErrorAction SilentlyContinue

            if ($s)
            {
                $s | Remove-AzureRmWebApp -Force
            }

            $lab.AzureResources.Services.Remove($service)
        }
    }
    
    end
    {
        Export-Lab
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
        
        $script:lab = Get-Lab
    }
    
    process
    {
        $servicePlan = $lab.AzureResources.ServicePlans | Where-Object Name -eq $Name
        
        if (-not $servicePlan)
        {
            Write-Error "The Azure App Service Plan '$Name' does not exist."
        }
        else
        {
            $sp = Get-AzureRmAppServicePlan -Name $servicePlan.Name -ResourceGroupName $servicePlan.ResourceGroup -ErrorAction SilentlyContinue

            if ($sp)
            {
                $sp | Remove-AzureRmAppServicePlan -Force
            }
            $lab.AzureResources.ServicePlans.Remove($servicePlan)
        }
    }
    
    end
    {
        Export-Lab
        Write-LogFunctionExit
    }
}
#endregion Remove-LabAzureAppServicePlan

#region Start-LabAzureWebApp
function Start-LabAzureWebApp
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
        $script:lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
    }

    process
    {
        if (-not $Name) { return }
        
        $service = $lab.AzureResources.Services | Where-Object Name -eq $Name
        
        if (-not $service)
        {
            Write-Error "The Azure App Service '$Name' does not exist."
        }
        else
        {
            Start-AzureRmWebApp -Name $service.Name -ResourceGroupName $service.ResourceGroup
        }
    }

    end
    {
        Write-LogFunctionExit
    }
}
#endregion Start-LabAzureWebApp

#region Stop-LabAzureWebApp
function Stop-LabAzureWebApp
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
        $script:lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
    }

    process
    {
        if (-not $Name) { return }
        
        $service = $lab.AzureResources.Services | Where-Object Name -eq $Name
        
        if (-not $service)
        {
            Write-Error "The Azure App Service '$Name' does not exist."
        }
        else
        {
            Stop-AzureRmWebApp -Name $service.Name -ResourceGroupName $service.ResourceGroup
        }
    }

    end
    {
        Write-LogFunctionExit
    }
}
#endregion Stop-LabAzureWebApp

#region Get-LabAzureWebAppStatus
function Get-LabAzureWebAppStatus
{
    # .ExternalHelp AutomatedLab.Help.xml
    
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        
        [switch]$PassThru
    )
    
    begin
    {
        Write-LogFunctionEntry
        $script:lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
        $result = @{}
    }

    process
    {
        if (-not $Name) { return }
        
        $service = $lab.AzureResources.Services | Where-Object Name -eq $Name
        
        if (-not $service)
        {
            Write-Error "The Azure App Service '$Name' does not exist."
        }
        else
        {
            $s = Get-AzureRmWebApp -Name $service.Name -ResourceGroupName $service.ResourceGroup -ErrorAction SilentlyContinue
            if ($s)
            {
                $result.Add($s.Name, $s.State)
            }
        }
    }

    end
    {
        $result
        Write-LogFunctionExit
    }
}
#Get-LabAzureWebAppStatus