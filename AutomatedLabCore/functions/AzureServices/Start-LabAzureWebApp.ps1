function Start-LabAzureWebApp
{
    [OutputType([AutomatedLab.Azure.AzureRmService])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ResourceGroup,

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

        $service = $lab.AzureResources.Services | Where-Object { $_.Name -eq $Name -and $_.ResourceGroup -eq $ResourceGroup }

        if (-not $service)
        {
            Write-Error "The Azure App Service '$Name' does not exist."
        }
        else
        {
            try
            {
                $s = Start-AzWebApp -Name $service.Name -ResourceGroupName $service.ResourceGroup -ErrorAction Stop
                $service.Merge($s, 'PublishProfiles')

                if ($PassThru)
                {
                    $service
                }
            }
            catch
            {
                Write-Error "The Azure Web App '$($service.Name)' in resource group '$($service.ResourceGroup)' could not be started"
            }
        }
    }

    end
    {
        Export-Lab
        Write-LogFunctionExit
    }
}
