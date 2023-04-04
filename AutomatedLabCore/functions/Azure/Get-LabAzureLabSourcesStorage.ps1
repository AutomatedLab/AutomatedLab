function Get-LabAzureLabSourcesStorage
{
    [CmdletBinding()]
    param
    ()

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    Test-LabAzureSubscription
    $azureLabSourcesResourceGroupName = 'AutomatedLabSources'

    $currentSubscription = (Get-AzContext).Subscription

    $storageAccount = Get-AzStorageAccount -ResourceGroupName automatedlabsources -ErrorAction SilentlyContinue | Where-Object StorageAccountName -like automatedlabsources?????

    if (-not $storageAccount)
    {
        Write-Error "The AutomatedLabSources share on Azure does not exist"
        return
    }

    $storageAccount | Add-Member -MemberType NoteProperty -Name StorageAccountKey -Value ($storageAccount | Get-AzStorageAccountKey)[0].Value -Force
    $storageAccount | Add-Member -MemberType NoteProperty -Name Path -Value "\\$($storageAccount.StorageAccountName).file.core.windows.net\labsources" -Force
    $storageAccount | Add-Member -MemberType NoteProperty -Name SubscriptionName -Value (Get-AzContext).Subscription.Name -Force

    $storageAccount
}
