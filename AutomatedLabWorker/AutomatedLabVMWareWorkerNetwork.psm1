#region Get-LWVMWareNetworkSwitch
function Get-LWVMWareNetworkSwitch
{
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.VirtualNetwork[]]$VirtualNetwork
    )
	
    Write-LogFunctionEntry

    foreach ($network in $VirtualNetwork)
    {
        $network = Get-VDPortgroup -Name $network.Name

        if (-not $network)
        {
            Write-Error "Network '$Name' is not configured"
        }

        $network
    }
	
    Write-LogFunctionExit
}
#endregion Get-LWVMWareNetworkSwitch