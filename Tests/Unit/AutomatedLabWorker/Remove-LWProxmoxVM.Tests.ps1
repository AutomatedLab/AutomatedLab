Describe 'Remove-LWProxmoxVM' {
    BeforeAll {
        $workerRoot = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker'
        . (Join-Path $workerRoot 'functions\ProxmoxWorkerVirtualMachines\Remove-LWProxmoxVM.ps1')

        function Get-LWProxmoxVM
        {
            [CmdletBinding()]
            param
            (
                [Alias('Name')]
                [string[]]$ComputerName,
                [object[]]$Node,
                [switch]$NoError,
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
        function Remove-PveQemu
        {
            param
            (
                [string]$Node,
                [object]$Vmid
            )
        }
        function Stop-PveVm
        {
            param
            (
                [string]$VmIdOrName
            )
        }
        function Wait-LWProxmoxTasksStatus
        {
            param
            (
                [string[]]$Upid,
                [string]$Node,
                [hashtable]$DesiredValues,
                [int]$TimeoutInSeconds
            )
        }
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
        Set-Variable -Name proxmoxVmCache -Scope Script -Value $null

        $script:runningVm = [pscustomobject]@{
            Name   = 'VM1'
            vmid   = 101
            node   = 'pve1'
            status = 'running'
        }

        # What a fresh API call reports. A successful destroy takes the VM out of this list.
        $script:clusterVms = @($script:runningVm)
        # What the session cache reports. Only a lookup without -NoCache reads it.
        $script:cachedVms = @($script:runningVm)
        $script:stopStopsVm = $true
        $script:destroyRemovesVm = $true
        $script:calls = [System.Collections.Generic.List[string]]::new()

        Mock -CommandName Get-LWProxmoxVM -MockWith {
            $source = if ($NoCache) { $script:clusterVms } else { $script:cachedVms }
            $found = @($source | Where-Object { $_.Name -in $ComputerName -and (-not $Node -or $_.node -in $Node) })
            if (-not $found -and -not $NoError)
            {
                # Like the real function, an absent VM is reported as a non-terminating error
                Write-Error -Message "Virtual machine '$ComputerName' not found on node(s) 'pve1, pve2'"
            }
            $found
        }
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith { & $ScriptBlock }
        Mock -CommandName Stop-PveVm -MockWith {
            $script:calls.Add("stop $VmIdOrName")
            if ($script:stopStopsVm)
            {
                $script:clusterVms | Where-Object { "$($_.vmid)" -eq $VmIdOrName } | ForEach-Object { $_.status = 'stopped' }
            }
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{ data = "UPID:stop:$VmIdOrName" }
            }
        }
        Mock -CommandName Remove-PveQemu -MockWith {
            $script:calls.Add("destroy $Node $Vmid")
            if ($script:destroyRemovesVm)
            {
                $script:clusterVms = @($script:clusterVms | Where-Object { -not ($_.node -eq $Node -and "$($_.vmid)" -eq "$Vmid") })
            }
            [pscustomobject]@{
                StatusCode = 200
                Response   = [pscustomobject]@{ data = "UPID:destroy:$Vmid" }
            }
        }
        Mock -CommandName Wait-LWProxmoxTasksStatus -MockWith { 'OK' }
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

    Context 'When the session cache is stale' {
        It 'removes the VM on the node where a fresh lookup finds it' {
            # The cache still lists the VM on pve1, but it was migrated to pve2 since
            $script:cachedVms = @([pscustomobject]@{ Name = 'VM1'; vmid = 101; node = 'pve1'; status = 'running' })
            $script:runningVm.node = 'pve2'

            $null = Remove-LWProxmoxVM -Name 'VM1'

            Should -Invoke -CommandName Remove-PveQemu -Times 1 -Exactly -ParameterFilter { $Node -eq 'pve2' -and $Vmid -eq 101 }
            Should -Invoke -CommandName Remove-PveQemu -Times 0 -Exactly -ParameterFilter { $Node -eq 'pve1' }
        }
    }

    Context 'When deciding whether the VM exists' {
        It 'asks every node for live data and never silences the lookup' {
            $null = Remove-LWProxmoxVM -Name 'VM1'

            Should -Invoke -CommandName Get-LWProxmoxVM -ParameterFilter { $NoCache -and -not $NoError -and -not $Node }
            Should -Invoke -CommandName Get-LWProxmoxVM -Times 0 -Exactly -ParameterFilter { -not $NoCache -or $NoError }
        }
    }

    Context 'When every node answered and none lists the VM' {
        BeforeEach {
            $script:clusterVms = @()
            $script:cachedVms = @()
        }

        It 'reports NotFound with one warning, no error and no destroy call' {
            # 2>&1 captures what the host would print in red; a suppressed nested error never reaches it
            $output = @(Remove-LWProxmoxVM -Name 'VM1' 2>&1)

            @($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }) | Should -BeNullOrEmpty
            $outcome = $output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
            $outcome.Outcome | Should -Be 'NotFound'
            Should -Invoke -CommandName Write-ScreenInfo -Times 1 -Exactly -ParameterFilter { $Type -eq 'Warning' }
            Should -Invoke -CommandName Remove-PveQemu -Times 0 -Exactly
        }
    }

    Context 'When several VMs share the name' {
        BeforeEach {
            $script:otherVm = [pscustomobject]@{ Name = 'VM1'; vmid = 205; node = 'pve2'; status = 'stopped' }
            $script:clusterVms = @($script:runningVm, $script:otherVm)
            $script:cachedVms = $script:clusterVms
        }

        It 'removes only the VMID the lab recorded and reports the other VM' {
            $outcome = Remove-LWProxmoxVM -Name 'VM1' -VmId 205

            $outcome.VmId | Should -Be 205
            Should -Invoke -CommandName Remove-PveQemu -Times 1 -Exactly
            Should -Invoke -CommandName Remove-PveQemu -Times 1 -Exactly -ParameterFilter { $Node -eq 'pve2' -and $Vmid -eq 205 }
            Should -Invoke -CommandName Write-ScreenInfo -Times 1 -Exactly -ParameterFilter {
                $Type -eq 'Warning' -and $Message -like '*VMID 101*' -and $Message -like "*'pve1'*"
            }
        }

        It 'removes nothing when no VM with the recorded VMID exists any more' {
            $outcome = Remove-LWProxmoxVM -Name 'VM1' -VmId 300

            $outcome.Outcome | Should -Be 'NotFound'
            Should -Invoke -CommandName Stop-PveVm -Times 0 -Exactly
            Should -Invoke -CommandName Remove-PveQemu -Times 0 -Exactly
        }

        It 'refuses to pick one of them when the lab recorded no VMID' {
            { Remove-LWProxmoxVM -Name 'VM1' } | Should -Throw -ExpectedMessage '*VMID 101*VMID 205*'

            Should -Invoke -CommandName Stop-PveVm -Times 0 -Exactly
            Should -Invoke -CommandName Remove-PveQemu -Times 0 -Exactly
        }
    }

    Context 'When a Proxmox task does not succeed' {
        It 'fails with node, VMID and the Proxmox text when the stop task fails' {
            Mock -CommandName Wait-LWProxmoxTasksStatus -ParameterFilter { $Upid -like 'UPID:stop:*' } -MockWith {
                "VM 101 qmp command 'quit' failed - got timeout"
            }

            { Remove-LWProxmoxVM -Name 'VM1' } | Should -Throw -ExpectedMessage "*VMID 101*node 'pve1'*VM 101 qmp command 'quit' failed - got timeout*"

            Should -Invoke -CommandName Remove-PveQemu -Times 0 -Exactly
        }

        It 'fails with node, VMID and the Proxmox text when the destroy task fails' {
            $script:destroyRemovesVm = $false
            Mock -CommandName Wait-LWProxmoxTasksStatus -ParameterFilter { $Upid -like 'UPID:destroy:*' } -MockWith {
                "can't lock file '/var/lock/qemu-server/lock-101.conf' - got timeout"
            }

            { Remove-LWProxmoxVM -Name 'VM1' } | Should -Throw -ExpectedMessage "*VMID 101*node 'pve1'*can't lock file*"
        }

        It 'fails with node and VMID when the destroy task reports no exit status in time' {
            $script:destroyRemovesVm = $false
            Mock -CommandName Wait-LWProxmoxTasksStatus -ParameterFilter { $Upid -like 'UPID:destroy:*' }

            { Remove-LWProxmoxVM -Name 'VM1' } | Should -Throw -ExpectedMessage "*VMID 101*node 'pve1'*no exit status within 600 seconds*"
        }

        It 'fails when a fresh lookup still lists the VM after its destroy task reported OK' {
            $script:destroyRemovesVm = $false

            { Remove-LWProxmoxVM -Name 'VM1' } | Should -Throw -ExpectedMessage "*VMID 101*still listed on node 'pve1'*OK*"
        }

        It 'accepts a destroy task with warnings when the VM is gone afterwards' {
            Mock -CommandName Wait-LWProxmoxTasksStatus -ParameterFilter { $Upid -like 'UPID:destroy:*' } -MockWith { 'WARNINGS: 1' }

            $outcome = Remove-LWProxmoxVM -Name 'VM1'

            $outcome.Outcome | Should -Be 'Removed'
            Should -Invoke -CommandName Write-ScreenInfo -Times 1 -Exactly -ParameterFilter { $Type -eq 'Warning' -and $Message -like '*WARNINGS: 1*' }
        }

        It 'continues after a stop task with warnings when the VM is stopped' {
            Mock -CommandName Wait-LWProxmoxTasksStatus -ParameterFilter { $Upid -like 'UPID:stop:*' } -MockWith { 'WARNINGS: 1' }

            $outcome = Remove-LWProxmoxVM -Name 'VM1'

            $outcome.Outcome | Should -Be 'Removed'
        }

        It 'fails after a stop task with warnings when the VM still runs' {
            $script:stopStopsVm = $false
            Mock -CommandName Wait-LWProxmoxTasksStatus -ParameterFilter { $Upid -like 'UPID:stop:*' } -MockWith { 'WARNINGS: 1' }

            { Remove-LWProxmoxVM -Name 'VM1' } | Should -Throw -ExpectedMessage "*VMID 101*node 'pve1'*WARNINGS: 1*"

            Should -Invoke -CommandName Remove-PveQemu -Times 0 -Exactly
        }
    }

    Context 'When the VM is running' {
        It 'stops the VM before destroying it' {
            $null = Remove-LWProxmoxVM -Name 'VM1'

            $script:calls -join ', ' | Should -Be 'stop 101, destroy pve1 101'
        }
    }

    Context 'When the VM is stopped' {
        It 'destroys the VM without stopping it first' {
            $script:runningVm.status = 'stopped'

            $null = Remove-LWProxmoxVM -Name 'VM1'

            $script:calls -join ', ' | Should -Be 'destroy pve1 101'
        }
    }

    Context 'After a successful removal' {
        It 'returns exactly one Removed outcome with node and VMID' {
            $output = @(Remove-LWProxmoxVM -Name 'VM1')

            $output | Should -HaveCount 1
            $output[0].Outcome | Should -Be 'Removed'
            $output[0].Node | Should -Be 'pve1'
            $output[0].VmId | Should -Be 101
        }

        It 'drops the cache entry of the node the VM was removed from' {
            $script:proxmoxVmCache = @{
                pve1 = @($script:runningVm)
                pve2 = @()
            }

            $null = Remove-LWProxmoxVM -Name 'VM1'

            $script:proxmoxVmCache.ContainsKey('pve1') | Should -Be $false
            $script:proxmoxVmCache.ContainsKey('pve2') | Should -Be $true
        }
    }

    Context 'When the lookup itself fails' {
        It 'ends the removal even when no try block encloses the call' {
            # Under -ErrorAction SilentlyContinue PowerShell swallows a plain throw unless a try block
            # encloses it. Pester runs every test inside one, so the scenario needs its own runspace.
            $functionPath = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker\functions\ProxmoxWorkerVirtualMachines\Remove-LWProxmoxVM.ps1'
            $runspaceScript = {
                param ($FunctionPath)

                . $FunctionPath
                function Get-LWProxmoxVM
                {
                    [CmdletBinding()]
                    param
                    (
                        [Alias('Name')]
                        [string[]]$ComputerName,
                        [switch]$NoCache
                    )

                    throw 'The Proxmox API did not answer'
                }
                function Write-LogFunctionEntry {}
                function Write-LogFunctionExit {}
                function Write-ScreenInfo
                {
                    param
                    (
                        [string]$Message,
                        [string]$Type
                    )
                }

                Remove-LWProxmoxVM -Name 'VM1'
            }

            $powershell = [powershell]::Create()
            try
            {
                $null = $powershell.AddScript($runspaceScript.ToString()).AddArgument($functionPath)

                { $powershell.Invoke() } | Should -Throw -ExpectedMessage '*The Proxmox API did not answer*'
            }
            finally
            {
                $powershell.Dispose()
            }
        }
    }
}
