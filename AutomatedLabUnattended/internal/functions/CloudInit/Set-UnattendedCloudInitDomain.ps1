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

	if ($script:un['autoinstall']['user-data']['hostname'])
	{
		$script:un['autoinstall']['user-data']['fqdn'] = '{0}.{1}' -f $script:un['autoinstall']['user-data']['hostname'].ToLower(), $DomainName
	}

	$script:un['autoinstall']['late-commands'] += 'curtin in-target --target=/target -- apt install -yq realmd sssd-tools sssd libnss-sss libpam-sss adcli policycoreutils'

	if ($OrganizationalUnit)
	{
		$script:un['autoinstall']['late-commands'] += "curtin in-target --target=/target -- echo '{0}' | realm join --computer-ou='{2}' -U {3} {1}" -f $Password, $DomainName, $OrganizationalUnit, $UserName
	}
	else
	{
		$script:un['autoinstall']['late-commands'] += "curtin in-target --target=/target -- echo '{0}' | realm join -U {2} {1}" -f $Password, $DomainName, $UserName
	}
}
