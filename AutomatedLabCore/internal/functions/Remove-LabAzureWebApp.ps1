function Remove-LabAzureWebApp
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
        $service = $lab.AzureResources.Services | Where-Object { $_.Name -eq $Name -and $_.ResourceGroup -eq $ResourceGroup }

        if (-not $service)
        {
            Write-Error "The Azure App Service '$Name' does not exist in the lab."
        }
        else
        {
            $s = Get-AzWebApp -Name $service.Name -ResourceGroupName $service.ResourceGroup -ErrorAction SilentlyContinue

            if ($s)
            {
                $s | Remove-AzWebApp -Force
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
