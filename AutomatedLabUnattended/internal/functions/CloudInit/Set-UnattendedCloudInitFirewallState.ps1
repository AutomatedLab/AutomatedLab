function Set-UnattendedCloudInitFirewallState
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[boolean]$State
	)

    $script:un['autoinstall']['late-commands'] += 'ufw enable'
    $script:un['autoinstall']['late-commands'] += 'ufw allow 22'
}