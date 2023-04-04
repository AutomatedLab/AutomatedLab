function New-LabAzureWebApp
{
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

            $webApp = New-AzWebApp -Name $app.Name -Location $app.Location -AppServicePlan $app.ApplicationServicePlan -ResourceGroupName $app.ResourceGroup

            if ($webApp)
            {
                $webApp = [AutomatedLab.Azure.AzureRmService]::Create($webApp)

                #Get app-level deployment credentials
                $xml = [xml](Get-AzWebAppPublishingProfile -Name $webApp.Name -ResourceGroupName $webApp.ResourceGroup -OutputFile null)

                $publishProfile = [AutomatedLab.Azure.PublishProfile]::Create($xml.publishData.publishProfile)
                $webApp.PublishProfiles = $publishProfile

                $existingWebApp = Get-LabAzureWebApp -Name $webApp.Name
                $existingWebApp.Merge($webApp)

				$existingWebApp | Set-LabAzureWebAppContent -LocalContentPath "$(Get-LabSourcesLocationInternal -Local)\PostInstallationActivities\WebSiteDefaultContent"

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
