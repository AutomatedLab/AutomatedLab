function Set-UnattendedKickstartAdministratorName
{
    param
    (
        $Name
    )

    $script:un.Add("user --name=$Name --groups=wheel --password='%PASSWORD%'")
}
