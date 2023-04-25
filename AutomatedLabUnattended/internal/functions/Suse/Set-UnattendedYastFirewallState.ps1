function Set-UnattendedYastFirewallState
{
	param (
		[Parameter(Mandatory = $true)]
		[boolean]$State
		)

		$fwState = $script:un.SelectSingleNode('/un:profile/un:firewall/un:enable_firewall', $script:nsm)
		$fwState.InnerText = $State.ToString().ToLower()
}