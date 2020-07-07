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
        Write-PSFMessage -Level Warning -Message 'Adding KDE UI to RHEL/CentOS via kickstart file is not supported. Please configure your UI manually.'
    }

    $script:un.Add('%packages --ignoremissing')
    $script:un.Add('@core')

    foreach ($p in $Package)
    {
        if ($p -eq 'core') { continue }

        $script:un.Add(('@{0}' -f $p))

        if ($p -like '*gnome*') { $script:un.Add('@^graphical-server-environment')}
    }

    $script:un.Add('oddjob')
    $script:un.Add('oddjob-mkhomedir')
    $script:un.Add('sssd')
    $script:un.Add('adcli')
    $script:un.Add('krb5-workstation')
    $script:un.Add('realmd')
    $script:un.Add('samba-common')
    $script:un.Add('samba-common-tools')
    $script:un.Add('authselect-compat')
    $script:un.Add('%end')
}
