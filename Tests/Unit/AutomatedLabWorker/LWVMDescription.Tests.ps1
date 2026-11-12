Describe 'Get-LWVMDescription and Set-LWVMDescription' {
    BeforeAll {
        $functions = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker\functions\VirtualMachines'
        . (Join-Path $functions 'Get-LWVMDescription.ps1')
        . (Join-Path $functions 'Set-LWVMDescription.ps1')
    }

    It 'keeps the old name <OldName> working as an alias of <NewName>' -ForEach @(
        @{ OldName = 'Get-LWHypervVMDescription'; NewName = 'Get-LWVMDescription' }
        @{ OldName = 'Set-LWHypervVMDescription'; NewName = 'Set-LWVMDescription' }
    ) {
        # Get-Alias, unlike Get-Command, never imports an installed AutomatedLab module
        $alias = Get-Alias -Name $OldName -ErrorAction SilentlyContinue

        $alias | Should -Not -BeNullOrEmpty
        $alias.ResolvedCommandName | Should -Be $NewName
    }

    It 'exports <OldName> from the module manifest, so that callers outside the module find it' -ForEach @(
        @{ OldName = 'Get-LWHypervVMDescription' }
        @{ OldName = 'Set-LWHypervVMDescription' }
    ) {
        # The build rewrites the manifest and keeps only the aliases that the source manifest lists
        $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker\AutomatedLabWorker.psd1')

        $manifest.AliasesToExport | Should -Contain $OldName
    }
}
