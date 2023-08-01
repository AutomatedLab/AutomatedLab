function Set-UnattendedCloudInitFirewallState
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[boolean]$State
	)

    $script:un['late-commands'] += 'ufw enable'
    $script:un['late-commands'] += 'ufw allow 22'
}