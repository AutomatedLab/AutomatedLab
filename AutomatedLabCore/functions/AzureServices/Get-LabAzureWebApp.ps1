function Get-LabAzureWebApp
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
