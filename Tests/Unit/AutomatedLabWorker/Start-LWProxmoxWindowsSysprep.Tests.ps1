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
}