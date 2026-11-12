Describe 'Wait-LWProxmoxWindowsImageStateComplete' {
    BeforeAll {
        $functionRoot = Join-Path $PSScriptRoot (
            '..\..\..\AutomatedLabWorker\functions\Internals'
        )
        . (Join-Path $functionRoot 'Get-LWProxmoxWindowsImageState.ps1')
        . (Join-Path $functionRoot 'Wait-LWProxmoxWindowsImageStateComplete.ps1')

        function Write-PSFMessage {
            param
            (
                [string]$Message,
                [string]$Level
            )
        }
    }

    It 'returns $true immediately when the first read is IMAGE_STATE_COMPLETE' {
        Mock -CommandName Get-LWProxmoxWindowsImageState -MockWith { 'IMAGE_STATE_COMPLETE' }
        Mock -CommandName Start-Sleep

        $result = Wait-LWProxmoxWindowsImageStateComplete -Node 'pve1' -Vmid 101 -TimeoutSeconds 30 -PollIntervalSeconds 1

        $result | Should -BeTrue
        Should -Invoke -CommandName Get-LWProxmoxWindowsImageState -Times 1 -Exactly
        Should -Invoke -CommandName Start-Sleep -Times 0 -Exactly
    }

    It 'keeps polling while IMAGE_STATE_UNDEPLOYABLE and returns $false after the timeout' {
        Mock -CommandName Get-LWProxmoxWindowsImageState -MockWith { 'IMAGE_STATE_UNDEPLOYABLE' }

        $result = Wait-LWProxmoxWindowsImageStateComplete -Node 'pve1' -Vmid 101 -TimeoutSeconds 2 -PollIntervalSeconds 1

        $result | Should -BeFalse
        Should -Invoke -CommandName Get-LWProxmoxWindowsImageState -Times 2
    }
}
