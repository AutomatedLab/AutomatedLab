function Get-LabAzureAppServicePlan
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
