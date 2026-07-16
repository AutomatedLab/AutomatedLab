Describe 'Start-LWProxmoxVM' {
    BeforeAll {
        $workerRoot = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker'
        . (Join-Path $workerRoot 'functions\ProxmoxWorkerVirtualMachines\Get-LWProxmoxVM.ps1')
        . (Join-Path $workerRoot 'functions\ProxmoxWorkerVirtualMachines\Start-LWProxmoxVM.ps1')

        function Get-LabVM {}
        function Invoke-LWProxmoxCallWithRetry {}
        function Start-PveVm {}
        function Wait-LWProxmoxTasksStatus {}
        function Write-PSFMessage {
            param
            (
                [string]$Message,
                [string]$Level
            )
        }
        function Write-LogFunctionExit {}
    }

    BeforeEach {
        $script:labVm = [pscustomobject]@{
            ResourceName        = 'Client1'
            SkipDeployment      = $false
            OperatingSystemType = 'Windows'
        }
        $script:stoppedVm = [pscustomobject]@{
            Name          = 'Client1'
            VmId          = 7096
            node          = 'pve1'
            status        = 'stopped'
            CurrentStatus = [pscustomobject]@{ qmpstatus = 'stopped' }
        }
        $script:runningVm = [pscustomobject]@{
            Name          = 'Client1'
            VmId          = 7096
            node          = 'pve1'
            status        = 'running'
            CurrentStatus = [pscustomobject]@{ qmpstatus = 'running' }
        }

        Mock -CommandName Get-LabVM -MockWith { $script:labVm }
        Mock -CommandName Get-LWProxmoxVM -MockWith {
            if ($NoCache.IsPresent) { $script:runningVm } else { $script:stoppedVm }
        }
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{ data = 'UPID:test' }
            }
        }
        Mock -CommandName Wait-LWProxmoxTasksStatus -MockWith { 'WARNINGS: 1' }
        Mock -CommandName Write-PSFMessage
        Mock -CommandName Write-LogFunctionExit
    }

    It 'accepts task warnings when a fresh query proves the VM is running' {
        { Start-LWProxmoxVM -ComputerName 'Client1' } | Should -Not -Throw

        Should -Invoke -CommandName Get-LWProxmoxVM -Times 1 -Exactly -ParameterFilter {
            $NoCache.IsPresent
        }
        Should -Invoke -CommandName Write-PSFMessage -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -match 'WARNINGS: 1'
        }
    }

    It 'rejects task warnings when the VM did not reach running state' {
        Mock -CommandName Get-LWProxmoxVM -MockWith { $script:stoppedVm }

        {
            Start-LWProxmoxVM -ComputerName 'Client1'
        } | Should -Throw -ExpectedMessage "*Could not start Proxmox machine*WARNINGS: 1*"
    }
}