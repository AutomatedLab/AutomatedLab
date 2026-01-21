function Select-LabProxmoxNode {
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]$NodeName
    )

    if (-not (Test-LabProxmoxConnection)) {
        Write-Error 'There is no connection to the Proxmox cluster.'
        return
    }

    $nodes = Get-PveNodes

    if ($nodes.StatusCode -ne 200) {
        Write-Error "Failed to retrieve nodes from Proxmox cluster: $($nodes.ReasonPhrase)"
        return
    }

    if ($nodes.Response.data.Count -eq 0) {
        Write-Error 'No nodes found in the Proxmox cluster.'
        return
    }

    if ($nodes.Response.data.Count -eq 1 -and -not $NodeName) {
        Write-ScreenInfo -Message "Only one node found. Selecting the only available node: $($nodes.Response.data[0].node)" -Type Verbose
        return $nodes.Response.data[0]
    }
    elseif ($nodes.Response.data.Count -eq 1 -and -not $nodes.Response.data[0].node -eq $NodeName) {
        Write-Error "The specified node '$NodeName' does not exist in the Proxmox cluster."
        return
    }

    $selectedNode = $nodes.Response.data | Where-Object { $_.node -eq $NodeName }

    if (-not $selectedNode) {
        Write-Error "The specified node '$NodeName' does not exist in the Proxmox cluster."
        return
    }

    return $selectedNode
}
