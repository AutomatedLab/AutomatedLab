function Set-UnattendedCloudInitFirewallState
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[boolean]$State
	)

    $script:un['autoinstall']['late-commands'] += 'curtin in-target --target=/target -- ufw enable'
    $script:un['autoinstall']['late-commands'] += 'curtin in-target --target=/target -- ufw allow 22'
}