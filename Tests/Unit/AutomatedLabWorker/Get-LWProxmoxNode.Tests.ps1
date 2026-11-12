Describe 'Get-LWProxmoxNode' {
    BeforeAll {
        $workerRoot = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker'
        . (Join-Path $workerRoot 'functions\ProxmoxWorkerVirtualMachines\Get-LWProxmoxNode.ps1')

        function Write-LogFunctionEntry {}
        function Write-LogFunctionExit {}
        function Test-LabProxmoxConnection {}
        function Invoke-LWProxmoxCallWithRetry
        {
            param
            (
                [scriptblock]$ScriptBlock,
                [string]$ActivityName
            )
        }
        function Write-PSFMessage
        {
            param
            (
                [string]$Message,
                [string]$Level
            )
        }
        function Write-ScreenInfo
        {
            param
            (
                [string]$Message,
                [string]$Type,
                [switch]$NoNewLine,
                [switch]$TaskStart,
                [switch]$TaskEnd
            )
        }
        function Get-PveNodesStatus
        {
            param
            (
                [string]$Node
            )
        }
    }

    BeforeEach {
        # The function remembers which unavailable nodes it already reported on screen
        Set-Variable -Name proxmoxUnavailableNodes -Scope Script -Value $null

        Mock -CommandName Write-LogFunctionEntry
        Mock -CommandName Write-LogFunctionExit
        Mock -CommandName Test-LabProxmoxConnection -MockWith { $true }
        Mock -CommandName Write-PSFMessage
        Mock -CommandName Write-ScreenInfo
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{
                    data = @(
                        [pscustomobject]@{ node = 'pve1'; status = 'online'; maxcpu = 48; maxmem = 400GB }
                        [pscustomobject]@{ node = 'pve2'; status = 'online'; maxcpu = 48; maxmem = 400GB }
                        # Physically removed, still part of the cluster configuration
                        [pscustomobject]@{ node = 'pve3'; status = 'unknown'; maxcpu = $null; maxmem = $null }
                    )
                }
            }
        }
    }

    It 'returns only nodes that are online' {
        $result = Get-LWProxmoxNode

        $result.node | Should -Be @('pve1', 'pve2')
    }

    It 'returns every cluster node with -IncludeUnavailable' {
        $result = Get-LWProxmoxNode -IncludeUnavailable

        $result.node | Should -Be @('pve1', 'pve2', 'pve3')
    }

    It 'honours an explicit request for an unavailable node by name' {
        (Get-LWProxmoxNode -Name 'pve3').node | Should -Be 'pve3'
    }

    It 'warns about an unavailable node only once per session' {
        $null = Get-LWProxmoxNode
        $null = Get-LWProxmoxNode

        Should -Invoke -CommandName Write-ScreenInfo -Times 1 -Exactly -ParameterFilter {
            $Type -eq 'Warning' -and $Message -match 'pve3'
        }
    }

    It 'does not warn when every node is online' {
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{
                    data = @([pscustomobject]@{ node = 'pve1'; status = 'online'; maxcpu = 48; maxmem = 400GB })
                }
            }
        }

        $null = Get-LWProxmoxNode

        Should -Invoke -CommandName Write-ScreenInfo -Times 0 -Exactly -ParameterFilter {
            $Type -eq 'Warning'
        }
    }

    It 'excludes an online node that reports no CPU or memory capacity' {
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{
                    data = @(
                        [pscustomobject]@{ node = 'pve1'; status = 'online'; maxcpu = 48; maxmem = 400GB }
                        [pscustomobject]@{ node = 'pve2'; status = 'online'; maxcpu = 0; maxmem = 0 }
                    )
                }
            }
        }

        (Get-LWProxmoxNode).node | Should -Be 'pve1'
        Should -Invoke -CommandName Write-ScreenInfo -Times 1 -Exactly -ParameterFilter {
            $Type -eq 'Warning' -and $Message -match 'pve2 \(reports no CPU or memory capacity\)'
        }
    }

    It 'does not probe node-scoped API calls unless -TestNodeConnection is used' {
        Mock -CommandName Get-PveNodesStatus -MockWith { [pscustomobject]@{ StatusCode = 200 } }

        $null = Get-LWProxmoxNode

        Should -Invoke -CommandName Get-PveNodesStatus -Times 0 -Exactly
    }

    It 'excludes a node that does not answer node-scoped API calls' {
        Mock -CommandName Get-PveNodesStatus -MockWith {
            if ($Node -eq 'pve2') { [pscustomobject]@{ StatusCode = 596 } } else { [pscustomobject]@{ StatusCode = 200 } }
        }

        (Get-LWProxmoxNode -TestNodeConnection).node | Should -Be 'pve1'
    }

    It 'treats a throwing node probe as unavailable' {
        Mock -CommandName Get-PveNodesStatus -MockWith {
            if ($Node -eq 'pve2') { throw "hostname lookup 'pve2' failed" } else { [pscustomobject]@{ StatusCode = 200 } }
        }

        (Get-LWProxmoxNode -TestNodeConnection).node | Should -Be 'pve1'
    }

    It 'fails closed when no node can host a virtual machine' {
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{
                    data = @([pscustomobject]@{ node = 'pve1'; status = 'offline'; maxcpu = $null; maxmem = $null })
                }
            }
        }

        { Get-LWProxmoxNode } | Should -Throw -ExpectedMessage '*No Proxmox node of the connected cluster can host a virtual machine*'
    }

    It 'fails closed when the cluster returns no node at all' {
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{ data = @() }
            }
        }

        { Get-LWProxmoxNode } | Should -Throw -ExpectedMessage '*did not return any node*'
    }
}
