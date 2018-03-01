function Set-UnattendedKickstartAdministratorPassword
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Password
    )
		
		$Script:un += "rootpw $Password"
		$Script:un = $Script:un -replace '%PASSWORD%', $Password
}