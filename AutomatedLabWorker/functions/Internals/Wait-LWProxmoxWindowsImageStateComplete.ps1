function Wait-LWProxmoxWindowsImageStateComplete
{
    <#
    .SYNOPSIS
        Waits until a Proxmox Windows clone reaches IMAGE_STATE_COMPLETE.

    .DESCRIPTION
        Polls the Windows Setup ImageState of a running clone (through the QEMU Guest Agent,
        via Get-LWProxmoxWindowsImageState) until it reports 'IMAGE_STATE_COMPLETE', which means
        the clone's own first-boot specialize has settled. A specialized golden template is
        already COMPLETE and the function returns immediately with no added delay; a generalized
        (sysprepped) template needs its first-boot specialize to finish before it is safe to run
        Sysprep against it. If the timeout elapses without reaching COMPLETE, the function logs a
        warning and returns $false so the caller can proceed on a best-effort basis.

    .PARAMETER Node
        The Proxmox node hosting the virtual machine.

    .PARAMETER Vmid
        The numeric VMID of the virtual machine to poll.

    .PARAMETER Name
        A friendly machine name used in log messages. Defaults to "VMID <Vmid>".

    .PARAMETER TimeoutSeconds
        The maximum time in seconds to wait for 'IMAGE_STATE_COMPLETE'. Defaults to 1800.

    .PARAMETER PollIntervalSeconds
        The number of seconds to wait between ImageState reads. Defaults to 10.

    .OUTPUTS
        System.Boolean. $true when 'IMAGE_STATE_COMPLETE' was observed within the timeout;
        otherwise $false.

    .EXAMPLE
        Wait-LWProxmoxWindowsImageStateComplete -Node 'pve1' -Vmid 101 -Name 'Client2'

        Waits up to 30 minutes for VMID 101 on node 'pve1' to finish its first-boot specialize.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)] [string]$Node,
        [Parameter(Mandatory)] [int]$Vmid,
        [Parameter()] [string]$Name = "VMID $Vmid",
        [Parameter()] [int]$TimeoutSeconds = 1800,
        [Parameter()] [int]$PollIntervalSeconds = 10
    )

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $lastState = $null
    while ($timer.Elapsed.TotalSeconds -lt $TimeoutSeconds)
    {
        $state = Get-LWProxmoxWindowsImageState -Node $Node -Vmid $Vmid
        if ($state -and $state -ne $lastState)
        {
            Write-PSFMessage -Message "VM '$Name' Windows ImageState is '$state' after $([int]$timer.Elapsed.TotalSeconds)s."
            $lastState = $state
        }
        if ($state -eq 'IMAGE_STATE_COMPLETE')
        {
            return $true
        }
        Start-Sleep -Seconds $PollIntervalSeconds
    }

    Write-PSFMessage -Level Warning -Message "VM '$Name' did not reach IMAGE_STATE_COMPLETE within $TimeoutSeconds s (last state: '$lastState'). Proceeding best-effort."
    return $false
}
