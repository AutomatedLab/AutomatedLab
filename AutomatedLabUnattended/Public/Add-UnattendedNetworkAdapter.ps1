function Add-UnattendedNetworkAdapter
{
    param (
        [string]$Interfacename,

        [AutomatedLab.IPNetwork[]]$IpAddresses,

        [AutomatedLab.IPAddress[]]$Gateways,

        [AutomatedLab.IPAddress[]]$DnsServers,

        [string]$ConnectionSpecificDNSSuffix,

        [string]$DnsDomain,

        [string]$UseDomainNameDevolution,

        [string]$DNSSuffixSearchOrder,

        [string]$EnableAdapterDomainNameRegistration,

        [string]$DisableDynamicUpdate,

        [string]$NetbiosOptions,

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
        $parameters = Sync-Parameter (Get-Command Add-UnattendedKickstartNetworkAdapter) -Parameters $PSBoundParameters
        Add-UnattendedKickstartNetworkAdapter @parameters
        return
    }
    if ($IsAutoYast)
    {
        $parameters = Sync-Parameter (Get-Command Add-UnattendedYastNetworkAdapter) -Parameters $PSBoundParameters
        Add-UnattendedYastNetworkAdapter @parameters
        return
    }

    $parameters = Sync-Parameter (Get-Command Add-UnattendedWindowsNetworkAdapter) -Parameters $PSBoundParameters
    Add-UnattendedWindowsNetworkAdapter @parameters
}