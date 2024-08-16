function Get-LabAzureDefaultResourceGroup
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    Update-LabAzureSettings

    if ($script:lab.AzureSettings.DefaultResourceGroup) { return $script:lab.AzureSettings.DefaultResourceGroup }

    $script:lab.AzureSettings.ResourceGroups | Where-Object ResourceGroupName -eq $script:lab.Name

    Write-LogFunctionExit
}
