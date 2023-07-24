function Set-UnattendedCloudInitDomain
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$DomainName,

		[Parameter(Mandatory = $true)]
		[string]$Username,

		[Parameter(Mandatory = $true)]
		[string]$Password,

		[Parameter()]
		[string]$OrganizationalUnit
	)

	$script:un.fqdn = '{0}.{1}' -f $script:un.hostname, $DomainName

	if ($OrganizationalUnit)
	{
		$script:un['late-commands'] += "realm join --computer-ou='{2}' --one-time-password='{0}' {1}" -f $Password, $DomainName, $OrganizationalUnit
	}
	else
	{
		$script:un['late-commands'] += "realm join --one-time-password='{0}' {1}" -f $Password, $DomainName
	}
}
