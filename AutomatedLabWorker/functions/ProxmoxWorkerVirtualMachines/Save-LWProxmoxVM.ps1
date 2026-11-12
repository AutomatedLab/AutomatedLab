function Save-LWProxmoxVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    Write-PsfMessage -Message "Saving Proxmox VMs: $($ComputerName -join ', ')" -Level Verbose

    foreach ($name in $ComputerName)
    {
        Write-PsfMessage -Message "Saving Proxmox VM: $name" -Level Verbose
        $vm = Get-LWProxmoxVM -Name $name

        if (-not $vm)
        {
            Write-Error "Proxmox VM '$name' not found."
            continue
        }

        $result = Suspend-PveQemu -Node $vm.node -Vmid $vm.VmId
        if ($result.StatusCode -eq 500)
        {
            Write-Warning "Proxmox machine '$name' is already suspended."
        }
        elseif ($result.StatusCode -ne 200)
        {
            Write-Error "Could not save Proxmox machine '$name': The error was '$($result.StatusCode)'" -ErrorAction Stop
        }
        else
        {
            $values = @{
                exitstatus = 'OK'
                status = 'stopped'
            }
            Wait-LWProxmoxTasksStatus -Upid $result.Response.data -Node $vm.node -DesiredValues $values -TimeoutInSeconds 600
        }

        $result = Suspend-PveQemu -Node $vm.node -Vmid $vm.VmId -Todisk $true
        if ($result.StatusCode -eq 500)
        {
            Write-Warning "Proxmox machine '$name' is already saved to disk."
        }
        elseif ($result.StatusCode -ne 200)
        {
            Write-Error "Could not save Proxmox machine '$name': The error was '$($result.StatusCode)'" -ErrorAction Stop
        }
        else
        {
            $values = @{
                exitstatus = 'OK'
                status = 'stopped'
            }
            Wait-LWProxmoxTasksStatus -Upid $result.Response.data -Node $vm.node -DesiredValues $values -TimeoutInSeconds 600
            Write-Verbose 'done.'
        }
    }

    Write-PSFMessage -Message "Proxmox VMs saved." -Level Verbose

}
