function Set-UnattendedKickstartComputerName
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    $script:un.Add("network --hostname=$ComputerName")
}
