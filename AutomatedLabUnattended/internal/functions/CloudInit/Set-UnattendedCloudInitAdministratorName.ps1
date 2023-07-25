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
    $Script:un['system_info']['default_user'] = $usr

    if (-not $script:un.ContainsKey('users')) { $script:un['users'] = @() }

    if ($script:un['users']['name'] -notcontains $Name)
    {
        $script:un['users'] += $usr
    }
}
