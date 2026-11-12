Describe 'Dynamics role tests of AutomatedLabTest' {
    BeforeAll {
        # Pester does not run inside a running Pester test, so each discovery gets a process of its own.
        function Invoke-RoleTestDiscovery
        {
            param
            (
                [string[]]$DynamicsVm
            )

            $testFolder = Join-Path $PSScriptRoot '..\..\..\AutomatedLabTest\tests'
            $files = foreach ($role in 'DynamicsAdmin', 'DynamicsBackend', 'DynamicsFrontend', 'DynamicsFull')
            {
                "'{0}'" -f (Join-Path $testFolder "$role.tests.ps1").Replace("'", "''")
            }
            $vms = foreach ($name in $DynamicsVm)
            {
                "'$name'"
            }

            $childScript = @'
function global:Get-Lab { [pscustomobject]@{ Name = 'TestLab'; Machines = @() } }
function global:Get-LabVM { param ([string]$Role) foreach ($name in @(__VMS__)) { $name } }
Import-Module Pester -MinimumVersion 5.3.0
$configuration = New-PesterConfiguration
$configuration.Run.Path = @(__FILES__)
$configuration.Run.SkipRun = $true
$configuration.Run.PassThru = $true
$configuration.Output.Verbosity = 'None'
$result = Invoke-Pester -Configuration $configuration
'FAILED-CONTAINERS=' + $result.FailedContainersCount
'URL-TESTS=' + @($result.Tests | Where-Object { $_.ExpandedName -like '*should reach its Dynamics URL' }).Count
'@
            $childScript = $childScript.Replace('__FILES__', ($files -join ', ')).Replace('__VMS__', ($vms -join ', '))
            $encodedScript = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childScript))
            $powershellPath = (Get-Process -Id $PID).Path

            & $powershellPath -NoProfile -NonInteractive -EncodedCommand $encodedScript 2>&1 | ForEach-Object { "$_" }
        }
    }

    It 'discovers the tests without an error on a lab without Dynamics machines' {
        $output = Invoke-RoleTestDiscovery -DynamicsVm @()

        $output | Should -Contain 'FAILED-CONTAINERS=0' -Because ($output -join [Environment]::NewLine)
        $output | Should -Contain 'URL-TESTS=0'
    }

    It 'creates one URL test per Dynamics machine in each of the four files' {
        $output = Invoke-RoleTestDiscovery -DynamicsVm 'DYN1', 'DYN2'

        $output | Should -Contain 'FAILED-CONTAINERS=0' -Because ($output -join [Environment]::NewLine)
        $output | Should -Contain 'URL-TESTS=8'
    }
}
