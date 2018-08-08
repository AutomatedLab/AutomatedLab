#region Get-LWVMwareNetworkSwitch
function Get-LWVMwareNetworkSwitch
{
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.VirtualNetwork[]]$VirtualNetwork
    )

    Write-LogFunctionEntry

    foreach ($network in $VirtualNetwork)
    {
        $network = Get-VirtualPortgroup -Name $network.Name -ErrorAction SilentlyContinue

        if (-not $network)
        {
            $network = Get-VDPortgroup -Name $network.Name -ErrorAction SilentlyContinue
        }

        if (-not $network)
        {
            Write-Error "Network '$Name' is not configured"
        }

        $network
    }

    Write-LogFunctionExit
}
#endregion Get-LWVMwareNetworkSwitch