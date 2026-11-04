Describe 'Start-LWProxmoxWindowsSysprep' {
    It 'removes unprovisioned user AppX packages before starting unattended Sysprep' {
        $functionPath = Join-Path $PSScriptRoot (
            '..\..\..\AutomatedLabWorker\functions\ProxmoxWorkerVirtualMachines\' +
            'Start-LWProxmoxWindowsSysprep.ps1'
        )

        Test-Path -LiteralPath $functionPath | Should -BeTrue
        $agentExecutionPath = Join-Path (Split-Path $functionPath) (
            'Start-LWProxmoxAgentExecutionOnVM.ps1'
        )
        . $agentExecutionPath
        . $functionPath

        $script:operations = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Start-LWProxmoxAgentExecutionOnVM -MockWith {
            $script:operations.Add([pscustomobject]@{
                Command      = $Command
                ComputerName = $ComputerName
                Wait         = $Wait.IsPresent
            })
        }

        Start-LWProxmoxWindowsSysprep -ComputerName 'Client2'

        Should -Invoke -CommandName Start-LWProxmoxAgentExecutionOnVM -Times 2 -Exactly
        $script:operations | Should -HaveCount 2
        $script:operations[0].ComputerName | Should -Be 'Client2'
        $script:operations[0].Wait | Should -BeTrue
        $script:operations[0].Command | Should -Match '^powershell\.exe -NoProfile -NonInteractive -EncodedCommand '

        $encodedCommand = $script:operations[0].Command -replace '^.*-EncodedCommand\s+', ''
        $guestScript = [Text.Encoding]::Unicode.GetString(
            [Convert]::FromBase64String($encodedCommand)
        )

        $guestScript | Should -Match 'Get-AppxProvisionedPackage -Online'
        $guestScript | Should -Match 'Get-AppxPackage -AllUsers'
        $guestScript | Should -Match '\$_.DisplayName, \$_.PublisherId, \$_.Version'
        $guestScript | Should -Match '\$_.Name, \$_.PublisherId, \$_.Version'
        $guestScript | Should -Match 'PackageUserInformation'
        $guestScript | Should -Match "InstallState -eq 'Installed'"
        $guestScript | Should -Match '\$packageIdentity -notin \$provisionedPackageIdentities'
        $guestScript | Should -Match '-not \$_.IsFramework'
        $guestScript | Should -Match '-not \$_.NonRemovable'
        $guestScript | Should -Match 'Remove-AppxPackage.+-AllUsers'
        $guestScript | Should -Not -Match 'sysprep\.exe'

        $script:operations[1].ComputerName | Should -Be 'Client2'
        $script:operations[1].Wait | Should -BeFalse
        $script:operations[1].Command | Should -Match (
            'sysprep\.exe.+/generalize.+/oobe.+/reboot.+/unattend:C:\\Unattend\.xml'
        )
    }

    It 'removes a user AppX package when its version differs from the provisioned version' {
        $functionRoot = Join-Path $PSScriptRoot (
            '..\..\..\AutomatedLabWorker\functions\ProxmoxWorkerVirtualMachines'
        )
        . (Join-Path $functionRoot 'Start-LWProxmoxAgentExecutionOnVM.ps1')
        . (Join-Path $functionRoot 'Start-LWProxmoxWindowsSysprep.ps1')

        $script:operations = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Start-LWProxmoxAgentExecutionOnVM -MockWith {
            $script:operations.Add([pscustomobject]@{
                Command = $Command
                Wait    = $Wait.IsPresent
            })
        }

        Start-LWProxmoxWindowsSysprep -ComputerName 'Client2'
        $encodedCommand = $script:operations[0].Command -replace '^.*-EncodedCommand\s+', ''
        $guestScript = [Text.Encoding]::Unicode.GetString(
            [Convert]::FromBase64String($encodedCommand)
        )

        function Get-AppxProvisionedPackage {
            [CmdletBinding()]
            param([switch]$Online)

            [pscustomobject]@{
                DisplayName = 'Contoso.UpdatedApp'
                PublisherId = 'contoso'
                Version     = [version]'1.0.0.0'
            }
            [pscustomobject]@{
                DisplayName = 'Contoso.StableApp'
                PublisherId = 'contoso'
                Version     = [version]'1.0.0.0'
            }
        }
        function Get-AppxPackage {
            [CmdletBinding()]
            param([switch]$AllUsers)

            [pscustomobject]@{
                Name            = 'Contoso.UpdatedApp'
                PublisherId     = 'contoso'
                Version         = [version]'2.0.0.0'
                PackageFullName = 'Contoso.UpdatedApp_2.0.0.0_x64__contoso'
                IsFramework     = $false
                NonRemovable    = $false
                PackageUserInformation = @(
                    [pscustomobject]@{ InstallState = 'Installed' }
                )
            }
            [pscustomobject]@{
                Name            = 'Contoso.StableApp'
                PublisherId     = 'contoso'
                Version         = [version]'1.0.0.0'
                PackageFullName = 'Contoso.StableApp_1.0.0.0_x64__contoso'
                IsFramework     = $false
                NonRemovable    = $false
                PackageUserInformation = @(
                    [pscustomobject]@{ InstallState = 'Installed' }
                )
            }
            [pscustomobject]@{
                Name            = 'Contoso.StagedApp'
                PublisherId     = 'contoso'
                Version         = [version]'2.0.0.0'
                PackageFullName = 'Contoso.StagedApp_2.0.0.0_x64__contoso'
                IsFramework     = $false
                NonRemovable    = $false
                PackageUserInformation = @(
                    [pscustomobject]@{ InstallState = 'Staged' }
                )
            }
            [pscustomobject]@{
                Name            = 'Contoso.BrokenApp'
                PublisherId     = 'contoso'
                Version         = [version]'2.0.0.0'
                PackageFullName = 'Contoso.BrokenApp_2.0.0.0_x64__contoso'
                IsFramework     = $false
                NonRemovable    = $false
                PackageUserInformation = @(
                    [pscustomobject]@{ InstallState = 'Installed' }
                )
            }
        }
        function Remove-AppxPackage {
            [CmdletBinding()]
            param(
                [string]$Package,
                [switch]$AllUsers
            )

            $script:attemptedPackages.Add($Package)
            if ($Package -like 'Contoso.BrokenApp_*') {
                $message = 'Deployment DeStage failed with error 0x80070002.'
                throw [Runtime.InteropServices.COMException]::new($message, -2147009286)
            }
            $script:removedPackages.Add($Package)
        }

        $script:attemptedPackages = [System.Collections.Generic.List[string]]::new()
        $script:removedPackages = [System.Collections.Generic.List[string]]::new()
        & ([scriptblock]::Create($guestScript))

        $script:attemptedPackages | Should -Be @(
            'Contoso.UpdatedApp_2.0.0.0_x64__contoso'
            'Contoso.BrokenApp_2.0.0.0_x64__contoso'
        )
        $script:removedPackages | Should -Be @(
            'Contoso.UpdatedApp_2.0.0.0_x64__contoso'
        )

        function Get-AppxPackage {
            [CmdletBinding()]
            param([switch]$AllUsers)

            [pscustomobject]@{
                Name            = 'Contoso.FatalApp'
                PublisherId     = 'contoso'
                Version         = [version]'2.0.0.0'
                PackageFullName = 'Contoso.FatalApp_2.0.0.0_x64__contoso'
                IsFramework     = $false
                NonRemovable    = $false
                PackageUserInformation = @(
                    [pscustomobject]@{ InstallState = 'Installed' }
                )
            }
        }
        function Remove-AppxPackage {
            [CmdletBinding()]
            param(
                [string]$Package,
                [switch]$AllUsers
            )

            $message = 'Deployment failed with error 0x80070005.'
            throw [Runtime.InteropServices.COMException]::new($message, -2147009286)
        }

        {
            & ([scriptblock]::Create($guestScript))
        } | Should -Throw -ExpectedMessage '*0x80070005*'
    }

    It 'does not start Sysprep after cleanup execution fails' {
        $functionRoot = Join-Path $PSScriptRoot (
            '..\..\..\AutomatedLabWorker\functions\ProxmoxWorkerVirtualMachines'
        )
        . (Join-Path $functionRoot 'Start-LWProxmoxAgentExecutionOnVM.ps1')
        . (Join-Path $functionRoot 'Start-LWProxmoxWindowsSysprep.ps1')

        Mock -CommandName Start-LWProxmoxAgentExecutionOnVM -MockWith {
            if ($Wait.IsPresent) {
                throw 'cleanup failed'
            }
        }

        {
            Start-LWProxmoxWindowsSysprep -ComputerName 'Client2'
        } | Should -Throw -ExpectedMessage '*cleanup failed*'

        Should -Invoke -CommandName Start-LWProxmoxAgentExecutionOnVM -Times 1 -Exactly
        Should -Invoke -CommandName Start-LWProxmoxAgentExecutionOnVM -Times 0 -Exactly -ParameterFilter {
            -not $Wait.IsPresent
        }
    }

    It 'throws when the Sysprep process cannot be started' {
        $functionRoot = Join-Path $PSScriptRoot (
            '..\..\..\AutomatedLabWorker\functions\ProxmoxWorkerVirtualMachines'
        )
        . (Join-Path $functionRoot 'Start-LWProxmoxAgentExecutionOnVM.ps1')
        . (Join-Path $functionRoot 'Start-LWProxmoxWindowsSysprep.ps1')

        Mock -CommandName Start-LWProxmoxAgentExecutionOnVM -MockWith {
            if (-not $Wait.IsPresent) {
                Write-Error 'Sysprep launch failed'
            }
        }

        {
            Start-LWProxmoxWindowsSysprep -ComputerName 'Client2'
        } | Should -Throw -ExpectedMessage '*Sysprep launch failed*'

        Should -Invoke -CommandName Start-LWProxmoxAgentExecutionOnVM -Times 2 -Exactly
    }

    Context 'When the cleanup result is lost' {
        BeforeAll {
            $functionRoot = Join-Path $PSScriptRoot (
                '..\..\..\AutomatedLabWorker\functions\ProxmoxWorkerVirtualMachines'
            )
            . (Join-Path $functionRoot 'Start-LWProxmoxAgentExecutionOnVM.ps1')
            . (Join-Path $functionRoot 'Start-LWProxmoxWindowsSysprep.ps1')

            function Get-LWProxmoxVM {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
                [CmdletBinding()]
                param
                (
                    [string[]]$ComputerName
                )
            }
            function Wait-LWProxmoxGuestAgentReady {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
                [CmdletBinding()]
                param
                (
                    [string]$Node,
                    [int]$Vmid,
                    [string]$Name,
                    [int]$TimeoutSeconds,
                    [int]$PollIntervalSeconds,
                    [switch]$RequireExec
                )
            }
            function Get-LabConfigurationItem {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
                param
                (
                    [string]$Name,
                    $Default
                )
            }
            function Write-PSFMessage {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
                param
                (
                    [string]$Level,
                    [string]$Message
                )
            }
        }

        BeforeEach {
            $script:operations = [System.Collections.Generic.List[string]]::new()
            $script:cleanupOutcomes = [System.Collections.Generic.Queue[string]]::new()
            $script:vmIds = @{ Client1 = 101; Client2 = 102 }
            $script:agentReady = $true

            Mock -CommandName Get-LWProxmoxVM -MockWith {
                [pscustomobject]@{
                    Name = $ComputerName[0]
                    node = 'pve1'
                    VmId = $script:vmIds[$ComputerName[0]]
                }
            }
            Mock -CommandName Wait-LWProxmoxGuestAgentReady -MockWith {
                $script:operations.Add("wait:$Name")
                $script:agentReady
            }
            Mock -CommandName Get-LabConfigurationItem -MockWith {
                switch ($Name)
                {
                    'ProxmoxAgentCleanupRetries' { 2 }
                    'ProxmoxAgentExecTimeout' { 300 }
                }
            }
            Mock -CommandName Write-PSFMessage
            Mock -CommandName Start-LWProxmoxAgentExecutionOnVM -MockWith {
                if (-not $Wait.IsPresent)
                {
                    $script:operations.Add("sysprep:$($ComputerName -join ',')")
                    return
                }

                $script:operations.Add("cleanup:$($ComputerName -join ',')")
                $outcome = 'ok'
                if ($script:cleanupOutcomes.Count -gt 0)
                {
                    $outcome = $script:cleanupOutcomes.Dequeue()
                }
                switch ($outcome)
                {
                    'lost' {
                        Write-Error -Message "The result of the command on VM '$($ComputerName[0])' was lost." -ErrorId 'ProxmoxAgentCommandResultLost' -Category ResourceUnavailable -ErrorAction Stop
                    }
                    'exit' {
                        Write-Error -Message "Command on VM '$($ComputerName[0])' failed with exit code 5. AppX cleanup failed" -ErrorAction Stop
                    }
                    'status' {
                        Write-Error -Message "Failed to retrieve command status on VM '$($ComputerName[0])'." -ErrorId 'ProxmoxAgentStatusQueryFailed' -Category ConnectionError -ErrorAction Stop
                    }
                    'stopped' {
                        Write-Error -Message "Failed to retrieve command status on VM '$($ComputerName[0])': the VM is not running." -ErrorId 'ProxmoxAgentVmNotRunning' -Category ResourceUnavailable -ErrorAction Stop
                    }
                }
            }
        }

        It 'looks nothing up while the cleanup succeeds' {
            Start-LWProxmoxWindowsSysprep -ComputerName 'Client2'

            $script:operations | Should -Be @('cleanup:Client2', 'sysprep:Client2')
            Should -Invoke -CommandName Get-LWProxmoxVM -Times 0 -Exactly
            Should -Invoke -CommandName Get-LabConfigurationItem -Times 0 -Exactly
            Should -Invoke -CommandName Wait-LWProxmoxGuestAgentReady -Times 0 -Exactly
        }

        It 'waits for the guest agent and runs the cleanup again after its result was lost' {
            $script:cleanupOutcomes.Enqueue('lost')

            {
                Start-LWProxmoxWindowsSysprep -ComputerName 'Client2'
            } | Should -Not -Throw

            $script:operations | Should -Be @(
                'cleanup:Client2', 'wait:Client2', 'cleanup:Client2', 'sysprep:Client2'
            )
            Should -Invoke -CommandName Wait-LWProxmoxGuestAgentReady -Times 1 -Exactly -ParameterFilter {
                $Node -eq 'pve1' -and $Vmid -eq 102 -and $TimeoutSeconds -eq 300 -and $RequireExec
            }
            Should -Invoke -CommandName Write-PSFMessage -Times 1 -Exactly -ParameterFilter {
                $Level -eq 'Warning' -and $Message -like "*VM 'Client2'*lost its result*"
            }
        }

        It 'runs the cleanup again only for the VM whose result was lost and starts Sysprep once for all VMs' {
            $script:cleanupOutcomes.Enqueue('ok')
            $script:cleanupOutcomes.Enqueue('lost')

            Start-LWProxmoxWindowsSysprep -ComputerName 'Client1', 'Client2'

            $script:operations | Should -Be @(
                'cleanup:Client1', 'cleanup:Client2', 'wait:Client2', 'cleanup:Client2', 'sysprep:Client1,Client2'
            )
            Should -Invoke -CommandName Wait-LWProxmoxGuestAgentReady -Times 1 -Exactly -ParameterFilter {
                $Vmid -eq 102
            }
        }

        It 'does not run the cleanup again after another cleanup failure (<Outcome>)' -ForEach @(
            @{ Outcome = 'exit'; Message = '*exit code 5*AppX cleanup failed*' }
            @{ Outcome = 'status'; Message = '*Failed to retrieve command status*' }
            @{ Outcome = 'stopped'; Message = '*the VM is not running*' }
        ) {
            $script:cleanupOutcomes.Enqueue($Outcome)

            {
                Start-LWProxmoxWindowsSysprep -ComputerName 'Client2'
            } | Should -Throw -ExpectedMessage $Message

            $script:operations | Should -Be @('cleanup:Client2')
            Should -Invoke -CommandName Wait-LWProxmoxGuestAgentReady -Times 0 -Exactly
        }

        It 'fails without starting Sysprep when every run loses its cleanup result' {
            1..3 | ForEach-Object { $script:cleanupOutcomes.Enqueue('lost') }

            {
                Start-LWProxmoxWindowsSysprep -ComputerName 'Client2'
            } | Should -Throw -ExpectedMessage (
                "*VM 'Client2' lost its result on every run (runs: 3, " +
                're-runs allowed by ProxmoxAgentCleanupRetries: 2)*Sysprep was not started*'
            )

            $script:operations | Should -Be @(
                'cleanup:Client2', 'wait:Client2', 'cleanup:Client2', 'wait:Client2', 'cleanup:Client2'
            )
        }

        It 'fails without a second run when the guest agent does not run commands again' {
            $script:agentReady = $false
            $script:cleanupOutcomes.Enqueue('lost')

            {
                Start-LWProxmoxWindowsSysprep -ComputerName 'Client2'
            } | Should -Throw -ExpectedMessage (
                "*VM 'Client2'*did not run commands again within 300 seconds*Sysprep was not started*"
            )

            $script:operations | Should -Be @('cleanup:Client2', 'wait:Client2')
        }

        It 'does not run the cleanup again when ProxmoxAgentCleanupRetries is 0' {
            Mock -CommandName Get-LabConfigurationItem -MockWith {
                switch ($Name)
                {
                    'ProxmoxAgentCleanupRetries' { 0 }
                    'ProxmoxAgentExecTimeout' { 300 }
                }
            }
            $script:cleanupOutcomes.Enqueue('lost')

            {
                Start-LWProxmoxWindowsSysprep -ComputerName 'Client2'
            } | Should -Throw -ExpectedMessage (
                '*lost its result on every run (runs: 1, re-runs allowed by ProxmoxAgentCleanupRetries: 0)*'
            )

            $script:operations | Should -Be @('cleanup:Client2')
        }
    }
}