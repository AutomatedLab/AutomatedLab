function New-LabAzureAppServicePlan
{
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

            if ((Get-AzAppServicePlan -Name $plan.Name -ResourceGroupName $plan.ResourceGroup -ErrorAction SilentlyContinue))
            {
                Write-Error "The Azure Application Service Plan '$planName' does already exist in $($plan.ResourceGroup)"
                return
            }

            $plan = New-AzAppServicePlan -Name $plan.Name -Location $plan.Location -ResourceGroupName $plan.ResourceGroup -Tier $plan.Tier -NumberofWorkers $plan.NumberofWorkers -WorkerSize $plan.WorkerSize

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
