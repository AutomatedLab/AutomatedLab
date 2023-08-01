function Remove-HostEntry
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByIpAddress')]
        [System.Net.IPAddress]$IpAddress,

        [Parameter(Mandatory, ParameterSetName = 'ByHostName')]
        $HostName,

        [Parameter(Mandatory, ParameterSetName = 'ByHostEntry')]
        $InputObject,

        [Parameter(Mandatory)]
        [string]$Section
    )

    if (-not $InputObject -and -not $IpAddress -and -not $HostName)
    {
        return
    }

    if ($InputObject)
    {
        $entriesToRemove = $InputObject
    }
    else
    {
        if (-not $InputObject -and ($IpAddress -or $HostName))
        {
            $entriesToRemove = Get-HostEntry @PSBoundParameters
        }
    }

    if (-not $entriesToRemove)
    {
        Write-Error "Trying to remove entry '$HostName' from hosts file. However, there is no entry by that name in this file"
    }

    $hostContent, $hostEntries = Get-HostFile -SuppressOutput

    $startMark = ("#$Section - start").ToLower()
    if (-not ($hostContent | Where-Object { $_ -eq $startMark }))
    {
        Write-Error "Trying to remove entry '$HostName' from hosts file. However, there is no section named '$Section' defined in the hosts file which is a requirement for removing entries from this."
        return
    }
    elseif ($entriesToRemove.Count -gt 1)
    {
        Write-Error "Trying to remove entry '$HostName' from hosts file. However, there are more than one entry with this name in the hosts file. Please remove this entry manually."
        return
    }

    if ($entriesToRemove)
    {
        $entryToRemove = ($hostContent -match "^($($entriesToRemove.IpAddress))[\t| ]+$($entriesToRemove.HostName)")[0]
        $entryToRemoveIndex = $hostContent.IndexOf($entryToRemove)

        $hostContent.RemoveAt($entryToRemoveIndex)
        $hostEntries.Remove($entriesToRemove)

        $hostContent | Out-File -FilePath $script:hostFilePath
    }
}
