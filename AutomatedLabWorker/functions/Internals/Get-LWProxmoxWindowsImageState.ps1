function Get-LWProxmoxWindowsImageState
{
    <#
    .SYNOPSIS
        Reads the Windows Setup ImageState of a Proxmox clone through the QEMU Guest Agent.

    .DESCRIPTION
        Queries 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State\ImageState' on a
        running clone by executing 'reg.exe query' through the QEMU Guest Agent. Because it uses
        the guest agent instead of remoting, it works before WinRM is available - for example
        while the clone is still running its own first-boot specialize/OOBE. If the guest agent
        returns the command output base64-encoded, the payload is decoded before the ImageState
        value is parsed.

    .PARAMETER Node
        The Proxmox node hosting the virtual machine.

    .PARAMETER Vmid
        The numeric VMID of the virtual machine to query.

    .PARAMETER TimeoutSeconds
        The maximum time in seconds to wait for the guest-exec process to finish. Defaults to 30.

    .OUTPUTS
        System.String. The ImageState value (for example 'IMAGE_STATE_COMPLETE' or
        'IMAGE_STATE_UNDEPLOYABLE'), or $null when it cannot be determined.

    .EXAMPLE
        Get-LWProxmoxWindowsImageState -Node 'pve1' -Vmid 101

        Returns the Windows ImageState of VMID 101 on Proxmox node 'pve1'.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)] [string]$Node,
        [Parameter(Mandatory)] [int]$Vmid,
        [Parameter()] [int]$TimeoutSeconds = 30
    )

    $ProgressPreference = 'SilentlyContinue'
    try
    {
        $exec = New-PveNodesQemuAgentExec -Node $Node -Vmid $Vmid -Command @('reg.exe', 'query', 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State', '/v', 'ImageState') -ErrorAction Stop 2>$null
        if ($exec.StatusCode -ne 200) { return $null }
        $guestPid = $exec.Response.data.pid

        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        do
        {
            Start-Sleep -Milliseconds 500
            $status = Get-PveNodesQemuAgentExecStatus -Node $Node -Vmid $Vmid -Pid_ $guestPid -ErrorAction Stop 2>$null
        } while ($status.Response.data.exited -ne 1 -and $timer.Elapsed.TotalSeconds -lt $TimeoutSeconds)

        $out = [string]$status.Response.data.'out-data'
        if ($out -notmatch 'IMAGE_STATE_\w+' -and $out -match '^[A-Za-z0-9+/=\s]+$' -and $out.Length -gt 8)
        {
            try { $out = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($out -replace '\s', ''))) } catch { }
        }
        if ($out -match 'IMAGE_STATE_\w+') { return $Matches[0] }
        return $null
    }
    catch
    {
        return $null
    }
}
