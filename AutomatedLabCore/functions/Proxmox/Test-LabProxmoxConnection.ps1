function Test-LabProxmoxConnection {
    [CmdletBinding()]
    param
    ()

    try {
        Get-PveCluster -ErrorAction SilentlyContinue
    }
    catch {
        Write-Verbose "Failed to call 'Get-PveCluster'."
    }

    if ($result.StatusCode -ne 200) {
        Write-Verbose "Failed to connect to Proxmox cluster: $($result.ReasonPhrase)"
        return $false
    }
    else {
        return $true
    }
}
