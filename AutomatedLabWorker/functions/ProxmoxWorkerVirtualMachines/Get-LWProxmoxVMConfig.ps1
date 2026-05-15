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
        Write-Error "VM with name '$ComputerName' not found."
        return
    }

    $configs = foreach ($vm in $vms)
    {
        $vmConfig = Invoke-LWProxmoxCallWithRetry -ActivityName "Get VM config for '$($vm.Name)'" -RetryDelaySeconds 5 -ScriptBlock { Get-PveNodesQemuConfig -Vmid $vm.VMID -Node $vm.node }

        if ($vmConfig.StatusCode -ne 200)
        {
            Write-Error "Failed to get VM config for VM '$($vm.Name)' (VMID: $($vm.VMID)) on node '$($vm.node)'. StatusCode: $($vmConfig.StatusCode)."
            continue
        }

        $vmConfig.Response.data
    }

    return $configs
}
