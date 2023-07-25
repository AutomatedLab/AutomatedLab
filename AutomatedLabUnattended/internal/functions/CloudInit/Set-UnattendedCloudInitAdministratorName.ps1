function Set-UnattendedCloudInitAdministratorName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    $Script:un.system_info.default_user = @{
        name = $Name
        home = "/home/$Name"
    }

    if ($script:un.users.name -notcontains $Name)
    {
        $script:un.users += @{
            name   = $Name
            groups = @('wheel')
        }
    }
}
