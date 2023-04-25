function Wait-LWHypervVMRestart
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [double]$TimeoutInMinutes = 15,

        [ValidateRange(1, 300)]
        [int]$ProgressIndicator,

        [AutomatedLab.Machine[]]$StartMachinesWhileWaiting,

        [System.Management.Automation.Job[]]$MonitorJob,

        [switch]$NoNewLine
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName -IncludeLinux

    $machines | Add-Member -Name Uptime -MemberType NoteProperty -Value 0 -Force
    foreach ($machine in $machines)
    {
        $machine.Uptime = (Get-LWHypervVM -Name $machine.ResourceName).Uptime.TotalSeconds
    }

    $vmDrive = ((Get-Lab).Target.Path)[0]
    $start = (Get-Date)
    $progressIndicatorStart = (Get-Date)
    $diskTime = @()
    $lastMachineStart = (Get-Date).AddSeconds(-5)
    $delayedStart = @()

    #$lastMonitorJob = (Get-Date)

    do
    {
        if (((Get-Date) - $progressIndicatorStart).TotalSeconds -gt $ProgressIndicator)
        {
            Write-ProgressIndicator
            $progressIndicatorStart = (Get-Date)
        }

        $diskTime += 100-([int](((Get-Counter -counter "\\$(hostname.exe)\PhysicalDisk(*)\% Idle Time" -SampleInterval 1).CounterSamples | Where-Object {$_.InstanceName -like "*$vmDrive`:*"}).CookedValue))

        if ($StartMachinesWhileWaiting)
        {
            if ($StartMachinesWhileWaiting[0].NetworkAdapters.Count -gt 1)
            {
                $StartMachinesWhileWaiting = $StartMachinesWhileWaiting | Where-Object { $_ -ne $StartMachinesWhileWaiting[0] }
                $delayedStart += $StartMachinesWhileWaiting[0]
            }
            else
            {
                Write-Debug -Message "Disk Time: $($diskTime[-1]). Average (20): $([int](($diskTime[(($diskTime).Count-15)..(($diskTime).Count)] | Measure-Object -Average).Average)) - Average (5): $([int](($diskTime[(($diskTime).Count-5)..(($diskTime).Count)] | Measure-Object -Average).Average))"
                if (((Get-Date) - $lastMachineStart).TotalSeconds -ge 20)
                {
                    if (($diskTime[(($diskTime).Count - 15)..(($diskTime).Count)] | Measure-Object -Average).Average -lt 50 -and ($diskTime[(($diskTime).Count-5)..(($diskTime).Count)] | Measure-Object -Average).Average -lt 60)
                    {
                        Write-PSFMessage -Message 'Starting next machine'
                        $lastMachineStart = (Get-Date)
                        Start-LabVM -ComputerName $StartMachinesWhileWaiting[0] -NoNewline:$NoNewLine
                        $StartMachinesWhileWaiting = $StartMachinesWhileWaiting | Where-Object { $_ -ne $StartMachinesWhileWaiting[0] }
                        if ($StartMachinesWhileWaiting)
                        {
                            Start-LabVM -ComputerName $StartMachinesWhileWaiting[0] -NoNewline:$NoNewLine
                            $StartMachinesWhileWaiting = $StartMachinesWhileWaiting | Where-Object { $_ -ne $StartMachinesWhileWaiting[0] }
                        }
                    }
                }
            }
        }
        else
        {
            Start-Sleep -Seconds 1
        }

        <#
                Not implemented yet as receive-job displays everything in the console
                if ($lastMonitorJob -and ((Get-Date) - $lastMonitorJob).TotalSeconds -ge 5)
                {
                foreach ($job in $MonitorJob)
                {
                try
                {
                $dummy = Receive-Job -Keep -Id $job.ID -ErrorAction Stop
                }
                catch
                {
                Write-ScreenInfo -Message "Something went wrong with '$($job.Name)'. Please check using 'Receive-Job -Id $($job.Id)'" -Type Error
                throw 'Execution stopped'
                }
                }
                }
        #>

        foreach ($machine in $machines)
        {
            $currentMachineUptime = (Get-LWHypervVM -Name $machine.ResourceName).Uptime.TotalSeconds
            Write-Debug -Message "Uptime machine '$($machine.ResourceName)'=$currentMachineUptime, Saved uptime=$($machine.uptime)"
            if ($machine.Uptime -ne 0 -and $currentMachineUptime -lt $machine.Uptime)
            {
                Write-PSFMessage -Message "Machine '$machine' is now stopped"
                $machine.Uptime = 0
            }
        }

        Start-Sleep -Seconds 2

        if ($MonitorJob)
        {
            foreach ($job in $MonitorJob)
            {
                if ($job.State -eq 'Failed')
                {
                    $result = $job | Receive-Job -ErrorVariable jobError

                    $criticalError = $jobError | Where-Object { $_.Exception.Message -like 'AL_CRITICAL*' }
                    if ($criticalError) { throw $criticalError.Exception }

                    $nonCriticalErrors = $jobError | Where-Object { $_.Exception.Message -like 'AL_ERROR*' }
                    foreach ($nonCriticalError in $nonCriticalErrors)
                    {
                        Write-PSFMessage "There was a non-critical error in job $($job.ID) '$($job.Name)' with the message: '($nonCriticalError.Exception.Message)'"
                    }
                }
            }
        }
    }
    until (($machines.Uptime | Measure-Object -Maximum).Maximum -eq 0 -or (Get-Date).AddMinutes(-$TimeoutInMinutes) -gt $start)

    if (($machines.Uptime | Measure-Object -Maximum).Maximum -eq 0)
    {
        Write-PSFMessage -Message "All machines have stopped: ($($machines.name -join ', '))"
    }

    if ((Get-Date).AddMinutes(-$TimeoutInMinutes) -gt $start)
    {
        foreach ($Computer in $ComputerName)
        {
            if ($machineInfo.($Computer) -gt 0)
            {
                Write-Error -Message "Timeout while waiting for computer '$computer' to restart." -TargetObject $computer
            }
        }
    }

    $remainingMinutes = $TimeoutInMinutes - ((Get-Date) - $start).TotalMinutes
    Wait-LabVM -ComputerName $ComputerName -ProgressIndicator $ProgressIndicator -TimeoutInMinutes $remainingMinutes -NoNewLine:$NoNewLine

    if ($delayedStart)
    {
        Start-LabVM -ComputerName $delayedStart -NoNewline:$NoNewLine
    }

    Write-ProgressIndicatorEnd

    Write-LogFunctionExit
}
