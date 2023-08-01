function New-LabNetworkSwitches
{
    [cmdletBinding()]
    param ()

    Write-LogFunctionEntry

    $Script:data = Get-Lab
    if (-not $Script:data)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $vmwareNetworks = $data.VirtualNetworks | Where-Object HostType -eq VMWare
    if ($vmwareNetworks)
    {
        foreach ($vmwareNetwork in $vmwareNetworks)
        {
            $network = Get-LWVMWareNetworkSwitch -VirtualNetwork $vmwareNetwork
            if (-not $vmwareNetworks)
            {
                throw "The networks '$($vmwareNetwork.Name)' does not exist and must be created before."
            }
            else
            {
                Write-PSFMessage "Network '$($vmwareNetwork.Name)' found"
            }
        }
    }

    Write-PSFMessage "Creating network switch '$($virtualNetwork.ResourceName)'..."

    $hypervNetworks = $data.VirtualNetworks | Where-Object HostType -eq HyperV
    if ($hypervNetworks)
    {
        New-LWHypervNetworkSwitch -VirtualNetwork $hypervNetworks
    }

    Write-PSFMessage 'done'

    Write-LogFunctionExit
}
