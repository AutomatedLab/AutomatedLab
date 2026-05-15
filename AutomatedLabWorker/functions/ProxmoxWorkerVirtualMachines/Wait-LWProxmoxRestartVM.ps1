function Wait-LWProxmoxRestartVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [switch]$DoNotUseCredSsp,

        [double]$TimeoutInMinutes = 15,

        [int]$ProgressIndicator,

        [switch]$NoNewLine,

        [datetime]
        $MonitoringStartTime = (Get-Date),

        [System.Management.Automation.Job[]]$MonitorJob,

        [AutomatedLab.Machine[]]$StartMachinesWhileWaiting
    )

    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Write-LogFunctionEntry

    $start = (Get-Date)

    Write-PSFMessage -Message "Starting monitoring the servers at '$start'"

    $machines = Get-LabVM -ComputerName $ComputerName

    # Track initial state - mark all machines as not yet stopped
    $machines | Add-Member -Name HasStopped -MemberType NoteProperty -Value $false -Force
    # Track whether the QEMU guest agent was ever observed as responsive on this machine.
    # We only consider the agent "gone" (= reboot started) once it has first been "up".
    $machines | Add-Member -Name AgentWasUp -MemberType NoteProperty -Value $false -Force

    # Map machine name -> VMID once; ping needs Node + Vmid and ResourceName -> VMID lookup.
    $vmIdMap = @{ }
    foreach ($machine in $machines)
    {
        $pveVm = Get-LWProxmoxVM -ComputerName $machine.ResourceName -NoCache -NoError | Select-Object -First 1
        if ($pveVm) { $vmIdMap[$machine.Name] = @{ Vmid = $pveVm.VmId; Node = $pveVm.Node } }
    }

    $ProgressIndicatorTimer = (Get-Date)

    # Suppress Invoke-RestMethod progress bars from the PVE API module to keep dot-output clean.
    $ProgressPreference = 'SilentlyContinue'

    # Phase 1: Detect guest-OS reboot via QEMU guest agent ping transitions.
    #
    # The previous implementation polled `qm status` for a transition to 'Stopped', but on
    # QEMU/KVM a guest-initiated reboot (Restart-Computer / shutdown /r, including the reboot
    # triggered by Install-ADDSForest) never stops the VM at the hypervisor level - the QEMU
    # process keeps running and `qmpstatus` stays 'running' throughout. That caused this
    # function to spin until the full TimeoutInMinutes (default 60) even though the DC had
    # already rebooted and AD was back online.
    #
    # The guest agent on the other hand becomes unresponsive for the duration of the reboot,
    # which is exactly the signal we need. We use the agent's ping endpoint (already used in
    # Initialize-LWProxmoxVM for the same purpose).
    do {
        if (((Get-Date) - $ProgressIndicatorTimer).TotalSeconds -ge $ProgressIndicator) {
            Write-ProgressIndicator
            $ProgressIndicatorTimer = (Get-Date)
        }

        # Check MonitorJob for failures (mirrors HyperV handler behavior)
        if ($MonitorJob) {
            foreach ($job in $MonitorJob) {
                if ($job.State -eq 'Failed') {
                    $result = $job | Receive-Job -ErrorVariable jobError

                    $criticalError = $jobError | Where-Object { $_.Exception.Message -like 'AL_CRITICAL*' }
                    if ($criticalError) { throw $criticalError.Exception }

                    $nonCriticalErrors = $jobError | Where-Object { $_.Exception.Message -like 'AL_ERROR*' }
                    foreach ($nonCriticalError in $nonCriticalErrors) {
                        Write-PSFMessage "There was a non-critical error in job $($job.ID) '$($job.Name)' with the message: '($nonCriticalError.Exception.Message)'"
                    }
                }
            }
        }

        # Start additional machines while waiting (mirrors HyperV handler behavior)
        if ($StartMachinesWhileWaiting) {
            Start-LabVM -ComputerName $StartMachinesWhileWaiting[0] -NoNewline:$NoNewLine
            $StartMachinesWhileWaiting = $StartMachinesWhileWaiting | Where-Object { $_ -ne $StartMachinesWhileWaiting[0] }
        }

        foreach ($machine in $machines) {
            if ($machine.HasStopped) { continue }

            $vmInfo = $vmIdMap[$machine.Name]
            $agentUp = $false
            if ($vmInfo) {
                try {
                    $pingResult = New-PveNodesQemuAgentPing -Node $vmInfo.Node -Vmid $vmInfo.Vmid -ErrorAction Stop
                    if ($pingResult.StatusCode -eq 200) { $agentUp = $true }
                }
                catch {
                    $agentUp = $false
                }
            }

            if ($agentUp -and -not $machine.AgentWasUp) {
                Write-PSFMessage -Message "QEMU guest agent on VM '$($machine.Name)' is responsive - baseline established"
                $machine.AgentWasUp = $true
            }
            elseif (-not $agentUp -and $machine.AgentWasUp) {
                Write-PSFMessage -Message "QEMU guest agent on VM '$($machine.Name)' stopped responding (reboot in progress)"
                $machine.HasStopped = $true
            }
        }

        if (($machines | Where-Object { -not $_.HasStopped }).Count -gt 0) {
            Start-Sleep -Seconds 3
        }
    }
    until (($machines | Where-Object { -not $_.HasStopped }).Count -eq 0 -or (Get-Date).AddMinutes(-$TimeoutInMinutes) -gt $start)

    if (($machines | Where-Object { -not $_.HasStopped }).Count -gt 0) {
        Write-PSFMessage -Message "Not all machines reported a reboot within timeout. Proceeding to wait for them to come back online."
    }
    else {
        Write-PSFMessage -Message "All machines have rebooted: ($($machines.Name -join ', '))"
    }

    # Phase 2: Wait for the VMs to come back online via WinRM (same as HyperV handler).
    # By this point, the original job sessions should have been cleaned up or timed out,
    # so we can safely poll via WinRM without interference.
    $remainingMinutes = [math]::Max(1, $TimeoutInMinutes - ((Get-Date) - $start).TotalMinutes)
    Wait-LabVM -ComputerName $ComputerName -ProgressIndicator $ProgressIndicator -TimeoutInMinutes $remainingMinutes -DoNotUseCredSsp:$DoNotUseCredSsp -NoNewLine:$NoNewLine

    # Phase 3: Stable-port readiness check to absorb the WinRM listener bounce that
    # occurs after Wait-LabVM declares the port open. On freshly-promoted DCs and on
    # domain-joined dependent machines that were just restarted, AD/Kerberos/SPN
    # reinitialisation briefly tears down and rebinds the WinRM listener (observed
    # window: 5-30 seconds after first reachability). Without this check, the next
    # caller (e.g. Wait-LabADReady -> Test-LabADReady -> Invoke-LabCommand ->
    # New-LabPSSession) sees "port is closed after 2 retries" because
    # New-LabPSSession defaults to Retries=2 / Interval=5s (~10s window). AL recovers
    # via outer retry loops but the noisy Write-Error appears in the console.
    #
    # Strategy: poll TCP/5985 every 2 s; require N consecutive successful probes
    # (default 8 ~= 16 s of stability) before returning. Cap total wait at 90 s so we
    # do not stall the deployment if the bounce is unusually long.
    $stableProbesRequired = 8
    $probeIntervalSeconds = 2
    $stabilityTimeoutSeconds = 90
    $stabilityStart = Get-Date
    $machineNames = @($ComputerName)
    Write-PSFMessage -Message "Phase 3: waiting for WinRM port 5985 to be stable on $($machineNames -join ', ') (require $stableProbesRequired consecutive opens, max ${stabilityTimeoutSeconds}s)"
    $consecutive = @{}
    foreach ($name in $machineNames) { $consecutive[$name] = 0 }
    while ($true) {
        $allStable = $true
        foreach ($name in $machineNames) {
            if ($consecutive[$name] -ge $stableProbesRequired) { continue }
            $allStable = $false
            $portTest = $null
            try { $portTest = Test-Port -ComputerName $name -Port 5985 -TCP -TcpTimeout 2000 -ErrorAction Stop } catch { $portTest = $null }
            if ($portTest -and $portTest.Open) {
                $consecutive[$name]++
            }
            else {
                if ($consecutive[$name] -gt 0) {
                    Write-PSFMessage -Message "Phase 3: WinRM bounce detected on '$name' after $($consecutive[$name]) stable probe(s); resetting counter"
                }
                $consecutive[$name] = 0
            }
        }
        if ($allStable) { break }
        if (((Get-Date) - $stabilityStart).TotalSeconds -ge $stabilityTimeoutSeconds) {
            $unstable = $machineNames | Where-Object { $consecutive[$_] -lt $stableProbesRequired }
            Write-PSFMessage -Level Warning -Message "Phase 3: WinRM port did not stabilise within ${stabilityTimeoutSeconds}s on: $($unstable -join ', '). Proceeding anyway."
            break
        }
        Start-Sleep -Seconds $probeIntervalSeconds
    }
    Write-PSFMessage -Message "Phase 3 complete after $([int]((Get-Date) - $stabilityStart).TotalSeconds)s"

    if (-not $NoNewLine) {
        Write-ProgressIndicatorEnd
    }

    if ((Get-Date).AddMinutes(-$TimeoutInMinutes) -gt $start) {
        foreach ($machine in $machines) {
            Write-Error -Message "Timeout while waiting for computers to restart. Computers '$($machine.Name)' not restarted" -TargetObject $machine.Name
        }
    }

    Write-PSFMessage -Message "Finished monitoring the servers at '$(Get-Date)'"

    Write-LogFunctionExit
}
