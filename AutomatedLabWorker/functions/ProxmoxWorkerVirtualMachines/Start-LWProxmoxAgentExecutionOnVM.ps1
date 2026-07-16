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
        300 seconds and accepts values from 1 to 3600.

    .PARAMETER PollIntervalSeconds
        Number of seconds to wait between guest-exec status checks when -Wait is specified. Defaults to 2
        seconds and accepts values from 1 to 60.

    .EXAMPLE
        Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Server1' -Command 'ipconfig.exe /all'

        Starts 'ipconfig.exe /all' on 'Server1' through the guest agent and returns immediately.

    .EXAMPLE
        Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Server1' -Command 'C:\Install.cmd' -Wait -TimeoutSeconds 600

        Starts 'C:\Install.cmd' on 'Server1' and waits up to ten minutes for it to finish, throwing a
        terminating error if the command exits with a non-zero exit code or does not complete in time.
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
        [int]$PollIntervalSeconds = 2
    )

    $proxmoxVms = Get-LWProxmoxVM

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
        $executionTimer = [System.Diagnostics.Stopwatch]::StartNew()
        $executionCompleted = $false

        while ($executionTimer.Elapsed.TotalSeconds -lt $TimeoutSeconds)
        {
            $executionStatus = Get-PveNodesQemuAgentExecStatus -Node $vm.node -Vmid $vm.VmId -Pid_ $guestProcessId
            if ($executionStatus.StatusCode -ne 200)
            {
                Write-Error "Failed to retrieve command status on VM '$name': $($executionStatus.ReasonPhrase)" -ErrorAction Stop
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
            Write-Error "Command on VM '$name' did not finish within $TimeoutSeconds seconds." -ErrorAction Stop
        }
    }
}
