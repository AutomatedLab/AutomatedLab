function Write-ProgressIndicatorEnd
{

    if (-not (Get-PSCallStack)[1].InvocationInfo.BoundParameters['ProgressIndicator'])
    {
        return
    }
    if ((Get-PSCallStack)[1].InvocationInfo.BoundParameters['NoNewLine'].IsPresent)
    {
        return
    }

    # Close the progress-dot run. If cursor is already at column 0 (external code broke the
    # stream), a final dot on its own line adds nothing - just reset the flag.
    try
    {
        if ($Host.UI.RawUI.CursorPosition.X -eq 0)
        {
            $Global:PSLog_NoNewLine = $false
            return
        }
    }
    catch
    {
    }

    Microsoft.PowerShell.Utility\Write-Host '.'
    $Global:PSLog_NoNewLine = $false
}
