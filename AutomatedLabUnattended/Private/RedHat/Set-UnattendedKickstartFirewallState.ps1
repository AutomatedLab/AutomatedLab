function Set-UnattendedKickstartFirewallState
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [boolean]$State
    )
		
    $script:un += if ($State)
    {
        'firewall --enabled'
    }
    else
    {
        'firewall --disabled'
    }
}