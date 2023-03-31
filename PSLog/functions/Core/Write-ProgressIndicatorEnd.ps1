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

    Write-ScreenInfo -Message '.'
}
