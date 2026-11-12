function Stop-LWProxmoxVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [double]$TimeoutInMinutes,

        [int]$ProgressIndicator,

        [switch]$NoNewLine,

        [bool]$ShutdownFromOperatingSystem = $true
    )

    Write-LogFunctionEntry

    $start = Get-Date

    $vms = Get-LWProxmoxVM -Name $ComputerName

    if ($ShutdownFromOperatingSystem)
    {
        $jobs = @()
        $linux, $windows = (Get-LabVM -ComputerName $ComputerName -IncludeLinux).Where({ $_.OperatingSystemType -eq 'Linux' }, 'Split')

        if ($windows)
        {
            $jobs += Invoke-LabCommand -ComputerName $windows -NoDisplay -AsJob -PassThru -ErrorAction SilentlyContinue -ErrorVariable invokeErrors -ScriptBlock {
                Stop-Computer -Force -ErrorAction Stop
            }
        }

        if ($linux)
        {
            $jobs += Invoke-LabCommand -UseLocalCredential -ComputerName $linux -NoDisplay -AsJob -PassThru -ScriptBlock {
                #Sleep as background process so that job does not fail.
                [void] (Start-Job -ScriptBlock {
                        Start-Sleep -Seconds 5
                        shutdown -P now
                })
            }
        }

        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine
        $failedJobs = $jobs | Where-Object { $_.State -eq 'Failed' }
        if ($failedJobs)
        {
            Write-ScreenInfo -Message "Could not stop Proxmox VM(s): '$($failedJobs.Location)'" -Type Error
        }

        $stopFailures = [System.Collections.Generic.List[string]]::new()

        foreach ($failedJob in $failedJobs)
        {
            if (Get-LabVM -ComputerName $failedJob.Location -IncludeLinux)
            {
                $stopFailures.Add($failedJob.Location)
            }
        }

        foreach ($invokeError in $invokeErrors.TargetObject)
        {
            if ($invokeError -is [System.Management.Automation.Runspaces.Runspace] -and $invokeError.ConnectionInfo.ComputerName -as [ipaddress])
            {
                # Special case - return value is an IP address instead of a host name. We need to look it up.
                $stopFailures.Add((Get-LabVM -ComputerName $ComputerName -IncludeLinux | Where-Object Ipv4Address -eq $invokeError.ConnectionInfo.ComputerName).ResourceName)
            }
            elseif ($invokeError -is [System.Management.Automation.Runspaces.Runspace])
            {
                $stopFailures.Add((Get-LabVM -ComputerName $invokeError.ConnectionInfo.ComputerName -IncludeLinux).ResourceName)
            }
        }

        $stopFailures = $stopFailures | Sort-Object -Unique

        if ($stopFailures)
        {
            Write-ScreenInfo -Message "Force-stopping VMs: $($stopFailures -join ',')"
            $vms = Get-LWProxmoxVM -Name $stopFailures
            foreach ($vm in $vms)
            {
                $null = Invoke-LWProxmoxCallWithRetry -ActivityName "Force-stop VM '$($vm.Name)'" -ScriptBlock { Stop-PveVm -VmIdOrName $vm.VmId }
            }
        }
    }
    else
    {
        $jobs = @()
        foreach ($name in (Get-LabVM -ComputerName $ComputerName -IncludeLinux | Where-Object SkipDeployment -eq $false).ResourceName)
        {
            $vm = $vms | Where-Object { $_.Name -eq $name } | Select-Object -ExpandProperty VmId
            $jobs += [PSCustomObject]@{
                Upid         = (Invoke-LWProxmoxCallWithRetry -ActivityName "Shutdown VM '$name'" -ScriptBlock { New-PveNodesQemuStatusShutdown -Node $vm.node -Vmid $vm.vmId -Forcestop $true }).Response.data
                ComputerName = $name
                Node         = $vm.node
            }
        }

        $d = (Get-Date).AddMinutes($TimeoutInMinutes)
        # Suppress progress bars from Invoke-RestMethod inside the PVE API module
        $ProgressPreference = 'SilentlyContinue'

        do
        {
            $currentJobs = $jobs.Clone()
            foreach ($job in $currentJobs)
            {
                $jobStatus = (Get-PveNodesTasksStatus -Node $job.Node -Upid $job.Upid).Response.data.Status
                if ($jobStatus -eq 'stopped')
                {
                    $jobs = $jobs -ne $job
                }
            }
        } until ($jobs.Count -eq 0 -or (Get-Date) -gt $d)

        if ($jobs.Count -gt 0)
        {
            Write-ScreenInfo -Message "The following VMs could not be stopped in time: $($jobs.ComputerName -join ', ')" -Type Warning
        }
    }

    Write-LogFunctionExit
}
