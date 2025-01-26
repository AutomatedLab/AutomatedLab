function Set-UnattendedCloudInitFirewallState
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[boolean]$State
	)

    $script:un['autoinstall']['late-commands'] += 'curtin in-target --target=/target -- ufw enable 2>/dev/null || true'
    $script:un['autoinstall']['late-commands'] += 'curtin in-target --target=/target -- ufw allow 22 2>/dev/null || true'
}