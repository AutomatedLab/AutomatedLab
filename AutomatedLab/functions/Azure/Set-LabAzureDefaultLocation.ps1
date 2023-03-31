function Set-LabAzureDefaultLocation
{

    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-LogFunctionEntry

    Update-LabAzureSettings

    if (-not ($Name -in $script:lab.AzureSettings.Locations.DisplayName -or $Name -in $script:lab.AzureSettings.Locations.Location))
    {
        Microsoft.PowerShell.Utility\Write-Error "Invalid location. Please specify one of the following locations: $($script:lab.AzureSettings.Locations.DisplayName -join ', ')"
        return
    }

    $script:lab.AzureSettings.DefaultLocation = $script:lab.AzureSettings.Locations | Where-Object { $_.DisplayName -eq $Name -or $_.Location -eq $Name }

    Write-LogFunctionExit
}
