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
    $script:un.Add('@^server-product-environment')
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
        if ($p -eq '@^server-product-environment' -or $p -in $required) { continue }

        $null = $script:un.Add($p)

        if ($p -like '*gnome*' -and $script:un -notcontains '@^graphical-server-environment') { $script:un.Add('@^graphical-server-environment')}
    }

    foreach ($p in $required)
    {
        $script:un.Add($p)
    }

    $script:un.Add('%end')
}
