function Mount-LWProxmoxIsoImage
{
    <#
    .SYNOPSIS
        Mounts an ISO image to a Proxmox VM as a SCSI CD-ROM drive.

    .DESCRIPTION
        Mounts an ISO file from a Proxmox storage to a virtual machine using the
        Proxmox VE API. The ISO is attached via a SCSI interface (scsi30 by default,
        to avoid conflicts with disk drives).

        Can be invoked with either a ComputerName (lab machine name) or with direct
        Proxmox API parameters (Node, VmId, IsoFile).

        When Storage is omitted, all ISO-capable storages on the node are searched
        automatically to locate the ISO file.

        Requires an active connection to the Proxmox cluster.

    .PARAMETER ComputerName
        The name of the lab machine. The machine's Proxmox properties are used to
        resolve the target node and VM ID automatically.

    .PARAMETER IsoPath
        The full path to the ISO file. Only the file name is used to locate the
        ISO on the Proxmox storage.

    .PARAMETER PassThru
        When specified, returns the mount result including the drive letter detected
        inside the guest operating system.

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
        Mount-LWProxmoxIsoImage -ComputerName 'Server01' -IsoPath 'D:\ISOs\setup.iso' -PassThru

        Mounts the ISO to the lab VM 'Server01' and returns the result with drive letter.

    .EXAMPLE
        Mount-LWProxmoxIsoImage -Node 'rz1pinhst101' -VmId 9004 -IsoFile 'dsc-resources.iso'

        Mounts the ISO file 'dsc-resources.iso' to VM 9004, automatically
        discovering which storage contains the file.

    .EXAMPLE
        Mount-LWProxmoxIsoImage -Node 'rz1pinhst101' -VmId 9004 -IsoFile 'setup.iso' -Storage 'cephfs' -ScsiSlot 29

        Mounts the ISO from 'cephfs' storage using SCSI slot 29.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ByApiParams')]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'ByComputerName', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByComputerName', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $IsoPath,

        [Parameter(ParameterSetName = 'ByComputerName')]
        [switch]
        $PassThru,

        [Parameter(Mandatory, ParameterSetName = 'ByApiParams')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Node,

        [Parameter(Mandatory, ParameterSetName = 'ByApiParams')]
        [ValidateRange(100, 999999999)]
        [int]
        $VmId,

        [Parameter(Mandatory, ParameterSetName = 'ByApiParams')]
        [ValidateNotNullOrEmpty()]
        [string]
        $IsoFile,

        [Parameter(ParameterSetName = 'ByApiParams')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Storage,

        [Parameter(ParameterSetName = 'ByApiParams')]
        [ValidateRange(0, 30)]
        [int]
        $ScsiSlot = 30
    )

    Write-LogFunctionEntry

    if ($PSCmdlet.ParameterSetName -eq 'ByComputerName')
    {
        $machines = Get-LabVM -ComputerName $ComputerName

        foreach ($machine in $machines)
        {
            $proxmoxVm = Get-LWProxmoxVM -ComputerName $machine.ResourceName
            if (-not $proxmoxVm)
            {
                Write-ScreenInfo -Message "Proxmox VM '$($machine.Name)' could not be found on any node." -Type Error
                continue
            }

            $targetNode = $proxmoxVm.node

            # Find the next free SCSI slot for a CD-ROM drive (scanning 30 down to 20)
            $vmConfig = (Get-PveNodesQemuConfig -Node $targetNode -Vmid $proxmoxVm.vmid).Response.data
            $isoFileName = Split-Path -Path $IsoPath -Leaf

            # Check if this ISO is already mounted on any slot
            $alreadyMounted = $false
            for ($slot = 30; $slot -ge 20; $slot--)
            {
                $slotValue = $vmConfig."scsi$slot"
                if ($slotValue -and $slotValue -match 'media=cdrom' -and $slotValue -match [regex]::Escape($isoFileName))
                {
                    Write-ScreenInfo -Message "ISO '$isoFileName' is already mounted on VM '$($machine.Name)' at scsi$slot. Skipping." -Type Warning
                    $alreadyMounted = $true
                    break
                }
            }
            if ($alreadyMounted) { continue }

            $freeSlot = $null
            for ($slot = 30; $slot -ge 20; $slot--)
            {
                $slotValue = $vmConfig."scsi$slot"
                if (-not $slotValue)
                {
                    $freeSlot = $slot
                    break
                }
            }

            if ($null -eq $freeSlot)
            {
                Write-ScreenInfo -Message "No free SCSI CD-ROM slot (scsi20-scsi30) available on VM '$($machine.Name)'." -Type Error
                continue
            }

            # Only query existing DVD drives when we need to detect the new drive letter
            if ($PassThru)
            {
                $dvdDrivesBefore = Invoke-LabCommand -ComputerName $machine -ScriptBlock {
                    Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType = 5 AND FileSystem LIKE "%"' | Select-Object -ExpandProperty DeviceID
                } -PassThru -NoDisplay

                if (-not $dvdDrivesBefore) { $dvdDrivesBefore = @() }
            }

            $isoFileName = Split-Path -Path $IsoPath -Leaf
            $mountResult = Mount-LWProxmoxIsoImage -Node $targetNode -VmId $proxmoxVm.vmid -IsoFile $isoFileName -ScsiSlot $freeSlot

            if ($PassThru -and $mountResult)
            {
                # Wait for the guest OS to recognise the new CD-ROM drive
                $driveLetter = $null
                $delaySeconds = 2, 3, 5, 10, 15
                foreach ($delay in $delaySeconds)
                {
                    Start-Sleep -Seconds $delay

                    $dvdDrivesAfter = Invoke-LabCommand -ComputerName $machine -ScriptBlock {
                        Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType = 5 AND FileSystem LIKE "%"' | Select-Object -ExpandProperty DeviceID
                    } -PassThru -NoDisplay

                    if (-not $dvdDrivesAfter) { $dvdDrivesAfter = @() }

                    $driveLetter = (Compare-Object -ReferenceObject $dvdDrivesBefore -DifferenceObject $dvdDrivesAfter -ErrorAction SilentlyContinue).InputObject
                    if ($driveLetter) { break }
                }

                $mountResult | Add-Member -Name DriveLetter -MemberType NoteProperty -Value $driveLetter
                $mountResult | Add-Member -Name InternalComputerName -MemberType NoteProperty -Value $machine.Name
                $mountResult
            }
        }

        Write-LogFunctionExit
        return
    }

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

    $matchingIso = Get-LWProxmoxIsoImage @getIsoParams
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
