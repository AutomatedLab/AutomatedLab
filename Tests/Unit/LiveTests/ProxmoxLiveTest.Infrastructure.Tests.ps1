BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\..\LiveTests\Proxmox\ProxmoxLiveTest.Support.ps1')

    # Stubs for everything outside the support file. The AutomatedLab and Proxmox modules are never loaded here.
    function Get-LWProxmoxVM
    {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        [CmdletBinding()]
        param ([string[]]$ComputerName, [object[]]$Node, [switch]$IncludeTemplates, [switch]$NoCache, [switch]$NoError)
    }
    function Get-LWProxmoxNode
    {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        [CmdletBinding()]
        param ([string[]]$Name)
    }
    function Remove-LWProxmoxVM
    {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        [CmdletBinding()]
        param ([string]$Name, [int]$VmId)
    }
    function Connect-LabProxmoxCluster
    {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        [CmdletBinding()]
        param ([string]$HostName, [int]$Port, [pscredential]$Credential, [string]$ApiToken)
    }
    function Test-LabProxmoxConnection
    {
        [CmdletBinding()]
        param ()
    }
    function Get-PveVersion
    {
        [CmdletBinding()]
        param ()
    }
    function Get-PveClusterNextid
    {
        [CmdletBinding()]
        param ()
    }
    function New-PveNodesQemuClone
    {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        [CmdletBinding()]
        param ([string]$Node, [int]$Vmid, [int]$Newid, [string]$Name, [string]$Description, [object]$Full, [string]$Storage)
    }
    function Get-PveNodesQemuConfig
    {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        [CmdletBinding()]
        param ([string]$Node, [int]$Vmid)
    }
    function Set-PveNodesQemuConfig
    {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        [CmdletBinding()]
        param ([string]$Node, [int]$Vmid, [string]$Tags, [string]$Delete)
    }
    function Start-PveVm
    {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        [CmdletBinding()]
        param ([string]$VmIdOrName)
    }
    function Get-PveNodesTasksStatus
    {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        [CmdletBinding()]
        param ([string]$Node, [string]$Upid)
    }

    function New-RawVm
    {
        param
        (
            [string]$Name = 'tpl',
            [string[]]$Tags = @('template'),
            [string]$Node = 'pve1',
            [int]$VmId = 100,
            [int]$Template = 1
        )

        [pscustomobject]@{
            name     = $Name
            vmid     = $VmId
            node     = $Node
            template = $Template
            tags     = $Tags
        }
    }

    function New-PveReply
    {
        param
        (
            [object]$Data,
            [int]$StatusCode = 200,
            [string]$ReasonPhrase = 'OK'
        )

        [pscustomobject]@{
            StatusCode   = $StatusCode
            ReasonPhrase = $ReasonPhrase
            Response     = [pscustomobject]@{ data = $Data }
        }
    }
}

Describe 'Test-ProxmoxLiveTestPrerequisite' {
    BeforeAll {
        $script:requiredNames = 'Pester', 'Corsinvest.ProxmoxVE.Api', 'PSFramework', 'PSLog', 'AutomatedLab.Common',
        'AutomatedLabCore', 'AutomatedLabWorker', 'AutomatedLabDefinition', 'AutomatedLabUnattended',
        'PSFileTransfer', 'AutomatedLabNotifications'
    }

    BeforeEach {
        $script:installed = @{}
        foreach ($moduleName in $script:requiredNames)
        {
            $script:installed[$moduleName] = @('1.0.0')
        }
        $script:installed['Pester'] = @('5.7.1')

        Mock -CommandName Get-Module -MockWith {
            foreach ($version in $script:installed[[string]$Name[0]])
            {
                [pscustomobject]@{ Name = [string]$Name[0]; Version = [version]$version }
            }
        }
    }

    It 'reports every requirement and passes when everything is installed' {
        $result = @(Test-ProxmoxLiveTestPrerequisite)

        ($result.Name | Sort-Object) | Should -Be ($script:requiredNames | Sort-Object)
        @($result | Where-Object { -not $_.Ok }) | Should -HaveCount 0
    }

    It 'requires Pester 5.3 or later' {
        $script:installed['Pester'] = @('3.4.0')

        $pester = Test-ProxmoxLiveTestPrerequisite | Where-Object Name -eq 'Pester'

        $pester.Ok | Should -Be $false
        $pester.Found | Should -Be '3.4.0'
        $pester.Detail | Should -BeLike '*Pester 5.3*'
    }

    It 'uses the newest installed version' {
        $script:installed['Pester'] = @('3.4.0', '6.1.0')

        $pester = Test-ProxmoxLiveTestPrerequisite | Where-Object Name -eq 'Pester'

        $pester.Ok | Should -Be $true
        $pester.Found | Should -Be '6.1.0'
    }

    It 'names the missing Proxmox API module and how to get it' {
        $script:installed['Corsinvest.ProxmoxVE.Api'] = @()

        $result = Test-ProxmoxLiveTestPrerequisite | Where-Object Name -eq 'Corsinvest.ProxmoxVE.Api'

        $result.Ok | Should -Be $false
        $result.Found | Should -BeNullOrEmpty
        $result.Detail | Should -BeLike '*Install-Module Corsinvest.ProxmoxVE.Api*'
    }

    It 'points to -ModulePath when an AutomatedLab module is missing' {
        $script:installed['AutomatedLabCore'] = @()

        $result = Test-ProxmoxLiveTestPrerequisite | Where-Object Name -eq 'AutomatedLabCore'

        $result.Ok | Should -Be $false
        $result.Detail | Should -BeLike '*-ModulePath*'
    }
}

