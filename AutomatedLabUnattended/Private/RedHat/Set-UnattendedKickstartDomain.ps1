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

	$script:un.Add(("realm join --one-time-password='{0}' {1}" -f $Password, $DomainName))
}
