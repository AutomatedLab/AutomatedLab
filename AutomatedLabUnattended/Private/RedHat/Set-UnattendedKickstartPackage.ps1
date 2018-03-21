function Set-UnattendedKickstartPackage
{
    param
    (
        [string[]]$Package
    )

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