Describe 'Import-ProxmoxLiveTestModule' {
    BeforeEach {
        $script:imported = [System.Collections.Generic.List[string]]::new()
        Mock -CommandName Import-Module -MockWith { $script:imported.Add([string]$Name) }
    }

    It 'imports the modules in dependency order' {
        Import-ProxmoxLiveTestModule

        $script:imported | Should -Be @(
            'PSFramework'
            'AutomatedLab.Common'
            'Corsinvest.ProxmoxVE.Api'
            'AutomatedLabUnattended'
            'PSLog'
            'PSFileTransfer'
            'AutomatedLabDefinition'
            'AutomatedLabWorker'
            'AutomatedLabNotifications'
            'AutomatedLabCore'
        )
    }

    It 'names the module that cannot be imported' {
        Mock -CommandName Import-Module -MockWith {
            if ([string]$Name -eq 'AutomatedLabWorker')
            {
                throw 'boom'
            }
        }

        { Import-ProxmoxLiveTestModule } | Should -Throw -ExpectedMessage "*'AutomatedLabWorker'*boom*"
    }
}

Describe 'Connect-ProxmoxLiveTestCluster' {
    BeforeEach {
        Mock -CommandName Connect-LabProxmoxCluster
        Mock -CommandName Test-LabProxmoxConnection -MockWith { $true }
    }

    It 'connects with the token as the plain string the cmdlet expects' {
        $connection = [pscustomobject]@{
            HostName   = 'pve1'
            Port       = 8006
            AuthType   = 'ApiToken'
            Credential = $null
            ApiToken   = ConvertTo-SecureString -String 'root@pam!live=1a2b3c4d-1111-2222-3333-444455556666' -AsPlainText -Force
        }

        Connect-ProxmoxLiveTestCluster -Connection $connection

        Should -Invoke -CommandName Connect-LabProxmoxCluster -Times 1 -Exactly -ParameterFilter {
            $HostName -eq 'pve1' -and $Port -eq 8006 -and
            $ApiToken -eq 'root@pam!live=1a2b3c4d-1111-2222-3333-444455556666' -and -not $Credential
        }
    }

    It 'connects with the credential' {
        $connection = [pscustomobject]@{
            HostName   = 'pve1'
            Port       = 8443
            AuthType   = 'Credential'
            Credential = [pscredential]::new('root@pam', (ConvertTo-SecureString -String 'not-a-real-password' -AsPlainText -Force))
            ApiToken   = $null
        }

        Connect-ProxmoxLiveTestCluster -Connection $connection

        Should -Invoke -CommandName Connect-LabProxmoxCluster -Times 1 -Exactly -ParameterFilter {
            $HostName -eq 'pve1' -and $Port -eq 8443 -and $Credential.UserName -eq 'root@pam' -and -not $ApiToken
        }
    }

    It 'fails when the API does not answer after connecting' {
        Mock -CommandName Test-LabProxmoxConnection -MockWith { $false }
        $connection = [pscustomobject]@{ HostName = 'pve1'; Port = 8006; AuthType = 'Credential'; Credential = [pscredential]::new('a@pam', (ConvertTo-SecureString -String 'x' -AsPlainText -Force)); ApiToken = $null }

        { Connect-ProxmoxLiveTestCluster -Connection $connection } | Should -Throw -ExpectedMessage "*'pve1:8006'*did not answer*"
    }

    It 'lets a connection error through without the token' {
        Mock -CommandName Connect-LabProxmoxCluster -MockWith { throw "Failed to connect to Proxmox cluster at 'pve1:8006': timeout" }
        $connection = [pscustomobject]@{
            HostName   = 'pve1'
            Port       = 8006
            AuthType   = 'ApiToken'
            Credential = $null
            ApiToken   = ConvertTo-SecureString -String 'root@pam!live=topsecret-token' -AsPlainText -Force
        }

        $thrown = $null
        try { Connect-ProxmoxLiveTestCluster -Connection $connection } catch { $thrown = $_ }

        $thrown.Exception.Message | Should -BeLike '*Failed to connect*timeout*'
        $thrown.Exception.Message | Should -Not -BeLike '*topsecret*'
    }
}

