function Get-LabAzureDefaultSubscription
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    Update-LabAzureSettings

    $script:lab.AzureSettings.DefaultSubscription

    Write-LogFunctionExit
}
