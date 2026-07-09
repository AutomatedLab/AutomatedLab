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

    .PARAMETER Confirm
        Prompts you for confirmation before running the cmdlet.

    .PARAMETER WhatIf
        Shows what would happen if the cmdlet runs. The cmdlet is not run.

    .EXAMPLE
        Mount-LWProxmoxIsoImage -ComputerName 'Server01' -IsoPath 'D:\ISOs\setup.iso' -PassThru

        Mounts the ISO to the lab VM 'Server01' and returns the result with drive letter.

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

            # PROXMOX-ISO-SLOT-FIX v1
            # Pick a free SCSI CD-ROM slot by scanning UPWARD from scsi2 (scsi0/scsi1 hold
            # the OS + data disks) and choosing the LOWEST free slot in scsi2..scsi29.
            # The previous logic scanned scsi30 -> scsi20 and grabbed scsi30, which FAILS on
            # VMs using the 'virtio-scsi-single' controller (the Dagger template default):
            # that controller gives every SCSI device its own PCI controller, and the top
            # index scsi30 cannot be hot-added to a running VM, so the Proxmox API returns
            # HTTP 400 'Parameter verification failed.' (and leaves a stray pending entry).
            # Low indices hot-add cleanly, so preferring the lowest free slot is robust for
            # both 'virtio-scsi-single' and the shared 'virtio-scsi-pci' controller.
            $vmConfig = (Invoke-LWProxmoxCallWithRetry -ActivityName "Get VM config for VM '$($machine.Name)'" -ScriptBlock { Get-PveNodesQemuConfig -Node $targetNode -Vmid $proxmoxVm.vmid }).Response.data
            $isoFileName = Split-Path -Path $IsoPath -Leaf

            # Check if this ISO is already mounted on any CD-ROM slot. Scan the full range
            # (up to scsi30) so a leftover high-slot mount from an older AutomatedLab or a
            # failed hot-add is still detected and not duplicated.
            $alreadyMounted = $false
            for ($slot = 2; $slot -le 30; $slot++)
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
            for ($slot = 2; $slot -le 29; $slot++)
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
                Write-ScreenInfo -Message "No free SCSI CD-ROM slot (scsi2-scsi29) available on VM '$($machine.Name)'." -Type Error
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
    $vmConfig = Invoke-LWProxmoxCallWithRetry -ActivityName "Get VM config for VM $VmId" -ScriptBlock { Get-PveNodesQemuConfig -Node $Node -Vmid $VmId }
    if ($vmConfig.StatusCode -ne 200)
    {
        Write-Error -Message "VM with ID $VmId not found on node '${Node}': $($vmConfig.ReasonPhrase)" -ErrorAction Stop
        return
    }

    # PROXMOX-ISO-SLOT-FIX v1
    # When the caller did not request a specific slot, auto-select the LOWEST free SCSI
    # slot in scsi2..scsi29 (scsi0/scsi1 are the OS + data disks). The historical default
    # of scsi30 FAILS on 'virtio-scsi-single' VMs (the Dagger template default: one PCI
    # controller per SCSI device) because the top index scsi30 cannot be hot-added to a
    # running VM -> the Proxmox API returns HTTP 400 'Parameter verification failed.'.
    # Low indices hot-add cleanly. The public Mount-LabIsoImage (AutomatedLabCore) calls
    # this function WITHOUT -ScsiSlot, so this is the path exercised by a lab deployment.
    $effectiveSlot = $ScsiSlot
    if (-not $PSBoundParameters.ContainsKey('ScsiSlot'))
    {
        $cfgData = $vmConfig.Response.data
        $effectiveSlot = -1
        for ($slot = 2; $slot -le 29; $slot++)
        {
            if (-not $cfgData."scsi$slot") { $effectiveSlot = $slot; break }
        }
        if ($effectiveSlot -lt 0)
        {
            Write-Error -Message "No free SCSI CD-ROM slot (scsi2-scsi29) available on VM $VmId." -ErrorAction Stop
            return
        }
    }

    $isoValue = "$isoVolId,media=cdrom"

    if ($PSCmdlet.ShouldProcess("VM $VmId on node $Node", "Mount ISO '$IsoFile' on scsi$effectiveSlot"))
    {
        Write-PSFMessage -Message "Mounting ISO '$isoVolId' on VM $VmId (node $Node) as scsi$effectiveSlot"

        $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Mount ISO on VM $VmId" -ScriptBlock { Set-PveNodesQemuConfig -Node $Node -Vmid $VmId -ScsiN @{ $effectiveSlot = $isoValue } }

        if ($result.StatusCode -ne 200)
        {
            Write-Error -Message "Failed to mount ISO on VM ${VmId}: $($result.ReasonPhrase)"
            return
        }

        Write-PSFMessage -Message "Successfully mounted ISO '$IsoFile' on VM $VmId as scsi$effectiveSlot"

        # Return the current config to confirm
        $updatedConfig = (Invoke-LWProxmoxCallWithRetry -ActivityName "Verify VM config for VM $VmId" -ScriptBlock { Get-PveNodesQemuConfig -Node $Node -Vmid $VmId }).Response.data
        [PSCustomObject]@{
            Node     = $Node
            VmId     = $VmId
            ScsiSlot = "scsi$effectiveSlot"
            Value    = $updatedConfig."scsi$effectiveSlot"
            IsoFile  = $IsoFile
            Storage  = $resolvedStorage
        }
    }

    Write-LogFunctionExit
}
