function Get-LWProxmoxNode
{
    <#
    .SYNOPSIS
        Retrieves Proxmox cluster nodes.

    .DESCRIPTION
        Retrieves information about Proxmox cluster nodes. Can filter by node name or return all nodes
        sorted by name.

        Only nodes that can actually host a VM are returned: the cluster must report them as 'online'
        and they must report CPU and memory capacity. A node that is part of the cluster configuration
        but not available - for example a node that was physically removed without being deleted from
        the cluster - is skipped, so no lab machine is ever placed on it and no API call is directed at
        it. An explicit -Name request is always honoured, and -IncludeUnavailable returns the full
        cluster membership. When no node is left, the function fails instead of returning an empty list.

    .PARAMETER Name
        The name(s) of the Proxmox node(s) to retrieve. If not specified, all nodes are returned.
        Nodes requested by name are returned regardless of their status.

    .PARAMETER IncludeUnavailable
        Returns cluster nodes regardless of their status. Use this switch to inspect the cluster
        membership, for example to verify that a lab machine's target node belongs to the connected
        cluster. Do not use it to select a node for a deployment.

    .PARAMETER TestNodeConnection
        Additionally verifies that every remaining node answers a node-scoped API call. This catches a
        node the cluster still reports as online but whose name no longer resolves, which otherwise
        surfaces much later as "hostname lookup '<node>' failed" on every VM operation. Costs one extra
        API call per node, so use it when selecting nodes for a deployment rather than on every query.

    .EXAMPLE
        Get-LWProxmoxNode

        Gets all Proxmox nodes in the cluster that can host a VM.

    .EXAMPLE
        Get-LWProxmoxNode -Name 'pve1', 'pve2'

        Gets specific Proxmox nodes by name.

    .EXAMPLE
        Get-LWProxmoxNode -IncludeUnavailable

        Gets all nodes known to the cluster, including nodes that are offline or in an unknown state.

    .EXAMPLE
        Get-LWProxmoxNode -TestNodeConnection

        Gets all usable nodes and additionally proves that each one answers node-scoped API calls.
    #>
    param (
        [Parameter()]
        [string[]]$Name,

        [Parameter()]
        [switch]$IncludeUnavailable,

        [Parameter()]
        [switch]$TestNodeConnection
    )

    Write-LogFunctionEntry

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    $result = Invoke-LWProxmoxCallWithRetry -ActivityName 'Retrieve Proxmox nodes' -ScriptBlock { Get-PveNodes }

    if ($result.StatusCode -ne 200)
    {
        Write-Error "Could not retrieve Proxmox nodes: The error was '$($result.StatusCode)'" -ErrorAction Stop
    }

    $result = if ($Name)
    {
        $result.Response.data | Where-Object { $Name -contains $_.node }
    }
    else
    {
        $result.Response.data | Sort-Object -Property node
    }

    if (-not $IncludeUnavailable -and -not $Name)
    {
        $availableNodes = [System.Collections.Generic.List[object]]::new()
        $unavailableNodes = [System.Collections.Generic.List[string]]::new()

        foreach ($candidate in $result)
        {
            $status = "$($candidate.status)"
            if ($status -ne 'online')
            {
                $unavailableNodes.Add("$($candidate.node) (cluster reports '$(if ($status) { $status } else { 'no status' })')")
                continue
            }

            # A node removed from the hardware but not from the cluster configuration is still listed,
            # but without any capacity.
            if (-not ($candidate.maxcpu -as [double]) -or -not ($candidate.maxmem -as [double]))
            {
                $unavailableNodes.Add("$($candidate.node) (reports no CPU or memory capacity)")
                continue
            }

            if ($TestNodeConnection)
            {
                $nodeAnswers = try
                {
                    (Get-PveNodesStatus -Node $candidate.node -ErrorAction Stop).StatusCode -eq 200
                }
                catch
                {
                    $false
                }

                if (-not $nodeAnswers)
                {
                    $unavailableNodes.Add("$($candidate.node) (does not answer node-scoped API calls)")
                    continue
                }
            }

            $availableNodes.Add($candidate)
        }

        if ($unavailableNodes.Count -gt 0)
        {
            $unavailableNodeInfo = $unavailableNodes -join ', '
            Write-PSFMessage -Message "Skipping unavailable Proxmox node(s): $unavailableNodeInfo"

            # Warn on screen only for nodes not reported before. Get-LWProxmoxNode runs on every VM
            # operation, so an unconditional warning would flood the deployment output.
            $newlyUnavailableNodes = @($unavailableNodes | Where-Object { $_ -notin $script:proxmoxUnavailableNodes })
            if ($newlyUnavailableNodes)
            {
                $script:proxmoxUnavailableNodes = @($script:proxmoxUnavailableNodes | Where-Object { $_ }) + $newlyUnavailableNodes
                Write-ScreenInfo -Message "The following Proxmox node(s) are not available and will not be used: $unavailableNodeInfo. Use 'Get-LWProxmoxNode -IncludeUnavailable' to list all cluster nodes." -Type Warning
            }
        }

        if ($availableNodes.Count -eq 0)
        {
            $reason = if ($unavailableNodes.Count -gt 0) { "Skipped: $($unavailableNodes -join ', ')" } else { 'The cluster did not return any node.' }
            Write-Error "No Proxmox node of the connected cluster can host a virtual machine. $reason" -ErrorAction Stop
            return
        }

        $result = $availableNodes.ToArray()
    }

    $result | Add-Member -Name ToString -MemberType ScriptMethod -Value { $this.node } -Force
    $result

    Write-LogFunctionExit
}
