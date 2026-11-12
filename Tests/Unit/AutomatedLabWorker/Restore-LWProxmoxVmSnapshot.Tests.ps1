Describe 'Restore-LWProxmoxVmSnapshot' {
    BeforeAll {
        $workerRoot = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker\functions'
        . (Join-Path $workerRoot 'ProxmoxWorkerVirtualMachines\Restore-LWProxmoxVmSnapshot.ps1')
        . (Join-Path $workerRoot 'Internals\ConvertTo-LWProxmoxTaskResultText.ps1')

        # The real workers give their mocks the exact parameters, so a wrong parameter name fails the test.
        . (Join-Path $workerRoot 'Internals\Invoke-LWProxmoxCallWithRetry.ps1')
        . (Join-Path $workerRoot 'ProxmoxWorkerVirtualMachines\Get-LWProxmoxVM.ps1')
        . (Join-Path $workerRoot 'ProxmoxWorkerVirtualMachines\Get-LWProxmoxVMConfig.ps1')
        . (Join-Path $workerRoot 'ProxmoxWorkerVirtualMachines\Get-LWProxmoxVmSnapshot.ps1')
        . (Join-Path $workerRoot 'ProxmoxWorkerVirtualMachines\Wait-LWProxmoxTasksStatus.ps1')

        function Test-LabProxmoxConnection {}
        function Get-Lab {}
        function Write-LogFunctionEntry {}
        function Write-LogFunctionExit {}
        function Get-LabVM
        {
            [CmdletBinding()]
            param
            (
                [string[]]$ComputerName,
                [switch]$IncludeLinux,
                [switch]$IsRunning
            )
        }
        function Stop-LabVM
        {
            [CmdletBinding()]
            param
            (
                [string[]]$ComputerName,
                [switch]$Wait
            )
        }
        function Start-LabVM
        {
            [CmdletBinding()]
            param
            (
                [string[]]$ComputerName,
                [switch]$Wait
            )
        }
        function Get-LabConfigurationItem
        {
            [CmdletBinding()]
            param
            (
                [string]$Name,
                $Default
            )
        }
        function Undo-PveVmSnapshot
        {
            [CmdletBinding()]
            param
            (
                [string]$VmIdOrName,
                [string]$Snapname
            )
        }
        function Stop-PveVm
        {
            [CmdletBinding()]
            param
            (
                [string]$VmIdOrName
            )
        }
        function Write-ScreenInfo
        {
            param
            (
                [string[]]$Message,
                [ValidateSet('Error', 'Warning', 'Info', 'Verbose', 'Debug')]
                [string]$Type,
                [switch]$NoNewLine,
                [switch]$TaskStart,
                [switch]$TaskEnd
            )
        }
        function New-TestMachine
        {
            param
            (
                [string]$Name,

                [string]$ResourceName = $Name
            )

            # Machine.ToString() returns the name, so a lab machine binds to [string[]] as its name.
            [pscustomobject]@{
                Name         = $Name
                ResourceName = $ResourceName
            } | Add-Member -MemberType ScriptMethod -Name ToString -Value { $this.Name } -Force -PassThru
        }
        function Invoke-Restore
        {
            param
            (
                [string[]]$ComputerName
            )

            # Pester runs a test with 'Stop'. With 'Continue' only a terminating error of the function ends the call.
            $ErrorActionPreference = 'Continue'
            $outcome = [pscustomobject]@{
                Thrown = $null
                Errors = @()
            }

            try
            {
                Restore-LWProxmoxVmSnapshot -ComputerName $ComputerName -SnapshotName 'VMCheckpoint' -ErrorVariable writtenErrors 2>$null
            }
            catch
            {
                $outcome.Thrown = $_
            }

            # The error variable also holds the terminating error, which Thrown covers, and the exception that stopped the call.
            $outcome.Errors = @($writtenErrors | Where-Object {
                    $_ -isnot [System.Management.Automation.ActionPreferenceStopException] -and
                    -not ($outcome.Thrown -and $_.FullyQualifiedErrorId -eq $outcome.Thrown.FullyQualifiedErrorId)
                })
            $outcome
        }
    }

    BeforeEach {
        $script:rbdText = "rbd snapshot base-701-disk-1/vm-7057-disk-1 to 'DJSRV2022R005_VMCheckpoint' error: Rolling back to snapshot: 0% complete...failed."
        $script:proxmoxVms = @(
            [pscustomobject]@{
                Name   = 'DJSRV2022R005'
                vmid   = 7057
                node   = 'pve2'
                status = 'stopped'
            }
            [pscustomobject]@{
                Name   = 'DJRDS2011R005'
                vmid   = 7056
                node   = 'pve1'
                status = 'stopped'
            }
            [pscustomobject]@{
                Name   = 'DJSQL2019R005'
                vmid   = 7058
                node   = 'pve3'
                status = 'stopped'
            }
        )
        $script:labVms = @($script:proxmoxVms | ForEach-Object { New-TestMachine -Name $_.Name })
        $script:runningBefore = @('DJSRV2022R005', 'DJRDS2011R005')
        $script:withoutSnapshot = @()
        # VMID -> the results of the rollback tasks, one per attempt; the last one repeats. No entry means 'OK'.
        $script:rollbackResults = @{}
        $script:rollbackCalls = @{}
        # VM name -> lock that the VM configuration shows until the test has slept UntilSleptSeconds in total.
        $script:locks = @{}
        $script:sleptSeconds = 0
        $script:configuredRetries = 2
        $script:configuredDelay = 20

        Mock -CommandName Test-LabProxmoxConnection -MockWith { $true }
        Mock -CommandName Get-Lab -MockWith { [pscustomobject]@{ Name = 'TestLab' } }
        Mock -CommandName Get-LabVM -MockWith { $script:labVms }
        Mock -CommandName Get-LabVM -ParameterFilter { $IsRunning.IsPresent } -MockWith {
            $script:labVms | Where-Object { $_.Name -in $ComputerName -and $_.Name -in $script:runningBefore }
        }
        Mock -CommandName Stop-LabVM
        Mock -CommandName Start-LabVM
        Mock -CommandName Get-LabConfigurationItem -ParameterFilter { $Name -eq 'ProxmoxSnapshotRollbackRetries' } -MockWith {
            $script:configuredRetries
        }
        Mock -CommandName Get-LabConfigurationItem -ParameterFilter { $Name -eq 'ProxmoxSnapshotRollbackRetryDelaySeconds' } -MockWith {
            $script:configuredDelay
        }
        Mock -CommandName Get-LWProxmoxVM -MockWith {
            $script:proxmoxVms | Where-Object { $_.Name -in $ComputerName }
        }
        Mock -CommandName Get-LWProxmoxVMConfig -MockWith {
            foreach ($name in $ComputerName)
            {
                $config = [ordered]@{
                    name = $name
                }
                $lock = $script:locks[$name]
                if ($lock -and $script:sleptSeconds -lt $lock.UntilSleptSeconds)
                {
                    $config.lock = $lock.Lock
                }

                [pscustomobject]$config
            }
        }
        Mock -CommandName Get-LWProxmoxVmSnapshot -MockWith {
            if ($ComputerName[0] -notin $script:withoutSnapshot)
            {
                [pscustomobject]@{
                    SnapshotName = $SnapshotName
                    ComputerName = $ComputerName[0]
                }
            }
        }
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith { & $ScriptBlock }
        Mock -CommandName Undo-PveVmSnapshot -MockWith {
            $vmid = [int]$VmIdOrName
            $script:rollbackCalls[$vmid] = 1 + [int]$script:rollbackCalls[$vmid]
            [pscustomobject]@{
                StatusCode   = 200
                ReasonPhrase = 'OK'
                Response     = [pscustomobject]@{ data = 'UPID:qmrollback:{0}:{1}' -f $vmid, $script:rollbackCalls[$vmid] }
            }
        }
        Mock -CommandName Stop-PveVm -MockWith {
            ($script:proxmoxVms | Where-Object { $_.vmid -eq [int]$VmIdOrName }).status = 'stopped'
            [pscustomobject]@{
                StatusCode   = 200
                ReasonPhrase = 'OK'
                Response     = [pscustomobject]@{ data = "UPID:qmstop:$VmIdOrName" }
            }
        }
        Mock -CommandName Wait-LWProxmoxTasksStatus -MockWith {
            if ($Upid[0] -notmatch '^UPID:qmrollback:(?<vmid>\d+):(?<attempt>\d+)$')
            {
                return 'OK'
            }

            $results = @($script:rollbackResults[[int]$Matches.vmid])
            if (-not $script:rollbackResults.ContainsKey([int]$Matches.vmid))
            {
                return 'OK'
            }

            $results[[Math]::Min([int]$Matches.attempt, $results.Count) - 1]
        }
        Mock -CommandName Start-Sleep -MockWith { $script:sleptSeconds += $Seconds }
        Mock -CommandName Write-ScreenInfo
        Mock -CommandName Write-LogFunctionEntry
        Mock -CommandName Write-LogFunctionExit
    }

    Context 'when every rollback succeeds' {
        It 'rolls each VM back once and starts the VMs again that were running' {
            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005', 'DJRDS2011R005', 'DJSQL2019R005'

            $outcome.Thrown | Should -BeNullOrEmpty
            $outcome.Errors | Should -BeNullOrEmpty
            $script:rollbackCalls[7057] | Should -Be 1
            $script:rollbackCalls[7056] | Should -Be 1
            $script:rollbackCalls[7058] | Should -Be 1
            Should -Invoke -CommandName Undo-PveVmSnapshot -Times 1 -Exactly -ParameterFilter {
                $VmIdOrName -eq '7057' -and $Snapname -eq 'DJSRV2022R005_VMCheckpoint'
            }
            Should -Invoke -CommandName Stop-LabVM -Times 1 -Exactly -ParameterFilter {
                ($ComputerName -join ',') -eq 'DJSRV2022R005,DJRDS2011R005'
            }
            Should -Invoke -CommandName Start-LabVM -Times 1 -Exactly -ParameterFilter {
                ($ComputerName -join ',') -eq 'DJSRV2022R005,DJRDS2011R005'
            }
            Should -Invoke -CommandName Start-Sleep -Times 0 -Exactly
        }

        It 'stops and starts again a running machine that has a FriendlyName' {
            $script:proxmoxVms += [pscustomobject]@{
                Name   = 'LAB-DC1'
                vmid   = 7059
                node   = 'pve1'
                status = 'stopped'
            }
            $script:labVms += New-TestMachine -Name 'DC1' -ResourceName 'LAB-DC1'
            $script:runningBefore += 'DC1'

            $outcome = Invoke-Restore -ComputerName 'LAB-DC1'

            $outcome.Thrown | Should -BeNullOrEmpty
            $script:rollbackCalls[7059] | Should -Be 1
            Should -Invoke -CommandName Stop-LabVM -Times 1 -Exactly -ParameterFilter {
                ($ComputerName -join ',') -eq 'DC1'
            }
            Should -Invoke -CommandName Start-LabVM -Times 1 -Exactly -ParameterFilter {
                ($ComputerName -join ',') -eq 'DC1'
            }
        }
    }

    Context 'when a rollback task fails' {
        It 'throws the Proxmox text with the VM, the snapshot, the node, the VMID and the task' {
            $script:rollbackResults[7057] = $script:rbdText

            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005'

            $outcome.Thrown | Should -Not -BeNullOrEmpty -Because 'a failed rollback has to end in a terminating error'
            $message = $outcome.Thrown.Exception.Message
            $message | Should -Match ([regex]::Escape($script:rbdText))
            $message | Should -Match "'DJSRV2022R005'"
            $message | Should -Match "snapshot 'VMCheckpoint'"
            $message | Should -Match "node 'pve2'"
            $message | Should -Match 'VMID 7057'
            $message | Should -Match 'UPID:qmrollback:7057:3'
        }

        It 'rolls back again after a failed attempt and reports nothing when the next attempt succeeds' {
            $script:rollbackResults[7057] = @($script:rbdText, 'OK')

            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005'

            $outcome.Thrown | Should -BeNullOrEmpty
            $outcome.Errors | Should -BeNullOrEmpty
            $script:rollbackCalls[7057] | Should -Be 2
            Should -Invoke -CommandName Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 20 }
            Should -Invoke -CommandName Get-LWProxmoxVMConfig -ParameterFilter { $NoCache.IsPresent }
            Should -Invoke -CommandName Get-LWProxmoxVM -ParameterFilter { $NoCache.IsPresent }
            Should -Invoke -CommandName Start-LabVM -Times 1 -Exactly -ParameterFilter {
                ($ComputerName -join ',') -eq 'DJSRV2022R005'
            }
        }

        It 'stops a VM that runs before it rolls the VM back again' {
            $script:rollbackResults[7057] = @($script:rbdText, 'OK')
            ($script:proxmoxVms | Where-Object Name -eq 'DJSRV2022R005').status = 'running'

            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005'

            $outcome.Thrown | Should -BeNullOrEmpty
            Should -Invoke -CommandName Stop-PveVm -Times 1 -Exactly -ParameterFilter { $VmIdOrName -eq '7057' }
            $script:rollbackCalls[7057] | Should -Be 2
        }

        It 'makes no further attempt when the VM stays locked and names the lock' {
            $script:rollbackResults[7057] = $script:rbdText
            $script:locks['DJSRV2022R005'] = @{
                Lock              = 'rollback'
                UntilSleptSeconds = [int]::MaxValue
            }

            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005'

            $outcome.Thrown | Should -Not -BeNullOrEmpty -Because 'a VM that stays locked cannot be rolled back'
            $outcome.Thrown.Exception.Message | Should -Match "locked \('rollback'\)"
            $outcome.Thrown.Exception.Message | Should -Match ([regex]::Escape($script:rbdText))
            $script:rollbackCalls[7057] | Should -Be 1
            $script:sleptSeconds | Should -BeLessOrEqual 40 -Because 'the lock gets at most one delay period after the retry delay'
        }

        It 'rolls back again once the lock clears within the delay' {
            $script:rollbackResults[7057] = @($script:rbdText, 'OK')
            $script:locks['DJSRV2022R005'] = @{
                Lock              = 'rollback'
                UntilSleptSeconds = 25
            }

            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005'

            $outcome.Thrown | Should -BeNullOrEmpty
            $script:rollbackCalls[7057] | Should -Be 2
        }

        It 'makes no further attempt when ProxmoxSnapshotRollbackRetries is 0' {
            $script:configuredRetries = 0
            $script:rollbackResults[7057] = $script:rbdText

            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005'

            $outcome.Thrown | Should -Not -BeNullOrEmpty
            $script:rollbackCalls[7057] | Should -Be 1
            Should -Invoke -CommandName Start-Sleep -Times 0 -Exactly
        }

        It 'reports every failed VM in one error after all VMs and starts only the restored ones' {
            $sqlText = "rbd snapshot base-702-disk-0/vm-7058-disk-0 to 'DJSQL2019R005_VMCheckpoint' error: Rolling back to snapshot: 12% complete...failed."
            $script:rollbackResults[7057] = $script:rbdText
            $script:rollbackResults[7058] = $sqlText

            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005', 'DJRDS2011R005', 'DJSQL2019R005'

            $outcome.Thrown | Should -Not -BeNullOrEmpty
            $outcome.Thrown.FullyQualifiedErrorId | Should -BeLike 'ProxmoxSnapshotRollbackFailed*'
            $message = $outcome.Thrown.Exception.Message
            $message | Should -Match ([regex]::Escape($script:rbdText))
            $message | Should -Match ([regex]::Escape($sqlText))
            $message | Should -Not -Match 'DJRDS2011R005'
            $outcome.Errors | Should -BeNullOrEmpty -Because 'the failed VMs are reported in the one terminating error only'
            $script:rollbackCalls[7057] | Should -Be 3
            $script:rollbackCalls[7056] | Should -Be 1
            $script:rollbackCalls[7058] | Should -Be 3
            Should -Invoke -CommandName Start-LabVM -Times 1 -Exactly -ParameterFilter {
                ($ComputerName -join ',') -eq 'DJRDS2011R005'
            }
        }
    }

    Context 'when the rollback task ends with warnings' {
        It 'counts the rollback as done when the VM is stopped and not locked' {
            $script:rollbackResults[7057] = 'WARNINGS: 1'

            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005'

            $outcome.Thrown | Should -BeNullOrEmpty
            $outcome.Errors | Should -BeNullOrEmpty
            $script:rollbackCalls[7057] | Should -Be 1
            Should -Invoke -CommandName Write-ScreenInfo -Times 1 -Exactly -ParameterFilter {
                $Type -eq 'Warning' -and $Message -match 'WARNINGS: 1'
            }
            Should -Invoke -CommandName Start-LabVM -Times 1 -Exactly -ParameterFilter {
                ($ComputerName -join ',') -eq 'DJSRV2022R005'
            }
        }

        It 'treats the warnings as a failure when the VM is locked' {
            $script:configuredRetries = 0
            $script:rollbackResults[7057] = 'WARNINGS: 1'
            $script:locks['DJSRV2022R005'] = @{
                Lock              = 'rollback'
                UntilSleptSeconds = [int]::MaxValue
            }

            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005'

            $outcome.Thrown | Should -Not -BeNullOrEmpty
            $outcome.Thrown.Exception.Message | Should -Match 'WARNINGS: 1'
            $outcome.Thrown.Exception.Message | Should -Match "locked \('rollback'\)"
            Should -Invoke -CommandName Start-LabVM -Times 0 -Exactly
        }

        It 'treats the warnings as a failure when the VM is running' {
            $script:configuredRetries = 0
            $script:rollbackResults[7057] = 'WARNINGS: 1'
            ($script:proxmoxVms | Where-Object Name -eq 'DJSRV2022R005').status = 'running'

            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005'

            $outcome.Thrown | Should -Not -BeNullOrEmpty
            $outcome.Thrown.Exception.Message | Should -Match 'WARNINGS: 1'
            $outcome.Thrown.Exception.Message | Should -Match "status is 'running'"
            Should -Invoke -CommandName Start-LabVM -Times 0 -Exactly
        }
    }

    Context 'behavior that stays as it was' {
        It 'ends at once when the rollback request is not answered with 200' {
            Mock -CommandName Undo-PveVmSnapshot -ParameterFilter { $VmIdOrName -eq '7057' } -MockWith {
                [pscustomobject]@{
                    StatusCode   = 500
                    ReasonPhrase = 'Internal Server Error'
                    Response     = $null
                }
            }

            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005', 'DJRDS2011R005'

            $outcome.Thrown.Exception.Message | Should -BeLike "*Could not restore snapshot 'VMCheckpoint' for Proxmox machine 'DJSRV2022R005'*500*"
            Should -Invoke -CommandName Wait-LWProxmoxTasksStatus -Times 0 -Exactly
            Should -Invoke -CommandName Undo-PveVmSnapshot -Times 0 -Exactly -ParameterFilter { $VmIdOrName -eq '7056' }
            Should -Invoke -CommandName Start-LabVM -Times 0 -Exactly
        }

        It 'skips a VM without the snapshot with a warning and restores the others' {
            $script:withoutSnapshot = @('DJSRV2022R005')

            $outcome = Invoke-Restore -ComputerName 'DJSRV2022R005', 'DJRDS2011R005'

            $outcome.Thrown | Should -BeNullOrEmpty
            Should -Invoke -CommandName Write-ScreenInfo -Times 1 -Exactly -ParameterFilter {
                $Type -eq 'Warning' -and $Message -eq 'No snapshot named VMCheckpoint found for DJSRV2022R005. Skipping restore.'
            }
            Should -Invoke -CommandName Undo-PveVmSnapshot -Times 0 -Exactly -ParameterFilter { $VmIdOrName -eq '7057' }
            $script:rollbackCalls[7056] | Should -Be 1
            Should -Invoke -CommandName Start-LabVM -Times 1 -Exactly -ParameterFilter {
                ($ComputerName -join ',') -eq 'DJSRV2022R005,DJRDS2011R005'
            }
        }

        It 'skips a VM that no node lists with a warning that names it' {
            $outcome = Invoke-Restore -ComputerName 'GHOST', 'DJRDS2011R005'

            $outcome.Thrown | Should -BeNullOrEmpty
            Should -Invoke -CommandName Write-ScreenInfo -Times 1 -Exactly -ParameterFilter {
                $Type -eq 'Warning' -and $Message -eq "Proxmox VM 'GHOST' could not be found. Skipping restore."
            }
            $script:rollbackCalls[7056] | Should -Be 1
        }
    }
}
