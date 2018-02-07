function Set-UnattendedKickstartComputerName
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    $script:un = $script:un -replace '%HOSTNAME%', $ComputerName
}