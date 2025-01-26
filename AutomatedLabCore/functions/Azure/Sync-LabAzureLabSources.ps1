function Sync-LabAzureLabSources {
    [CmdletBinding()]
    param
    (
        [switch]
        $SkipIsos,

        [switch]
        $DoNotSkipOsIsos,

        [int]
        $MaxFileSizeInMb,

        [string]
        $Filter,

        [switch]
        $NoDisplay
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionExit
    Test-LabAzureSubscription

    if (-not (Test-LabAzureLabSourcesStorage)) {
        Write-Error "There is no LabSources share available in the current subscription '$((Get-AzContext).Subscription.Name)'. To create one, please call 'New-LabAzureLabSourcesStorage'."
        return
    }

    $currentSubscription = (Get-AzContext).Subscription
    Write-ScreenInfo -Message "Syncing LabSources in subscription '$($currentSubscription.Name)'" -TaskStart

    # Retrieve storage context
    $storageAccount = Get-AzStorageAccount -ResourceGroupName automatedlabsources | Where-Object StorageAccountName -Like automatedlabsources?????

    $localLabsources = Get-LabSourcesLocationInternal -Local
    Unblock-LabSources -Path $localLabsources

    # Sync the lab sources
    $fileParams = @{
        Recurse     = $true
        Path        = $localLabsources
        File        = $true
        Filter      = if ($Filter) { $Filter } else { '*' }
        ErrorAction = 'SilentlyContinue'
    }

    $files = Get-ChildItem @fileParams
    $share = Get-AzStorageShare -Name labsources -Context $storageAccount.Context

    foreach ($file in $files) {
        Write-ProgressIndicator
        if ($SkipIsos -and $file.Directory.Name -eq 'Isos') {
            Write-PSFMessage "SkipIsos is true, skipping $($file.Name)"
            continue
        }

        if ($MaxFileSizeInMb -and $file.Length / 1MB -ge $MaxFileSizeInMb) {
            Write-PSFMessage "MaxFileSize is $MaxFileSizeInMb MB, skipping '$($file.Name)'"
            continue
        }

        # Check if file is an OS ISO and skip
        if ($file.Extension -eq '.iso') {
            $isOs = [bool](Get-LabAvailableOperatingSystem -Path $file.FullName)

            if ($isOs -and -not $DoNotSkipOsIsos) {
                Write-PSFMessage "Skipping OS ISO $($file.FullName)"
                continue
            }
        }

        $fileName = $file.FullName.Replace("$($localLabSources)\", '')

        $azureFile = Get-AzStorageFile -ShareClient $share.ShareClient -Context $share.Context -Path $fileName -ErrorAction SilentlyContinue
        if ($azureFile) {
            $sBuilder = [System.Text.StringBuilder]::new()
            foreach ($byte in $azureFile.FileProperties.ContentHash) {
                $null = $sBuilder.Append($byte.ToString('x2'))
            }
            $azureHash = $sBuilder.ToString()

            $localHash = (Get-FileHash -Path $file.FullName -Algorithm MD5).Hash
            Write-PSFMessage "$fileName already exists in Azure. Source hash is $localHash and Azure hash is $azureHash"
        }

        if ($azureFile -and $localHash -eq $azureHash) {
            continue
        }

        if (-not $azureFile -or ($azureFile -and $localHash -ne $azureHash)) {
            $null = New-LabSourcesPath -RelativePath $fileName -Share $share
            $null = Set-AzStorageFileContent -ShareClient $share.ShareClient -Context $share.Context -Path $fileName -Source $file.FullName -ErrorAction SilentlyContinue -Force
            Write-PSFMessage "Azure file $fileName successfully uploaded. Updating file hash..."
        }

        Write-PSFMessage "Azure file $fileName successfully uploaded and hash generated"
    }

    Write-ScreenInfo 'LabSources Sync complete' -TaskEnd

    Write-LogFunctionExit
}
