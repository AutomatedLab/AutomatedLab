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

    # PATCH (ProjectDagger, 2026-05-13): probe with Get-PveVersion instead of
    # Get-PveClusterStatus. Get-PveClusterStatus requires 'Sys.Audit' on '/',
    # which API tokens do not have unless an admin grants it explicitly. The
    # /version endpoint is the standard "is the API reachable and is my auth
    # valid" probe and works for every authenticated principal (user or
    # token) without any RBAC grants. This fixes the 50-second hang and the
    # spurious 'no connection to the Proxmox cluster' for token sessions.
    $result = Get-PveVersion -ErrorAction SilentlyContinue

    if ($result.StatusCode -ne 200)
    {
        # Connection failed - attempt reconnection with retries if we have stored credentials
        if ($script:connectionData)
        {
            $maxRetries = 3
            $retryDelays = @(5, 15, 30)

            for ($attempt = 1; $attempt -le $maxRetries; $attempt++)
            {
                Write-ScreenInfo -Message "Proxmox API returned status $($result.StatusCode). Reconnection attempt $attempt of $maxRetries..." -Type Verbose

                if ($attempt -gt 1)
                {
                    $delay = $retryDelays[$attempt - 1]
                    Write-ScreenInfo -Message "Waiting $delay seconds before retry..." -Type Verbose
                    Start-Sleep -Seconds $delay
                }

                Connect-LabProxmoxCluster -RefreshExistingConnection

                $result = Get-PveVersion -ErrorAction SilentlyContinue
                if ($result.StatusCode -eq 200)
                {
                    Write-ScreenInfo -Message 'Successfully reconnected to Proxmox cluster.' -Type Verbose
                    return $true
                }
            }
        }

        Write-ScreenInfo -Message "Failed to connect to Proxmox cluster after all retry attempts: $($result.ReasonPhrase)" -Type Verbose
        return $false
    }
    else
    {
        return $true
    }
}
