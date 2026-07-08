function Invoke-LWProxmoxCallWithRetry
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [string]$ActivityName = 'Proxmox API call',

        [Parameter()]
        [int]$MaxRetries = 3,

        [Parameter()]
        [int]$RetryDelaySeconds = 10,

        [Parameter()]
        [int]$MaxDelaySeconds = 30,

        [Parameter()]
        [switch]$ProgressiveBackoff
    )

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++)
    {
        # Suppress progress bars from Invoke-RestMethod inside the Proxmox API module.
        # Without this, the progress output fragments progress-dot streams into
        # individual lines during long-running wait loops (e.g. DC restart waits).
        $ProgressPreference = 'SilentlyContinue'
        $result = & $ScriptBlock

        if ($result.StatusCode -eq 200)
        {
            return $result
        }

        Write-PSFMessage -Message "$ActivityName failed with status $($result.StatusCode): $($result.ReasonPhrase). Attempt $attempt of $MaxRetries."

        if ($attempt -lt $MaxRetries)
        {
            # Validate and refresh the connection before retrying
            if (-not (Test-LabProxmoxConnection))
            {
                Write-PSFMessage -Message 'Proxmox connection lost. Reconnection was attempted by Test-LabProxmoxConnection.'
            }
            $delay = if ($ProgressiveBackoff.IsPresent)
            {
                [math]::Min([int]($RetryDelaySeconds * [math]::Pow(2, $attempt - 1)), $MaxDelaySeconds)
            }
            else
            {
                $RetryDelaySeconds
            }
            Start-Sleep -Seconds $delay
        }
    }

    # Return the last failed result so callers can inspect StatusCode/ReasonPhrase
    return $result
}

function Wait-LWProxmoxGuestAgentReady
{
    # Pinging the agent - and even guest-file-write - succeeds BEFORE the agent's guest-exec
    # (process-spawning) subsystem is ready; under host load guest-exec also intermittently
    # returns 'not running' / 'got timeout'. Phase 1 waits for a ping; with -RequireExec,
    # Phase 2 probes a trivial 'cmd /c ver' guest-exec until it actually executes.
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)] [string]$Node,
        [Parameter(Mandatory)] [int]$Vmid,
        [Parameter()] [string]$Name = "VMID $Vmid",
        [Parameter()] [int]$TimeoutSeconds = 300,
        [Parameter()] [int]$PollIntervalSeconds = 3,
        [switch]$RequireExec
    )

    $ProgressPreference = 'SilentlyContinue'
    $timer = [System.Diagnostics.Stopwatch]::StartNew()

    $pingReady = $false
    while ($timer.Elapsed.TotalSeconds -lt $TimeoutSeconds)
    {
        try
        {
            $pingResult = New-PveNodesQemuAgentPing -Node $Node -Vmid $Vmid -ErrorAction Stop 2>$null
            if ($pingResult.StatusCode -eq 200) { $pingReady = $true; break }
        }
        catch { }
        Start-Sleep -Seconds $PollIntervalSeconds
    }

    if (-not $pingReady)
    {
        Write-PSFMessage -Level Warning -Message "QEMU guest agent on VM '$Name' did not answer a ping within $TimeoutSeconds s."
        return $false
    }

    if (-not $RequireExec.IsPresent) { return $true }

    while ($timer.Elapsed.TotalSeconds -lt $TimeoutSeconds)
    {
        try
        {
            $execResult = New-PveNodesQemuAgentExec -Node $Node -Vmid $Vmid -Command @('cmd', '/c', 'ver') -ErrorAction Stop 2>$null
            if ($execResult.StatusCode -eq 200)
            {
                Write-PSFMessage -Message "QEMU guest agent guest-exec ready on VM '$Name' after $([int]$timer.Elapsed.TotalSeconds)s."
                return $true
            }
        }
        catch { }
        Start-Sleep -Seconds $PollIntervalSeconds
    }

    Write-PSFMessage -Level Warning -Message "QEMU guest agent on VM '$Name' answered pings but guest-exec was not ready within $TimeoutSeconds s."
    return $false
}
