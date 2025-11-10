function Test-LabAzureModuleAvailability
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [switch]
        $AzureStack
    )

    [hashtable[]] $modules = if ($AzureStack.IsPresent) {
        Get-LabConfigurationItem -Name RequiredAzStackModules
    }
    else {
        Get-LabConfigurationItem -Name RequiredAzModules
    }
    $installedModules = Get-Module -ListAvailable
    $loadedModules = Get-Module
    [hashtable[]] $modulesMissing = @()

    foreach ($module in $modules) {
        $param = @{
            Name        = $module.Name
            ErrorAction = 'Stop'
        }

        if ($module.MinimumVersion) {
            $isPresent = $installedModules | Where-Object { $_.Name -eq $module.Name -and $_.Version -ge $module.MinimumVersion }
            $isLoaded = $loadedModules | Where-Object { $_.Name -eq $module.Name -and $_.Version -ge $module.MinimumVersion }
            $param.MinimumVersion = $module.MinimumVersion
        }
        elseif ($module.RequiredVersion) {
            $isPresent = $installedModules | Where-Object { $_.Name -eq $module.Name -and $_.Version -eq $module.RequiredVersion }
            $isLoaded = $loadedModules | Where-Object { $_.Name -eq $module.Name -and $_.Version -ge $module.MinimumVersion }
            $param.RequiredVersion = $module.RequiredVersion
        }

        if ($isLoaded) {
            Write-PSFMessage -Message "The module $($module.Name) with version is already loaded."
            continue
        }

        try {
            if ($isPresent) {
                Write-PSFMessage -Message "The module $($module.Name) was found but is not yet loaded. Calling 'Import-Module'."
                Import-Module @param
                continue
            }}
        catch {
            if ($module.MinimumVersion)
            {
                Write-PSFMessage -Level Error -Message "The module '$($param.Name)', MinimumVersion $($param.MinimumVersion), could not be imported: $($_.Exception.Message)"
            }
            else
            {
                Write-PSFMessage -Level Error -Message "The module '$($param.Name)', RequiredVersion $($param.RequiredVersion), could not be imported: $($_.Exception.Message)"
            }
            
            return $false
        }

        Write-PSFMessage -Message "$($module.Name) missing"
        $modulesMissing += $module
    }

    if ($modulesMissing.Count -gt 0) {
        $missingString = $modulesMissing.ForEach({ "$($_.Name), Minimum: $($_.MinimumVersion) or required: $($_.RequiredVersion)" })
        Write-PSFMessage -Level Error -Message "Missing Az modules: $missingString"
    }

    return ($modulesMissing.Count -eq 0)
}
