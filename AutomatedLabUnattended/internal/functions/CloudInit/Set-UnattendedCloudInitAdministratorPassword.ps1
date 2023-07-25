function Set-UnattendedCloudInitAdministratorPassword
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Password
    )

    $Script:un['password'] = $Password

    foreach ($user in $script:un['user-data']['users'])
    {
        $user['plaintext_passwd'] = $Password
    }
}
