#TODO: This function needs to be moved to AutomatedLabCommon

function New-MacAddress {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^(([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}|[0-9A-Fa-f]{12})$')]
        [string]$MacAddressPrefix,

        [Parameter()]
        [ValidatePattern('^(([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}|[0-9A-Fa-f]{12})$')]
        [string[]]$ExistingMacAddresses = @(),

        [Parameter()]
        [switch]$NoSeparator
    )

    # Normalize the MAC address prefix to colon-separated format
    if ($MacAddressPrefix -match ':') {
        $prefix = ($MacAddressPrefix -split ':')[0..2] -join ':'
    }
    else {
        # Convert BC241112DB71 to BC:24:11
        $prefix = ($MacAddressPrefix -replace '(.{2})', '$1:').TrimEnd(':').Substring(0, 8)
    }

    # Convert existing MAC addresses to uppercase and normalize to colon-separated format
    $existingSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($mac in $ExistingMacAddresses) {
        $normalizedMac = if ($mac -match ':') {
            $mac.ToUpper()
        }
        else {
            # Convert BC241112DB71 to BC:24:11:12:DB:71
            ($mac -replace '(.{2})', '$1:').TrimEnd(':').ToUpper()
        }
        [void]$existingSet.Add($normalizedMac)
    }

    # Maximum attempts to avoid infinite loop
    $maxAttempts = 10000
    $attempts = 0

    do {
        $attempts++
        if ($attempts -gt $maxAttempts) {
            throw "Unable to generate unique MAC address after $maxAttempts attempts"
        }

        # Generate random last 3 octets
        $octet4 = '{0:X2}' -f (Get-Random -Minimum 0 -Maximum 256)
        $octet5 = '{0:X2}' -f (Get-Random -Minimum 0 -Maximum 256)
        $octet6 = '{0:X2}' -f (Get-Random -Minimum 0 -Maximum 256)

        $newMac = "$prefix`:$octet4`:$octet5`:$octet6"

    } while ($existingSet.Contains($newMac.ToUpper()))

    if ($NoSeparator) {
        return $newMac -replace ':', ''
    }

    return $newMac
}
