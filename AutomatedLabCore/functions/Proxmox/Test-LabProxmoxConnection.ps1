function Test-LabProxmoxConnection
{
    [CmdletBinding()]
    param
    ()
    
    $date = Get-Date
    $maxTicketLifetime = Get-LabConfigurationItem -Name MaxAuthTicketLifetimeMinutes

    if ($script:connectionData.TicketTimestamp -and
        $script:connectionData.TicketTimestamp -lt $date.AddMinutes(-$maxTicketLifetime))
    {
        Write-PSFMessage -Message "Proxmox cluster connection ticket is older than $maxTicketLifetime minutes. Reconnecting..." -Level Verbose
        Connect-LabProxmoxCluster -RefreshExistingConnection
    }

    $result = Get-PveClusterStatus -ErrorAction SilentlyContinue

    if ($result.StatusCode -ne 200)
    {
        Write-Verbose "Failed to connect to Proxmox cluster: $($result.ReasonPhrase)"
        return $false
    }
    else
    {
        return $true
    }
}
