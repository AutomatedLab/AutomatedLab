Describe 'Remove-LabVM' {
    BeforeAll {
        $coreRoot = Join-Path $PSScriptRoot '..\..\..\AutomatedLabCore'
        . (Join-Path $coreRoot 'functions\VirtualMachines\Remove-LabVM.ps1')

        function Get-Lab {}
        function Get-LabConfigurationItem
        {
            param
            (
                [string]$Name
            )
        }
        function Get-HostEntry
        {
            param
            (
                [string]$Section,
                [object]$HostName
            )
        }
        function Remove-HostEntry
        {
            param
            (
                [string]$Section,
                [object]$HostName
            )
        }
        function Remove-LWHypervVM
        {
            param
            (
                [string]$Name
            )
        }
        function Remove-LWAzureVM
        {
            param
            (
                [string]$Name
            )
        }
        function Remove-LWVMWareVM
        {
            param
            (
                [string]$Name
            )
        }
        function Remove-LWProxmoxVM
        {
            param
            (
                [string]$Name,
                [int]$VmId
            )
        }
        function UnInstall-LabSshKnownHost
        {
            param
            (
                [object[]]$ComputerName
            )
        }
        function Write-LogFunctionEntry {}
        function Write-LogFunctionExitWithError
        {
            param
            (
                [string]$Message
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

        function New-TestMachine
        {
            param
            (
                [string]$Name,
                [string]$HostType,
                [hashtable]$ProxmoxProperties = @{}
            )

            $machine = [pscustomobject]@{
                Name              = $Name
                ResourceName      = $Name
                HostType          = $HostType
                FriendlyName      = $null
                IPV4Address       = '192.168.10.10'
                ProxmoxProperties = $ProxmoxProperties
            }
            $machine | Add-Member -MemberType ScriptMethod -Name ToString -Value { $this.Name } -Force
            $machine
        }
    }

    BeforeEach {
        $script:proxmoxMachine = New-TestMachine -Name 'PVM1' -HostType 'Proxmox' -ProxmoxProperties @{ VmId = '205' }
        $script:hyperVMachine = New-TestMachine -Name 'HVM1' -HostType 'HyperV'

        Mock -CommandName Get-Lab -MockWith {
            [pscustomobject]@{
                Name     = 'TestLab'
                Machines = @($script:proxmoxMachine, $script:hyperVMachine)
            }
        }
        Mock -CommandName Get-LabConfigurationItem
        Mock -CommandName Get-HostEntry
        Mock -CommandName Remove-HostEntry
        Mock -CommandName Get-PSSession
        Mock -CommandName Remove-PSSession
        Mock -CommandName Remove-LWHypervVM
        Mock -CommandName Remove-LWAzureVM
        Mock -CommandName Remove-LWVMWareVM
        Mock -CommandName Remove-LWProxmoxVM -MockWith {
            [pscustomobject]@{
                Name    = $Name
                VmId    = 205
                Node    = 'pve1'
                Outcome = 'Removed'
            }
        }
        Mock -CommandName UnInstall-LabSshKnownHost
        Mock -CommandName Write-LogFunctionEntry
        Mock -CommandName Write-LogFunctionExitWithError
        Mock -CommandName Write-ScreenInfo
    }

    Context 'When the Proxmox VM was removed' {
        It 'reports the lab VM as removed' {
            Remove-LabVM -ComputerName 'PVM1'

            Should -Invoke -CommandName Write-ScreenInfo -Times 1 -Exactly -ParameterFilter { $Message -eq "Lab VM 'PVM1' has been removed" }
        }

        It 'passes the VMID the lab recorded to the Proxmox removal' {
            Remove-LabVM -ComputerName 'PVM1'

            Should -Invoke -CommandName Remove-LWProxmoxVM -Times 1 -Exactly -ParameterFilter { $Name -eq 'PVM1' -and $VmId -eq 205 }
        }

        It 'emits nothing to the pipeline' {
            $output = Remove-LabVM -ComputerName 'PVM1'

            $output | Should -BeNullOrEmpty
        }
    }

    Context 'When the Proxmox VM was not found' {
        BeforeEach {
            Mock -CommandName Remove-LWProxmoxVM -MockWith {
                [pscustomobject]@{
                    Name    = $Name
                    VmId    = 205
                    Node    = $null
                    Outcome = 'NotFound'
                }
            }
        }

        It 'says there was nothing to remove instead of claiming a removal' {
            Remove-LabVM -ComputerName 'PVM1'

            Should -Invoke -CommandName Write-ScreenInfo -Times 1 -Exactly -ParameterFilter { $Message -eq "Lab VM 'PVM1' was not found, nothing to remove" }
            Should -Invoke -CommandName Write-ScreenInfo -Times 0 -Exactly -ParameterFilter { $Message -like '*has been removed*' }
        }

        It 'emits nothing to the pipeline' {
            $output = Remove-LabVM -ComputerName 'PVM1'

            $output | Should -BeNullOrEmpty
        }
    }

    Context 'When the lab recorded a VMID that is not a number' {
        It 'removes the VM without a VMID' {
            $script:proxmoxMachine.ProxmoxProperties = @{ VmId = 'System.Object[]' }

            Remove-LabVM -ComputerName 'PVM1'

            Should -Invoke -CommandName Remove-LWProxmoxVM -Times 1 -Exactly -ParameterFilter { $Name -eq 'PVM1' -and -not $VmId }
        }
    }

    Context 'When the VM runs on Hyper-V' {
        It 'removes and reports it as before' {
            Remove-LabVM -ComputerName 'HVM1'

            Should -Invoke -CommandName Remove-LWHypervVM -Times 1 -Exactly -ParameterFilter { $Name -eq 'HVM1' }
            Should -Invoke -CommandName Remove-LWProxmoxVM -Times 0 -Exactly
            Should -Invoke -CommandName Write-ScreenInfo -Times 1 -Exactly -ParameterFilter { $Message -eq "Lab VM 'HVM1' has been removed" }
        }
    }
}
