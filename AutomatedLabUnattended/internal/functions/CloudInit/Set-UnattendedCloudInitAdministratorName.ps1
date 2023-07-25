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
    $Script:un['user-data']['system_info']['default_user'] = $usr

    if (-not $script:un['user-data'].ContainsKey('users')) { $script:un['user-data']['users'] = @() }

    if ($script:un['user-data']['users']['name'] -notcontains $Name)
    {
        $script:un['user-data']['users'] += $usr
    }
}
