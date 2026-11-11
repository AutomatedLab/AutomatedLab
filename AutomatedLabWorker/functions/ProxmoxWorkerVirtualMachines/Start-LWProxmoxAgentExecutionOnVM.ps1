function Start-LWProxmoxAgentExecutionOnVM
{
    <#
    .SYNOPSIS
        Runs a command on Proxmox-hosted VMs through the QEMU Guest Agent.

    .DESCRIPTION
        Executes a command line on one or more Proxmox virtual machines using the QEMU Guest Agent
        guest-exec subsystem. The command string is tokenized so that the executable and its arguments
        are passed to the guest agent as separate arguments, preserving quoted segments (for example
        registry paths that contain spaces).

        By default the function starts the command and returns immediately without waiting for it to
        finish. When -Wait is specified the function polls the guest-exec status until the process exits
        and then inspects the result: a non-zero exit code, a termination signal, a missing exit code or a
        timeout each raise a terminating error. Without -Wait, a VM that cannot be found or a command that
        fails to start is reported as a non-terminating error and processing continues with the next
        computer; with -Wait these conditions are terminating.

        While waiting, a failed status query does not end the wait at once. A short outage of the QEMU Guest
        Agent, for example while the guest is stalled or restarting, is tolerated: the function keeps polling
        until the command exits, until -TimeoutSeconds has elapsed, or until the queries have been failing for
        -StatusFailureToleranceSeconds without a single success in between. After every failed query the VM is
        looked up afresh; a VM that is not running ends the wait at once. Every outage that was survived is
        logged once as a warning with its start, its size and the last reason.

        When the guest agent answers again but no longer knows the process, the result of the command is gone
        (the agent restarted or the guest rebooted). The function then stops waiting and raises the error
        'ProxmoxAgentCommandResultLost'. The command may or may not have completed. Once the start call has
        returned a process id, the function never starts the command a second time, because a command is not
        idempotent in general; the caller decides whether a re-run is safe. The start call itself is retried
        up to 8 times when Proxmox answers it with an error, so a start that the guest agent executed but
        Proxmox reported as failed (for example with a timeout) can run the command more than once. The guest
        agent reports an unknown process as "Invalid parameter 'pid'" (QEMU up to 8.1) or as "PID <n> does not
        exist" (QEMU 8.2 and later, where the number is missing from the text because of an upstream formatting
        bug); Proxmox passes that text on in the reason phrase. These texts come from the QEMU and Proxmox
        sources. The GuestAgent live test in LiveTests\Proxmox confirmed on Proxmox VE 9.2 that the reason
        phrase of an unknown process matches the pattern that this function uses.

    .PARAMETER Command
        The full command line to execute on the guest, for example
        'powershell.exe -NoProfile -Command Get-Service'.

    .PARAMETER ComputerName
        The name(s) of the Proxmox-hosted VM(s) on which to run the command.

    .PARAMETER Wait
        Waits for the command to finish on each VM and throws a terminating error if it does not complete
        successfully within the timeout. When omitted, the command is started and the function returns
        without waiting for completion.

    .PARAMETER TimeoutSeconds
        Maximum number of seconds to wait for the command to finish when -Wait is specified. Defaults to
        300 seconds and accepts values from 1 to 3600. Tolerated status failures do not extend this limit; the
        wait ends at the first check after the limit has elapsed, so it can overshoot by one poll.

    .PARAMETER PollIntervalSeconds
        Number of seconds to wait between guest-exec status checks when -Wait is specified. Defaults to 2
        seconds and accepts values from 1 to 60.

    .PARAMETER StatusFailureToleranceSeconds
        Number of seconds the status queries may keep failing, without a successful query in between, before
        -Wait gives up. A successful query resets the window; 0 fails at the first failed query. Accepts
        values from 0 to 3600. When omitted, the configuration item ProxmoxAgentStatusFailureTolerance is
        used (120 seconds by default).

    .EXAMPLE
        Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Server1' -Command 'ipconfig.exe /all'

        Starts 'ipconfig.exe /all' on 'Server1' through the guest agent and returns immediately.

    .EXAMPLE
        Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Server1' -Command 'C:\Install.cmd' -Wait -TimeoutSeconds 600

        Starts 'C:\Install.cmd' on 'Server1' and waits up to ten minutes for it to finish, throwing a
        terminating error if the command exits with a non-zero exit code or does not complete in time.

    .NOTES
        Besides the exit code, signal and timeout errors, -Wait raises these terminating errors with a
        dedicated error id (FullyQualifiedErrorId):

        ProxmoxAgentCommandResultLost  The guest agent answers but no longer knows the process.
        ProxmoxAgentVmNotRunning       A status query failed and the VM is not running.
        ProxmoxAgentStatusQueryFailed  The status queries kept failing for the whole tolerance.

        Write-Error appends the name of the calling command to the id, so match it with a wildcard or with
        '^ProxmoxAgentCommandResultLost(,|$)'.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,

        [Parameter()]
        [switch]$Wait,

        [Parameter()]
        [ValidateRange(1, 3600)]
        [int]$TimeoutSeconds = 300,

        [Parameter()]
        [ValidateRange(1, 60)]
        [int]$PollIntervalSeconds = 2,

        [Parameter()]
        [ValidateRange(0, 3600)]
        [int]$StatusFailureToleranceSeconds
    )

    $proxmoxVms = Get-LWProxmoxVM

    $failureToleranceSeconds = 120
    if ($PSBoundParameters.ContainsKey('StatusFailureToleranceSeconds'))
    {
        $failureToleranceSeconds = $StatusFailureToleranceSeconds
    }
    elseif ($Wait.IsPresent)
    {
        # No -Default: Get-LabConfigurationItem would turn a configured 0 into the default.
        $configuredTolerance = Get-LabConfigurationItem -Name ProxmoxAgentStatusFailureTolerance
        if (-not [string]::IsNullOrEmpty([string]$configuredTolerance))
        {
            $failureToleranceSeconds = [int]$configuredTolerance
        }
    }

    # The text of a status query for a process the guest agent does not know (see the help).
    $unknownProcessPattern = '(?i)invalid parameter .pid.|\bpid(\s+\S+)?\s+does not exist\b'

    foreach ($name in $ComputerName)
    {
        $vm = $proxmoxVms | Where-Object { $_.Name -eq $name }
        if (-not $vm)
        {
            if ($Wait.IsPresent)
            {
                Write-Error "Proxmox VM '$name' not found." -ErrorAction Stop
            }
            Write-Error "Proxmox VM '$name' not found."
            continue
        }

        # Parse the command string respecting quoted segments so that paths
        # with spaces (e.g. "HKLM\SOFTWARE\Microsoft\Windows NT\...") are
        # kept as a single argument.
        $commandParts = [System.Collections.Generic.List[string]]::new()
        foreach ($token in [System.Management.Automation.PSParser]::Tokenize($Command, [ref]$null))
        {
            if ($token.Type -in 'String', 'CommandArgument', 'CommandParameter', 'Command', 'Number')
            {
                $commandParts.Add($token.Content)
            }
        }

        # Fallback to simple split if tokenizer returned nothing useful
        if ($commandParts.Count -eq 0)
        {
            $commandParts.AddRange([string[]]($Command.Split(' ')))
        }

        $param = @{
            Node    = $vm.node
            Vmid    = $vm.VmId
            Command = $commandParts.ToArray()
        }
        $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Execute command on VM '$name'" -MaxRetries 8 -RetryDelaySeconds 5 -MaxDelaySeconds 30 -ProgressiveBackoff -ScriptBlock { New-PveNodesQemuAgentExec @param }

        if ($result.StatusCode -ne 200)
        {
            if ($Wait.IsPresent)
            {
                Write-Error "Failed to start command on VM '$name'. The error was '$($result.ReasonPhrase)'." -ErrorAction Stop
            }
            Write-Error "Failed to start command on VM '$name'. The error was '$($result.ReasonPhrase)'."
            continue
        }

        if (-not $Wait.IsPresent)
        {
            continue
        }

        $guestProcessId = $result.Response.data.pid
        $target = "VM '$name' (node '$($vm.node)', VMID $($vm.VmId))"
        $executionTimer = [System.Diagnostics.Stopwatch]::StartNew()
        $executionCompleted = $false
        $failedPolls = 0
        $failureStartSeconds = 0
        $failureStartClock = ''
        $failureSummary = ''
        $lastReasonSummary = ''

        while ($executionTimer.Elapsed.TotalSeconds -lt $TimeoutSeconds)
        {
            $executionStatus = Get-PveNodesQemuAgentExecStatus -Node $vm.node -Vmid $vm.VmId -Pid_ $guestProcessId
            if ($executionStatus.StatusCode -ne 200)
            {
                $lastReason = [string]$executionStatus.ReasonPhrase
                $lastReasonSummary = "Last reason: '$lastReason' (HTTP $($executionStatus.StatusCode))."
                if ($failedPolls -eq 0)
                {
                    $failureStartSeconds = $executionTimer.Elapsed.TotalSeconds
                    $failureStartClock = Get-Date -Format 'HH:mm:ss'
                }
                $failedPolls++
                $failureSeconds = $executionTimer.Elapsed.TotalSeconds - $failureStartSeconds
                $failureSummary = "Failed status polls: $failedPolls over $([int][math]::Floor($failureSeconds))s"

                if ($lastReason -match $unknownProcessPattern)
                {
                    Write-Error -Message "The result of the command on $target was lost: the guest agent answers again but no longer knows guest process $guestProcessId. The command may or may not have completed and was not started again. $failureSummary. $lastReasonSummary" -ErrorId 'ProxmoxAgentCommandResultLost' -Category ResourceUnavailable -TargetObject $name -ErrorAction Stop
                }

                # A VM that is not running will not answer again, so waiting for it is pointless. A lookup that
                # fails or does not list the VM proves nothing and the wait continues within the tolerance.
                $vmRunning = $null
                $vmState = 'unknown'
                try
                {
                    $currentVm = Get-LWProxmoxVM -Node $vm.node -NoCache -ErrorAction Stop |
                        Where-Object { [int]$_.VmId -eq [int]$vm.VmId } |
                        Select-Object -First 1
                    if ($currentVm)
                    {
                        $vmQmpStatus = $currentVm.CurrentStatus.qmpstatus
                        $vmState = "status '$($currentVm.status)', qmpstatus '$vmQmpStatus'"
                        $vmRunning = $currentVm.status -eq 'running' -and $vmQmpStatus -eq 'running'
                    }
                    else
                    {
                        $vmState = 'not listed by the node'
                    }
                }
                catch
                {
                    $vmState = "unknown ($($_.Exception.Message))"
                }

                if ($vmRunning -eq $false)
                {
                    Write-Error -Message "Failed to retrieve command status on ${target}: the VM is not running. VM state: $vmState. $failureSummary. $lastReasonSummary" -ErrorId 'ProxmoxAgentVmNotRunning' -Category ResourceUnavailable -TargetObject $name -ErrorAction Stop
                }

                if ($failureSeconds -ge $failureToleranceSeconds)
                {
                    Write-Error -Message "Failed to retrieve command status on ${target}: the status polls kept failing. $failureSummary, reaching the tolerance of ${failureToleranceSeconds}s. $lastReasonSummary VM state: $vmState." -ErrorId 'ProxmoxAgentStatusQueryFailed' -Category ConnectionError -TargetObject $name -ErrorAction Stop
                }

                Start-Sleep -Seconds $PollIntervalSeconds
                continue
            }

            if ($failedPolls -gt 0)
            {
                $outageSeconds = [int][math]::Floor($executionTimer.Elapsed.TotalSeconds - $failureStartSeconds)
                Write-PSFMessage -Level Warning -Message "QEMU guest agent outage tolerated on ${target}: the status polls for the command failed from $failureStartClock. Failed status polls: $failedPolls over ${outageSeconds}s (tolerance of ${failureToleranceSeconds}s) before the guest agent answered again. $lastReasonSummary Continuing to wait for the command."
                $failedPolls = 0
            }

            if ($executionStatus.Response.data.exited -eq 1)
            {
                $executionCompleted = $true
                $executionData = $executionStatus.Response.data
                $errorOutput = $executionData.'err-data'
                if ([string]::IsNullOrWhiteSpace($errorOutput))
                {
                    $errorOutput = $executionData.'out-data'
                }

                $signalProperty = $executionData.PSObject.Properties['signal']
                $signal = if ($signalProperty) { $signalProperty.Value } else { $null }
                if ($signalProperty)
                {
                    if (-not [string]::IsNullOrEmpty([string]$signal))
                    {
                        Write-Error "Command on VM '$name' terminated with signal $signal. $errorOutput" -ErrorAction Stop
                    }
                }

                $exitCodeProperty = $executionData.PSObject.Properties['exitcode']
                $exitCodeValue = if ($exitCodeProperty) { $exitCodeProperty.Value } else { $null }
                if (-not $exitCodeProperty)
                {
                    Write-Error "Command on VM '$name' completed without an exit code. $errorOutput" -ErrorAction Stop
                }
                if ([string]::IsNullOrEmpty([string]$exitCodeValue))
                {
                    Write-Error "Command on VM '$name' completed without an exit code. $errorOutput" -ErrorAction Stop
                }

                $exitCode = [int]$exitCodeValue
                if ($exitCode -ne 0)
                {
                    Write-Error "Command on VM '$name' failed with exit code $exitCode. $errorOutput" -ErrorAction Stop
                }
                break
            }

            Start-Sleep -Seconds $PollIntervalSeconds
        }

        $executionTimer.Stop()
        if (-not $executionCompleted)
        {
            $timeoutMessage = "Command on VM '$name' did not finish within $TimeoutSeconds seconds."
            if ($failedPolls -gt 0)
            {
                $timeoutMessage = "$timeoutMessage The status polls were still failing when the wait ended. $failureSummary. $lastReasonSummary"
            }
            Write-Error $timeoutMessage -ErrorAction Stop
        }
    }
}
