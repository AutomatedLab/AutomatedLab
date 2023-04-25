function Set-UnattendedKickstartDomain
{
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

	if ($OrganizationalUnit)
	{
		$script:un.Add(("realm join --computer-ou='{2}' --one-time-password='{0}' {1}" -f $Password, $DomainName, $OrganizationalUnit))

	}
	else
	{
		$script:un.Add(("realm join --one-time-password='{0}' {1}" -f $Password, $DomainName))
	}
}
