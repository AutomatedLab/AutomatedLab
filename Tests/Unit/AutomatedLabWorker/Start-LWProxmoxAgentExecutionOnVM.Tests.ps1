Describe 'Start-LWProxmoxAgentExecutionOnVM' {
    BeforeAll {
        $functionPath = Join-Path $PSScriptRoot (
            '..\..\..\AutomatedLabWorker\functions\ProxmoxWorkerVirtualMachines\' +
            'Start-LWProxmoxAgentExecutionOnVM.ps1'
        )
        . $functionPath

        function Get-LWProxmoxVM {
            param
            (
                [string[]]$ComputerName
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
    }

    BeforeEach {
        Mock -CommandName Get-LWProxmoxVM -MockWith {
            [pscustomobject]@{
                Name = 'Client2'
                node = 'pve1'
                VmId = 101
            }
        }
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
}