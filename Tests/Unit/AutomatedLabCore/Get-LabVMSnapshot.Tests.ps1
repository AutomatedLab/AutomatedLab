Describe 'Get-LabVMSnapshot' {
    BeforeAll {
        $coreRoot = Join-Path $PSScriptRoot '..\..\..\AutomatedLabCore'
        . (Join-Path $coreRoot 'functions\VirtualMachines\Get-LabVMSnapshot.ps1')

        function Get-Lab {}
        function Get-LabVM
        {
            param
            (
                [string[]]$ComputerName,
                [switch]$IncludeLinux
            )
        }
        function Write-LogFunctionEntry {}
        function Write-LogFunctionExit {}
        function Write-LogFunctionExitWithError
        {
            param
            (
                [string]$Message
            )
        }

        # The worker stubs declare the parameters of the real workers, so a parameter
        # that a worker does not have fails to bind here as it does in a lab
        function Get-LWHypervVMSnapshot
        {
            [CmdletBinding()]
            param
            (
                [string[]]$VMName,

                [string]$Name
            )
        }
        function Get-LWAzureVmSnapshot
        {
            param
            (
                [Parameter()]
                [Alias('VMName')]
                [string[]]
                $ComputerName,

                [Parameter()]
                [Alias('Name')]
                [string]
                $SnapshotName
            )
        }
        function Get-LWProxmoxVMSnapshot
        {
            param
            (
                [Parameter()]
                [Alias('VMName')]
                [string[]]
                $ComputerName,

                [Parameter()]
                [string]
                $SnapshotName
            )
        }

        function New-TestMachine
        {
            param
            (
                [string]$Name,
                [string]$FriendlyName,
                [switch]$SkipDeployment
            )

            # Like AutomatedLab.Machine: the resource name is the friendly name when there is one,
            # and ToString() returns the name
            $resourceName = $Name
            if ($FriendlyName)
            {
                $resourceName = $FriendlyName
            }

            $machine = [pscustomobject]@{
                Name           = $Name
                ResourceName   = $resourceName
                SkipDeployment = $SkipDeployment.IsPresent
            }
            $machine | Add-Member -MemberType ScriptMethod -Name ToString -Value { $this.Name } -Force
            $machine
        }
    }

    BeforeEach {
        # DC1 has a friendly name, so its resource name is not its name; the lab does not deploy EXT1
        $script:machines = @(
            New-TestMachine -Name 'DC1' -FriendlyName 'LAB-DC1'
            New-TestMachine -Name 'WEB1'
            New-TestMachine -Name 'EXT1' -SkipDeployment
        )
        $script:snapshots = @(
            [pscustomobject]@{
                SnapshotName = 'Checkpoint1'
                ComputerName = 'LAB-DC1'
            }
            [pscustomobject]@{
                SnapshotName = 'Checkpoint1'
                ComputerName = 'WEB1'
            }
        )
        $script:workerCalls = [System.Collections.Generic.List[object]]::new()

        Mock -CommandName Get-LabVM -MockWith { $script:machines }
        Mock -CommandName Write-LogFunctionEntry
        Mock -CommandName Write-LogFunctionExit
        Mock -CommandName Write-LogFunctionExitWithError
        Mock -CommandName Get-LWHypervVMSnapshot -MockWith {
            $script:workerCalls.Add([pscustomobject]@{
                    Worker     = 'HyperV'
                    Parameters = $PesterBoundParameters
                })
            $script:snapshots
        }
        Mock -CommandName Get-LWAzureVmSnapshot -MockWith {
            $script:workerCalls.Add([pscustomobject]@{
                    Worker     = 'Azure'
                    Parameters = $PesterBoundParameters
                })
            $script:snapshots
        }
        Mock -CommandName Get-LWProxmoxVMSnapshot -MockWith {
            $script:workerCalls.Add([pscustomobject]@{
                    Worker     = 'Proxmox'
                    Parameters = $PesterBoundParameters
                })
            $script:snapshots
        }
    }

    Context 'When the lab runs on Proxmox' {
        BeforeEach {
            Mock -CommandName Get-Lab -MockWith {
                [pscustomobject]@{
                    DefaultVirtualizationEngine = 'Proxmox'
                }
            }
        }

        It 'Should pass the snapshot name as SnapshotName and not as Name' {
            $null = Get-LabVMSnapshot -SnapshotName 'Checkpoint1'

            $script:workerCalls.Count | Should -Be 1
            $script:workerCalls[0].Worker | Should -Be 'Proxmox'
            $script:workerCalls[0].Parameters['SnapshotName'] | Should -Be 'Checkpoint1'
            $script:workerCalls[0].Parameters.ContainsKey('Name') | Should -Be $false
        }

        It 'Should pass the resource names and leave out machines that skip deployment' {
            $null = Get-LabVMSnapshot -SnapshotName 'Checkpoint1'

            $script:workerCalls[0].Parameters['ComputerName'] | Should -Be @('LAB-DC1', 'WEB1')
        }

        It 'Should pass only the resource names when no snapshot name is given' {
            $null = Get-LabVMSnapshot

            $script:workerCalls.Count | Should -Be 1
            $script:workerCalls[0].Parameters['ComputerName'] | Should -Be @('LAB-DC1', 'WEB1')
            $script:workerCalls[0].Parameters.ContainsKey('SnapshotName') | Should -Be $false
        }

        It 'Should return the snapshots that the worker finds' {
            $result = Get-LabVMSnapshot -SnapshotName 'Checkpoint1'

            $result | Should -Be $script:snapshots
        }
    }

    Context 'When the lab runs on Hyper-V' {
        BeforeEach {
            Mock -CommandName Get-Lab -MockWith {
                [pscustomobject]@{
                    DefaultVirtualizationEngine = 'HyperV'
                }
            }
        }

        It 'Should pass the machines as VMName and the snapshot name as Name, as before' {
            $null = Get-LabVMSnapshot -SnapshotName 'Checkpoint1'

            $script:workerCalls.Count | Should -Be 1
            $script:workerCalls[0].Worker | Should -Be 'HyperV'
            $script:workerCalls[0].Parameters['VMName'] | Should -Be @('DC1', 'WEB1')
            $script:workerCalls[0].Parameters['Name'] | Should -Be 'Checkpoint1'
        }
    }
}
