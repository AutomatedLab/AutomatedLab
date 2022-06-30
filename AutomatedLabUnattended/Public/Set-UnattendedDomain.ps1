function Set-UnattendedDomain
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
		[string]$OrganizationalUnit,

        [switch]
        $IsKickstart,

        [switch]
        $IsAutoYast
	)

	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}

    if ($IsKickstart) { Set-UnattendedKickstartDomain -DomainName $DomainName -Username $Username -Password $Password -OrganizationalUnit $OrganizationalUnit; return }
    if ($IsAutoYast) { Set-UnattendedYastDomain -DomainName $DomainName -Username $Username -Password $Password -OrganizationalUnit $OrganizationalUnit; return }
    Set-UnattendedWindowsDomain -DomainName $DomainName -Username $Username -Password $Password -OrganizationalUnit $OrganizationalUnit
}
