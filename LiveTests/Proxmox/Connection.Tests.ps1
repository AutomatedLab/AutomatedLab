param
(
    [hashtable]$LiveTest
)

# Read-only checks of the connection the runner made. Needs the data from Invoke-ProxmoxLiveTest.ps1; without it
# every test is skipped.

Describe 'Proxmox connection' -Tag 'ProxmoxLive', 'ReadOnly' -Skip:(-not ($LiveTest -and $LiveTest.Ready)) {
    It 'has an active, authenticated API connection' {
        Test-LabProxmoxConnection | Should -Be $true
    }

    It 'reports the Proxmox version' {
        $reply = Get-PveVersion

        $reply.StatusCode | Should -Be 200
        $reply.Response.data.version | Should -Not -BeNullOrEmpty
    }

    It 'lists at least one node that can host a VM' {
        @(Get-LWProxmoxNode).Count | Should -BeGreaterThan 0
    }

    It 'lists the node of every template selected for the run' {
        $nodes = @(Get-LWProxmoxNode | ForEach-Object { [string]$_.node })

        foreach ($template in $LiveTest.Templates)
        {
            $nodes | Should -Contain $template.Node -Because "the template '$($template.Name)' lives on node '$($template.Node)'"
        }
    }

    It 'lists a storage that can hold VM disks' {
        $reply = Get-PveStorage

        $reply.StatusCode | Should -Be 200
        @($reply.Response.data | Where-Object { $_.content -match '\bimages\b' }).Count | Should -BeGreaterThan 0
    }
}
