function Write-ProgressIndicator
{


    if (-not (Get-PSCallStack)[1].InvocationInfo.BoundParameters['ProgressIndicator'])
    {
        return
    }

    # A progress dot is a continuation marker. Bypass Write-ScreenInfo so the dot can never be
    # emitted as a fully timestamped line ("HH:MM:SS|...| .") even when $Global:PSLog_NoNewLine
    # has been cleared by external output between polls. In the worst case - when external code
    # (Invoke-LabCommand, Proxmox API verbose writes, child runspaces) has printed a newline
    # between dots - the dot simply appears at the start of its own line. That is ugly but
    # harmless, and far better than falling silent during long waits: the user still sees
    # liveness and the log stays short.
    Microsoft.PowerShell.Utility\Write-Host '.' -NoNewline
    $Global:PSLog_NoNewLine = $true
}
