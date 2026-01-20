function Start-LWProxmoxAgentExecutionOnVM {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName
    )

    $proxmoxVms = Get-LWProxmoxVM

    foreach ($name in $ComputerName) {
        $vm = $proxmoxVms | Where-Object { $_.Name -eq $name }
        if (-not $vm) {
            Write-Error "Proxmox VM '$name' not found."
            continue
        }

        $param = @{
            Node    = $global:proxmoxNode
            Vmid    = $vm.VmId
            Command = $Command.Split(' ')
        }
        $result = New-PveNodesQemuAgentExec @param

        if ($result.StatusCode -ne 200) {
            Write-Error "Failed to start command on VM '$name'. The error was '$($result.ReasonPhrase)'."
            continue
        }
    }
}
