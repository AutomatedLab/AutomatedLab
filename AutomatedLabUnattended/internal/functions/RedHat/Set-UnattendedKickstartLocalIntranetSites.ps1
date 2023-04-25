function Set-UnattendedKickstartLocalIntranetSites
{
	param (
		[Parameter(Mandatory = $true)]
		[string[]]$Values
	)

	Write-PSFMessage -Message 'No local intranet sites for RHEL/CentOS/Fedora'
}
