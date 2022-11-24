function Add-UnattendedNetworkAdapter
{
	[CmdletBinding(DefaultParameterSetName = 'Windows')]
    param (
        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='Kickstart')]
        [Parameter(ParameterSetName='Yast')]
        [Parameter(ParameterSetName='CloudInit')]
        [string]$Interfacename,

        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='Kickstart')]
        [Parameter(ParameterSetName='Yast')]
        [Parameter(ParameterSetName='CloudInit')]
        [AutomatedLab.IPNetwork[]]$IpAddresses,

        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='Kickstart')]
        [Parameter(ParameterSetName='Yast')]
        [Parameter(ParameterSetName='CloudInit')]
        [AutomatedLab.IPAddress[]]$Gateways,

        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='Kickstart')]
        [Parameter(ParameterSetName='Yast')]
        [Parameter(ParameterSetName='CloudInit')]
        [AutomatedLab.IPAddress[]]$DnsServers,

        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='Kickstart')]
        [Parameter(ParameterSetName='Yast')]
        [Parameter(ParameterSetName='CloudInit')]
        [string]$ConnectionSpecificDNSSuffix,

        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='Kickstart')]
        [Parameter(ParameterSetName='Yast')]
        [Parameter(ParameterSetName='CloudInit')]
        [string]$DnsDomain,

        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='Kickstart')]
        [Parameter(ParameterSetName='Yast')]
        [Parameter(ParameterSetName='CloudInit')]
        [string]$UseDomainNameDevolution,

        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='Kickstart')]
        [Parameter(ParameterSetName='Yast')]
        [Parameter(ParameterSetName='CloudInit')]
        [string]$DNSSuffixSearchOrder,

        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='Kickstart')]
        [Parameter(ParameterSetName='Yast')]
        [Parameter(ParameterSetName='CloudInit')]
        [string]$EnableAdapterDomainNameRegistration,

        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='Kickstart')]
        [Parameter(ParameterSetName='Yast')]
        [Parameter(ParameterSetName='CloudInit')]
        [string]$DisableDynamicUpdate,

        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='Kickstart')]
        [Parameter(ParameterSetName='Yast')]
        [Parameter(ParameterSetName='CloudInit')]
        [string]$NetbiosOptions,

        [Parameter(ParameterSetName='Kickstart')]
        [switch]
        $IsKickstart,

        [Parameter(ParameterSetName='Yast')]
        [switch]
        $IsAutoYast,

        [Parameter(ParameterSetName='CloudInit')]
        [switch]
        $IsCloudInit
    )

	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}

    $command = Get-Command -Name $PSCmdlet.MyInvocation.MyCommand.Name.Replace('Unattended', "Unattended$($PSCmdlet.ParameterSetName)")
    $parameters = Sync-Parameter $command -Parameters $PSBoundParameters
    & $command @parameters
}