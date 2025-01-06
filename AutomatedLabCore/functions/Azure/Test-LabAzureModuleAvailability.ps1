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
    [hashtable[]] $modulesMissing = @()

    foreach ($module in $modules) {
        $param = @{
            Name  = $module.Name
            Force = $true
        }

        $isPresent = if ($module.MinimumVersion) {
            $installedModules | Where-Object { $_.Name -eq $module.Name -and $_.Version -ge $module.MinimumVersion }
            $param.MinimumVersion = $module.MinimumVersion
        }
        elseif ($module.RequiredVersion) {
            $installedModules | Where-Object { $_.Name -eq $module.Name -and $_.Version -eq $module.RequiredVersion }
            $param.RequiredVersion = $module.RequiredVersion
        }

        if ($isPresent) {
            Write-PSFMessage -Message "$($module.Name) found"
            Import-Module @param
            continue
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
