function Set-UnattendedKickstartDomain {
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

	if ($OrganizationalUnit) {
		$script:un.Add(("realm join --computer-ou='{2}' --one-time-password='{0}' {1}" -f $Password, $DomainName, $OrganizationalUnit))

	}
	else {
		$script:un.Add(("realm join --one-time-password='{0}' {1}" -f $Password, $DomainName))
	}

	$existingLine = $script:un | Where-Object { $_ -match 'network' }

	if ($existingLine -like '*--ipv4-dns-search*') {
		$index = $script:un.IndexOf($existingLine)
		$script:un[$index] = $existingLine -replace 'ipv4-dns-search=[\w\.]+', "--ipv4-dns-search=$DomainName"
		return
	}

	if ($existingLine) {
		$index = $script:un.IndexOf($existingLine)
		$script:un[$index] = '{0} {1}' -f $existingLine, "--ipv4-dns-search=$DomainName"
		return
	}

	$script:un.Add("network --ipv4-dns-search=$DomainName")
}
