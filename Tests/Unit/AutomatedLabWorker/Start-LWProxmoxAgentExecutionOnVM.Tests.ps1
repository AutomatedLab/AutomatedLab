Describe 'Start-LWProxmoxAgentExecutionOnVM' {
    BeforeAll {
        $functionPath = Join-Path $PSScriptRoot (
            '..\..\..\AutomatedLabWorker\functions\ProxmoxWorkerVirtualMachines\' +
            'Start-LWProxmoxAgentExecutionOnVM.ps1'
        )
        . $functionPath

        function Get-LWProxmoxVM {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
            [CmdletBinding()]
            param
            (
                [string[]]$ComputerName,
                [object[]]$Node,
                [switch]$NoCache
            )
        }
        function Invoke-LWProxmoxCallWithRetry {
            param
            (
                [string]$ActivityName,
                [int]$MaxRetries,
                [int]$RetryDelaySeconds,
                [int]$MaxDelaySeconds,
                [switch]$ProgressiveBackoff,
                [scriptblock]$ScriptBlock
            )
        }
        function New-PveNodesQemuAgentExec {
            param
            (
                [string]$Node,
                [int]$Vmid,
                [array]$Command
            )
        }
        function Get-PveNodesQemuAgentExecStatus {
            param
            (
                [string]$Node,
                [int]$Vmid,
                [int]$Pid_
            )
        }
        function Get-LabConfigurationItem {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
            param
            (
                [string]$Name,
                $Default
            )
        }
        function Write-PSFMessage {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
            param
            (
                [string]$Level,
                [string]$Message
            )
        }
        function New-StatusReply {
            param
            (
                [int]$StatusCode = 200,
                [string]$ReasonPhrase,
                [object]$Data = [pscustomobject]@{ exited = 0 }
            )

            [pscustomobject]@{
                StatusCode   = $StatusCode
                ReasonPhrase = $ReasonPhrase
                Response     = [pscustomobject]@{ data = $Data }
            }
        }
        function Get-ThrownError {
            param
            (
                [scriptblock]$ScriptBlock
            )

            try
            {
                & $ScriptBlock
            }
            catch
            {
                $_
            }
        }
    }

    BeforeEach {
        $script:statusReplies = @()
        $script:statusCalls = 0
        $script:vmStatus = 'running'
        $script:vmQmpStatus = 'running'
        Mock -CommandName Get-PveNodesQemuAgentExecStatus -MockWith {
            # Guard against a runaway poll loop: the last reply repeats until the list is exhausted.
            if ($script:statusCalls -ge 200)
            {
                throw 'runaway status poll loop'
            }
            $index = [math]::Min($script:statusCalls, $script:statusReplies.Count - 1)
            $script:statusCalls++
            $script:statusReplies[$index]
        }
        Mock -CommandName Get-LWProxmoxVM -MockWith {
            [pscustomobject]@{
                Name = 'Client2'
                node = 'pve1'
                VmId = 101
            }
        }
        Mock -CommandName Get-LWProxmoxVM -ParameterFilter { $NoCache } -MockWith {
            [pscustomobject]@{
                Name          = 'Client2'
                node          = 'pve1'
                VmId          = 101
                status        = $script:vmStatus
                CurrentStatus = [pscustomobject]@{ qmpstatus = $script:vmQmpStatus }
            }
        }
        Mock -CommandName Get-LabConfigurationItem -MockWith { 120 }
        Mock -CommandName Write-PSFMessage
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{
                    data = [pscustomobject]@{ pid = 42 }
                }
            }
        }
        Mock -CommandName Start-Sleep
    }

    It 'waits for a successful guest process when Wait is specified' {
        Mock -CommandName Get-PveNodesQemuAgentExecStatus -MockWith {
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{
                    data = [pscustomobject]@{
                        exited   = 1
                        exitcode = 0
                    }
                }
            }
        }

        Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait

        Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 1 -Exactly
        Should -Invoke -CommandName Start-Sleep -Times 0 -Exactly
    }

    It 'throws when a waited VM cannot be found' {
        Mock -CommandName Get-LWProxmoxVM -MockWith { $null }

        {
            Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Missing' -Command 'cmd /c ver' -Wait
        } | Should -Throw -ExpectedMessage "*VM 'Missing' not found*"
    }

    It 'throws when a waited guest process cannot be started' {
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            [pscustomobject]@{
                StatusCode   = 500
                ReasonPhrase = 'guest-exec failed'
            }
        }

        {
            Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait
        } | Should -Throw -ExpectedMessage "*Failed to start command*guest-exec failed*"
    }

    It 'preserves executable switches in the command sent to QEMU' {
        $script:capturedCommand = $null
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            & $ScriptBlock
        }
        Mock -CommandName New-PveNodesQemuAgentExec -MockWith {
            $script:capturedCommand = $Command
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{
                    data = [pscustomobject]@{ pid = 42 }
                }
            }
        }

        $command = 'powershell.exe -NoProfile -NonInteractive -EncodedCommand ZgBvAG8A'
        Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command $command

        $script:capturedCommand | Should -Be @(
            'powershell.exe'
            '-NoProfile'
            '-NonInteractive'
            '-EncodedCommand'
            'ZgBvAG8A'
        )
    }

    It 'throws when a waited guest process returns a nonzero exit code' {
        Mock -CommandName Get-PveNodesQemuAgentExecStatus -MockWith {
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{
                    data = [pscustomobject]@{
                        exited    = 1
                        exitcode  = 5
                        'err-data' = 'AppX cleanup failed'
                    }
                }
            }
        }

        {
            Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c exit 5' -Wait
        } | Should -Throw -ExpectedMessage '*exit code 5*AppX cleanup failed*'
    }

    It 'throws when a waited guest process terminates with a signal and no exit code' {
        Mock -CommandName Get-PveNodesQemuAgentExecStatus -MockWith {
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{
                    data = [pscustomobject]@{
                        exited     = 1
                        signal     = 11
                        'err-data' = 'Process terminated abnormally'
                    }
                }
            }
        }

        {
            Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c fail' -Wait
        } | Should -Throw -ExpectedMessage '*signal 11*Process terminated abnormally*'
    }

    It 'throws when a waited guest process completes without an exit code' {
        $script:statusReplies = @(
            New-StatusReply -Data ([pscustomobject]@{ exited = 1; 'out-data' = 'no exit code reported' })
        )

        {
            Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait
        } | Should -Throw -ExpectedMessage '*completed without an exit code*no exit code reported*'
    }

    It 'throws when a waited guest process does not finish within TimeoutSeconds' {
        Mock -CommandName Start-Sleep -MockWith { [System.Threading.Thread]::Sleep(1200) }
        $script:statusReplies = @(New-StatusReply)

        {
            Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait -TimeoutSeconds 1
        } | Should -Throw -ExpectedMessage "*VM 'Client2' did not finish within 1 seconds*"

        Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 1 -Exactly
    }

    It 'polls at the requested interval and looks nothing up while every poll succeeds' {
        $script:statusReplies = @(
            (New-StatusReply)
            (New-StatusReply)
            (New-StatusReply -Data ([pscustomobject]@{ exited = 1; exitcode = 0 }))
        )

        Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait -PollIntervalSeconds 3

        Should -Invoke -CommandName Invoke-LWProxmoxCallWithRetry -Times 1 -Exactly
        Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 3 -Exactly
        Should -Invoke -CommandName Start-Sleep -Times 2 -Exactly -ParameterFilter { $Seconds -eq 3 }
        Should -Invoke -CommandName Get-LWProxmoxVM -Times 1 -Exactly
        Should -Invoke -CommandName Write-PSFMessage -Times 0 -Exactly
    }

    Context 'When status polls fail' {
        It 'tolerates one failed poll and does not start the command again' {
            $script:statusReplies = @(
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply -Data ([pscustomobject]@{ exited = 1; exitcode = 0 }))
            )

            {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait
            } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-LWProxmoxCallWithRetry -Times 1 -Exactly
            Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 2 -Exactly
            Should -Invoke -CommandName Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 2 }
        }

        It 'logs one warning per tolerated outage with its start, size, tolerance and last reason' {
            $script:statusReplies = @(
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply -StatusCode 500 -ReasonPhrase "VM 101 qga command 'guest-exec-status' failed - got timeout")
                (New-StatusReply -Data ([pscustomobject]@{ exited = 1; exitcode = 0 }))
            )

            Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait

            Should -Invoke -CommandName Write-PSFMessage -Times 1 -Exactly -ParameterFilter { $Level -eq 'Warning' }
            Should -Invoke -CommandName Write-PSFMessage -Times 1 -Exactly -ParameterFilter {
                $Message -like "*VM 'Client2' (node 'pve1', VMID 101)*" -and
                $Message -like '*from [0-9][0-9]:[0-9][0-9]:[0-9][0-9]*' -and
                $Message -like '*Failed status polls: 3 over *' -and
                $Message -like '*tolerance of 120s*' -and
                $Message -like "*Last reason: 'VM 101 qga command 'guest-exec-status' failed - got timeout'*"
            }
        }

        It 'looks the VM up afresh on its node after each failed poll' {
            $script:statusReplies = @(
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply -Data ([pscustomobject]@{ exited = 1; exitcode = 0 }))
            )

            Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait

            Should -Invoke -CommandName Get-LWProxmoxVM -Times 2 -Exactly -ParameterFilter {
                $NoCache -and $Node -eq 'pve1'
            }
        }

        It 'keeps polling when the VM lookup itself fails' {
            Mock -CommandName Get-LWProxmoxVM -ParameterFilter { $NoCache } -MockWith { throw 'node did not answer' }
            $script:statusReplies = @(
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply -Data ([pscustomobject]@{ exited = 1; exitcode = 0 }))
            )

            {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait
            } | Should -Not -Throw

            Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 2 -Exactly
        }

        It 'keeps polling when the node does not list the VM' {
            Mock -CommandName Get-LWProxmoxVM -ParameterFilter { $NoCache } -MockWith { $null }
            $script:statusReplies = @(
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply -Data ([pscustomobject]@{ exited = 1; exitcode = 0 }))
            )

            {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait
            } | Should -Not -Throw

            Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 2 -Exactly
        }

        It 'fails at once when the VM is not running' {
            $script:vmStatus = 'stopped'
            $script:vmQmpStatus = 'stopped'
            $script:statusReplies = @(
                New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running'
            )

            $thrown = Get-ThrownError {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.FullyQualifiedErrorId | Should -BeLike 'ProxmoxAgentVmNotRunning*'
            $thrown.Exception.Message | Should -BeLike "*VM 'Client2' (node 'pve1', VMID 101)*"
            $thrown.Exception.Message | Should -BeLike "*status 'stopped', qmpstatus 'stopped'*"
            $thrown.Exception.Message | Should -BeLike '*Failed status polls: 1 over *'
            $thrown.Exception.Message | Should -BeLike "*Last reason: 'QEMU guest agent is not running'*"
            Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 1 -Exactly
            Should -Invoke -CommandName Start-Sleep -Times 0 -Exactly
        }

        It 'fails with the last reason, the VM state and the counts once the failures outlast the tolerance' {
            Mock -CommandName Start-Sleep -MockWith { [System.Threading.Thread]::Sleep(1500) }
            $script:statusReplies = @(
                New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running'
            )

            $thrown = Get-ThrownError {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait -StatusFailureToleranceSeconds 1
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.FullyQualifiedErrorId | Should -BeLike 'ProxmoxAgentStatusQueryFailed*'
            $thrown.Exception.Message | Should -BeLike "*VM 'Client2' (node 'pve1', VMID 101)*"
            $thrown.Exception.Message | Should -BeLike '*Failed status polls: 2 over *'
            $thrown.Exception.Message | Should -BeLike '*tolerance of 1s*'
            $thrown.Exception.Message | Should -BeLike "*Last reason: 'QEMU guest agent is not running' (HTTP 500)*"
            $thrown.Exception.Message | Should -BeLike "*VM state: status 'running', qmpstatus 'running'*"
            Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 2 -Exactly
        }

        It 'fails at the first failed poll when the tolerance is 0' {
            $script:statusReplies = @(
                New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running'
            )

            $thrown = Get-ThrownError {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait -StatusFailureToleranceSeconds 0
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.FullyQualifiedErrorId | Should -BeLike 'ProxmoxAgentStatusQueryFailed*'
            Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 1 -Exactly
            Should -Invoke -CommandName Start-Sleep -Times 0 -Exactly
        }

        It 'resets the failure window after a successful poll' {
            Mock -CommandName Start-Sleep -MockWith { [System.Threading.Thread]::Sleep(600) }
            $script:statusReplies = @(
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply)
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply -Data ([pscustomobject]@{ exited = 1; exitcode = 0 }))
            )

            {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait -StatusFailureToleranceSeconds 1
            } | Should -Not -Throw

            Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 4 -Exactly
            Should -Invoke -CommandName Write-PSFMessage -Times 2 -Exactly -ParameterFilter { $Level -eq 'Warning' }
        }

        It 'never lets tolerated failures extend the wait beyond TimeoutSeconds' {
            Mock -CommandName Start-Sleep -MockWith { [System.Threading.Thread]::Sleep(1200) }
            $script:statusReplies = @(
                New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running'
            )

            $thrown = Get-ThrownError {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait -TimeoutSeconds 1 -StatusFailureToleranceSeconds 3600 -PollIntervalSeconds 1
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -BeLike "*VM 'Client2' did not finish within 1 seconds*"
            $thrown.Exception.Message | Should -BeLike "*Last reason: 'QEMU guest agent is not running'*"
            Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 1 -Exactly
        }

        It 'does not mistake the reason <Reason> for a lost result' -ForEach @(
            @{ Reason = "VM 101 qga command 'guest-exec-status' failed - got timeout" }
            @{ Reason = "Configuration file 'nodes/pve1/qemu-server/101.conf' does not exist" }
            @{ Reason = 'VM 101 is not running' }
        ) {
            $script:statusReplies = @(
                New-StatusReply -StatusCode 500 -ReasonPhrase $Reason
            )

            $thrown = Get-ThrownError {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait -StatusFailureToleranceSeconds 0
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.FullyQualifiedErrorId | Should -BeLike 'ProxmoxAgentStatusQueryFailed*'
            $thrown.FullyQualifiedErrorId | Should -Not -BeLike 'ProxmoxAgentCommandResultLost*'
        }
    }

    Context 'When the tolerance comes from the configuration' {
        It 'reads ProxmoxAgentStatusFailureTolerance when the parameter is omitted' {
            Mock -CommandName Get-LabConfigurationItem -MockWith { 0 }
            $script:statusReplies = @(
                New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running'
            )

            $thrown = Get-ThrownError {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.FullyQualifiedErrorId | Should -BeLike 'ProxmoxAgentStatusQueryFailed*'
            Should -Invoke -CommandName Get-LabConfigurationItem -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'ProxmoxAgentStatusFailureTolerance'
            }
            Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 1 -Exactly
        }

        It 'prefers an explicit StatusFailureToleranceSeconds over the configuration item' {
            Mock -CommandName Get-LabConfigurationItem -MockWith { 45 }
            $script:statusReplies = @(
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply -Data ([pscustomobject]@{ exited = 1; exitcode = 0 }))
            )

            Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait -StatusFailureToleranceSeconds 90

            Should -Invoke -CommandName Get-LabConfigurationItem -Times 0 -Exactly
            Should -Invoke -CommandName Write-PSFMessage -Times 1 -Exactly -ParameterFilter {
                $Message -like '*tolerance of 90s*'
            }
        }

        It 'uses the configured value when it is set' {
            Mock -CommandName Get-LabConfigurationItem -MockWith { 45 }
            $script:statusReplies = @(
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply -Data ([pscustomobject]@{ exited = 1; exitcode = 0 }))
            )

            Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait

            Should -Invoke -CommandName Write-PSFMessage -Times 1 -Exactly -ParameterFilter {
                $Message -like '*tolerance of 45s*'
            }
        }

        It 'falls back to 120 seconds when the configuration item has no value' {
            Mock -CommandName Get-LabConfigurationItem -MockWith { $null }
            $script:statusReplies = @(
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply -Data ([pscustomobject]@{ exited = 1; exitcode = 0 }))
            )

            Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait

            Should -Invoke -CommandName Write-PSFMessage -Times 1 -Exactly -ParameterFilter {
                $Message -like '*tolerance of 120s*'
            }
        }
    }

    Context 'When the guest agent no longer knows the process' {
        It 'raises the lost-result error for the agent reason <Reason>' -ForEach @(
            @{ Reason = "VM 101 qga command 'guest-exec-status' failed - Invalid parameter 'pid'" }
            @{ Reason = "VM 101 qga command 'guest-exec-status' failed - PID lld does not exist" }
            @{ Reason = 'Agent error: PID 4242 does not exist' }
        ) {
            $script:statusReplies = @(
                (New-StatusReply -StatusCode 500 -ReasonPhrase 'QEMU guest agent is not running')
                (New-StatusReply -StatusCode 500 -ReasonPhrase $Reason)
            )

            $thrown = Get-ThrownError {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.FullyQualifiedErrorId | Should -BeLike 'ProxmoxAgentCommandResultLost*'
            $thrown.Exception.Message | Should -BeLike "*VM 'Client2' (node 'pve1', VMID 101)*"
            $thrown.Exception.Message | Should -BeLike '*guest process 42*'
            $thrown.Exception.Message | Should -BeLike '*was not started again*'
            Should -Invoke -CommandName Invoke-LWProxmoxCallWithRetry -Times 1 -Exactly
            Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 2 -Exactly
        }

        It 'raises the lost-result error without a VM lookup when the first poll reports the unknown process' {
            $script:statusReplies = @(
                New-StatusReply -StatusCode 500 -ReasonPhrase "VM 101 qga command 'guest-exec-status' failed - Invalid parameter 'pid'"
            )

            $thrown = Get-ThrownError {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName 'Client2' -Command 'cmd /c ver' -Wait
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.FullyQualifiedErrorId | Should -BeLike 'ProxmoxAgentCommandResultLost*'
            Should -Invoke -CommandName Get-PveNodesQemuAgentExecStatus -Times 1 -Exactly
            Should -Invoke -CommandName Get-LWProxmoxVM -Times 0 -Exactly -ParameterFilter { $NoCache }
            Should -Invoke -CommandName Start-Sleep -Times 0 -Exactly
        }
    }
}