Describe 'Test-ProxmoxLiveTestCapability' {
    It 'returns true when the worker command reports the parameter' {
        Mock -CommandName Invoke-ProxmoxLiveTestWorkerCommand -MockWith { $true }

        Test-ProxmoxLiveTestCapability -Command 'Start-LWProxmoxAgentExecutionOnVM' -Parameter 'StatusFailureToleranceSeconds' | Should -Be $true
    }

    It 'returns false when the worker command does not report the parameter' {
        Mock -CommandName Invoke-ProxmoxLiveTestWorkerCommand -MockWith { $false }

        Test-ProxmoxLiveTestCapability -Command 'Start-LWProxmoxAgentExecutionOnVM' -Parameter 'StatusFailureToleranceSeconds' | Should -Be $false
    }

    It 'returns false when the worker module cannot be asked' {
        Mock -CommandName Invoke-ProxmoxLiveTestWorkerCommand -MockWith { throw 'The module AutomatedLabWorker is not loaded.' }

        Test-ProxmoxLiveTestCapability -Command 'Start-LWProxmoxAgentExecutionOnVM' -Parameter 'StatusFailureToleranceSeconds' | Should -Be $false
    }

    It 'passes the command and the parameter name on' {
        Mock -CommandName Invoke-ProxmoxLiveTestWorkerCommand -MockWith { $true }

        $null = Test-ProxmoxLiveTestCapability -Command 'Start-LWProxmoxAgentExecutionOnVM' -Parameter 'StatusFailureToleranceSeconds'

        Should -Invoke -CommandName Invoke-ProxmoxLiveTestWorkerCommand -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -eq 'Start-LWProxmoxAgentExecutionOnVM' -and $ArgumentList[1] -eq 'StatusFailureToleranceSeconds'
        }
    }
}

Describe 'Get-ProxmoxLiveTestLeftoverVm' {
    BeforeEach {
        Mock -CommandName Get-LWProxmoxVM -MockWith {
            New-RawVm -Name 'allive-0123abcd-1' -Tags 'al-live-test' -VmId 301 -Template 0
            New-RawVm -Name 'allive-0123abcd-2' -Tags @() -VmId 302 -Template 0
            New-RawVm -Name 'ALServer2025' -Tags 'al-live-test' -VmId 196 -Template 0
            New-RawVm -Name 'allive-0123abcd-3' -Tags 'al-live-test', 'template' -VmId 303 -Template 1
            New-RawVm -Name 'allive-89abcdef-1' -Tags 'al-live-test' -VmId 304 -Template 0
            New-RawVm -Name 'allive-89abcdef-2' -Tags @() -VmId 305 -Template 0
        }
    }

    It 'finds VMs that have both the live-test name and the live-test tag' {
        $leftovers = @(Get-ProxmoxLiveTestLeftoverVm)

        ($leftovers.vmid | Sort-Object) | Should -Be @(301, 304)
    }

    It 'looks the VMs up afresh' {
        $null = Get-ProxmoxLiveTestLeftoverVm

        Should -Invoke -CommandName Get-LWProxmoxVM -Times 1 -Exactly -ParameterFilter { $NoCache }
    }

    It 'finds every VM of one run by its name, tag or not' {
        $leftovers = @(Get-ProxmoxLiveTestLeftoverVm -RunId '0123abcd')

        ($leftovers.vmid | Sort-Object) | Should -Be @(301, 302)
    }

    It 'returns nothing when no VM qualifies' {
        Mock -CommandName Get-LWProxmoxVM -MockWith { New-RawVm -Name 'DC1' -Tags 'al-live-test' -VmId 120 -Template 0 }

        @(Get-ProxmoxLiveTestLeftoverVm) | Should -HaveCount 0
    }
}

Describe 'Remove-ProxmoxLiveTestVm' {
    BeforeEach {
        Mock -CommandName Remove-LWProxmoxVM -MockWith {
            [pscustomobject]@{ Name = $Name; VmId = $VmId; Node = 'pve1'; Outcome = 'Removed' }
        }
    }

    It 'removes a live-test VM by name and VMID' {
        $outcome = New-RawVm -Name 'allive-0123abcd-1' -VmId 301 -Template 0 | Remove-ProxmoxLiveTestVm -Confirm:$false

        Should -Invoke -CommandName Remove-LWProxmoxVM -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'allive-0123abcd-1' -and $VmId -eq 301
        }
        $outcome.Outcome | Should -Be 'Removed'
    }

    It 'accepts the object that New-ProxmoxLiveTestVm returns' {
        $vm = [pscustomobject]@{ Name = 'allive-0123abcd-2'; VmId = 302; Node = 'pve1' }

        $null = $vm | Remove-ProxmoxLiveTestVm -Confirm:$false

        Should -Invoke -CommandName Remove-LWProxmoxVM -Times 1 -Exactly -ParameterFilter { $VmId -eq 302 }
    }

    It 'refuses a VM whose name is not a live-test name' {
        $vm = New-RawVm -Name 'ALServer2025' -VmId 196 -Template 0

        { $vm | Remove-ProxmoxLiveTestVm -Confirm:$false } | Should -Throw -ExpectedMessage "*Refusing to remove 'ALServer2025'*"

        Should -Invoke -CommandName Remove-LWProxmoxVM -Times 0 -Exactly
    }

    It 'removes nothing with -WhatIf' {
        $null = New-RawVm -Name 'allive-0123abcd-1' -VmId 301 -Template 0 | Remove-ProxmoxLiveTestVm -WhatIf

        Should -Invoke -CommandName Remove-LWProxmoxVM -Times 0 -Exactly
    }
}

