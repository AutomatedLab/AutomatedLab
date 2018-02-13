function Set-UnattendedKickstartAdministratorName
{
    param
    (
        $Name
    )

    $script:un += "user --name=$Name --groups=wheel --password=%PASSWORD%"
}