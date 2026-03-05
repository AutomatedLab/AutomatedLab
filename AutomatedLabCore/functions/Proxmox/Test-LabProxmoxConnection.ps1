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
        # Connection failed - attempt reconnection if we have stored credentials
        if ($script:connectionData)
        {
            Write-ScreenInfo -Message "Proxmox API returned status $($result.StatusCode). Attempting reconnection..." -Type Warning
            Connect-LabProxmoxCluster -RefreshExistingConnection

            $result = Get-PveClusterStatus -ErrorAction SilentlyContinue
            if ($result.StatusCode -eq 200)
            {
                Write-ScreenInfo -Message 'Successfully reconnected to Proxmox cluster.' -Type Info
                return $true
            }
        }

        Write-ScreenInfo -Message "Failed to connect to Proxmox cluster: $($result.ReasonPhrase)" -Type Verbose
        return $false
    }
    else
    {
        return $true
    }
}
