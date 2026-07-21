function Remove-LWProxmoxIsoImage
{
    <#
    .SYNOPSIS
        Removes (deletes) an ISO image from a Proxmox storage.

    .DESCRIPTION
        Deletes an ISO file from a Proxmox VE storage using the storage content API.
        The ISO can be identified either by file name (with optional storage) or by
        its full Proxmox volume identifier.

        Unlike Dismount-LWProxmoxIsoImage and Remove-LWProxmoxCdDrive, which only
        detach the CD-ROM drive from a VM, this function permanently deletes the ISO
        file from the storage.

        Requires an active connection to the Proxmox cluster (Connect-LabProxmoxCluster).

    .PARAMETER Node
        The name of the Proxmox node hosting the storage.

    .PARAMETER IsoFile
        The ISO file name to delete (e.g. 'WinServer2025.iso'). When -Storage is
        omitted, all ISO-capable storages on the node are searched for the file.

    .PARAMETER Storage
        The storage identifier that holds the ISO. When omitted, all ISO-capable
        storages on the node are searched for the file.

    .PARAMETER VolId
        The full Proxmox volume identifier of the ISO (e.g. 'local:iso/WinServer2025.iso').

    .PARAMETER TimeoutInSeconds
        Maximum time to wait for the Proxmox delete task to complete. Defaults to 300.

    .PARAMETER Force
        Delete without prompting for confirmation.

    .PARAMETER PassThru
        Return an object describing the deleted ISO.

    .PARAMETER Confirm
        Prompts for confirmation before deleting the ISO image.

    .PARAMETER WhatIf
        Shows what would happen if the command runs. The ISO image is not deleted.

    .EXAMPLE
        Remove-LWProxmoxIsoImage -Node 'rz1pinhst101' -IsoFile 'WinServer2025.iso'

        Searches all ISO-capable storages on the node and deletes the ISO.

    .EXAMPLE
        Remove-LWProxmoxIsoImage -Node 'rz1pinhst101' -IsoFile 'setup.iso' -Storage 'cephfs' -Force

        Deletes the ISO from the 'cephfs' storage without confirmation.

    .EXAMPLE
        Remove-LWProxmoxIsoImage -Node 'rz1pinhst101' -VolId 'local:iso/setup.iso'

        Deletes the ISO identified by its full volume id.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'ByFile')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Node,

        [Parameter(Mandatory, ParameterSetName = 'ByFile')]
        [ValidateNotNullOrEmpty()]
        [string]
        $IsoFile,

        [Parameter(ParameterSetName = 'ByFile')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Storage,

        [Parameter(Mandatory, ParameterSetName = 'ByVolId')]
        [ValidateNotNullOrEmpty()]
        [string]
        $VolId,

        [Parameter()]
        [ValidateRange(1, 86400)]
        [int]
        $TimeoutInSeconds = 300,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [switch]
        $PassThru
    )

    Write-LogFunctionEntry

    # -Force implies a non-interactive call: suppress the High-impact ShouldProcess
    # confirmation prompt unless the caller explicitly passed -Confirm.
    if ($Force -and -not $PSBoundParameters.ContainsKey('Confirm'))
    {
        $ConfirmPreference = 'None'
    }

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error -Message 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    # Resolve the target ISO into a storage + volume id
    if ($PSCmdlet.ParameterSetName -eq 'ByVolId')
    {
        if ($VolId -notmatch '^[^:]+:iso/.+\.iso$')
        {
            Write-Error -Message "The volume id '$VolId' is not a valid ISO volume identifier (expected '<storage>:iso/<file>.iso')." -ErrorAction Stop
            return
        }
        $resolvedStorage = ($VolId -split ':', 2)[0]
        $resolvedVolId = $VolId
        $resolvedName = ($VolId -split '/')[-1]
    }
    else
    {
        $getParams = @{ Node = $Node; IsoFile = $IsoFile }
        if ($Storage) { $getParams['Storage'] = $Storage }

        $iso = $null
        try { $iso = Get-LWProxmoxIsoImage @getParams -ErrorAction Stop | Select-Object -First 1 } catch { $iso = $null }

        if (-not $iso)
        {
            $scope = if ($Storage) { " storage '$Storage'" } else { '' }
            Write-Error -Message "ISO file '$IsoFile' was not found on node '$Node'$scope." -ErrorAction Stop
            return
        }

        $resolvedStorage = $iso.Storage
        $resolvedVolId = $iso.VolId
        $resolvedName = $iso.FileName
    }

    if (-not $PSCmdlet.ShouldProcess("$resolvedVolId on node '$Node'", 'Delete ISO image from storage'))
    {
        Write-LogFunctionExit
        return
    }

    Write-PSFMessage -Message "Deleting ISO '$resolvedVolId' from node '$Node'."

    $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Delete ISO '$resolvedName' from storage '$resolvedStorage'" -ScriptBlock {
        Remove-PveNodesStorageContent -Node $Node -Storage $resolvedStorage -Volume $resolvedVolId
    }

    if ($result.StatusCode -ne 200)
    {
        Write-Error -Message "Failed to delete ISO '$resolvedVolId' from node '$Node': $($result.ReasonPhrase)" -ErrorAction Stop
        return
    }

    $upid = $result.Response.data
    if ($upid -and "$upid" -like 'UPID:*')
    {
        Write-PSFMessage -Message "Delete accepted. Waiting for task '$upid' to finish."
        $exitStatus = Wait-LWProxmoxTasksStatus -Upid $upid -Node $Node -DesiredValues @{ status = 'stopped' } -TimeoutInSeconds $TimeoutInSeconds

        if ($exitStatus -ne 'OK')
        {
            Write-Error -Message "The Proxmox delete task for '$resolvedVolId' finished with a non-OK status: '$exitStatus'." -ErrorAction Stop
            return
        }
    }

    Write-ScreenInfo -Message "Successfully deleted ISO '$resolvedName' from storage '$resolvedStorage' on node '$Node'." -Type Info

    if ($PassThru)
    {
        [PSCustomObject]@{
            Node     = $Node
            Storage  = $resolvedStorage
            VolId    = $resolvedVolId
            FileName = $resolvedName
            Deleted  = $true
        }
    }

    Write-LogFunctionExit
}
