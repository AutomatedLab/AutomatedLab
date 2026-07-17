Describe 'Get-LWProxmoxWindowsImageState' {
    BeforeAll {
        $functionPath = Join-Path $PSScriptRoot (
            '..\..\..\AutomatedLabWorker\functions\Internals\' +
            'Get-LWProxmoxWindowsImageState.ps1'
        )
        . $functionPath

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
        Mock -CommandName New-PveNodesQemuAgentExec -MockWith {
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{
                    data = [pscustomobject]@{ pid = 42 }
                }
            }
        }
        # Skip the 500 ms guest-exec status poll so the test stays fast.
        Mock -CommandName Start-Sleep
    }

    It 'parses IMAGE_STATE_COMPLETE from the reg query output' {
        Mock -CommandName Get-PveNodesQemuAgentExecStatus -MockWith {
            [pscustomobject]@{
                Response = [pscustomobject]@{
                    data = [pscustomobject]@{
                        exited     = 1
                        'out-data' = '    ImageState    REG_SZ    IMAGE_STATE_COMPLETE'
                    }
                }
            }
        }

        Get-LWProxmoxWindowsImageState -Node 'pve1' -Vmid 101 | Should -Be 'IMAGE_STATE_COMPLETE'
    }

    It 'parses IMAGE_STATE_UNDEPLOYABLE from the reg query output' {
        Mock -CommandName Get-PveNodesQemuAgentExecStatus -MockWith {
            [pscustomobject]@{
                Response = [pscustomobject]@{
                    data = [pscustomobject]@{
                        exited     = 1
                        'out-data' = '    ImageState    REG_SZ    IMAGE_STATE_UNDEPLOYABLE'
                    }
                }
            }
        }

        Get-LWProxmoxWindowsImageState -Node 'pve1' -Vmid 101 | Should -Be 'IMAGE_STATE_UNDEPLOYABLE'
    }

    It 'decodes a base64 out-data payload before parsing the ImageState' {
        Mock -CommandName Get-PveNodesQemuAgentExecStatus -MockWith {
            $regText = '    ImageState    REG_SZ    IMAGE_STATE_COMPLETE'
            $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($regText))
            [pscustomobject]@{
                Response = [pscustomobject]@{
                    data = [pscustomobject]@{
                        exited     = 1
                        'out-data' = $encoded
                    }
                }
            }
        }

        Get-LWProxmoxWindowsImageState -Node 'pve1' -Vmid 101 | Should -Be 'IMAGE_STATE_COMPLETE'
    }

    It 'returns $null when the guest-exec call does not succeed' {
        Mock -CommandName New-PveNodesQemuAgentExec -MockWith {
            [pscustomobject]@{ StatusCode = 500 }
        }

        Get-LWProxmoxWindowsImageState -Node 'pve1' -Vmid 101 | Should -BeNullOrEmpty
    }
}
