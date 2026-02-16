function Mount-LWProxmoxIso
{
    <#
    .SYNOPSIS
        Mounts an ISO image to a Proxmox VM as a SCSI CD-ROM drive.

    .DESCRIPTION
        Mounts an ISO file from a Proxmox storage to a virtual machine using the
        Proxmox VE API. The ISO is attached via a SCSI interface (scsi30 by default,
        to avoid conflicts with disk drives).

        When Storage is omitted, all ISO-capable storages on the node are searched
        automatically to locate the ISO file.

        Requires an active connection to the Proxmox cluster.

    .PARAMETER Node
        The name of the Proxmox node where the VM is running.

    .PARAMETER VmId
        The numeric ID of the virtual machine.

    .PARAMETER IsoFile
        The name of the ISO file (e.g. 'dsc-resources.iso'). The file must already
        exist on one of the available storages.

    .PARAMETER Storage
        Optional storage identifier where the ISO file is located. When omitted,
        all ISO-capable storages are searched automatically.

    .PARAMETER ScsiSlot
        The SCSI slot number (0-30) to use for the CD-ROM drive. Defaults to 30,
        to avoid conflicts with disk drives that typically use lower slots.

    .EXAMPLE
        Mount-LWProxmoxIso -Node 'rz1pinhst101' -VmId 9004 -IsoFile 'dsc-resources.iso'

        Mounts the ISO file 'dsc-resources.iso' to VM 9004, automatically
        discovering which storage contains the file.

    .EXAMPLE
        Mount-LWProxmoxIso -Node 'rz1pinhst101' -VmId 9004 -IsoFile 'setup.iso' -Storage 'cephfs' -ScsiSlot 29

        Mounts the ISO from 'cephfs' storage using SCSI slot 29.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Node,

        [Parameter(Mandatory)]
        [ValidateRange(100, 999999999)]
        [int]
        $VmId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $IsoFile,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Storage,

        [Parameter()]
        [ValidateRange(0, 30)]
        [int]
        $ScsiSlot = 30
    )

    Write-LogFunctionEntry

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error -Message 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    # Verify the ISO file exists, auto-searching storages when Storage is not specified
    $getIsoParams = @{
        Node      = $Node
        IsoFile   = $IsoFile
        ErrorAction = 'Stop'
    }
    if ($Storage)
    {
        $getIsoParams['Storage'] = $Storage
    }

    $matchingIso = Get-LWProxmoxIso @getIsoParams
    if (-not $matchingIso)
    {
        return
    }

    # Use the storage from the discovered ISO (take first match)
    $resolvedStorage = $matchingIso[0].Storage
    $isoVolId = $matchingIso[0].VolId

    if (-not $Storage)
    {
        Write-PSFMessage -Message "ISO '$IsoFile' found on storage '$resolvedStorage'."
    }

    # Verify the VM exists
    $vmConfig = Get-PveNodesQemuConfig -Node $Node -Vmid $VmId
    if ($vmConfig.StatusCode -ne 200)
    {
        Write-Error -Message "VM with ID $VmId not found on node '${Node}': $($vmConfig.ReasonPhrase)" -ErrorAction Stop
        return
    }

    $isoValue = "$isoVolId,media=cdrom"

    if ($PSCmdlet.ShouldProcess("VM $VmId on node $Node", "Mount ISO '$IsoFile' on scsi$ScsiSlot"))
    {
        Write-PSFMessage -Message "Mounting ISO '$isoVolId' on VM $VmId (node $Node) as scsi$ScsiSlot"

        $result = Set-PveNodesQemuConfig -Node $Node -Vmid $VmId -ScsiN @{ $ScsiSlot = $isoValue }

        if ($result.StatusCode -ne 200)
        {
            Write-Error -Message "Failed to mount ISO on VM ${VmId}: $($result.ReasonPhrase)"
            return
        }

        Write-PSFMessage -Message "Successfully mounted ISO '$IsoFile' on VM $VmId as scsi$ScsiSlot"

        # Return the current config to confirm
        $updatedConfig = (Get-PveNodesQemuConfig -Node $Node -Vmid $VmId).Response.data
        [PSCustomObject]@{
            Node     = $Node
            VmId     = $VmId
            ScsiSlot = "scsi$ScsiSlot"
            Value    = $updatedConfig."scsi$ScsiSlot"
            IsoFile  = $IsoFile
            Storage  = $resolvedStorage
        }
    }

    Write-LogFunctionExit
}