Describe 'Get-ProxmoxLiveTestNextVmId' {
    It 'asks the cluster for the next free VMID' {
        Mock -CommandName Get-PveClusterNextid -MockWith { New-PveReply -Data '237' }

        Get-ProxmoxLiveTestNextVmId | Should -Be 237
    }

    It 'falls back to the highest VMID plus one' {
        Mock -CommandName Get-PveClusterNextid -MockWith { New-PveReply -Data $null -StatusCode 500 -ReasonPhrase 'denied' }
        Mock -CommandName Get-LWProxmoxVM -MockWith {
            New-RawVm -VmId 100
            New-RawVm -VmId 196
            New-RawVm -VmId 150
        }

        Get-ProxmoxLiveTestNextVmId | Should -Be 197

        Should -Invoke -CommandName Get-LWProxmoxVM -Times 1 -Exactly -ParameterFilter { $IncludeTemplates -and $NoCache }
    }

    It 'fails when no way yields an id' {
        Mock -CommandName Get-PveClusterNextid -MockWith { New-PveReply -Data $null -StatusCode 500 -ReasonPhrase 'denied' }
        Mock -CommandName Get-LWProxmoxVM

        { Get-ProxmoxLiveTestNextVmId } | Should -Throw -ExpectedMessage '*free VMID*'
    }
}

Describe 'Wait-ProxmoxLiveTestTask' {
    BeforeEach {
        $script:taskReplies = @()
        $script:taskCalls = 0
        Mock -CommandName Get-PveNodesTasksStatus -MockWith {
            $index = [math]::Min($script:taskCalls, $script:taskReplies.Count - 1)
            $script:taskCalls++
            $script:taskReplies[$index]
        }
        Mock -CommandName Start-Sleep
    }

    It 'returns the exit status of a finished task' {
        $script:taskReplies = @(New-PveReply -Data ([pscustomobject]@{ status = 'stopped'; exitstatus = 'OK' }))

        Wait-ProxmoxLiveTestTask -Node 'pve1' -Upid 'UPID:pve1:1' | Should -Be 'OK'
    }

    It 'polls until the task has stopped' {
        $script:taskReplies = @(
            (New-PveReply -Data ([pscustomobject]@{ status = 'running' }))
            (New-PveReply -Data ([pscustomobject]@{ status = 'running' }))
            (New-PveReply -Data ([pscustomobject]@{ status = 'stopped'; exitstatus = 'OK' }))
        )

        Wait-ProxmoxLiveTestTask -Node 'pve1' -Upid 'UPID:pve1:1' | Should -Be 'OK'

        Should -Invoke -CommandName Start-Sleep -Times 2 -Exactly
    }

    It 'keeps polling after a failed status query' {
        $script:taskReplies = @(
            (New-PveReply -Data $null -StatusCode 500 -ReasonPhrase 'timeout')
            (New-PveReply -Data ([pscustomobject]@{ status = 'stopped'; exitstatus = 'WARNINGS: 1' }))
        )

        Wait-ProxmoxLiveTestTask -Node 'pve1' -Upid 'UPID:pve1:1' | Should -Be 'WARNINGS: 1'
    }

    It 'fails with the last status after the timeout' {
        Mock -CommandName Start-Sleep -MockWith { [System.Threading.Thread]::Sleep(1200) }
        $script:taskReplies = @(New-PveReply -Data ([pscustomobject]@{ status = 'running' }))

        {
            Wait-ProxmoxLiveTestTask -Node 'pve1' -Upid 'UPID:pve1:1' -TimeoutSeconds 1
        } | Should -Throw -ExpectedMessage "*did not finish within 1 seconds*last status: 'running'*"
    }
}

