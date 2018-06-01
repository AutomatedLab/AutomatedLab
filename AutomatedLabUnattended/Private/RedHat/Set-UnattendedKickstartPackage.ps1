function Set-UnattendedKickstartPackage
{
    param
    (
        [string[]]$Package
    )

    if ($Package -like '*Gnome*')
    {
        $script:un += 'xconfig  --defaultdesktop=GNOME'
    }
    elseif ($Package -like '*KDE*')
    {
        $script:un += 'xconfig  --defaultdesktop=KDE'
    }

    $script:un += '%packages --ignoremissing'
    $script:un += '@core'    

    foreach ($p in $Package)
    {
        if ($p -eq 'core') { continue }
        
        $script:un += '@{0}' -f $p
    }

    $script:un += 'oddjob'
    $script:un += 'oddjob-mkhomedir'
    $script:un += 'sssd'
    $script:un += 'adcli'
    $script:un += '%end'
}