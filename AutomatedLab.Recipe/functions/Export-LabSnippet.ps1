function Export-LabSnippet
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Name,

        [string[]]
        $DependsOn,

        [switch]
        $MetaData
    )

    process
    {
        $schnippet = Get-LabSnippet -Name $Name
        $type = $schnippet.Name.Split('.')[1]
        $useAzure = Get-PSFConfigValue -FullName AutomatedLab.Recipe.UseAzureBlobStorage
        $location = Get-PSFConfigValue -FullName AutomatedLab.Recipe.SnippetStore
        $filePath = Join-Path -Path $location -ChildPath "$($schnippet.Name).ps1"
        $metaPath = Join-Path -Path $location -ChildPath "$($schnippet.Name).psd1"
        

        if ($useAzure)
        {
            if (-not (Test-LabAzureModuleAvailability))
            {                
                Write-ScreenInfo -Type Error -Message "Az.Storage is missing. To use Azure, try Install-LabAzureRequiredModule"
                return
            }

            if (-not (Get-AzContext))
            {
                Write-ScreenInfo -Type Error -Message "No Azure context. Please follow the on-screen instructions to log in."
                $null = Connect-AzAccount -UseDeviceAuthentication -WarningAction Continue
            }

            $account = Get-PSFConfigValue -FullName AutomatedLab.Recipe.AzureBlobStorage.AccountName
            $rg = Get-PSFConfigValue -FullName AutomatedLab.Recipe.AzureBlobStorage.ResourceGroupName
            $container = Get-PSFConfigValue -FullName AutomatedLab.Recipe.AzureBlobStorage.ContainerName
            
            if (-not $account -or -not $rg -or -not $container)
            {
                Write-ScreenInfo -Type Error -Message "Unable to upload to storage account, parameters missing. You provided AzureBlobStorage.AccountName as '$account', AzureBlobStorage.ResourceGroupName as '$rg' and AzureBlobStorage.ContainerName as '$container'"
                return
            }
            
            $ctx = (Get-AzStorageAccount -ResourceGroupName $rg -Name $account -ErrorAction SilentlyContinue).Context

            if (-not $ctx)
            {
                Write-ScreenInfo -Type Error -Message "Unable to establish storage context with account $account. Does it exist?"
                return
            }

            
            if (-not (Get-AzStorageContainer -Name $container -Context $ctx))
            {
                $null = New-AzStorageContainer -Name $container -Context $ctx
            }
        }

        if (-not $useAzure -and -not (Test-Path -Path $location))
        {
            $null = New-Item -Path $location -ItemType Directory -Force
        }

        if (-not $useAzure -and -not $MetaData.IsPresent)
        {
            Set-Content -Path $filePath -Value $schnippet.ScriptBlock.ToString() -Encoding Unicode -Force
        }
        
        if ($useAzure -and -not $MetaData.IsPresent)
        {
            $tmpFile = New-TemporaryFile
            Set-Content -Path $tmpFile.FullName -Value $schnippet.ScriptBlock.ToString() -Encoding Unicode -Force
            $null = Set-AzStorageBlobContent -File $tmpFile.FullName -Container $container -Blob "$($type)/$($schnippet.Name).ps1" -Context $ctx
            $tmpFile | Remove-Item
        }

        $metaContent = @"
@{
    Name = '$Name'
    Type = '$Type'
    Tag  = @(
        $(($Tag | ForEach-Object {"'$_'"}) -join ",")
    )
    DependsOn  = @(
        $(($DependsOn | ForEach-Object {"'$_'"}) -join ",")
    )
    Description = '$($Description.Replace("'", "''"))'
}
"@ 

        if ($useAzure)
        {
            $tmpFile = New-TemporaryFile
            Set-Content -Path $tmpFile.FullName -Value $metaContent -Encoding Unicode -Force
            $null = Set-AzStorageBlobContent -File $tmpFile.FullName -Container $container -Blob "$($type)/$($schnippet.Name).psd1" -Context (Get-AzStorageAccount -ResourceGroupName $rg -Name $account).Context
            $tmpFile | Remove-Item
        }
        else
        {
            $metaContent | Set-Content -Path $metaPath -Force
        }
    }
}