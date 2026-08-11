Describe 'Get-LWProxmoxVM' {
    BeforeAll {
        $workerRoot = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker'
        . (Join-Path $workerRoot 'functions\ProxmoxWorkerVirtualMachines\Get-LWProxmoxVM.ps1')

        function Write-LogFunctionEntry {}
        function Write-LogFunctionExit {}
        function Test-LabProxmoxConnection {}
        function Get-LWProxmoxNode
        {
            param
            (
                [string[]]$Name,
                [switch]$IncludeUnavailable
            )
        }
        function Invoke-LWProxmoxCallWithRetry
        {
            param
            (
                [scriptblock]$ScriptBlock,
                [string]$ActivityName
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
    }

    BeforeEach {
        Set-Variable -Name proxmoxVmCache -Scope Script -Value $null

        Mock -CommandName Write-LogFunctionEntry
        Mock -CommandName Write-LogFunctionExit
        Mock -CommandName Test-LabProxmoxConnection -MockWith { $true }
        Mock -CommandName Write-ScreenInfo
        Mock -CommandName Get-LWProxmoxNode -MockWith {
            @(
                [pscustomobject]@{ node = 'pve1' }
                [pscustomobject]@{ node = 'pve2' }
            )
        }

        # 'pve2' is unreachable, so its API call fails while 'pve1' answers normally
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            if ($ActivityName -match 'pve2')
            {
                [pscustomobject]@{
                    StatusCode   = 596
                    ReasonPhrase = "hostname lookup 'pve2' failed - failed to get address info"
                }
            }
            else
            {
                [pscustomobject]@{
                    StatusCode = 200
                    Response   = [pscustomobject]@{
                        data = @([pscustomobject]@{ Name = 'VM1'; vmid = 101; template = 0; tags = '' })
                    }
                }
            }
        }
    }

    It 'returns the VMs of the healthy nodes when one node is unreachable' {
        $result = Get-LWProxmoxVM

        $result.Name | Should -Be 'VM1'
        $result.node | Should -Be 'pve1'
    }

    It 'warns about the unreachable node instead of failing the whole query' {
        $null = Get-LWProxmoxVM

        Should -Invoke -CommandName Write-ScreenInfo -Times 1 -Exactly -ParameterFilter {
            $Type -eq 'Warning' -and $Message -match 'pve2'
        }
    }

    It 'does not cache the failed node so a later query retries it' {
        $null = Get-LWProxmoxVM
        $null = Get-LWProxmoxVM

        Should -Invoke -CommandName Invoke-LWProxmoxCallWithRetry -Times 2 -Exactly -ParameterFilter {
            $ActivityName -match 'pve2'
        }
        Should -Invoke -CommandName Invoke-LWProxmoxCallWithRetry -Times 1 -Exactly -ParameterFilter {
            $ActivityName -match 'pve1'
        }
    }
}
