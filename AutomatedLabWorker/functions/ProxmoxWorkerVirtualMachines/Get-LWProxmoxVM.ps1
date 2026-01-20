function Get-LWProxmoxVM {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCmdlets', '', Justification = 'Not relevant on Linux')]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [Alias('Name')]
        [string[]]
        $ComputerName,

        [Parameter()]
        [switch]
        $NoError,

        [Parameter()]
        [switch]
        $IncludeTemplates
    )

    Write-LogFunctionEntry

    if (-not (Test-LabProxmoxConnection)) {
        Write-Error 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    $vms = Get-PveNodesQemu -Node $global:proxmoxNode

    if ($vms.StatusCode -ne 200) {
        Write-Error "Failed to retrieve VM templates from Proxmox node '$($Node.node)': $($vms.ReasonPhrase)"
        return
    }

    $vms = if ($IncludeTemplates) {
        $vms.Response.data
    }
    else {
        $vms.Response.data | Where-Object { $_.template -ne 1 }
    }

    foreach ($vm in $vms) {
        $currentStatus = Get-PveNodesQemuStatusCurrent -Node $proxmoxNode -Vmid $vm.vmid
        $vm | Add-Member -Name CurrentStatus -MemberType NoteProperty -Value $currentStatus.Response.data
        $vm.tags = $vm.tags -split ';'
    }

    [object[]]$vms = $vms

    $vms = $vms | Sort-Object -Unique -Property Name

    if ($ComputerName.Count -gt 0) {
        return $vms | Where-Object { $_.Name -in $ComputerName }
    }

    if (-not $NoError.IsPresent -and $ComputerName.Count -gt 0 -and -not $vm) {
        Write-Error -Message "No virtual machine '$ComputerName' found"
        return
    }

    if ($vms.Count -eq 0) {
        return
    }

    $vms

    Write-LogFunctionExit
}
