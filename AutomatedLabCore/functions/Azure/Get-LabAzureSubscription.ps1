function Get-LabAzureSubscription
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    Update-LabAzureSettings

    $script:lab.AzureSettings.Subscriptions

    Write-LogFunctionExit
}
