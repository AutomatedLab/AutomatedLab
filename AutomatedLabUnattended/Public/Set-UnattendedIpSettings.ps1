function Set-UnattendedIpSettings
{
    param (
        [string]$IpAddress,

        [string]$Gateway,

        [String[]]$DnsServers,

        [string]$DnsDomain,

        [switch]
        $IsKickstart,

        [switch]
        $IsAutoYast
    )

    if (-not $script:un)
    {
        Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
        return
    }



    if ($IsKickstart)
    {
        $parameters = Sync-Parameter (Get-Command Set-UnattendedKickstartIpSettings) -Parameters $PSBoundParameters
        Set-UnattendedKickstartIpSettings @parameters
        return
    }
    if ($IsAutoYast)
    {
        $parameters = Sync-Parameter (Get-Command Set-UnattendedYastIpSettings) -Parameters $PSBoundParameters
        Set-UnattendedYastIpSettings @parameters
        return
    }

    $parameters = Sync-Parameter (Get-Command Set-UnattendedWindowsIpSettings) -Parameters $PSBoundParameters
    Set-UnattendedWindowsIpSettings @parameters
}