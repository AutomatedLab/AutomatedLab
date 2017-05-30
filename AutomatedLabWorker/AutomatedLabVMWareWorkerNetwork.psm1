#region Get-LWVMWareNetworkSwitch
function Get-LWVMWareNetworkSwitch
{
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.VirtualNetwork[]]$VirtualNetwork
    )
	
    Write-LogFunctionEntry

    foreach ($name in $VirtualNetwork)
    {
        $network = Get-VDPortgroup -Name $Name

        if (-not $network)
        {
            Write-Error "Network '$Name' is not configured"
        }

        $network
    }
	
    Write-LogFunctionExit
}
#endregion Get-LWVMWareNetworkSwitch