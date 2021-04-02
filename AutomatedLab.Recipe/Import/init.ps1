# Initialize settings
Set-PSFConfig -Module AutomatedLab.Recipe -Name SnippetStore -Value (Join-Path -Path $HOME -ChildPath 'automatedlab/snippets') -Validation string -Initialize -Description 'Snippet and recipe storage location'

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
if (-not (Test-Path -Path $location)) { return }
foreach ($meta in (Get-ChildItem -Path $location -Filter AutomatedLab.*.*.psd1))
{
    $metadata = Import-PowerShellDataFile -Path $meta.FullName -ErrorAction SilentlyContinue
    $scriptfile = [IO.Path]::ChangeExtension($meta.FullName, 'ps1')
    $scriptblock = [scriptblock]::Create((Get-Content -Path $scriptfile -Raw))
    if (-not $metadata) { continue }

    New-LabSnippet -Name $metadata.Name -Description $metadata.Description -Tag $metadata.Tag -Type $metadata.Type -ScriptBlock $scriptblock -NoExport -Force
}
