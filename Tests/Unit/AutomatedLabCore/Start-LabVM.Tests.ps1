Describe 'Start-LabVM' {
    BeforeAll {
        Import-Module -Name AutomatedLab -Force -ErrorAction Stop

        $functionPath = Join-Path $PSScriptRoot (
            '..\..\..\AutomatedLabCore\functions\VirtualMachines\Start-LabVM.ps1'
        )
        . $functionPath
    }

    BeforeEach {
        $script:callOrder = [System.Collections.Generic.List[string]]::new()
        $script:savedInitState = [AutomatedLab.LabVMInitState]::Uninitialized
        $script:machine = [AutomatedLab.Machine]::new()
        $script:machine.Name = 'Client2'
        $script:machine.HostType = [AutomatedLab.VirtualizationHost]::Proxmox
        $script:machine.OperatingSystem = [AutomatedLab.OperatingSystem]::new('Windows 10 Enterprise')
        $script:machine.SkipDeployment = $false
        $script:lab = [pscustomobject]@{
            Machines = @($script:machine)
        }

        Mock -CommandName Get-Lab -MockWith { $script:lab }
        Mock -CommandName Get-LabVM -MockWith { $script:machine }
        Mock -CommandName Get-LabVMStatus -MockWith { @{ Client2 = 'Stopped' } }
        Mock -CommandName Start-LWProxmoxVM -MockWith {
            $script:callOrder.Add('start')
        }
        Mock -CommandName Get-LWVMDescription -MockWith {
            @{
                InitState = 'EnabledCredSsp'
            }
        }
        Mock -CommandName Wait-LabVM -MockWith {
            $script:callOrder.Add('wait')
        }
        Mock -CommandName Repair-LWProxmoxNetworkConfig -MockWith {
            $script:callOrder.Add('repair')
        }
        Mock -CommandName Set-LWVMDescription -MockWith {
            $script:savedInitState = $Hashtable.InitState
        }
        Mock -CommandName Write-PSFMessage
        Mock -CommandName Write-ProgressIndicatorEnd
        Mock -CommandName Write-LogFunctionEntry
        Mock -CommandName Write-LogFunctionExit
    }

    It 'waits for WinRM before repairing Proxmox network configuration' {
        Start-LabVM -ComputerName $script:machine.Name -Wait -TimeoutInMinutes 1 -ProgressIndicator 0

        $script:callOrder | Should -Be @('start', 'wait', 'repair')
        ($script:savedInitState -band [AutomatedLab.LabVMInitState]::EnabledCredSsp) |
            Should -Be ([AutomatedLab.LabVMInitState]::EnabledCredSsp)
        ($script:savedInitState -band [AutomatedLab.LabVMInitState]::NetworkAdapterBindingCorrected) |
            Should -Be ([AutomatedLab.LabVMInitState]::NetworkAdapterBindingCorrected)
    }

    It 'skips Proxmox network repair when it is already recorded' {
        Mock -CommandName Get-LWVMDescription -MockWith {
            @{
                InitState = 'EnabledCredSsp, NetworkAdapterBindingCorrected'
            }
        }

        Start-LabVM -ComputerName $script:machine.Name -Wait -TimeoutInMinutes 1 -ProgressIndicator 0

        $script:callOrder | Should -Be @('start', 'wait')
        Should -Invoke -CommandName Repair-LWProxmoxNetworkConfig -Times 0
        Should -Invoke -CommandName Set-LWVMDescription -Times 0
    }
}