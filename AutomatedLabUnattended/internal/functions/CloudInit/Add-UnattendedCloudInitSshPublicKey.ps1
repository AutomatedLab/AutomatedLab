function Add-UnattendedCloudInitSshPublicKey
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $PublicKey
    )

    if (-not $script:un.ContainsKey('ssh_authorized_keys'))
    {
        $script:un.Add('ssh_authorized_keys', @())
    }

    $script:un.ssh_authorized_keys += $PublicKey
}
