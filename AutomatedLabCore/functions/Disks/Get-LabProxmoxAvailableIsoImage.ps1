function Get-LabIsoImage
{
    <#
    .SYNOPSIS
        Lists available ISO images on a Proxmox storage.

    .DESCRIPTION
        Queries the Proxmox VE API for ISO images available on the storage of a
        specific node. If a ComputerName is given, the node is derived from the
        machine's Proxmox target node. Otherwise the first available Proxmox
        node is used.

    .PARAMETER ComputerName
        Optional. One or more lab machine names whose Proxmox target node is
        used for the query. Only Proxmox machines are supported.

    .PARAMETER Storage
        The storage identifier to list ISOs from. Defaults to 'local'.

    .PARAMETER IsoFile
        Optional. When specified, returns only the ISO matching this file name.
        If no match is found, an error is written.

    .EXAMPLE
        Get-LabIsoImage

        Lists all ISO images on the 'local' storage of the first Proxmox node.

    .EXAMPLE
        Get-LabIsoImage -ComputerName T01U01RZ1DVWEB03 -Storage cephfs

        Lists all ISO images on 'cephfs' storage of the node hosting the given VM.

    .EXAMPLE
        Get-LabIsoImage -IsoFile 'dsc-resources.iso'

        Returns only the specified ISO or writes an error if not found.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter()]
        [string[]]
        $ComputerName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Storage = 'local',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $IsoFile
    )

    Write-LogFunctionEntry

    if ($ComputerName)
    {
        $machines = Get-LabVM -ComputerName $ComputerName | Where-Object HostType -eq Proxmox
        if (-not $machines)
        {
            Write-Error "No Proxmox machines found for '$($ComputerName -join ', ')'. Get-LabIsoImage currently only supports Proxmox VMs."
            Write-LogFunctionExit
            return
        }

        $nodes = $machines.ProxmoxProperties.TargetNode | Select-Object -Unique
    }
    else
    {
        $nodes = Get-LWProxmoxNode | Select-Object -First 1 -ExpandProperty node
        if (-not $nodes)
        {
            Write-Error 'No Proxmox nodes available. Ensure a connection to the Proxmox cluster exists.'
            Write-LogFunctionExit
            return
        }
    }

    foreach ($node in $nodes)
    {
        $params = @{
            Node    = $node
            Storage = $Storage
        }

        if ($IsoFile)
        {
            $params.IsoFile = $IsoFile
        }

        Get-LWProxmoxIsoImage @params
    }

    Write-LogFunctionExit
}
