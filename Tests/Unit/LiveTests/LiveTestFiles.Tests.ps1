BeforeDiscovery {
    $repositoryRoot = (Resolve-Path -Path (Join-Path $PSScriptRoot '..\..\..')).Path
    $liveFiles = @(Get-ChildItem -LiteralPath (Join-Path $repositoryRoot 'LiveTests') -Recurse -Filter '*.Tests.ps1' -File -ErrorAction SilentlyContinue)
    $liveFileCases = foreach ($file in $liveFiles)
    {
        @{ Name = $file.Name; Path = $file.FullName }
    }
}

Describe 'Live test files' {
    BeforeAll {
        $script:repositoryRoot = (Resolve-Path -Path (Join-Path $PSScriptRoot '..\..\..')).Path

        function Get-ParsedAst
        {
            param ([string]$Path)

            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        }
    }

    It 'include the Connection, Templates and GuestAgent suites for Proxmox' {
        $names = @(Get-ChildItem -LiteralPath (Join-Path $script:repositoryRoot 'LiveTests\Proxmox') -Filter '*.Tests.ps1' -File).Name

        $names | Should -Contain 'Connection.Tests.ps1'
        $names | Should -Contain 'Templates.Tests.ps1'
        $names | Should -Contain 'GuestAgent.Tests.ps1'
    }

    It 'stay outside the Tests folder that the normal build runs' {
        $build = Get-Content -LiteralPath (Join-Path $script:repositoryRoot '.build\03-validate.ps1') -Raw

        $build | Should -Match 'Run\.Path\s*=\s*"\$ProjectRoot\\Tests"'
        @(Get-ChildItem -LiteralPath (Join-Path $script:repositoryRoot 'Tests') -Recurse -File -Filter '*.Tests.ps1' |
                Select-String -Pattern '^\s*param\s*\(\s*\[hashtable\]\$LiveTest\s*\)') | Should -HaveCount 0
    }

    It 'are skipped without a failure when a plain Pester run reaches them' {
        $configuration = New-PesterConfiguration
        $configuration.Run.Path = Join-Path $script:repositoryRoot 'LiveTests\Proxmox'
        $configuration.Run.PassThru = $true
        $configuration.Output.Verbosity = 'None'

        $result = Invoke-Pester -Configuration $configuration

        $result.FailedContainersCount | Should -Be 0 -Because 'every suite must survive discovery when it gets no live-test data'
        $result.FailedCount | Should -Be 0
        $result.PassedCount | Should -Be 0 -Because 'no live test may run without live-test data'
        $result.SkippedCount | Should -BeGreaterThan 0
    }

    It '<Name> takes the LiveTest hashtable from the runner' -ForEach $liveFileCases {
        $ast = Get-ParsedAst -Path $Path

        $parameter = $ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'LiveTest' }

        $parameter | Should -Not -BeNullOrEmpty
        $parameter.StaticType.Name | Should -Be 'Hashtable'
    }

    It '<Name> skips every Describe unless the runner passed live-test data' -ForEach $liveFileCases {
        $ast = Get-ParsedAst -Path $Path

        $describes = @($ast.FindAll({
                    param ($node)
                    $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Describe'
                }, $true))

        $describes | Should -Not -BeNullOrEmpty
        foreach ($describe in $describes)
        {
            $skip = $describe.CommandElements |
                Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'Skip' }

            $skip | Should -Not -BeNullOrEmpty -Because "the Describe at line $($describe.Extent.StartLineNumber) must carry -Skip"
            $skip.Argument.Extent.Text | Should -BeLike '*LiveTest*Ready*'
        }
    }

    It '<Name> never connects to Proxmox or handles a secret itself' -ForEach $liveFileCases {
        $content = Get-Content -LiteralPath $Path -Raw

        $content | Should -Not -Match 'Connect-LabProxmoxCluster|Connect-PveCluster|ConvertFrom-ProxmoxLiveTestSecureString|Get-Credential|Read-Host'
    }

    It '<Name> parses without errors' -ForEach $liveFileCases {
        $tokens = $null
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)

        $errors | Should -HaveCount 0
    }
}
