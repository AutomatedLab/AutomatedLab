function Remove-LabAzureLabSourcesStorage
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    ()

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionExit
    Test-LabAzureSubscription

    if (Test-LabAzureLabSourcesStorage)
    {
        $azureLabStorage = Get-LabAzureLabSourcesStorage

        if ($PSCmdlet.ShouldProcess($azureLabStorage.ResourceGroupName, 'Remove Resource Group'))
        {
            Remove-AzResourceGroup -Name $azureLabStorage.ResourceGroupName -Force | Out-Null
            Write-ScreenInfo "Azure Resource Group '$($azureLabStorage.ResourceGroupName)' was removed" -Type Warning
        }
    }

    Write-LogFunctionExit
}
