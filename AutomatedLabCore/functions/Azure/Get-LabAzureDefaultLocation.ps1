function Get-LabAzureDefaultLocation
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    Update-LabAzureSettings

    if (-not $Script:lab.AzureSettings.DefaultLocation)
    {
        Write-Error 'The default location is not defined. Use Set-LabAzureDefaultLocation to define it.'
        return
    }

    $Script:lab.AzureSettings.DefaultLocation

    Write-LogFunctionExit
}
