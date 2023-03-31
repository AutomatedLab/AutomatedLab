function Remove-LabAzureAppServicePlan
{
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ResourceGroup
    )

    begin
    {
        Write-LogFunctionEntry

        $script:lab = Get-Lab
    }

    process
    {
        $servicePlan = $lab.AzureResources.ServicePlans | Where-Object { $_.Name -eq $Name -and $_.ResourceGroup -eq $ResourceGroup }

        if (-not $servicePlan)
        {
            Write-Error "The Azure App Service Plan '$Name' does not exist."
        }
        else
        {
            $sp = Get-AzAppServicePlan -Name $servicePlan.Name -ResourceGroupName $servicePlan.ResourceGroup -ErrorAction SilentlyContinue

            if ($sp)
            {
                $sp | Remove-AzAppServicePlan -Force
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
