function Install-LabAzureServices
{
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
