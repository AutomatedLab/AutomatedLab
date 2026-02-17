function Get-LWProxmoxIsoImage
{
    <#
    .SYNOPSIS
        Lists available ISO images on Proxmox storages.

    .DESCRIPTION
        Queries the Proxmox VE API for ISO images available on a specific node.
        When Storage is specified, only that storage is queried. When omitted,
        all storages that support ISO content are discovered automatically and
        searched.

        Returns objects with volume ID, file name, size and storage details.

        Requires an active connection to the Proxmox cluster.

    .PARAMETER Node
        The name of the Proxmox node to query.

    .PARAMETER Storage
        Optional storage identifier to list ISOs from. When omitted, all
        ISO-capable storages on the node are searched automatically.

    .PARAMETER IsoFile
        Optional. When specified, returns only the ISO matching this file name.
        If no match is found, a non-terminating error is written.

    .EXAMPLE
        Get-LWProxmoxIsoImage -Node 'rz1pinhst101'

        Lists all ISO images across all ISO-capable storages on node rz1pinhst101.

    .EXAMPLE
        Get-LWProxmoxIsoImage -Node 'rz1pinhst101' -Storage 'cephfs'

        Lists all ISO images on the 'cephfs' storage only.

    .EXAMPLE
        Get-LWProxmoxIsoImage -Node 'rz1pinhst101' -IsoFile 'dsc-resources.iso'

        Searches all ISO-capable storages and returns the matching entry.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Node,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Storage,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $IsoFile
    )

    Write-LogFunctionEntry

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error -Message 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    # Determine which storages to search
    if ($Storage)
    {
        $storageList = @($Storage)
    }
    else
    {
        Write-PSFMessage -Message "No storage specified. Discovering all ISO-capable storages on node '$Node'."
        $storageResponse = Get-PveNodesStorage -Node $Node -Content 'iso'
        if ($storageResponse.StatusCode -ne 200 -or -not $storageResponse.Response.data)
        {
            Write-Error -Message "Failed to discover ISO-capable storages on node '${Node}'." -ErrorAction Stop
            return
        }
        $storageList = @($storageResponse.Response.data | ForEach-Object { $_.storage })
        Write-PSFMessage -Message "Found ISO-capable storages: $($storageList -join ', ')"
    }

    $allResults = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($storageName in $storageList)
    {
        $response = Get-PveNodesStorageContent -Node $Node -Storage $storageName -Content iso
        if ($response.StatusCode -ne 200)
        {
            Write-PSFMessage -Message "Failed to query storage '$storageName' on node '${Node}': $($response.ReasonPhrase)" -Level Warning
            continue
        }

        $isoContent = $response.Response.data
        if (-not $isoContent)
        {
            Write-PSFMessage -Message "No ISO images found on storage '$storageName' of node '$Node'."
            continue
        }

        if ($IsoFile)
        {
            $expectedVolId = "$($storageName):iso/$IsoFile"
            $matchingIso = $isoContent | Where-Object { $_.volid -eq $expectedVolId }

            if ($matchingIso)
            {
                foreach ($iso in @($matchingIso))
                {
                    $fileName = ($iso.volid -split '/')[-1]
                    $sizeInMb = [math]::Round($iso.size / 1MB, 2)

                    $allResults.Add([PSCustomObject]@{
                        Node     = $Node
                        Storage  = $storageName
                        VolId    = $iso.volid
                        FileName = $fileName
                        SizeMB   = $sizeInMb
                        Format   = $iso.format
                    })
                }
                # When searching for a specific file, return first match
                break
            }
        }
        else
        {
            foreach ($iso in $isoContent)
            {
                $fileName = ($iso.volid -split '/')[-1]
                $sizeInMb = [math]::Round($iso.size / 1MB, 2)

                $allResults.Add([PSCustomObject]@{
                    Node     = $Node
                    Storage  = $storageName
                    VolId    = $iso.volid
                    FileName = $fileName
                    SizeMB   = $sizeInMb
                    Format   = $iso.format
                })
            }
        }
    }

    if ($IsoFile -and $allResults.Count -eq 0)
    {
        $searchedStorages = $storageList -join ', '
        Write-Error -Message "ISO file '$IsoFile' not found on node '$Node'. Searched storages: $searchedStorages" -ErrorAction Stop
        Write-LogFunctionExit
        return
    }

    $allResults

    Write-LogFunctionExit
}
