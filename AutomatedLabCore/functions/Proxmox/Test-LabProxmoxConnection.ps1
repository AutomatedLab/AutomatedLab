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
        Write-ScreenInfo -Message "Proxmox cluster connection ticket is older than $maxTicketLifetime minutes. Reconnecting..." -Type Verbose
        Connect-LabProxmoxCluster -RefreshExistingConnection
    }

    $result = Get-PveClusterStatus -ErrorAction SilentlyContinue

    if ($result.StatusCode -ne 200)
    {
        Write-ScreenInfo -Message "Failed to connect to Proxmox cluster: $($result.ReasonPhrase)" -Type Verbose
        return $false
    }
    else
    {
        return $true
    }
}
