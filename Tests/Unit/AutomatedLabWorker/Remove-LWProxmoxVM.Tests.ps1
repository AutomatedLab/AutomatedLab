Describe 'Remove-LWProxmoxVM' {
    BeforeAll {
        $workerRoot = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker'
        . (Join-Path $workerRoot 'functions\ProxmoxWorkerVirtualMachines\Remove-LWProxmoxVM.ps1')

        function Get-LWProxmoxVM
        {
            param
            (
                [Alias('Name')]
                [string[]]$ComputerName,
                [object[]]$Node,
                [switch]$NoCache
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
        function Remove-PveQemu {}
        function Stop-PveVm {}
        function Wait-LWProxmoxTasksStatus {}
        function Write-LogFunctionEntry {}
        function Write-LogFunctionExit {}
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
                [string]$Type
            )
        }
    }

    BeforeEach {
        $script:runningVm = [pscustomobject]@{
            Name   = 'VM1'
            VmId   = 101
            node   = 'pve1'
            status = 'running'
        }

        Mock -CommandName Get-LWProxmoxVM -MockWith { $script:runningVm }
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{ data = 'UPID:test' }
            }
        }
        Mock -CommandName Wait-LWProxmoxTasksStatus
        Mock -CommandName Write-LogFunctionEntry
        Mock -CommandName Write-LogFunctionExit
        Mock -CommandName Write-PSFMessage
        Mock -CommandName Write-ScreenInfo
    }

    It 'removes a VM that exists' {
        Remove-LWProxmoxVM -Name 'VM1'

        Should -Invoke -CommandName Invoke-LWProxmoxCallWithRetry -Times 1 -Exactly -ParameterFilter {
            $ActivityName -eq "Remove VM 'VM1'"
        }
    }

    It 'skips removal when the VM is proven absent' {
        Mock -CommandName Get-LWProxmoxVM

        Remove-LWProxmoxVM -Name 'VM1'

        Should -Invoke -CommandName Invoke-LWProxmoxCallWithRetry -Times 0 -Exactly
    }

    It 'does not re-query every node after the first lookup found nothing' {
        Mock -CommandName Get-LWProxmoxVM

        Remove-LWProxmoxVM -Name 'VM1'

        Should -Invoke -CommandName Get-LWProxmoxVM -Times 1 -Exactly
    }

    It 'propagates an undetermined lookup instead of silently skipping removal' {
        Mock -CommandName Get-LWProxmoxVM -MockWith {
            Write-Error -Message "Cannot determine whether virtual machine(s) 'VM1' exist." -ErrorAction Stop
        }

        { Remove-LWProxmoxVM -Name 'VM1' } | Should -Throw -ExpectedMessage '*Cannot determine*'

        Should -Invoke -CommandName Invoke-LWProxmoxCallWithRetry -Times 0 -Exactly
    }
}
