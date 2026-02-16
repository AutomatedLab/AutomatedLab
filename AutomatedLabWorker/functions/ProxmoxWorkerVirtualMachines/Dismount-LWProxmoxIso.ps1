function Dismount-LWProxmoxIso
{
    <#
    .SYNOPSIS
        Unmounts all mounted ISO images from a Proxmox VM.

    .DESCRIPTION
        Scans the VM configuration for all SCSI slots that have an ISO image
        mounted (media=cdrom with an actual ISO, not 'none'). Each discovered
        slot is changed to an empty CD-ROM drive. The SCSI device remains but
        the disc is ejected.

        Requires an active connection to the Proxmox cluster.

    .PARAMETER Node
        The name of the Proxmox node where the VM is running.

    .PARAMETER VmId
        The numeric ID of the virtual machine.

    .EXAMPLE
        Dismount-LWProxmoxIso -Node 'rz1pinhst101' -VmId 9004

        Finds and ejects all mounted ISO images from VM 9004.
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
        $VmId
    )

    Write-LogFunctionEntry

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error -Message 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    # Verify the VM exists and get current config
    $vmConfig = Get-PveNodesQemuConfig -Node $Node -Vmid $VmId
    if ($vmConfig.StatusCode -ne 200)
    {
        Write-Error -Message "VM with ID $VmId not found on node '${Node}': $($vmConfig.ReasonPhrase)" -ErrorAction Stop
        return
    }

    $configData = $vmConfig.Response.data

    # Find all SCSI slots with a mounted ISO (media=cdrom and not 'none')
    $mountedSlots = 0..30 | ForEach-Object {
        $slotName = "scsi$_"
        $value = $configData.$slotName
        if ($value -and $value -match 'media=cdrom' -and $value -notmatch '^none')
        {
            [PSCustomObject]@{
                Slot  = $_
                Name  = $slotName
                Value = $value
            }
        }
    }

    if (-not $mountedSlots)
    {
        Write-ScreenInfo -Message "No mounted ISO images found on VM $VmId. Nothing to dismount." -Type Warning
        Write-LogFunctionExit
        return
    }

    Write-PSFMessage -Message "Found $($mountedSlots.Count) mounted ISO(s) on VM ${VmId}: $($mountedSlots.Name -join ', ')"

    foreach ($slot in $mountedSlots)
    {
        if ($PSCmdlet.ShouldProcess("VM $VmId on node $Node", "Dismount ISO from $($slot.Name) (current: $($slot.Value))"))
        {
            Write-PSFMessage -Message "Ejecting ISO from $($slot.Name) on VM $VmId (node $Node). Current value: '$($slot.Value)'"

            $result = Set-PveNodesQemuConfig -Node $Node -Vmid $VmId -ScsiN @{ $slot.Slot = 'none,media=cdrom' }

            if ($result.StatusCode -ne 200)
            {
                Write-Error -Message "Failed to dismount ISO from $($slot.Name) on VM ${VmId}: $($result.ReasonPhrase)"
                continue
            }

            Write-PSFMessage -Message "Successfully dismounted ISO from $($slot.Name) on VM $VmId"

            [PSCustomObject]@{
                Node          = $Node
                VmId          = $VmId
                ScsiSlot      = $slot.Name
                PreviousValue = $slot.Value
                CurrentValue  = 'none,media=cdrom'
            }
        }
    }

    Write-LogFunctionExit
}
