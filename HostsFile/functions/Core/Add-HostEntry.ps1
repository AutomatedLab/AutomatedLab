function Add-HostEntry
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByString')]
        [System.Net.IPAddress]$IpAddress,

        [Parameter(Mandatory, ParameterSetName = 'ByString')]
        $HostName,

        [Parameter(Mandatory, ParameterSetName = 'ByHostEntry')]
        $InputObject,

        [Parameter(Mandatory)]
        [string]$Section
    )

    if (-not $InputObject)
    {
        $InputObject = New-Object System.Net.HostRecord $IpAddress, $HostName.ToLower()
    }

    $hostContent, $hostEntries = Get-HostFile


    if ($hostEntries.Contains($InputObject))
    {
        return $false
    }

    if (($hostEntries | Where-Object HostName -eq $HostName) -and ($hostEntries | Where-Object HostName -eq $HostName).IpAddress.IPAddressToString -ne $IpAddress)
    {
        throw "Trying to add entry to hosts file with name '$HostName'. There is already another entry with this name pointing to another IP address."
    }

    $startMark = ("#$Section - start").ToLower()
    $endMark = ("#$Section - end").ToLower()

    if (-not ($hostContent | Where-Object { $_ -eq $startMark }))
    {
        $hostContent.Add($startMark) | Out-Null
        $hostContent.Add($endMark) | Out-Null
    }

    $hostContent.Insert($hostContent.IndexOf($endMark), $InputObject.ToString().ToLower())
    $hostEntries.Add($InputObject.ToString().ToLower()) | Out-Null

    $hostContent | Out-File -FilePath $script:hostFilePath

    return $true
}
