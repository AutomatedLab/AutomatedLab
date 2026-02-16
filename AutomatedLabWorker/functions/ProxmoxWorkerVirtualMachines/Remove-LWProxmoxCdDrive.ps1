function Remove-LWProxmoxCdDrive
{
    <#
    .SYNOPSIS
        Removes a SCSI CD-ROM drive from a Proxmox VM.

    .DESCRIPTION
        Completely removes the specified SCSI CD-ROM device from the VM configuration.
        Unlike Dismount-LWProxmoxIso (which ejects the disc but keeps the drive),
        this function deletes the SCSI device entry entirely.

        Can also remove all SCSI CD-ROM drives at once with the -All switch.

        Requires an active connection to the Proxmox cluster.

    .PARAMETER Node
        The name of the Proxmox node where the VM is running.

    .PARAMETER VmId
        The numeric ID of the virtual machine.

    .PARAMETER ScsiSlot
        The SCSI slot number (0-30) to remove.

    .PARAMETER All
        When specified, removes all SCSI CD-ROM drives (scsi0-scsi30) from the VM.

    .EXAMPLE
        Remove-LWProxmoxCdDrive -Node 'rz1pinhst101' -VmId 9004 -ScsiSlot 30

        Removes the scsi30 device from VM 9004.

    .EXAMPLE
        Remove-LWProxmoxCdDrive -Node 'rz1pinhst101' -VmId 9004 -All

        Removes all SCSI CD-ROM drives from VM 9004.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'BySlot')]
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

        [Parameter(Mandatory, ParameterSetName = 'BySlot')]
        [ValidateRange(0, 30)]
        [int]
        $ScsiSlot,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]
        $All
    )

    Write-LogFunctionEntry

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error -Message 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    # Verify the VM exists
    $vmConfig = Get-PveNodesQemuConfig -Node $Node -Vmid $VmId
    if ($vmConfig.StatusCode -ne 200)
    {
        Write-Error -Message "VM with ID $VmId not found on node '${Node}': $($vmConfig.ReasonPhrase)" -ErrorAction Stop
        return
    }

    $config = $vmConfig.Response.data

    if ($All)
    {
        # Find all SCSI CD-ROM drives in the config
        $scsiDrives = $config | Get-Member -MemberType NoteProperty | Where-Object Name -Match '^scsi\d{1,2}$'
        $scsiCdDrives = $scsiDrives | Where-Object { $config.$($_.Name) -match 'media=cdrom' }

        if (-not $scsiCdDrives)
        {
            Write-ScreenInfo -Message "No SCSI CD-ROM drives found on VM $VmId." -Type Warning
            return
        }

        foreach ($drive in $scsiCdDrives)
        {
            if ($PSCmdlet.ShouldProcess("VM $VmId on node $Node", "Remove $($drive.Name) (value: $($config.$($drive.Name)))"))
            {
                Write-PSFMessage -Message "Removing $($drive.Name) from VM $VmId (node $Node)"

                $maxRetries = 3
                $retryDelay = 3
                $success = $false

                for ($attempt = 1; $attempt -le $maxRetries; $attempt++)
                {
                    $result = New-PveNodesQemuConfig -Node $Node -Vmid $VmId -Delete $drive.Name
                    if ($result.StatusCode -eq 200)
                    {
                        $success = $true
                        break
                    }

                    if ($attempt -lt $maxRetries)
                    {
                        Write-PSFMessage -Message "Attempt $attempt to remove $($drive.Name) failed ($($result.ReasonPhrase)). Retrying in ${retryDelay}s..."
                        Start-Sleep -Seconds $retryDelay
                    }
                }

                if (-not $success)
                {
                    Write-Error -Message "Failed to remove $($drive.Name) from VM ${VmId}: $($result.ReasonPhrase)"
                }
                else
                {
                    # Wait for the async task to complete
                    $taskUpid = $result.Response.data
                    if ($taskUpid)
                    {
                        $taskTimeout = 30
                        $taskStart = Get-Date
                        do
                        {
                            Start-Sleep -Seconds 1
                            $taskStatus = (Get-PveNodesTasksStatus -Node $Node -Upid $taskUpid).Response.data
                        }
                        while ($taskStatus.status -ne 'stopped' -and ((Get-Date) - $taskStart).TotalSeconds -lt $taskTimeout)

                        if ($taskStatus.exitstatus -ne 'OK')
                        {
                            Write-Error -Message "Task to remove $($drive.Name) from VM ${VmId} failed: $($taskStatus.exitstatus)"
                            continue
                        }
                    }

                    Write-PSFMessage -Message "Successfully removed $($drive.Name) from VM $VmId"
                    [PSCustomObject]@{
                        Node          = $Node
                        VmId          = $VmId
                        RemovedDevice = $drive.Name
                        PreviousValue = $config.$($drive.Name)
                    }
                }
            }
        }
    }
    else
    {
        $currentValue = $config."scsi$ScsiSlot"

        if (-not $currentValue)
        {
            Write-ScreenInfo -Message "No SCSI device found at scsi$ScsiSlot on VM $VmId. Nothing to remove." -Type Warning
            return
        }

        if ($PSCmdlet.ShouldProcess("VM $VmId on node $Node", "Remove scsi$ScsiSlot (value: $currentValue)"))
        {
            Write-PSFMessage -Message "Removing scsi$ScsiSlot from VM $VmId (node $Node)"

            $maxRetries = 3
            $retryDelay = 3
            $success = $false

            for ($attempt = 1; $attempt -le $maxRetries; $attempt++)
            {
                $result = New-PveNodesQemuConfig -Node $Node -Vmid $VmId -Delete "scsi$ScsiSlot"
                if ($result.StatusCode -eq 200)
                {
                    $success = $true
                    break
                }

                if ($attempt -lt $maxRetries)
                {
                    Write-PSFMessage -Message "Attempt $attempt to remove scsi$ScsiSlot failed ($($result.ReasonPhrase)). Retrying in ${retryDelay}s..."
                    Start-Sleep -Seconds $retryDelay
                }
            }

            if (-not $success)
            {
                Write-Error -Message "Failed to remove scsi${ScsiSlot} from VM ${VmId}: $($result.ReasonPhrase)"
                return
            }

            # Wait for the async task to complete
            $taskUpid = $result.Response.data
            if ($taskUpid)
            {
                $taskTimeout = 30
                $taskStart = Get-Date
                do
                {
                    Start-Sleep -Seconds 1
                    $taskStatus = (Get-PveNodesTasksStatus -Node $Node -Upid $taskUpid).Response.data
                }
                while ($taskStatus.status -ne 'stopped' -and ((Get-Date) - $taskStart).TotalSeconds -lt $taskTimeout)

                if ($taskStatus.exitstatus -ne 'OK')
                {
                    Write-Error -Message "Task to remove scsi${ScsiSlot} from VM ${VmId} failed: $($taskStatus.exitstatus)"
                    return
                }
            }

            Write-PSFMessage -Message "Successfully removed scsi$ScsiSlot from VM $VmId"

            [PSCustomObject]@{
                Node          = $Node
                VmId          = $VmId
                RemovedDevice = "scsi$ScsiSlot"
                PreviousValue = $currentValue
            }
        }
    }

    Write-LogFunctionExit
}
