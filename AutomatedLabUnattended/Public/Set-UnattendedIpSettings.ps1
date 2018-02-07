function Set-UnattendedIpSettings
{
	param (
		[string]$IpAddress,
		
		[string]$Gateway,
		
		[String[]]$DnsServers,

        [string]$DnsDomain,
        
        [Parameter(ParameterSetName = 'Kickstart')]
        [switch]
        $IsKickstart,

        [Parameter(ParameterSetName = 'Yast')]
        [switch]
        $IsAutoYast
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
    $parameters = Sync-Parameter (Get-Command Set-UnattendedWindowsIpSettings) -Parameters $PSBoundParameters
    
    if ($IsKickstart) { Set-UnattendedKickstartIpSettings @parameters; return }
    if ($IsAutoYast) { Set-UnattendedYastIpSettings @parameters; return }
    Set-UnattendedWindowsIpSettings @parameters
}