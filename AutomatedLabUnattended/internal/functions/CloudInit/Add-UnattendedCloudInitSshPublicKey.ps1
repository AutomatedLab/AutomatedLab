function Add-UnattendedCloudInitSshPublicKey
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $PublicKey
    )

    foreach ($user in $script:un['autoinstall']['user-data']['users'])
    {
        if ($user -eq 'default') { continue }
        if (-not $user.ContainsKey('ssh_authorized_keys'))
        {
            $user.Add('ssh_authorized_keys', @())
        }

        $user['ssh_authorized_keys'] += $PublicKey
    }
}
