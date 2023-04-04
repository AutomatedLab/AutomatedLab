function New-LabAzureLabSourcesStorage
{
    [CmdletBinding()]
    param
    (
        [string]$LocationName,

        [switch]$NoDisplay
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    Test-LabAzureSubscription
    $azureLabSourcesResourceGroupName = 'AutomatedLabSources'

    if (-not $LocationName)
    {
        $LocationName = (Get-LabAzureDefaultLocation -ErrorAction SilentlyContinue).DisplayName
    }
    if (-not $LocationName)
    {
        Write-Error "LocationName was not provided and could not be retrieved from a present lab. Please specify a location name or import a lab"
        return
    }
    if ($LocationName -notin (Get-AzLocation).DisplayName)
    {
        Write-Error "The location name '$LocationName' is not valid. Please invoke 'Get-AzLocation' to get a list of possible locations"
    }

    $currentSubscription = (Get-AzContext).Subscription
    Write-ScreenInfo "Looking for Azure LabSources inside subscription '$($currentSubscription.Name)'" -TaskStart

    $resourceGroup = Get-AzResourceGroup -Name $azureLabSourcesResourceGroupName -ErrorAction SilentlyContinue
    if (-not $resourceGroup)
    {
        Write-ScreenInfo "Resoure Group '$azureLabSourcesResourceGroupName' could not be found, creating it"
        $resourceGroup = New-AzResourceGroup -Name $azureLabSourcesResourceGroupName -Location $LocationName | Out-Null
    }

    $storageAccount = Get-AzStorageAccount -ResourceGroupName $azureLabSourcesResourceGroupName -ErrorAction SilentlyContinue | Where-Object StorageAccountName -like automatedlabsources?????
    if (-not $storageAccount)
    {
        Write-ScreenInfo "No storage account for AutomatedLabSources could not be found, creating it"
        $storageAccountName = "automatedlabsources$((1..5 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"
        New-AzStorageAccount -ResourceGroupName $azureLabSourcesResourceGroupName -Name $storageAccountName -Location $LocationName -Kind Storage -SkuName Standard_LRS | Out-Null
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $azureLabSourcesResourceGroupName | Where-Object StorageAccountName -like automatedlabsources?????
    }

    $share = Get-AzStorageShare -Context $StorageAccount.Context -Name labsources -ErrorAction SilentlyContinue
    if (-not $share)
    {
        Write-ScreenInfo "The share 'labsources' could not be found, creating it"
        New-AzStorageShare -Name 'labsources' -Context $storageAccount.Context | Out-Null
    }

    Write-ScreenInfo "Azure LabSources verified / created" -TaskEnd

    Write-LogFunctionExit
}
