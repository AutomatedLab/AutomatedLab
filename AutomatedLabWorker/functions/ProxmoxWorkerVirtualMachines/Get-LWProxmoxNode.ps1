function Get-LWProxmoxNode
{
    <#
    .SYNOPSIS
        Retrieves Proxmox cluster nodes.

    .DESCRIPTION
        Retrieves information about Proxmox cluster nodes. Can filter by node name or return all nodes
        sorted by name.

        Only nodes that report the status 'online' are returned. A node that is part of the cluster
        configuration but not available - for example a node that was physically removed without being
        deleted from the cluster - is skipped, so no lab machine is ever placed on it and no API call is
        directed at it. An explicit -Name request is always honoured, and -IncludeUnavailable returns the
        full cluster membership.

    .PARAMETER Name
        The name(s) of the Proxmox node(s) to retrieve. If not specified, all nodes are returned.
        Nodes requested by name are returned regardless of their status.

    .PARAMETER IncludeUnavailable
        Returns cluster nodes regardless of their status. Use this switch to inspect the cluster
        membership, for example to verify that a lab machine's target node belongs to the connected
        cluster. Do not use it to select a node for a deployment.

    .EXAMPLE
        Get-LWProxmoxNode

        Gets all online Proxmox nodes in the cluster.

    .EXAMPLE
        Get-LWProxmoxNode -Name 'pve1', 'pve2'

        Gets specific Proxmox nodes by name.

    .EXAMPLE
        Get-LWProxmoxNode -IncludeUnavailable

        Gets all nodes known to the cluster, including nodes that are offline or in an unknown state.
    #>
    param (
        [Parameter()]
        [string[]]$Name,

        [Parameter()]
        [switch]$IncludeUnavailable
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
        $unavailableNodes = @($result | Where-Object { $_.status -ne 'online' })

        if ($unavailableNodes)
        {
            $unavailableNodeInfo = ($unavailableNodes | ForEach-Object { "$($_.node) (status '$($_.status)')" }) -join ', '
            Write-PSFMessage -Message "Skipping unavailable Proxmox node(s): $unavailableNodeInfo"

            # Warn on screen only for nodes not reported before. Get-LWProxmoxNode runs on every VM
            # operation, so an unconditional warning would flood the deployment output.
            $newlyUnavailableNodes = @($unavailableNodes.node | Where-Object { $_ -notin $script:proxmoxUnavailableNodes })
            if ($newlyUnavailableNodes)
            {
                $script:proxmoxUnavailableNodes = @($script:proxmoxUnavailableNodes | Where-Object { $_ }) + $newlyUnavailableNodes
                Write-ScreenInfo -Message "The following Proxmox node(s) are not available and will not be used: $unavailableNodeInfo. Use 'Get-LWProxmoxNode -IncludeUnavailable' to list all cluster nodes." -Type Warning
            }

            $result = @($result | Where-Object { $_.status -eq 'online' })
        }
    }

    $result | Add-Member -Name ToString -MemberType ScriptMethod -Value { $this.node } -Force
    $result

    Write-LogFunctionExit
}
