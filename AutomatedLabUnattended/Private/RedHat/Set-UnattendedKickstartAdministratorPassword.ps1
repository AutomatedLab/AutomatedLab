function Set-UnattendedKickstartAdministratorPassword
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Password
    )
		
		$Script:un += "`nrootpw $Password"
}