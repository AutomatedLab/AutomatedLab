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
        # Connection failed - attempt reconnection with retries if we have stored credentials
        if ($script:connectionData)
        {
            $maxRetries = 3
            $retryDelays = @(5, 15, 30)

            for ($attempt = 1; $attempt -le $maxRetries; $attempt++)
            {
                Write-ScreenInfo -Message "Proxmox API returned status $($result.StatusCode). Reconnection attempt $attempt of $maxRetries..." -Type Warning

                if ($attempt -gt 1)
                {
                    $delay = $retryDelays[$attempt - 1]
                    Write-ScreenInfo -Message "Waiting $delay seconds before retry..." -Type Warning
                    Start-Sleep -Seconds $delay
                }

                Connect-LabProxmoxCluster -RefreshExistingConnection

                $result = Get-PveClusterStatus -ErrorAction SilentlyContinue
                if ($result.StatusCode -eq 200)
                {
                    Write-ScreenInfo -Message 'Successfully reconnected to Proxmox cluster.' -Type Info
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
