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
