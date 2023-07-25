function Add-UnattendedCloudInitSshPublicKey
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $PublicKey
    )

    $script:un.ssh_authorized_keys += $PublicKey
    foreach ($user in $script:un.users)
    {
        if (-not $user.ContainsKey('ssh_authorized_keys'))
        {
            $user.Add('ssh_authorized_keys', @())
        }

        $user.ssh_authorized_keys += $PublicKey
    }
}
