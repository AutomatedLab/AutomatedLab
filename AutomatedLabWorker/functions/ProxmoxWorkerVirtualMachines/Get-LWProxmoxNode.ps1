function Get-LWProxmoxNode
{
    <#
    .SYNOPSIS
        Retrieves Proxmox cluster nodes.

    .DESCRIPTION
        Retrieves information about Proxmox cluster nodes. Can filter by node name or return all nodes
        sorted by name.

    .PARAMETER Name
        The name(s) of the Proxmox node(s) to retrieve. If not specified, all nodes are returned.

    .EXAMPLE
        Get-LWProxmoxNode

        Gets all Proxmox nodes in the cluster.

    .EXAMPLE
        Get-LWProxmoxNode -Name 'pve1', 'pve2'

        Gets specific Proxmox nodes by name.
    #>
    param (
        [Parameter()]
        [string[]]$Name
    )

    Write-LogFunctionEntry

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    $maxRetries = 3
    $retryDelaySec = 10
    $attempt = 0
    $result = $null

    while ($attempt -lt $maxRetries)
    {
        $attempt++
        $result = Get-PveNodes

        if ($result.StatusCode -eq 200)
        {
            break
        }

        if ($attempt -lt $maxRetries)
        {
            Write-ScreenInfo -Message "Could not retrieve Proxmox nodes (StatusCode '$($result.StatusCode)'). Retrying in $retryDelaySec seconds (attempt $attempt of $maxRetries)..." -Type Warning
            Start-Sleep -Seconds $retryDelaySec

            # Refresh the connection in case the ticket expired or the session dropped
            Connect-LabProxmoxCluster -RefreshExistingConnection
        }
    }

    if ($result.StatusCode -ne 200)
    {
        Write-Error "Could not retrieve Proxmox nodes after $maxRetries attempts: The error was '$($result.StatusCode)'" -ErrorAction Stop
    }

    $result = if ($Name)
    {
        $result.Response.data | Where-Object { $Name -contains $_.node }
    }
    else
    {
        $result.Response.data | Sort-Object -Property node
    }

    $result | Add-Member -Name ToString -MemberType ScriptMethod -Value { $this.node } -Force
    $result

    Write-LogFunctionExit
}
