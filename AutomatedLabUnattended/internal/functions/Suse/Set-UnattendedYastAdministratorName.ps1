function Set-UnattendedYastAdministratorName
{
    param
    (
        $Name
    )

    $userNode = $script:un.SelectSingleNode('/un:profile/un:users', $script:nsm)

    $user = $script:un.CreateElement('user', $script:nsm.LookupNamespace('un'))
    $username = $script:un.CreateElement('username', $script:nsm.LookupNamespace('un'))
    $pw = $script:un.CreateElement('user_password', $script:nsm.LookupNamespace('un'))
    $encrypted = $script:un.CreateElement('encrypted', $script:nsm.LookupNamespace('un'))
    $listAttr = $script:un.CreateAttribute('config','type', $script:nsm.LookupNamespace('config'))
    $listAttr.InnerText = 'boolean'
    $null = $encrypted.Attributes.Append($listAttr)

    $encrypted.InnerText = 'false'
    $pw.InnerText = 'none'
    $username.InnerText = $Name

    $null = $user.AppendChild($pw)
    $null = $user.AppendChild($encrypted)
    $null = $user.AppendChild($username)

    $null = $userNode.AppendChild($user)
}