#region Internals
$script:hostFilePath = if ($PSEdition -eq 'Desktop' -or $IsWindows)
{
    "$($env:SystemRoot)\System32\drivers\etc\hosts"
}
elseif ($PSEdition -eq 'Core' -and $IsLinux)
{
    '/etc/hosts'
}

$type = @'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace System.Net
{
    public class HostRecord
    {
        private IPAddress ipAddress;
        private string hostName;

        public IPAddress IpAddress
        {
            get { return ipAddress; }
            set { ipAddress = value; }
        }

        public string HostName
        {
            get { return hostName; }
            set { hostName = value; }
        }

        public HostRecord(IPAddress ipAddress, string hostName)
        {
            this.ipAddress = ipAddress;
            this.hostName = hostName;
        }

        public HostRecord(string ipAddress, string hostName)
        {
            this.ipAddress = IPAddress.Parse(ipAddress);
            this.hostName = hostName;
        }

        public override string ToString()
        {
            return string.Format("{0}\t{1}", this.ipAddress.ToString(), this.hostName);
        }

        public override bool Equals(object obj)
        {
            if (GetType() != obj.GetType())
                return false;

            var otherObject = (HostRecord)obj;

            if (this.hostName != otherObject.hostName)
                return false;

            return this.ipAddress.Equals(otherObject.ipAddress);
        }

        public override int GetHashCode()
        {
            return this.hostName.GetHashCode() ^ this.ipAddress.GetHashCode();
        }
    }
}
'@
#endregion Internals

Add-Type -TypeDefinition $type -PassThru

#region Get-HostFile
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
#endregion Get-HostFile

#region Get-HostEntry
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
#endregion Get-HostEntry

#region Add-HostEntry
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
#endregion Add-HostEntry

#region Remove-HostEntry
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
#endregion Remove-HostEntry

#region function Clear-HostFile
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
#endregion function Clear-HostFile
