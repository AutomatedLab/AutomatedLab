function Set-UnattendedFirewallState
{
	param (
		[Parameter(Mandatory = $true)]
		[boolean]$State,

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

    if ($IsKickstart) { Set-UnattendedKickstartFirewallState -State $State; return }

    if ($IsAutoYast) { Set-UnattendedYastFirewallState -State $State; return }

    Set-UnattendedWindowsFirewallState -State $State
}