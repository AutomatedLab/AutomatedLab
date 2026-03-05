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

    $maxRetries = 3
    $retryDelaySeconds = 5

    $vms = Get-LWProxmoxVM @PSBoundParameters
    if (-not $vms)
    {
        Write-Error "VM with name '$ComputerName' not found."
        return
    }

    $configs = foreach ($vm in $vms)
    {
        $vmConfig = $null
        for ($attempt = 1; $attempt -le $maxRetries; $attempt++)
        {
            $vmConfig = Get-PveNodesQemuConfig -Vmid $vm.VMID -Node $vm.node

            if ($vmConfig.StatusCode -eq 200)
            {
                break
            }

            if ($attempt -lt $maxRetries)
            {
                Write-PSFMessage -Message "Failed to get VM config for VM '$($vm.Name)' (VMID: $($vm.VMID)) on node '$($vm.node)'. StatusCode: $($vmConfig.StatusCode). Retrying in $retryDelaySeconds seconds (attempt $attempt of $maxRetries)..."
                Start-Sleep -Seconds $retryDelaySeconds
            }
        }

        if ($vmConfig.StatusCode -ne 200)
        {
            Write-Error "Failed to get VM config for VM '$($vm.Name)' (VMID: $($vm.VMID)) on node '$($vm.node)'. StatusCode: $($vmConfig.StatusCode) after $maxRetries attempts."
            continue
        }

        $vmConfig.Response.data
    }

    return $configs
}