Describe 'New-ProxmoxLiveTestVm' {
    BeforeEach {
        $script:template = [pscustomobject]@{ Name = 'ALServer2025'; VmId = 196; Node = 'pve1' }
        Mock -CommandName Get-ProxmoxLiveTestNextVmId -MockWith { 301 }
        Mock -CommandName New-PveNodesQemuClone -MockWith { New-PveReply -Data 'UPID:pve1:clone' }
        Mock -CommandName Wait-ProxmoxLiveTestTask -MockWith { 'OK' }
        Mock -CommandName Get-PveNodesQemuConfig -MockWith {
            New-PveReply -Data ([pscustomobject]@{
                    net0  = 'virtio=AA:BB:CC:DD:EE:01,bridge=vmbr0'
                    net1  = 'virtio=AA:BB:CC:DD:EE:02,bridge=vmbr1'
                    scsi0 = 'local-lvm:vm-196-disk-0'
                    agent = '1'
                })
        }
        Mock -CommandName Set-PveNodesQemuConfig -MockWith { New-PveReply -Data $null }
    }

    It 'returns what the tests need to find and remove the VM' {
        $vm = New-ProxmoxLiveTestVm -Template $script:template -Name 'allive-0123abcd-1'

        $vm.Name | Should -Be 'allive-0123abcd-1'
        $vm.VmId | Should -Be 301
        $vm.Node | Should -Be 'pve1'
        $vm.TemplateName | Should -Be 'ALServer2025'
    }

    It 'refuses a name that is not a live-test name' {
        { New-ProxmoxLiveTestVm -Template $script:template -Name 'DJSRV2025R005' } | Should -Throw -ExpectedMessage "*'DJSRV2025R005' is not a live-test VM name*"

        Should -Invoke -CommandName New-PveNodesQemuClone -Times 0 -Exactly
    }

    It 'makes a linked clone on the node of the template by default' {
        $null = New-ProxmoxLiveTestVm -Template $script:template -Name 'allive-0123abcd-1'

        Should -Invoke -CommandName New-PveNodesQemuClone -Times 1 -Exactly -ParameterFilter {
            $Node -eq 'pve1' -and $Vmid -eq 196 -and $Newid -eq 301 -and $Name -eq 'allive-0123abcd-1' -and -not $Full -and -not $Storage
        }
    }

    It 'makes a full clone on request' {
        $null = New-ProxmoxLiveTestVm -Template $script:template -Name 'allive-0123abcd-1' -FullClone

        Should -Invoke -CommandName New-PveNodesQemuClone -Times 1 -Exactly -ParameterFilter { $Full }
    }

    It 'makes a full clone when a storage is given, because linked clones cannot choose one' {
        $null = New-ProxmoxLiveTestVm -Template $script:template -Name 'allive-0123abcd-1' -Storage 'local-zfs'

        Should -Invoke -CommandName New-PveNodesQemuClone -Times 1 -Exactly -ParameterFilter {
            $Full -and $Storage -eq 'local-zfs'
        }
    }

    It 'tags the clone and removes its network adapters so it cannot disturb the network' {
        $null = New-ProxmoxLiveTestVm -Template $script:template -Name 'allive-0123abcd-1'

        Should -Invoke -CommandName Set-PveNodesQemuConfig -Times 1 -Exactly -ParameterFilter {
            $Node -eq 'pve1' -and $Vmid -eq 301 -and $Tags -eq 'al-live-test' -and $Delete -eq 'net0,net1'
        }
    }

    It 'only tags a clone that has no network adapter' {
        Mock -CommandName Get-PveNodesQemuConfig -MockWith { New-PveReply -Data ([pscustomobject]@{ scsi0 = 'local-lvm:vm-196-disk-0'; agent = '1' }) }

        $null = New-ProxmoxLiveTestVm -Template $script:template -Name 'allive-0123abcd-1'

        Should -Invoke -CommandName Set-PveNodesQemuConfig -Times 1 -Exactly -ParameterFilter { $Tags -eq 'al-live-test' -and -not $Delete }
    }

    It 'accepts a clone task that ended with warnings' {
        Mock -CommandName Wait-ProxmoxLiveTestTask -MockWith { 'WARNINGS: 1' }

        { New-ProxmoxLiveTestVm -Template $script:template -Name 'allive-0123abcd-1' } | Should -Not -Throw
    }

    It 'fails when the clone request is rejected' {
        Mock -CommandName New-PveNodesQemuClone -MockWith { New-PveReply -Data $null -StatusCode 500 -ReasonPhrase 'unable to create VM 301' }

        {
            New-ProxmoxLiveTestVm -Template $script:template -Name 'allive-0123abcd-1'
        } | Should -Throw -ExpectedMessage "*Failed to clone template 'ALServer2025' (VMID 196)*unable to create VM 301*"

        Should -Invoke -CommandName Wait-ProxmoxLiveTestTask -Times 0 -Exactly
        Should -Invoke -CommandName Set-PveNodesQemuConfig -Times 0 -Exactly
    }

    It 'fails when the clone task does not end well' {
        Mock -CommandName Wait-ProxmoxLiveTestTask -MockWith { 'clone failed: no space left' }

        {
            New-ProxmoxLiveTestVm -Template $script:template -Name 'allive-0123abcd-1'
        } | Should -Throw -ExpectedMessage "*clone task for 'allive-0123abcd-1'*ended with 'clone failed: no space left'*"
    }

    It 'names the VM when it was cloned but could not be prepared' {
        Mock -CommandName Set-PveNodesQemuConfig -MockWith { New-PveReply -Data $null -StatusCode 403 -ReasonPhrase 'Permission check failed' }

        {
            New-ProxmoxLiveTestVm -Template $script:template -Name 'allive-0123abcd-1'
        } | Should -Throw -ExpectedMessage "*'allive-0123abcd-1' (VMID 301)*cloned but could not be prepared*Permission check failed*"
    }
}

