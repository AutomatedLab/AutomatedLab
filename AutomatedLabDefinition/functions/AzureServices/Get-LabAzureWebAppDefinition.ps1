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
