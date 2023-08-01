function Get-LWAzureVmSize
{
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine
    )

    $lab = Get-Lab

    if ($machine.AzureRoleSize)
    {
        $roleSize = $lab.AzureSettings.RoleSizes |
        Where-Object { $_.Name -eq $machine.AzureRoleSize }
        Write-PSFMessage -Message "Using specified role size of '$($roleSize.Name)'"
    }
    elseif ($machine.AzureProperties.RoleSize)
    {
        $roleSize = $lab.AzureSettings.RoleSizes |
        Where-Object { $_.Name -eq $machine.AzureProperties.RoleSize }
        Write-PSFMessage -Message "Using specified role size of '$($roleSize.Name)'"
    }
    elseif ($machine.AzureProperties.UseAllRoleSizes)
    {
        $DefaultAzureRoleSize = Get-LabConfigurationItem -Name DefaultAzureRoleSize
        $roleSize = $lab.AzureSettings.RoleSizes |
        Where-Object { $_.MemoryInMB -ge $machine.Memory -and $_.NumberOfCores -ge $machine.Processors -and $machine.Disks.Count -le $_.MaxDataDiskCount } |
        Sort-Object -Property MemoryInMB, NumberOfCores |
        Select-Object -First 1

        Write-PSFMessage -Message "Using specified role size of '$($roleSize.InstanceSize)'. VM was configured to all role sizes but constrained to role size '$DefaultAzureRoleSize' by psd1 file"
    }
    else
    {
        $pattern = switch ($lab.AzureSettings.DefaultRoleSize)
        {
            'A' { '^Standard_A\d{1,2}(_v\d{1,3})|Basic_A\d{1,2})' }
            'AS' { '^Standard_AS\d{1,2}(_v\d{1,3})' }
            'AC' { '^Standard_AC\d{1,2}(_v\d{1,3})' }
            'D' { '^Standard_D\d{1,2}(_v\d{1,3})' }
            'DS' { '^Standard_DS\d{1,2}(_v\d{1,3})' }
            'DC' { '^Standard_DC\d{1,2}(_v\d{1,3})' }
            "E" { '^Standard_E\d{1,2}(_v\d{1,3})' }
            "ES" { '^Standard_ES\d{1,2}(_v\d{1,3})' }
            "EC" { '^Standard_EC\d{1,2}(_v\d{1,3})' }
            'F' { '^Standard_F\d{1,2}(_v\d{1,3})' }
            'FS' { '^Standard_FS\d{1,2}(_v\d{1,3})' }
            'FC' { '^Standard_FC\d{1,2}(_v\d{1,3})' }
            'G' { '^Standard_G\d{1,2}(_v\d{1,3})' }
            'GS' { '^Standard_GS\d{1,2}(_v\d{1,3})' }
            'GC' { '^Standard_GC\d{1,2}(_v\d{1,3})' }
            'H' { '^Standard_H\d{1,2}(_v\d{1,3})' }
            'HS' { '^Standard_HS\d{1,2}(_v\d{1,3})' }
            'HC' { '^Standard_HC\d{1,2}(_v\d{1,3})' }
            'L' { '^Standard_L\d{1,2}(_v\d{1,3})' }
            'LS' { '^Standard_LS\d{1,2}(_v\d{1,3})' }
            'LC' { '^Standard_LC\d{1,2}(_v\d{1,3})' }
            'N' { '^Standard_N\d{1,2}(_v\d{1,3})' }
            'NS' { '^Standard_NS\d{1,2}(_v\d{1,3})' }
            'NC' { '^Standard_NC\d{1,2}(_v\d{1,3})' }
            default { '^(Standard_A\d{1,2}(_v\d{1,3})|Basic_A\d{1,2})' }
        }

        $roleSize = $lab.AzureSettings.RoleSizes |
        Where-Object { $_.Name -Match $pattern -and $_.Name -notlike '*promo*' } |
        Where-Object { $_.MemoryInMB -ge ($machine.Memory / 1MB) -and $_.NumberOfCores -ge $machine.Processors } |
        Sort-Object -Property MemoryInMB, NumberOfCores, @{ Expression = { if ($_.Name -match '.+_v(?<Version>\d{1,2})') { $Matches.Version } }; Ascending = $false } |
        Select-Object -First 1

        Write-PSFMessage -Message "Using specified role size of '$($roleSize.Name)' out of role sizes '$pattern'"
    }

    $roleSize
}