Describe 'Start-ProxmoxLiveTestVm' {
    BeforeEach {
        $script:vm = [pscustomobject]@{ Name = 'allive-0123abcd-1'; VmId = 301; Node = 'pve1' }
        Mock -CommandName Start-PveVm -MockWith { New-PveReply -Data 'UPID:pve1:start' }
        Mock -CommandName Wait-ProxmoxLiveTestTask -MockWith { 'OK' }
        Mock -CommandName Get-LWProxmoxVM -MockWith {
            [pscustomobject]@{
                name          = 'allive-0123abcd-1'
                vmid          = 301
                node          = 'pve1'
                status        = 'running'
                CurrentStatus = [pscustomobject]@{ qmpstatus = 'running' }
            }
        }
    }

    It 'starts the VM and confirms with a fresh lookup that it is running' {
        $result = Start-ProxmoxLiveTestVm -Vm $script:vm

        $result.Name | Should -Be 'allive-0123abcd-1'
        Should -Invoke -CommandName Start-PveVm -Times 1 -Exactly -ParameterFilter { $VmIdOrName -eq '301' }
        Should -Invoke -CommandName Get-LWProxmoxVM -Times 1 -Exactly -ParameterFilter {
            $NoCache -and $ComputerName -eq 'allive-0123abcd-1' -and $Node -eq 'pve1'
        }
    }

    It 'accepts a task warning when the VM is running' {
        Mock -CommandName Wait-ProxmoxLiveTestTask -MockWith { 'WARNINGS: 1' }

        { Start-ProxmoxLiveTestVm -Vm $script:vm } | Should -Not -Throw
    }

    It 'fails when the task does not end well and the VM is not running' {
        Mock -CommandName Wait-ProxmoxLiveTestTask -MockWith { 'start failed' }
        Mock -CommandName Get-LWProxmoxVM -MockWith {
            [pscustomobject]@{ name = 'allive-0123abcd-1'; vmid = 301; node = 'pve1'; status = 'stopped'; CurrentStatus = [pscustomobject]@{ qmpstatus = 'stopped' } }
        }

        {
            Start-ProxmoxLiveTestVm -Vm $script:vm
        } | Should -Throw -ExpectedMessage "*start task for 'allive-0123abcd-1'*ended with 'start failed'*stopped*"
    }

    It 'fails when the start request is rejected' {
        Mock -CommandName Start-PveVm -MockWith { New-PveReply -Data $null -StatusCode 500 -ReasonPhrase 'not enough memory' }

        { Start-ProxmoxLiveTestVm -Vm $script:vm } | Should -Throw -ExpectedMessage "*Failed to start 'allive-0123abcd-1' (VMID 301)*not enough memory*"
    }
}

Describe 'Wait-ProxmoxLiveTestVmReady' {
    BeforeEach {
        $script:vm = [pscustomobject]@{ Name = 'allive-0123abcd-1'; VmId = 301; Node = 'pve1' }
        $script:workerAnswers = [System.Collections.Generic.Queue[object]]::new()
        Mock -CommandName Invoke-ProxmoxLiveTestWorkerCommand -MockWith { $script:workerAnswers.Dequeue() }
    }

    It 'returns once the agent runs commands and the Windows image state is complete' {
        $script:workerAnswers.Enqueue($true)
        $script:workerAnswers.Enqueue($true)

        { Wait-ProxmoxLiveTestVmReady -Vm $script:vm } | Should -Not -Throw

        Should -Invoke -CommandName Invoke-ProxmoxLiveTestWorkerCommand -Times 2 -Exactly
    }

    It 'explains an agent that never runs commands' {
        $script:workerAnswers.Enqueue($false)

        {
            Wait-ProxmoxLiveTestVmReady -Vm $script:vm -TimeoutSeconds 30
        } | Should -Throw -ExpectedMessage "*'allive-0123abcd-1'*did not run commands within 30 seconds*agent*"
    }

    It 'explains a Windows image that does not settle' {
        $script:workerAnswers.Enqueue($true)
        $script:workerAnswers.Enqueue($false)

        {
            Wait-ProxmoxLiveTestVmReady -Vm $script:vm -ImageStateTimeoutSeconds 60
        } | Should -Throw -ExpectedMessage "*IMAGE_STATE_COMPLETE within 60 seconds*"
    }
}

