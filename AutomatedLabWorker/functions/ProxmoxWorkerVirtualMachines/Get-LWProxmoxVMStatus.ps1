function Get-LWProxmoxVMStatus {
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    if (-not (Test-LabProxmoxConnection)) {
        Write-Error 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Write-LogFunctionEntry

    #TODO: Add Proxmox config item
    $proxmoxRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $result = @{ }
    $vms = Get-LWProxmoxVM @PSBoundParameters

    $vmTable = @{ }
    Get-LabVm -ComputerName $ComputerName -IncludeLinux | ForEach-Object { $vmTable[$_.FriendlyName] = $_.Name }

    foreach ($vm in $vms) {
        $vmName = if ($vmTable[$vm.Name]) { $vmTable[$vm.Name] } else { $vm.Name }

        if ($vm.status -eq 'running' -and $vm.CurrentStatus.qmpstatus -eq 'running') {
            $result.Add($vmName, 'Started')
        }
        elseif ($vm.status -eq 'stopped' -and $vm.CurrentStatus.qmpstatus -eq 'stopped') {
            $result.Add($vmName, 'Stopped')
        }
        else {
            $result.Add($vmName, 'Unknown')
        }
    }

    $result

    Write-LogFunctionExit
}
