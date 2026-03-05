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
        [int]$RetryDelaySeconds = 10
    )

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++)
    {
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
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    # Return the last failed result so callers can inspect StatusCode/ReasonPhrase
    return $result
}
