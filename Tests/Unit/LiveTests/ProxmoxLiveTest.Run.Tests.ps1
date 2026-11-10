BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\..\LiveTests\Proxmox\ProxmoxLiveTest.Support.ps1')
}

Describe 'Invoke-ProxmoxLiveTestRun' {
    BeforeAll {
        $script:testRoot = Join-Path $TestDrive 'live'
        New-Item -ItemType Directory -Path $script:testRoot | Out-Null
        foreach ($suiteName in 'Connection', 'Templates', 'GuestAgent')
        {
            Set-Content -LiteralPath (Join-Path $script:testRoot "$suiteName.Tests.ps1") -Value '# dummy suite'
        }
        Set-Content -LiteralPath (Join-Path $script:testRoot 'ProxmoxLiveTest.Support.ps1') -Value '# not a suite'

        $script:token = ConvertTo-SecureString -String 'root@pam!live=topsecret-token' -AsPlainText -Force
    }

    BeforeEach {
        $script:calls = [System.Collections.Generic.List[string]]::new()
        $script:capturedConfiguration = $null
        $script:modulePathDuringImport = $null
        $script:runner = {
            param ($Configuration)

            $script:capturedConfiguration = $Configuration
            [pscustomobject]@{ Result = 'Passed'; FailedCount = 0; TotalCount = 3 }
        }
        $script:common = @{
            TestRoot       = $script:testRoot
            HostName       = '192.0.2.10'
            ApiToken       = $script:token
            NonInteractive = $true
            TestRunner     = $script:runner
        }
        $script:plan = [pscustomobject]@{
            HostName     = '192.0.2.10'
            Port         = 8006
            AuthType     = 'ApiToken'
            Principal    = 'root@pam!live'
            Ready        = $true
            Problems     = @()
            Selected     = @(
                [pscustomobject]@{ Name = 'S2025'; VmId = 196; Node = 'pve1'; Family = 'Server'; Release = '2025'; OsTag = 'windowsserver2025datacenterdesktopexperience'; Selection = 'newest server' }
                [pscustomobject]@{ Name = 'W11'; VmId = 197; Node = 'pve2'; Family = 'Client'; Release = '11'; OsTag = 'windows11enterprise'; Selection = 'newest client' }
            )
            Capabilities = @{ OutageHandling = $true }
            Leftovers    = @()
        }

        Mock -CommandName Test-ProxmoxLiveTestPrerequisite -MockWith {
            [pscustomobject]@{ Name = 'Pester'; Required = '5.3.0 or later'; Found = '5.7.1'; Ok = $true; Detail = '' }
        }
        Mock -CommandName Import-ProxmoxLiveTestModule -MockWith {
            $script:calls.Add('import')
            $script:modulePathDuringImport = $env:PSModulePath
        }
        Mock -CommandName Connect-ProxmoxLiveTestCluster -MockWith { $script:calls.Add('connect') }
        Mock -CommandName Get-ProxmoxLiveTestPlan -MockWith {
            $script:calls.Add('plan')
            $script:plan
        }
        Mock -CommandName Format-ProxmoxLiveTestPlan -MockWith { 'plan text' }
        Mock -CommandName Get-ProxmoxLiveTestLeftoverVm
        Mock -CommandName Remove-ProxmoxLiveTestVm -MockWith { [pscustomobject]@{ Name = $Vm.Name; Outcome = 'Removed' } }
    }

    Context 'When the input is wrong' {
        It 'fails on incomplete credentials before touching modules or the network' {
            $p = @{ TestRoot = $script:testRoot; HostName = 'pve1'; NonInteractive = $true; TestRunner = $script:runner }

            { Invoke-ProxmoxLiveTestRun @p } | Should -Throw -ExpectedMessage '*-Credential*-ApiToken*'

            Should -Invoke -CommandName Test-ProxmoxLiveTestPrerequisite -Times 0 -Exactly
            $script:calls | Should -HaveCount 0
        }

        It 'fails when the test folder does not exist' {
            $p = $script:common.Clone()
            $p.TestRoot = Join-Path $TestDrive 'missing'

            { Invoke-ProxmoxLiveTestRun @p } | Should -Throw -ExpectedMessage '*Test folder*not found*'
        }

        It 'fails when the module path does not exist' {
            $p = $script:common.Clone()
            $p.ModulePath = Join-Path $TestDrive 'missing-modules'

            { Invoke-ProxmoxLiveTestRun @p } | Should -Throw -ExpectedMessage '*-ModulePath*not found*'
        }

        It 'fails on an unknown suite and names the available ones' {
            $p = $script:common.Clone()
            $p.Suite = 'Nope'

            { Invoke-ProxmoxLiveTestRun @p } | Should -Throw -ExpectedMessage "*Unknown suite 'Nope'*Connection, GuestAgent, Templates*"
        }

        It 'stops before importing or connecting when a prerequisite is missing' {
            Mock -CommandName Test-ProxmoxLiveTestPrerequisite -MockWith {
                [pscustomobject]@{ Name = 'Corsinvest.ProxmoxVE.Api'; Required = 'any version'; Found = $null; Ok = $false; Detail = 'not found. Install it.' }
            }
            $p = $script:common.Clone()

            { Invoke-ProxmoxLiveTestRun @p } | Should -Throw -ExpectedMessage '*Corsinvest.ProxmoxVE.Api*not found*'

            $script:calls | Should -HaveCount 0
            $script:capturedConfiguration | Should -BeNullOrEmpty
        }
    }

    Context 'When the run is prepared' {
        It 'imports, connects and plans, then starts the tests' {
            $p = $script:common.Clone()

            $result = Invoke-ProxmoxLiveTestRun @p

            $script:calls | Should -Be @('import', 'connect', 'plan')
            $script:capturedConfiguration | Should -Not -BeNullOrEmpty
            $result.Mode | Should -Be 'Run'
            $result.Ready | Should -Be $true
            $result.Passed | Should -Be $true
        }

        It 'passes the plan on as it was asked for' {
            $p = $script:common.Clone()
            $p.TemplateCount = 1
            $p.MinimumTemplateCount = 1
            $p.Template = 'W11'

            $null = Invoke-ProxmoxLiveTestRun @p

            Should -Invoke -CommandName Get-ProxmoxLiveTestPlan -Times 1 -Exactly -ParameterFilter {
                $TemplateCount -eq 1 -and $MinimumTemplateCount -eq 1 -and $TemplateName -eq 'W11' -and $Connection.HostName -eq '192.0.2.10'
            }
        }

        It 'checks the preflight only and starts nothing with -PreflightOnly' {
            $p = $script:common.Clone()
            $p.PreflightOnly = $true

            $result = Invoke-ProxmoxLiveTestRun @p

            $result.Mode | Should -Be 'Preflight'
            $result.Ready | Should -Be $true
            $script:capturedConfiguration | Should -BeNullOrEmpty
            Should -Invoke -CommandName Remove-ProxmoxLiveTestVm -Times 0 -Exactly
        }

        It 'does not start the tests when the plan is not ready' {
            $script:plan.Ready = $false
            $script:plan.Problems = @('Found 1 usable template(s); at least 2 are required.')
            $p = $script:common.Clone()

            $result = Invoke-ProxmoxLiveTestRun @p -WarningVariable warnings -WarningAction SilentlyContinue

            $result.Ready | Should -Be $false
            $result.Mode | Should -Be 'Run'
            $script:capturedConfiguration | Should -BeNullOrEmpty
            ($warnings -join ' ') | Should -BeLike '*preflight*'
        }

        It 'puts the module path first while importing and restores it afterwards' {
            $moduleFolder = Join-Path $TestDrive 'modules'
            New-Item -ItemType Directory -Path $moduleFolder | Out-Null
            $before = $env:PSModulePath
            $p = $script:common.Clone()
            $p.ModulePath = $moduleFolder

            $null = Invoke-ProxmoxLiveTestRun @p

            $script:modulePathDuringImport | Should -BeLike "$moduleFolder$([System.IO.Path]::PathSeparator)*"
            $env:PSModulePath | Should -Be $before
        }
    }

    Context 'When the Pester run is configured' {
        It 'creates one container per suite file and ignores other scripts' {
            $p = $script:common.Clone()

            $null = Invoke-ProxmoxLiveTestRun @p

            $containers = @($script:capturedConfiguration.Run.Container.Value)
            $containers | Should -HaveCount 3
            $paths = @($containers | ForEach-Object { "$($_.Item)" })
            @($paths | Where-Object { $_ -like '*Support.ps1' }) | Should -HaveCount 0
            @($paths | Where-Object { $_ -like '*GuestAgent.Tests.ps1' }) | Should -HaveCount 1
        }

        It 'runs only the requested suites, matched regardless of case' {
            $p = $script:common.Clone()
            $p.Suite = 'guestagent'

            $null = Invoke-ProxmoxLiveTestRun @p

            $containers = @($script:capturedConfiguration.Run.Container.Value)
            $containers | Should -HaveCount 1
            "$($containers[0].Item)" | Should -BeLike '*GuestAgent.Tests.ps1'
        }

        It 'hands the plan to every suite as the LiveTest hashtable' {
            $p = $script:common.Clone()

            $null = Invoke-ProxmoxLiveTestRun @p

            $liveTest = @($script:capturedConfiguration.Run.Container.Value)[0].Data.LiveTest
            $liveTest.Ready | Should -Be $true
            $liveTest.RunId | Should -Match '^[0-9a-f]{8}$'
            $liveTest.Connection.HostName | Should -Be '192.0.2.10'
            $liveTest.Connection.Port | Should -Be 8006
            $liveTest.Connection.AuthType | Should -Be 'ApiToken'
            $liveTest.Connection.Principal | Should -Be 'root@pam!live'
            $liveTest.Capabilities.OutageHandling | Should -Be $true
            @($liveTest.Templates) | Should -HaveCount 2
            $liveTest.Templates[0].Name | Should -Be 'S2025'
            $liveTest.Templates[0].VmId | Should -Be 196
            $liveTest.Templates[0].VmName | Should -Be "allive-$($liveTest.RunId)-1"
            $liveTest.Templates[1].VmName | Should -Be "allive-$($liveTest.RunId)-2"
            $liveTest.Templates[0].VmName | Should -Match (Get-ProxmoxLiveTestSetting).VmNamePattern
        }

        It 'hands no secret to the tests' {
            $p = $script:common.Clone()

            $null = Invoke-ProxmoxLiveTestRun @p

            $data = @($script:capturedConfiguration.Run.Container.Value) | ForEach-Object { $_.Data }
            ($data | ConvertTo-Json -Depth 8) | Should -Not -BeLike '*topsecret*'
            ($data.LiveTest.Keys) | Should -Not -Contain 'ApiToken'
            ($data.LiveTest.Keys) | Should -Not -Contain 'Credential'
        }

        It 'forwards the clone options' {
            $p = $script:common.Clone()
            $p.FullClone = $true
            $p.Storage = 'local-zfs'
            $p.KeepVm = $true

            $null = Invoke-ProxmoxLiveTestRun @p

            $options = @($script:capturedConfiguration.Run.Container.Value)[0].Data.LiveTest.Options
            $options.FullClone | Should -Be $true
            $options.Storage | Should -Be 'local-zfs'
            $options.KeepVm | Should -Be $true
            $options.SkipOutageTests | Should -Be $false
        }

        It 'excludes the Outage tag with -SkipOutageTests' {
            $p = $script:common.Clone()
            $p.SkipOutageTests = $true

            $null = Invoke-ProxmoxLiveTestRun @p

            @($script:capturedConfiguration.Filter.ExcludeTag.Value) | Should -Contain 'Outage'
            @($script:capturedConfiguration.Run.Container.Value)[0].Data.LiveTest.Options.SkipOutageTests | Should -Be $true
        }

        It 'excludes nothing by default' {
            $p = $script:common.Clone()

            $null = Invoke-ProxmoxLiveTestRun @p

            @($script:capturedConfiguration.Filter.ExcludeTag.Value) | Should -Not -Contain 'Outage'
        }

        It 'asks for the detailed output and the result object' {
            $p = $script:common.Clone()

            $null = Invoke-ProxmoxLiveTestRun @p

            $script:capturedConfiguration.Output.Verbosity.Value | Should -Be 'Detailed'
            $script:capturedConfiguration.Run.PassThru.Value | Should -Be $true
        }

        It 'writes an NUnit result file when asked' {
            $p = $script:common.Clone()
            $p.TestResultPath = Join-Path $TestDrive 'result.xml'

            $null = Invoke-ProxmoxLiveTestRun @p

            $script:capturedConfiguration.TestResult.Enabled.Value | Should -Be $true
            $script:capturedConfiguration.TestResult.OutputPath.Value | Should -Be (Join-Path $TestDrive 'result.xml')
        }

        It 'reports a failed Pester run as not passed' {
            $p = $script:common.Clone()
            $p.TestRunner = { [pscustomobject]@{ Result = 'Failed'; FailedCount = 2; TotalCount = 9 } }

            $result = Invoke-ProxmoxLiveTestRun @p

            $result.Passed | Should -Be $false
            $result.PesterResult.FailedCount | Should -Be 2
        }
    }

    Context 'When the run has created VMs' {
        BeforeEach {
            Mock -CommandName Get-ProxmoxLiveTestLeftoverVm -MockWith {
                [pscustomobject]@{ name = "allive-$RunId-1"; vmid = 301; node = 'pve1' }
                [pscustomobject]@{ name = "allive-$RunId-2"; vmid = 302; node = 'pve2' }
            }
        }

        It 'removes the VMs of this run afterwards' {
            $p = $script:common.Clone()

            $result = Invoke-ProxmoxLiveTestRun @p

            Should -Invoke -CommandName Get-ProxmoxLiveTestLeftoverVm -Times 1 -Exactly -ParameterFilter { $RunId -match '^[0-9a-f]{8}$' }
            Should -Invoke -CommandName Remove-ProxmoxLiveTestVm -Times 2 -Exactly
            @($result.Removed) | Should -HaveCount 2
        }

        It 'removes them even when the test runner fails' {
            $p = $script:common.Clone()
            $p.TestRunner = { throw 'runner exploded' }

            { Invoke-ProxmoxLiveTestRun @p } | Should -Throw -ExpectedMessage '*runner exploded*'

            Should -Invoke -CommandName Remove-ProxmoxLiveTestVm -Times 2 -Exactly
        }

        It 'keeps the VMs with -KeepVm and says which ones' {
            $p = $script:common.Clone()
            $p.KeepVm = $true

            $result = Invoke-ProxmoxLiveTestRun @p -InformationVariable information

            Should -Invoke -CommandName Remove-ProxmoxLiveTestVm -Times 0 -Exactly
            @($result.Kept) | Should -HaveCount 2
            ($information -join ' ') | Should -BeLike '*allive-*'
        }

        It 'warns instead of failing when a VM cannot be removed' {
            Mock -CommandName Remove-ProxmoxLiveTestVm -MockWith { throw 'destroy task failed' }
            $p = $script:common.Clone()

            $result = Invoke-ProxmoxLiveTestRun @p -WarningVariable warnings -WarningAction SilentlyContinue

            $result.Passed | Should -Be $true
            ($warnings -join ' ') | Should -BeLike '*Could not remove*destroy task failed*-RemoveLeftovers*'
        }
    }

    Context 'When leftovers are removed' {
        BeforeEach {
            Mock -CommandName Get-ProxmoxLiveTestLeftoverVm -MockWith {
                [pscustomobject]@{ name = 'allive-0123abcd-1'; vmid = 301; node = 'pve1' }
                [pscustomobject]@{ name = 'allive-89abcdef-1'; vmid = 304; node = 'pve1' }
            }
        }

        It 'removes the leftovers of earlier runs and starts no test' {
            $p = $script:common.Clone()
            $p.RemoveLeftovers = $true

            $result = Invoke-ProxmoxLiveTestRun @p -Confirm:$false

            $result.Mode | Should -Be 'RemoveLeftovers'
            @($result.Found) | Should -HaveCount 2
            Should -Invoke -CommandName Remove-ProxmoxLiveTestVm -Times 2 -Exactly
            Should -Invoke -CommandName Get-ProxmoxLiveTestPlan -Times 0 -Exactly
            $script:capturedConfiguration | Should -BeNullOrEmpty
        }

        It 'removes nothing with -WhatIf' {
            $p = $script:common.Clone()
            $p.RemoveLeftovers = $true

            $result = Invoke-ProxmoxLiveTestRun @p -WhatIf

            @($result.Found) | Should -HaveCount 2
            Should -Invoke -CommandName Remove-ProxmoxLiveTestVm -Times 0 -Exactly
        }

        It 'reports that there is nothing to remove' {
            Mock -CommandName Get-ProxmoxLiveTestLeftoverVm
            $p = $script:common.Clone()
            $p.RemoveLeftovers = $true

            $result = Invoke-ProxmoxLiveTestRun @p -Confirm:$false

            $result.Mode | Should -Be 'RemoveLeftovers'
            @($result.Found) | Should -HaveCount 0
            Should -Invoke -CommandName Remove-ProxmoxLiveTestVm -Times 0 -Exactly
        }
    }
}
