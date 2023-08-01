function Write-ProgressIndicator
{


    if (-not (Get-PSCallStack)[1].InvocationInfo.BoundParameters['ProgressIndicator'])
    {
        return
    }
    Write-ScreenInfo -Message '.' -NoNewline
}
