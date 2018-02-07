function Add-UnattendedYastNetworkAdapter
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

        [string]$NetbiosOptions
    )
    
}