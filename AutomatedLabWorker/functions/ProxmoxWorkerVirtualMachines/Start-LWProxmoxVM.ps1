function Start-LWProxmoxVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [int]$DelayBetweenComputers = 0,

        [int]$PreDelaySeconds = 0,

        [int]$PostDelaySeconds = 0,

        [int]$ProgressIndicator,

        [switch]$NoNewLine
    )

    if ($PreDelaySeconds) {
        $job = Start-Job -Name 'Start-LWHypervVM - Pre Delay' -ScriptBlock { Start-Sleep -Seconds $Using:PreDelaySeconds }
        Wait-LWLabJob -Job $job -NoNewLine -ProgressIndicator $ProgressIndicator -Timeout 15 -NoDisplay
    }

    $vms = Get-LWProxmoxVM

    foreach ($vm in (Get-LabVM -ComputerName $ComputerName -IncludeLinux | Where-Object SkipDeployment -eq $false))
    {
        $vmid = $vms | where-object { $_.Name -eq $vm.ResourceName } | Select-Object -ExpandProperty VmId

        try
        {
            $proxmoxVm = Get-LWProxmoxVM -Name $vm
            if ($proxmoxVm.status -eq 'running' -and $proxmoxVm.CurrentStatus.qmpstatus -eq 'running')
            {
                Write-PSFMessage -Message "Proxmox machine '$vm' is already running. Skipping start." -Level 'Verbose'
                continue
            }

            if ($proxmoxVm.CurrentStatus.qmpstatus -eq 'paused')
            {
                Write-PSFMessage -Message "Resuming Proxmox machine '$vm' from paused state." -Level 'Verbose'
                $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Resume VM '$vm'" -ScriptBlock { Resume-PveQemu -Node $proxmoxVm.node -Vmid $vmid }
                if ($result.StatusCode -ne 200)
                {
                    Write-Error "Could not resume Proxmox machine '$vm': The error was '$($result.StatusCode)'" -ErrorAction Stop
                }
                continue
            }

            $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Start VM '$vm'" -ScriptBlock { Start-PveVm -VmIdOrName $vmid }

            if ($result.StatusCode -ne 200)
            {
                Write-Error "Could not start Proxmox machine '$vm': The error was '$($result.StatusCode)'" -ErrorAction Stop
            }

            $values = @{
                status = 'stopped'
            }
            $result = Wait-LWProxmoxTasksStatus -Upid $result.Response.data -Node $proxmoxVm.node -DesiredValues $values -TimeoutInSeconds 600
            if ($result -ne 'OK' -and $result -ne "VM $vmid already running")
            {
                Write-Error -Message "Could not start Proxmox machine '$vm'. The error was '$result'." -ErrorAction Stop
            }
        }
        catch
        {
            Write-Error -Message "Could not start Proxmox machine '$vm': $($_.Exception.Message)" -Exception $_.Exception -ErrorAction Stop
        }

        if ($vm.OperatingSystemType -eq 'Linux')
        {
            Write-PSFMessage -Message "Skipping the wait period for '$vm' as it is a Linux system"
            continue
        }

        if ($DelayBetweenComputers -and $vm -ne $ComputerName[-1])
        {
            $job = Start-Job -Name 'Start-LWHypervVM - DelayBetweenComputers' -ScriptBlock { Start-Sleep -Seconds $Using:DelayBetweenComputers }
            Wait-LWLabJob -Job $job -NoNewLine:$NoNewLine -ProgressIndicator $ProgressIndicator -Timeout 15 -NoDisplay
        }
    }

    if ($PostDelaySeconds)
    {
        $job = Start-Job -Name 'Start-LWHypervVM - Post Delay' -ScriptBlock { Start-Sleep -Seconds $Using:PostDelaySeconds }
        Wait-LWLabJob -Job $job -NoNewLine:$NoNewLine -ProgressIndicator $ProgressIndicator -Timeout 15 -NoDisplay
    }

    Write-LogFunctionExit
}
