# Runs inside the guest as a command of the QEMU guest agent, in Windows PowerShell 5.1. The live test sends it with
# -EncodedCommand after it has removed the comment lines, so keep the code free of block comments.
#
# The script schedules a restart of the QEMU guest agent service a few seconds from now and then keeps running, so
# the restart always happens while this command runs and the agent loses the result of this very command. A
# scheduled task that runs as SYSTEM does the restart. It lives outside the process tree of the agent, so the
# restart cannot take itself down. Every step is logged to C:\Windows\Temp\ALLiveRestartAgent.log; the live test
# reads that log when the command ran to its end without losing its result.

$ErrorActionPreference = 'Stop'
$restartDelaySeconds = 8
$runSeconds = 60
$taskName = 'ALLiveRestartAgent'
$logPath = Join-Path -Path $env:windir -ChildPath 'Temp\ALLiveRestartAgent.log'

function Select-QemuGuestAgentService
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [object[]]$Service
    )

    # Only the service that runs qemu-ga.exe is the agent. Other services carry its name, for example the
    # 'QEMU Guest Agent VSS Provider', and restarting one of them leaves the agent alone.
    $agent = @($Service | Where-Object { [string]$_.PathName -match '(^|[\\"\s])qemu-ga\.exe\b' })
    if ($agent.Count -eq 0)
    {
        $agent = @($Service | Where-Object { $_.Name -eq 'QEMU-GA' })
    }

    $agent | Select-Object -First 1
}

function Write-AgentLog
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Add-Content -LiteralPath $logPath -Value ('{0:o} {1}' -f (Get-Date), $Message)
}

Write-AgentLog -Message 'command started'

$services = @(Get-CimInstance -ClassName Win32_Service)
foreach ($item in @($services | Where-Object { ('{0} {1} {2}' -f $_.Name, $_.DisplayName, $_.PathName) -match 'qemu' }))
{
    Write-AgentLog -Message ("service '{0}' ({1}): state {2}, process {3}, path {4}" -f $item.Name, $item.DisplayName, $item.State, $item.ProcessId, $item.PathName)
}

$service = Select-QemuGuestAgentService -Service $services
if (-not $service)
{
    Write-AgentLog -Message 'no service of the QEMU guest agent found'
    throw 'The service of the QEMU guest agent was not found in the guest.'
}

# The task runs in its own process, so it gets its settings from the first lines of its script.
$restartTask = {
    $ErrorActionPreference = 'Stop'
    Start-Sleep -Seconds $delaySeconds
    $filter = "Name='$serviceName'"
    $before = Get-CimInstance -ClassName Win32_Service -Filter $filter
    Add-Content -LiteralPath $logPath -Value ('{0:o} restarting {1}: state {2}, process {3}' -f (Get-Date), $serviceName, $before.State, $before.ProcessId)
    try
    {
        Restart-Service -Name $serviceName -Force
        $after = Get-CimInstance -ClassName Win32_Service -Filter $filter
        Add-Content -LiteralPath $logPath -Value ('{0:o} restarted {1}: state {2}, process {3}' -f (Get-Date), $serviceName, $after.State, $after.ProcessId)
    }
    catch
    {
        Add-Content -LiteralPath $logPath -Value ('{0:o} the restart failed: {1}' -f (Get-Date), $_.Exception.Message)
        throw
    }
}

$taskScript = @(
    ('$delaySeconds = {0}' -f $restartDelaySeconds)
    ("`$serviceName = '{0}'" -f $service.Name.Replace("'", "''"))
    ("`$logPath = '{0}'" -f $logPath.Replace("'", "''"))
    $restartTask.ToString()
) -join "`r`n"

$encodedTask = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($taskScript))
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ' + $encodedTask)
Register-ScheduledTask -TaskName $taskName -Action $action -User 'SYSTEM' -RunLevel Highest -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Write-AgentLog -Message ("restart of '{0}' scheduled for {1} seconds from now; this command keeps running for {2} seconds" -f $service.Name, $restartDelaySeconds, $runSeconds)

Start-Sleep -Seconds $runSeconds
Write-AgentLog -Message 'command ended'
