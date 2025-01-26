function Add-UnattendedYastSshPublicKey
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $PublicKey
    )

    <#
    <authorized_keys config:type="list">
    <listentry>ssh-rsa ...</listentry>
    </authorized_keys>
    #>
    $userNode = $script:un.SelectSingleNode('/un:profile/un:users', $script:nsm)
    foreach ($user in $userNode.ChildNodes)
    {
        if (-not $user.authorized_keys)
        {
            $keyNode = $script:un.CreateElement('authorized_keys', $script:nsm.LookupNamespace('un'))
            $keyNode.SetAttribute('type', $script:nsm.LookupNamespace('config'), 'list')
            $null = $user.AppendChild($keyNode)
        }

        $keyNode = $user.authorized_keys
        if ($keyNode.listentry -contains $PublicKey) { continue }
        $listEntry = $script:un.CreateElement('listentry', $script:nsm.LookupNamespace('un'))
        $listEntry.InnerText = $PublicKey
        $null = $keyNode.AppendChild($listEntry)
    }
}
