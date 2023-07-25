function Set-UnattendedCloudInitAdministratorPassword
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Password
    )

    $Script:un['autoinstall']['user-data']['password'] = $Password

    foreach ($user in $script:un['autoinstall']['user-data']['users'])
    {
        $user['plaintext_passwd'] = $Password
    }
}
