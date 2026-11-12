Describe 'Remove-LWProxmoxVMSnapshot' {
    BeforeAll {
        $workerRoot = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker\functions'
        . (Join-Path $workerRoot 'ProxmoxWorkerVirtualMachines\Remove-LWProxmoxVMSnapshot.ps1')

        # The real workers give their mocks the exact parameters, so a wrong parameter name fails the test.
        . (Join-Path $workerRoot 'Internals\Invoke-LWProxmoxCallWithRetry.ps1')
        . (Join-Path $workerRoot 'ProxmoxWorkerVirtualMachines\Get-LWProxmoxVM.ps1')
        . (Join-Path $workerRoot 'ProxmoxWorkerVirtualMachines\Get-LWProxmoxVmSnapshot.ps1')
        . (Join-Path $workerRoot 'ProxmoxWorkerVirtualMachines\Wait-LWProxmoxTasksStatus.ps1')

        function Write-LogFunctionEntry {}
        function Write-LogFunctionExit {}
        function Get-LabVM {}
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
                [string[]]$Message,
                [ValidateSet('Error', 'Warning', 'Info', 'Verbose', 'Debug')]
                [string]$Type
            )
        }
        function Remove-PveNodesQemuSnapshot
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory)]
                [string]$Node,

                [Parameter(Mandatory)]
                [string]$Snapname,

                [Parameter(Mandatory)]
                [int]$Vmid
            )
        }
        function Invoke-Removal
        {
            param
            (
                [hashtable]$Parameters
            )

            # Pester runs a test with 'Stop'. With 'Continue' only a terminating error of the function ends the call.
            $ErrorActionPreference = 'Continue'
            $outcome = [pscustomobject]@{
                Thrown = $null
                Errors = @()
            }

            try
            {
                Remove-LWProxmoxVMSnapshot @Parameters -ErrorVariable writtenErrors 2>$null
            }
            catch
            {
                $outcome.Thrown = $_
            }

            $outcome.Errors = @($writtenErrors | Where-Object { $_ -isnot [System.Management.Automation.ActionPreferenceStopException] })
            $outcome
        }
    }

    BeforeEach {
        $script:refused = @()
        $script:taskResults = @{}

        Mock -CommandName Get-LWProxmoxVM -MockWith {
            [pscustomobject]@{
                Name = 'VM1'
                VmId = 101
                node = 'pve1'
            }
        }
        Mock -CommandName Get-LWProxmoxVmSnapshot -MockWith {
            # Like AutomatedLab.Snapshot: SnapshotName and ComputerName, but no Name.
            foreach ($name in 'VMCheckpoint', 'BeforeUpdate')
            {
                if (-not $SnapshotName -or $SnapshotName -eq $name)
                {
                    [pscustomobject]@{
                        SnapshotName = $name
                        ComputerName = 'VM1'
                    }
                }
            }
        }
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith { & $ScriptBlock }
        Mock -CommandName Remove-PveNodesQemuSnapshot -MockWith {
            if ($Snapname -in $script:refused)
            {
                return [pscustomobject]@{
                    StatusCode   = 500
                    ReasonPhrase = 'Internal Server Error'
                    Response     = $null
                }
            }

            [pscustomobject]@{
                StatusCode   = 200
                ReasonPhrase = 'OK'
                Response     = [pscustomobject]@{ data = "UPID:delsnapshot:$Snapname" }
            }
        }
        Mock -CommandName Wait-LWProxmoxTasksStatus -MockWith {
            $snapname = $Upid[0] -replace '^UPID:delsnapshot:', ''
            if ($script:taskResults.ContainsKey($snapname))
            {
                return $script:taskResults[$snapname]
            }

            'OK'
        }
        Mock -CommandName Write-PSFMessage
        Mock -CommandName Write-ScreenInfo
        Mock -CommandName Write-LogFunctionEntry
        Mock -CommandName Write-LogFunctionExit
    }

    It 'names the snapshot that it removes' {
        $outcome = Invoke-Removal -Parameters @{
            ComputerName = 'VM1'
            SnapshotName = 'VMCheckpoint'
        }

        $outcome.Thrown | Should -BeNullOrEmpty
        Should -Invoke -CommandName Remove-PveNodesQemuSnapshot -Times 1 -Exactly -ParameterFilter { $Snapname -eq 'VM1_VMCheckpoint' }
        Should -Invoke -CommandName Write-PSFMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Removing snapshot 'VMCheckpoint' for VM 'VM1'"
        }
    }

    It 'names the snapshot when the removal task fails' {
        $script:taskResults['VM1_VMCheckpoint'] = 'snapshot delete failed: rbd error'

        $outcome = Invoke-Removal -Parameters @{
            ComputerName = 'VM1'
            SnapshotName = 'VMCheckpoint'
        }

        $outcome.Errors.Count | Should -Be 1
        $outcome.Errors[0].Exception.Message | Should -Match "snapshot 'VMCheckpoint' for Proxmox machine 'VM1'"
        $outcome.Errors[0].Exception.Message | Should -Match 'snapshot delete failed: rbd error'
    }

    It 'goes on with the next snapshot when Proxmox refuses a removal' {
        $script:refused = @('VM1_VMCheckpoint')

        $outcome = Invoke-Removal -Parameters @{
            ComputerName = 'VM1'
            All          = $true
        }

        $outcome.Thrown | Should -BeNullOrEmpty -Because 'a refused removal must not end in a binding error of the wait'
        $outcome.Errors.Count | Should -Be 1
        $outcome.Errors[0].Exception.Message | Should -Match "snapshot 'VMCheckpoint' for Proxmox machine 'VM1'"
        Should -Invoke -CommandName Remove-PveNodesQemuSnapshot -Times 1 -Exactly -ParameterFilter { $Snapname -eq 'VM1_BeforeUpdate' }
        Should -Invoke -CommandName Wait-LWProxmoxTasksStatus -Times 1 -Exactly
    }
}
