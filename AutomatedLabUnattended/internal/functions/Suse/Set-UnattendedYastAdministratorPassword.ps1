function Set-UnattendedYastAdministratorPassword
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Password
    )

		$passwordNodes = $script:un.SelectNodes('/un:profile/un:users/un:user/un:user_password', $script:nsm)

		foreach ($node in $passwordNodes)
		{
			$node.InnerText = $Password
		}
}