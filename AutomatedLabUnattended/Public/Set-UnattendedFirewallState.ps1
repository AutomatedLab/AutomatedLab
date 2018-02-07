function Set-UnattendedFirewallState
{
	param (
		[Parameter(Mandatory = $true)]
		[boolean]$State,
        
        [Parameter(ParameterSetName = 'Kickstart')]
        [switch]
        $IsKickstart,

        [Parameter(ParameterSetName = 'Yast')]
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