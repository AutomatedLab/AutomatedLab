function Clear-HostFile
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [string]$Section
    )

    $hostContent, $hostEntries = Get-HostFile

    $startMark = ("#$Section - start").ToLower()
    $endMark = ("#$Section - end").ToLower()

    $startPosition = $hostContent.IndexOf($startMark)
    $endPosition = $hostContent.IndexOf($endMark)
    if ($startPosition -eq -1 -and $endPosition - 1)
    {
        Write-Error "Trying to remove all entries for lab from host file. However, there is no section named '$Section' defined in the hosts file which is a requirement for removing entries from this."
        return
    }

    $hostContent.RemoveRange($startPosition, $endPosition - $startPosition + 1)
    $hostContent | Out-File -FilePath $script:hostFilePath
}
