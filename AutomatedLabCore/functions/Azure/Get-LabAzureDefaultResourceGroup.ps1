function Get-LabAzureDefaultResourceGroup
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    Update-LabAzureSettings

    $script:lab.AzureSettings.ResourceGroups | Where-Object ResourceGroupName -eq $script:lab.Name

    Write-LogFunctionExit
}
