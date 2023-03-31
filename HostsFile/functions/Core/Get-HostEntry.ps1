function Get-HostEntry
{
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'ByHostName')]
        [ValidateNotNullOrEmpty()][string]$HostName,

        [Parameter(ParameterSetName = 'ByIpAddress')]
        [ValidateNotNullOrEmpty()]
        [System.Net.IPAddress]$IpAddress,

        [Parameter()]
        [string]$Section
    )

    if ($Section)
    {
        $hostContent, $hostEntries = Get-HostFile -Section $Section
    }
    else
    {
        $hostContent, $hostEntries = Get-HostFile
    }

    if ($HostName)
    {
        $results = $hostEntries | Where-Object HostName -eq $HostName

        $hostEntries | Where-Object HostName -eq $HostName
    }
    elseif ($IpAddress)
    {
        $results = $hostEntries | Where-Object IpAddress -contains $IpAddress
        if (($results).count -gt 1)
        {
            Write-ScreenInfo -Message "More than one entry found in hosts file with IP address '$IpAddress' (host names: $($results.Hostname -join ','). Returning the last entry" -Type Warning
        }

        @($hostEntries | Where-Object IpAddress -contains $IpAddress)[-1]
    }
    else
    {
        $hostEntries
    }
}
