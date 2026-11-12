Describe 'Remove-LWProxmoxIsoImage' {
    BeforeAll {
        $workerRoot = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker'
        . (Join-Path $workerRoot 'functions\ProxmoxWorkerVirtualMachines\Remove-LWProxmoxIsoImage.ps1')

        function Test-LabProxmoxConnection {}
        function Get-LWProxmoxIsoImage {}
        function Invoke-LWProxmoxCallWithRetry { param([scriptblock]$ScriptBlock, [string]$ActivityName) }
        function Remove-PveNodesStorageContent {}
        function Wait-LWProxmoxTasksStatus {}
        function Write-LogFunctionEntry {}
        function Write-LogFunctionExit {}
        function Write-PSFMessage { param([string]$Message, [string]$Level) }
        function Write-ScreenInfo { param([string]$Message, [string]$Type) }
    }

    BeforeEach {
        Mock -CommandName Test-LabProxmoxConnection -MockWith { $true }
        Mock -CommandName Wait-LWProxmoxTasksStatus -MockWith { 'OK' }
        Mock -CommandName Write-LogFunctionEntry
        Mock -CommandName Write-LogFunctionExit
        Mock -CommandName Write-PSFMessage
        Mock -CommandName Write-ScreenInfo
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            [pscustomobject]@{ StatusCode = 200; Response = [pscustomobject]@{ data = 'UPID:pve1:test' } }
        }
        Mock -CommandName Get-LWProxmoxIsoImage -MockWith {
            [pscustomobject]@{ Node = 'pve1'; Storage = 'local'; VolId = 'local:iso/sample.iso'; FileName = 'sample.iso' }
        }
    }

    It 'throws when there is no connection to the cluster' {
        Mock -CommandName Test-LabProxmoxConnection -MockWith { $false }
        { Remove-LWProxmoxIsoImage -Node 'pve1' -IsoFile 'sample.iso' -Force -ErrorAction Stop } |
            Should -Throw -ExpectedMessage '*no connection*'
    }

    It 'throws when the VolId is not a valid ISO volume identifier' {
        { Remove-LWProxmoxIsoImage -Node 'pve1' -VolId 'local:vztmpl/foo.tar.gz' -Force -ErrorAction Stop } |
            Should -Throw -ExpectedMessage '*not a valid ISO volume identifier*'
    }

    It 'throws when the ISO file is not found' {
        Mock -CommandName Get-LWProxmoxIsoImage -MockWith { }
        { Remove-LWProxmoxIsoImage -Node 'pve1' -IsoFile 'missing.iso' -Storage 'local' -Force -ErrorAction Stop } |
            Should -Throw -ExpectedMessage '*was not found*'
    }

    It 'deletes an ISO resolved by file name and returns a PassThru object' {
        $result = Remove-LWProxmoxIsoImage -Node 'pve1' -IsoFile 'sample.iso' -Storage 'local' -Force -PassThru

        $result.VolId | Should -Be 'local:iso/sample.iso'
        $result.Deleted | Should -BeTrue
        Should -Invoke -CommandName Invoke-LWProxmoxCallWithRetry -Times 1 -Exactly
        Should -Invoke -CommandName Wait-LWProxmoxTasksStatus -Times 1 -Exactly
    }

    It 'deletes an ISO addressed directly by VolId without querying storage' {
        Remove-LWProxmoxIsoImage -Node 'pve1' -VolId 'cephfs:iso/win.iso' -Force

        Should -Not -Invoke -CommandName Get-LWProxmoxIsoImage
        Should -Invoke -CommandName Invoke-LWProxmoxCallWithRetry -Times 1 -Exactly
    }

    It 'throws when the delete API call returns a non-200 status' {
        Mock -CommandName Invoke-LWProxmoxCallWithRetry -MockWith {
            [pscustomobject]@{ StatusCode = 500; ReasonPhrase = 'Internal Server Error'; Response = $null }
        }
        { Remove-LWProxmoxIsoImage -Node 'pve1' -IsoFile 'sample.iso' -Storage 'local' -Force -ErrorAction Stop } |
            Should -Throw -ExpectedMessage '*Failed to delete*'
    }

    It 'does not prompt for confirmation when -Force is used' {
        # -Force must suppress the High-impact ShouldProcess confirmation; otherwise
        # this call would block on a prompt. A clean return proves the suppression.
        { Remove-LWProxmoxIsoImage -Node 'pve1' -VolId 'local:iso/sample.iso' -Force } | Should -Not -Throw
        Should -Invoke -CommandName Invoke-LWProxmoxCallWithRetry -Times 1 -Exactly
    }
}
