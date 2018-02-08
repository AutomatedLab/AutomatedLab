function Export-UnattendedKickstartFile
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $script:un += '%packages --ignoremissing'
    $script:un += '@core'
    $script:un += 'oddjob'
    $script:un += 'oddjob-mkhomedir'
    $script:un += 'sssd'
    $script:un += 'adcli'
    $script:un += '%end'
    $script:un | Set-Content -Path $Path -Force
}