Describe 'Get-ProxmoxLiveTestPlan' {
    BeforeAll {
        $script:connection = [pscustomobject]@{
            HostName   = '192.0.2.10'
            Port       = 8006
            AuthType   = 'ApiToken'
            UserName   = $null
            Principal  = 'root@pam!live'
            Credential = [pscredential]::new('root@pam', (ConvertTo-SecureString -String 'topsecret-pw' -AsPlainText -Force))
            ApiToken   = ConvertTo-SecureString -String 'root@pam!live=topsecret-token' -AsPlainText -Force
        }
    }

    BeforeEach {
        $script:vms = @(
            (New-RawVm -Name 'S2025' -VmId 196 -Tags 'template', 'windowsserver2025datacenterdesktopexperience')
            (New-RawVm -Name 'W11' -VmId 197 -Tags 'template', 'windows11enterprise' -Node 'pve2')
            (New-RawVm -Name 'U1' -VmId 198 -Tags 'template', 'ubuntu2404')
            (New-RawVm -Name 'DC1' -VmId 120 -Tags @() -Template 0)
        )
        Mock -CommandName Get-PveVersion -MockWith { New-PveReply -Data ([pscustomobject]@{ version = '9.0.3' }) }
        Mock -CommandName Get-LWProxmoxNode -MockWith {
            [pscustomobject]@{ node = 'pve1' }
            [pscustomobject]@{ node = 'pve2' }
        }
        Mock -CommandName Get-LWProxmoxVM -MockWith { $script:vms }
        Mock -CommandName Test-ProxmoxLiveTestCapability -MockWith { $true }
        Mock -CommandName Get-ProxmoxLiveTestLeftoverVm
    }

    It 'is ready when two supported templates exist' {
        $plan = Get-ProxmoxLiveTestPlan -Connection $script:connection

        $plan.Ready | Should -Be $true
        $plan.Problems | Should -HaveCount 0
        $plan.Selected.Name | Should -Be @('S2025', 'W11')
        $plan.Nodes | Should -Be @('pve1', 'pve2')
        $plan.ProxmoxVersion | Should -Be '9.0.3'
        $plan.HostName | Should -Be '192.0.2.10'
        $plan.Principal | Should -Be 'root@pam!live'
    }

    It 'lists every template, usable or not, but no ordinary VM' {
        $plan = Get-ProxmoxLiveTestPlan -Connection $script:connection

        ($plan.Templates.Name | Sort-Object) | Should -Be @('S2025', 'U1', 'W11')
        @($plan.Templates | Where-Object IsSupported).Count | Should -Be 2
    }

    It 'is not ready with one supported template and says what was ignored and why' {
        $script:vms = @($script:vms | Where-Object { $_.name -ne 'W11' })

        $plan = Get-ProxmoxLiveTestPlan -Connection $script:connection

        $plan.Ready | Should -Be $false
        $plan.Selected.Name | Should -Be @('S2025')
        $problems = $plan.Problems -join ' '
        $problems | Should -BeLike '*at least 2*'
        $problems | Should -BeLike '*U1*not in the supported list*'
    }

    It 'accepts a single template when only one is requested' {
        $script:vms = @($script:vms | Where-Object { $_.name -ne 'W11' })

        $plan = Get-ProxmoxLiveTestPlan -Connection $script:connection -TemplateCount 1 -MinimumTemplateCount 2

        $plan.Ready | Should -Be $true
        $plan.Selected.Name | Should -Be @('S2025')
    }

    It 'uses the named templates and needs exactly those' {
        $plan = Get-ProxmoxLiveTestPlan -Connection $script:connection -TemplateName 'W11'

        $plan.Ready | Should -Be $true
        $plan.Selected.Name | Should -Be @('W11')
    }

    It 'reports a named template that does not exist' {
        $plan = Get-ProxmoxLiveTestPlan -Connection $script:connection -TemplateName 'S2025', 'W10missing'

        $plan.Ready | Should -Be $false
        ($plan.Problems -join ' ') | Should -BeLike "*'W10missing'*not among the supported templates*"
    }

    It 'is not ready when no node can host a VM' {
        Mock -CommandName Get-LWProxmoxNode -MockWith { throw 'No Proxmox node of the connected cluster can host a virtual machine.' }

        $plan = Get-ProxmoxLiveTestPlan -Connection $script:connection

        $plan.Ready | Should -Be $false
        ($plan.Problems -join ' ') | Should -BeLike '*No usable Proxmox node*'
        Should -Invoke -CommandName Get-LWProxmoxVM -Times 0 -Exactly
    }

    It 'is not ready when the VM list cannot be read' {
        Mock -CommandName Get-LWProxmoxVM -MockWith { throw 'node pve2 did not answer' }

        $plan = Get-ProxmoxLiveTestPlan -Connection $script:connection

        $plan.Ready | Should -Be $false
        ($plan.Problems -join ' ') | Should -BeLike '*Could not list the VMs and templates*pve2 did not answer*'
    }

    It 'asks whether the installed worker tolerates guest-agent outages' {
        $null = Get-ProxmoxLiveTestPlan -Connection $script:connection

        Should -Invoke -CommandName Test-ProxmoxLiveTestCapability -Times 1 -Exactly -ParameterFilter {
            $Command -eq 'Start-LWProxmoxAgentExecutionOnVM' -and $Parameter -eq 'StatusFailureToleranceSeconds'
        }
    }

    It 'stays ready when the installed worker predates the outage handling' {
        Mock -CommandName Test-ProxmoxLiveTestCapability -MockWith { $false }

        $plan = Get-ProxmoxLiveTestPlan -Connection $script:connection

        $plan.Capabilities.OutageHandling | Should -Be $false
        $plan.Ready | Should -Be $true
    }

    It 'reports live-test VMs left behind by earlier runs without failing' {
        Mock -CommandName Get-ProxmoxLiveTestLeftoverVm -MockWith { New-RawVm -Name 'allive-0123abcd-1' -VmId 301 -Template 0 -Tags 'al-live-test' }

        $plan = Get-ProxmoxLiveTestPlan -Connection $script:connection

        $plan.Leftovers | Should -Be @('allive-0123abcd-1')
        $plan.Ready | Should -Be $true
    }

    It 'carries no secret' {
        $plan = Get-ProxmoxLiveTestPlan -Connection $script:connection

        $plan.PSObject.Properties.Name | Should -Not -Contain 'Credential'
        $plan.PSObject.Properties.Name | Should -Not -Contain 'ApiToken'
        ($plan | ConvertTo-Json -Depth 6) | Should -Not -BeLike '*topsecret*'
    }
}

