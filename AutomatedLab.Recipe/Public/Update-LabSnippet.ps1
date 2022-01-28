function Update-LabSnippet
{
    [CmdletBinding()]
    param ( )

    # Register all sample scripts
    $location = Join-Path -Path (Get-LabSourcesLocation -Local) -ChildPath 'SampleScripts'
    if (-not (Test-Path -Path $location)) { return }
    foreach ($samplescript in (Get-ChildItem -Recurse -Path $location -File -Filter *.ps1))
    {
        $sampleMeta = [IO.Path]::ChangeExtension($samplescript.FullName, 'psd1')
        $metadata = @{
            Description = "Sample script $($samplescript.BaseName)"
            Name        = $samplescript.BaseName -replace '\.', '-' -replace '[^\w\-]'
        }
    
        if (Test-Path -Path $sampleMeta)
        {
            $metadata = Import-PowerShellDataFile -Path $sampleMeta -ErrorAction SilentlyContinue
        }

        $scriptblock = [scriptblock]::Create((Get-Content -Path $samplescript.FullName -Raw))

        New-LabSnippet -Name $metadata.Name -Description $metadata.Description -Tag $metadata.Tag -Type 'Sample' -ScriptBlock $scriptblock -NoExport -Force
    }

    # Register all custom roles
    $location = Join-Path -Path (Get-LabSourcesLocation -Local) -ChildPath 'CustomRoles'
    if (-not (Test-Path -Path $location)) { return }
    foreach ($customrole in (Get-ChildItem -Path $location -Directory))
    {
        $customroleMeta = Join-Path -Path $customrole.FullName -ChildPath "$($customRole.Name).psd1"
        $scriptfile = Join-Path -Path $customrole.FullName -ChildPath HostStart.ps1

        if (-not (Test-Path -Path $scriptFile)) { continue }

        $metadata = @{
            Description = "Custom role to deploy $($customRole.Name)"
        }
    
        if (Test-Path -Path $customroleMeta)
        {
            $metadata = Import-PowerShellDataFile -Path $customroleMeta -ErrorAction SilentlyContinue
        }

        $scriptblock = [scriptblock]::Create((Get-Content -Path $scriptfile -Raw))

        New-LabSnippet -Name $customrole.Name -Description $metadata.Description -Tag $metadata.Tag -Type 'CustomRole' -ScriptBlock $scriptblock -NoExport -Force
    }

    # Register all user-defined blocks
    $location = Get-PSFConfigValue -FullName AutomatedLab.Recipe.SnippetStore
    $useAzure = Get-PSFConfigValue -FullName AutomatedLab.Recipe.UseAzureBlobStorage
        
    if ($useAzure -and -not (Get-Command -Name Set-AzStorageBlobContent -ErrorAction SilentlyContinue))
    {                
        Write-ScreenInfo -Type Error -Message "Az.Storage is missing. To use Azure, ensure that the module Az is installed."
        return
    }
    
    if ($useAzure -and -not (Get-AzContext))
    {                
        Write-ScreenInfo -Type Error -Message "No Azure context. Please follow the on-screen instructions to log in."
        $null = Connect-AzAccount -UseDeviceAuthentication -WarningAction Continue
    }

    if ($useAzure)
    {
        $account = Get-PSFConfigValue -FullName AutomatedLab.Recipe.AzureBlobStorage.AccountName
        $rg = Get-PSFConfigValue -FullName AutomatedLab.Recipe.AzureBlobStorage.ResourceGroupName
        $container = Get-PSFConfigValue -FullName AutomatedLab.Recipe.AzureBlobStorage.ContainerName

        if (-not $account -or -not $container -or -not $rg)
        {
            Write-PSFMessage -Level Warning -Message "Skipping import of Azure snippets since parameters were missing"
            return
        }

        $blobs = [System.Collections.ArrayList]::new()
        try { $blobs.AddRange((Get-AzStorageBlob -Blob [sS]nippet/*.ps*1 -Container $container -Context (Get-AzStorageAccount -ResourceGroupName $rg -Name $account).Context)) } catch {}
        try { $blobs.AddRange((Get-AzStorageBlob -Blob [sS]ample/*.ps*1 -Container $container -Context (Get-AzStorageAccount -ResourceGroupName $rg -Name $account).Context)) } catch {}

        if ($blobs.Count -eq 0) { return }
        Push-Location # Super ugly...
        $location = Join-Path -Path $env:TEMP -ChildPath snippetcache
        if (-not (Test-Path -Path $location)) { $null = New-Item -ItemType Directory -Path $location }
        Get-ChildItem -Path $location -Recurse -File | Remove-Item
        Set-Location -Path $location
        $null = $blobs | Get-AzStorageBlobContent
        Pop-Location
    }

    if (-not (Test-Path -Path $location)) { return }
    foreach ($meta in (Get-ChildItem -Path $location -File -Recurse -Filter AutomatedLab.*.*.psd1))
    {
        $metadata = Import-PowerShellDataFile -Path $meta.FullName -ErrorAction SilentlyContinue
        $scriptfile = [IO.Path]::ChangeExtension($meta.FullName, 'ps1')
        $scriptblock = [scriptblock]::Create((Get-Content -Path $scriptfile -Raw))
        if (-not $metadata) { continue }

        New-LabSnippet -Name $metadata.Name -Description $metadata.Description -Tag $metadata.Tag -Type $metadata.Type -ScriptBlock $scriptblock -NoExport -Force
    }

}