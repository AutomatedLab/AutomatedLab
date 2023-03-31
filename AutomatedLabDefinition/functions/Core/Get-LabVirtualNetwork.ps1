function Get-LabVirtualNetwork
{
    [cmdletBinding()]

    $virtualnetworks = @()

    $switches = if ($IsLinux)
    {  
    }
    else
    {
        Get-VMSwitch 
    }

    foreach ($switch in $switches)
    {
        $network = New-Object AutomatedLab.VirtualNetwork
        $network.Name = $switch.Name
        $network.SwitchType = $switch.SwitchType.ToString()
        $ipAddress = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.InterfaceAlias -eq "vEthernet ($($network.Name))" -and $_.PrefixOrigin -eq 'manual' } |
        Select-Object -First 1

        if ($ipAddress)
        {
            $network.AddressSpace = "$($ipAddress.IPAddress)/$($ipAddress.PrefixLength)"
        }

        $virtualnetworks += $network
    }

    $virtualnetworks
}
