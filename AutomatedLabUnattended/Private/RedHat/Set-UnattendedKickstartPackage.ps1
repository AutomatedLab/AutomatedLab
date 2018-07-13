function Set-UnattendedKickstartPackage
{
    param
    (
        [string[]]$Package
    )

    if ($Package -like '*Gnome*')
    {
        $script:un.Add('xconfig --startxonboot --defaultdesktop=GNOME')
    }
    elseif ($Package -like '*KDE*')
    {
        Write-Warning -Message 'Adding KDE UI to RHEL/CentOS via kickstart file is not supported.'
    }

    $script:un.Add('%packages --ignoremissing')
    $script:un.Add('@core')

    foreach ($p in $Package)
    {
        if ($p -eq 'core') { continue }

        $script:un.Add(('@{0}' -f $p))
    }

    $script:un.Add('oddjob')
    $script:un.Add('oddjob-mkhomedir')
    $script:un.Add('sssd')
    $script:un.Add('adcli')
    $script:un.Add('krb5-workstation')
    $script:un.Add('%end')
}
