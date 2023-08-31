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
	
	$script:un['autoinstall']['user-data']['write_files'] += @{
		append  = $false
		path    = '/etc/cron.d/realmjoin'
		content = if ($OrganizationalUnit)
		{
			"@reboot root echo '{0}' | realm join --computer-ou='{2}' -U {3} {1}`n" -f $Password, $DomainName, $OrganizationalUnit, $UserName
		}
		else
		{
			"@reboot root echo '{0}' | realm join -U {2} {1}`n" -f $Password, $DomainName, $UserName
		}
	}
	$script:un['autoinstall']['user-data']['write_files'] += @{
		append  = $true
		path    = '/etc/sudoers'
		content = '%Domain\ Admins ALL=(ALL:ALL) NOPASSWD:ALL'
	}
}