Describe 'Format-ProxmoxLiveTestPlan' {
    BeforeAll {
        $script:readyPlan = [pscustomobject]@{
            HostName       = '192.0.2.10'
            Port           = 8006
            AuthType       = 'ApiToken'
            Principal      = 'root@pam!live'
            ProxmoxVersion = '9.0.3'
            Nodes          = @('pve1', 'pve2')
            Templates      = @(
                [pscustomobject]@{ Name = 'S2025'; IsSupported = $true }
                [pscustomobject]@{ Name = 'U1'; IsSupported = $false }
            )
            Selected       = @(
                [pscustomobject]@{ Name = 'S2025'; VmId = 196; Node = 'pve1'; Family = 'Server'; Release = '2025'; Selection = 'newest server' }
                [pscustomobject]@{ Name = 'W11'; VmId = 197; Node = 'pve2'; Family = 'Client'; Release = '11'; Selection = 'newest client' }
            )
            Capabilities   = @{ OutageHandling = $true }
            Leftovers      = @()
            Problems       = @()
            Ready          = $true
        }
    }

    It 'shows host, authentication, nodes and the selected templates' {
        $text = (Format-ProxmoxLiveTestPlan -Plan $script:readyPlan) -join "`n"

        $text | Should -BeLike '*192.0.2.10:8006*ApiToken*root@pam!live*'
        $text | Should -BeLike '*9.0.3*'
        $text | Should -BeLike '*pve1, pve2*'
        $text | Should -BeLike '*S2025*VMID 196*node pve1*Server 2025*newest server*'
        $text | Should -BeLike '*W11*VMID 197*node pve2*Windows 11*newest client*'
        $text | Should -BeLike '*Ready: yes*'
    }

    It 'lists every problem when the plan is not ready' {
        $plan = $script:readyPlan.PSObject.Copy()
        $plan.Ready = $false
        $plan.Problems = @('Found 1 usable template; at least 2 are required.', 'No usable Proxmox node.')

        $text = (Format-ProxmoxLiveTestPlan -Plan $plan) -join "`n"

        $text | Should -BeLike '*Ready: no*'
        $text | Should -BeLike '*at least 2 are required*'
        $text | Should -BeLike '*No usable Proxmox node*'
    }

    It 'says when the outage tests will be skipped' {
        $plan = $script:readyPlan.PSObject.Copy()
        $plan.Capabilities = @{ OutageHandling = $false }

        $text = (Format-ProxmoxLiveTestPlan -Plan $plan) -join "`n"

        $text | Should -BeLike '*outage*skipped*'
    }

    It 'mentions leftover VMs' {
        $plan = $script:readyPlan.PSObject.Copy()
        $plan.Leftovers = @('allive-0123abcd-1', 'allive-0123abcd-2')

        $text = (Format-ProxmoxLiveTestPlan -Plan $plan) -join "`n"

        $text | Should -BeLike '*2 live-test VM*-RemoveLeftovers*'
    }
}
