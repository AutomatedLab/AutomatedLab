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

	$script:un['autoinstall']['user-data']['fqdn'] = '{0}.{1}' -f $script:un['autoinstall']['user-data']['hostname'], $DomainName

	if ($OrganizationalUnit)
	{
		$script:un['autoinstall']['late-commands'] += "realm join --computer-ou='{2}' --one-time-password='{0}' {1}" -f $Password, $DomainName, $OrganizationalUnit
	}
	else
	{
		$script:un['autoinstall']['late-commands'] += "realm join --one-time-password='{0}' {1}" -f $Password, $DomainName
	}
}
