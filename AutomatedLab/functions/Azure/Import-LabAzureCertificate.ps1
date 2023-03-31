function Import-LabAzureCertificate
{
    [CmdletBinding()]
    param ()

    Test-LabHostConnected -Throw -Quiet

    throw New-Object System.NotImplementedException
    Write-LogFunctionEntry

    Update-LabAzureSettings

    $resourceGroup = Get-AzResourceGroup -name (Get-LabAzureDefaultResourceGroup)
    $keyVault = Get-AzKeyVault -VaultName (Get-LabAzureDefaultKeyVault) -ResourceGroupName $resourceGroup
    $temp = [System.IO.Path]::GetTempFileName()

    $cert = ($keyVault | Get-AzKeyVaultCertificate).Data

    if ($cert)
    {
        $cert | Out-File -FilePath $temp
        certutil -addstore -f Root $temp | Out-Null

        Remove-Item -Path $temp
        Write-LogFunctionExit
    }
    else
    {
        Write-LogFunctionExitWithError -Message "Could not receive certificate for resource group '$resourceGroup'"
    }
}
