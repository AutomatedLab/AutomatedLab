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
    $required = @(
        'oddjob'
        'oddjob-mkhomedir'
        'sssd'
        'adcli'
        'krb5-workstation'
        'realmd'
        'samba-common'
        'samba-common-tools'
        'authselect-compat'
        'sshd'
    )

    foreach ($p in $Package)
    {
        if ($p -eq 'core' -or $p -in $required) { continue }

        $script:un.Add(('@{0}' -f $p))

        if ($p -like '*gnome*') { $script:un.Add('@^graphical-server-environment')}
    }

    foreach ($p in $required)
    {
        $script:un.Add($p)
    }

    $script:un.Add('%end')
}
