function Set-UnattendedKickstartFirewallState
{
    param
    (
        [Parameter(Mandatory = $true)]
        [boolean]$State
    )

    if ($State)
    {
        $script:un.Add('firewall --enabled')
    }
    else
    {
        $script:un.Add('firewall --disabled')
    }
}
