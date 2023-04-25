function Set-UnattendedKickstartAdministratorPassword
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Password
    )

		$Script:un.Add("rootpw '$Password'")
		$Script:un = [System.Collections.Generic.List[string]]($Script:un.Replace('%PASSWORD%', $Password))
}
