function Set-UnattendedKickstartComputerName
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    $script:un +=  "network --hostname=$ComputerName"
}