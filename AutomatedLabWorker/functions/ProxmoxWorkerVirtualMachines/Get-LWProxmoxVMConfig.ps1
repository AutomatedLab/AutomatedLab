function Get-LWProxmoxVMConfig
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string[]]$ComputerName,

        [Parameter(ValueFromPipeline = $true)]
        [object]$Node,

        [Parameter()]
        [switch]
        $NoCache,

        [Parameter()]
        [switch]
        $IncludeTemplates
    )

    $vms = Get-LWProxmoxVM @PSBoundParameters
    if (-not $vms)
    {
        Write-Error "VM with name '$Name' not found."
        return
    }

    $configs = foreach ($vm in $vms)
    {
        $vmConfig = Get-PveNodesQemuConfig -Vmid $vm.VMID -Node $vm.node

        if ($vmConfig.StatusCode -ne 200)
        {
            Write-Error "Failed to get VM config for VM '$Name' (VMID: $($vm.VMID)) on node '$node'."
            return
        }

        $vmConfig.Response.data
    }

    return $configs
}
