function Set-UnattendedCloudInitAdministratorName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    $usr = @{
        name   = $Name
        groups = @('wheel')
    }
    
    $Script:un['autoinstall']['user-data']['system_info']['default_user'] = $usr

    if (-not $script:un['autoinstall']['user-data'].ContainsKey('users')) { $script:un['autoinstall']['user-data']['users'] = @() }

    if ($script:un['autoinstall']['user-data']['users']['name'] -notcontains $Name)
    {
        $script:un['autoinstall']['user-data']['users'] += $usr
    }
}
