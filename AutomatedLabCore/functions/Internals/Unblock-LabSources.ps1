function Unblock-LabSources
{

    param(
        [string]$Path = $global:labSources
    )

    Write-LogFunctionEntry

    $lab = Get-Lab -ErrorAction SilentlyContinue
    if (-not $lab)
    {
        $lab = Get-LabDefinition -ErrorAction SilentlyContinue
    }

    if ($lab.DefaultVirtualizationEngine -eq 'Azure' -and $Path.StartsWith("\\"))
    {
        Write-PSFMessage 'Skipping the unblocking of lab sources since we are on Azure and lab sources are unblocked during Sync-LabAzureLabSources'
        return
    }

    if (-not (Test-Path -Path $Path))
    {
        Write-Error "The path '$Path' could not be found"
        return
    }

    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String, DateTime

    try
    {
        if ($IsLinux -or $IsMacOs)
        {
            $cache = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
        }
        else
        {
            $cache = $type::ImportFromRegistry('Cache', 'Timestamps')
        }

        Write-PSFMessage 'Imported Cache\Timestamps from registry/file store'
    }
    catch
    {
        $cache = New-Object $type
        Write-PSFMessage 'No entry found in the registry at Cache\Timestamps'
    }

    if (-not $cache['LabSourcesLastUnblock'] -or $cache['LabSourcesLastUnblock'] -lt (Get-Date).AddDays(-1))
    {
        Write-PSFMessage 'Last unblock more than 24 hours ago, unblocking files'
        if (-not ($IsLinux -or $IsMacOs)) { Get-ChildItem -Path $Path -Recurse | Unblock-File }
        $cache['LabSourcesLastUnblock'] = Get-Date
        if ($IsLinux -or $IsMacOs)
        {
            $cache.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
        }
        else
        {
            $cache.ExportToRegistry('Cache', 'Timestamps')
        }

        Write-PSFMessage 'LabSources folder unblocked and new timestamp written to Cache\Timestamps'
    }
    else
    {
        Write-PSFMessage 'Last unblock less than 24 hours ago, doing nothing'
    }

    Write-LogFunctionExit
}
