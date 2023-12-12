function Get-LabVirtualNetwork
{
    [cmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(ParameterSetName = 'ByName')]
        [string]$Name,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )

    $virtualnetworks = @()
    $lab = Get-Lab -ErrorAction SilentlyContinue

    if (-not $lab)
    {
        return
    }

    $switches = if ($IsLinux)
    {
        return
    }

    $switches = if ($Name)
    {
        $Name | foreach { Get-VMSwitch -Name $_ }
    }
    elseif ($All)
    {
        Get-VMSwitch
    }
    else
    {
        Get-VMSwitch | Where-Object Name -in $lab.VirtualNetworks.Name
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

        $network.Notes = Get-LWHypervNetworkSwitchDescription -NetworkSwitchName $switch.Name

        $virtualnetworks += $network
    }

    $virtualnetworks
}
