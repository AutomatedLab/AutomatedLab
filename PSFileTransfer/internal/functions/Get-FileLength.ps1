function Get-FileLength
{
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try
    {
        $FilePath = $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)
    }
    catch
    {
        throw $_
    }

    (Get-Item -Path $FilePath -Force).Length
}
