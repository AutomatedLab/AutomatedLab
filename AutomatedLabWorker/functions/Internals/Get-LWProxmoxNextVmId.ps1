function Get-LWProxmoxNextVmId
{
    <#
    .SYNOPSIS
        Returns the VMID after the highest VMID of the Proxmox cluster.

    .DESCRIPTION
        Reads the VMIDs of all guests of the cluster, virtual machines and containers on every node, and
        returns the VMID after the highest one, at least 100. Proxmox may still refuse it as taken: another
        host can take it first, and the list leaves out the guests that the connected user may not see.
        After such a refusal, pass the refused VMID as -After to get a higher one.

    .PARAMETER After
        A VMID that Proxmox refused as taken. The result is higher than it.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        [Parameter()]
        [int]
        $After
    )

    $result = Invoke-LWProxmoxCallWithRetry -ActivityName 'Retrieve the VMIDs of the cluster' -ScriptBlock { Get-PveClusterResources -Type vm }
    if ($result.StatusCode -ne 200)
    {
        Write-Error "Failed to retrieve the VMIDs in use in the Proxmox cluster: $($result.ReasonPhrase)"
        return
    }

    $highestVmId = [int]($result.Response.data | Measure-Object -Property vmid -Maximum).Maximum

    [Math]::Max([Math]::Max($highestVmId, $After) + 1, 100)
}
