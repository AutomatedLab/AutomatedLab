function Remove-LWProxmoxVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCmdlets', '', Justification = 'Not relevant on Linux')]
    [Cmdletbinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [int]$VmId
    )

    $PSBoundParameters.Add('ProgressIndicator', 1) #enables progress indicator
    if ($Machine.SkipDeployment)
    {
        return
    }

    Write-LogFunctionEntry

    Write-ScreenInfo -Message "Removing Proxmox VM '$Name'"

    # Every decision below rests on a fresh lookup on all available nodes. The session cache can still list
    # a VM that was deleted or migrated long ago. SilentlyContinue hides only the non-terminating 'not found'
    # error; the error for nodes that did not answer is terminating. The try block keeps a plain throw from
    # the lookup terminating too: without it, SilentlyContinue would swallow it and report the VM as absent.
    $getLiveVms = {
        try
        {
            @(Get-LWProxmoxVM -ComputerName $Name -NoCache -ErrorAction SilentlyContinue)
        }
        catch
        {
            Write-Error -ErrorRecord $_ -ErrorAction Stop
        }
    }

    $candidates = @(& $getLiveVms)

    if ($VmId -gt 0)
    {
        $matchingVms = @($candidates | Where-Object vmid -eq $VmId)
        $otherVms = @($candidates | Where-Object vmid -ne $VmId)
        if ($otherVms)
        {
            $otherVmInfo = ($otherVms | ForEach-Object { "VMID $($_.vmid) on node '$($_.node)'" }) -join ', '
            Write-ScreenInfo -Message "Not removing other Proxmox VM(s) named '$Name' ($otherVmInfo) because the lab created VMID $VmId." -Type Warning
        }
    }
    else
    {
        $matchingVms = $candidates
        if ($matchingVms.Count -gt 1)
        {
            $vmInfo = ($matchingVms | ForEach-Object { "VMID $($_.vmid) on node '$($_.node)'" }) -join ', '
            Write-Error -Message "Cannot tell which Proxmox VM named '$Name' belongs to the lab ($vmInfo) because the lab has no VMID for it. Remove the lab's VM manually." -ErrorAction Stop
        }
    }

    if (-not $matchingVms)
    {
        $vmIdInfo = ''
        $outcomeVmId = $null
        if ($VmId -gt 0)
        {
            $vmIdInfo = " with VMID $VmId"
            $outcomeVmId = $VmId
        }

        Write-ScreenInfo -Message "Proxmox VM '$Name'$vmIdInfo was not found on any available Proxmox node, nothing to remove." -Type Warning
        Write-LogFunctionExit
        return [pscustomobject]@{
            Name    = $Name
            VmId    = $outcomeVmId
            Node    = $null
            Outcome = 'NotFound'
        }
    }

    $vm = $matchingVms[0]
    $vmInfo = "Proxmox VM '$Name' (VMID $($vm.vmid)) on node '$($vm.node)'"
    $values = @{
        status = 'stopped'
    }
    $taskTimeoutInSeconds = 600

    if ($vm.status -ne 'stopped')
    {
        Write-ScreenInfo -Message "Stopping Proxmox VM '$Name' before removal"
        $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Stop VM '$Name'" -ScriptBlock { Stop-PveVm -VmIdOrName $vm.vmid }
        if ($result.StatusCode -ne 200)
        {
            Write-Error -Message "Could not stop $($vmInfo): the API returned '$($result.StatusCode) $($result.ReasonPhrase)'." -ErrorAction Stop
        }

        $taskStatus = [string](Wait-LWProxmoxTasksStatus -Upid $result.Response.data -Node $vm.node -DesiredValues $values -TimeoutInSeconds $taskTimeoutInSeconds)
        if (-not $taskStatus)
        {
            $taskStatus = "no exit status within $taskTimeoutInSeconds seconds"
        }

        if ($taskStatus -ne 'OK')
        {
            # A stop task with warnings is fine as long as the VM is stopped now
            $liveStatus = $null
            if ($taskStatus -like 'WARNINGS:*')
            {
                $liveStatus = (& $getLiveVms | Where-Object vmid -eq $vm.vmid).status
            }

            if ($liveStatus -ne 'stopped')
            {
                Write-Error -Message "Could not stop $($vmInfo): the stop task ended with '$taskStatus' and the VM status is '$liveStatus'." -ErrorAction Stop
            }

            Write-ScreenInfo -Message "The stop task of $vmInfo ended with '$taskStatus'. The VM is stopped, continuing." -Type Warning
        }
    }

    $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Remove VM '$Name'" -ScriptBlock { Remove-PveQemu -Node $vm.node -Vmid $vm.vmid } #-Purge $true -DestroyUnreferencedDisks $true
    if ($result.StatusCode -ne 200)
    {
        Write-Error -Message "Could not remove $($vmInfo): the API returned '$($result.StatusCode) $($result.ReasonPhrase)'." -ErrorAction Stop
    }

    $taskStatus = [string](Wait-LWProxmoxTasksStatus -Upid $result.Response.data -Node $vm.node -DesiredValues $values -TimeoutInSeconds $taskTimeoutInSeconds)
    if (-not $taskStatus)
    {
        $taskStatus = "no exit status within $taskTimeoutInSeconds seconds"
    }

    if ($taskStatus -ne 'OK' -and $taskStatus -notlike 'WARNINGS:*')
    {
        Write-Error -Message "Could not remove $($vmInfo): the destroy task ended with '$taskStatus'." -ErrorAction Stop
    }

    $remainingVm = & $getLiveVms | Where-Object vmid -eq $vm.vmid
    if ($remainingVm)
    {
        Write-Error -Message "Proxmox VM '$Name' (VMID $($vm.vmid)) is still listed on node '$($remainingVm.node -join ', ')' after its destroy task ended with '$taskStatus'." -ErrorAction Stop
    }

    if ($taskStatus -ne 'OK')
    {
        Write-ScreenInfo -Message "Removed $vmInfo, but the destroy task ended with '$taskStatus'. Check the task log of '$($result.Response.data)' for leftovers such as disks." -Type Warning
    }

    # Later lookups in this session must not serve the removed VM from the cache
    if ($script:proxmoxVmCache)
    {
        $script:proxmoxVmCache.Remove($vm.node)
    }

    Write-LogFunctionExit

    [pscustomobject]@{
        Name    = $Name
        VmId    = $vm.vmid
        Node    = $vm.node
        Outcome = 'Removed'
    }
}
