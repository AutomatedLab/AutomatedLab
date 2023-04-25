function Get-HostFile
{
    [CmdletBinding()]
    param
    (
        [switch]$SuppressOutput,

        [string]$Section
    )

    $hostContent = New-Object -TypeName System.Collections.ArrayList
    $hostEntries = New-Object -TypeName System.Collections.ArrayList

    Write-PSFMessage "Opening file '$script:hostFilePath'"

    $currentHostContent = (Get-Content -Path $script:hostFilePath)
    if ($currentHostContent)
    {
        $currentHostContent = $currentHostContent.ToLower()
    }

    if ($Section)
    {
        $startMark = ("#$Section - start").ToLower()
        $endMark = ("#$Section - end").ToLower()

        if (($currentHostContent | Where-Object { $_ -eq $startMark }) -and ($currentHostContent | Where-Object { $_ -eq $endMark }))
        {
            $startPosition = $currentHostContent.IndexOf($startMark) + 1
            $endPosition = $currentHostContent.IndexOf($endMark) - 1
            $currentHostContent = $currentHostContent[$startPosition..$endPosition]
        }
        else
        {
            $currentHostContent = ''
        }
    }

    if ($currentHostContent)
    {
        $hostContent.AddRange($currentHostContent)

        foreach ($entry in $currentHostContent)
        {
            $hostfileIpAddress = [System.Text.RegularExpressions.Regex]::Matches($entry, '^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))')[0].Value
            $hostfileHostName = [System.Text.RegularExpressions.Regex]::Matches($entry, '[\w\.-]+$')[0].Value

            if ($entry -notmatch '^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))[\t| ]+[\w\.-]+')
            {
                continue
            }

            if (-not $hostfileIpAddress -or -not $hostfileHostName)
            {
                #could not get the IP address or hostname from current line
                continue
            }

            $newEntry = New-Object System.Net.HostRecord($hostfileIpAddress, $hostfileHostName.ToLower())
            $null = $hostEntries.Add($newEntry)
        }
    }

    Write-PSFMessage "File loaded with $($hostContent.Count) lines"

    $hostContent, $hostEntries
}
