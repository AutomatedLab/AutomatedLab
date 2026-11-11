BeforeAll {
    $supportPath = Join-Path $PSScriptRoot '..\..\..\LiveTests\Proxmox\ProxmoxLiveTest.Support.ps1'
    . $supportPath

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

    function New-Info
    {
        param
        (
            [string]$Name,
            [string]$OsTag,
            [string]$Node = 'pve1',
            [int]$VmId = 100
        )

        New-RawVm -Name $Name -Tags 'template', $OsTag -Node $Node -VmId $VmId | ConvertTo-ProxmoxLiveTestTemplateInfo
    }
}

Describe 'Get-ProxmoxLiveTestSetting' {
    It 'returns the default API port 8006' {
        (Get-ProxmoxLiveTestSetting).Port | Should -Be 8006
    }

    It 'returns the tag that marks live-test VMs' {
        (Get-ProxmoxLiveTestSetting).VmTag | Should -Be 'al-live-test'
    }

    It 'recognises names created by New-ProxmoxLiveTestVmName' {
        $name = New-ProxmoxLiveTestVmName -RunId '0123abcd' -Index 2

        $name | Should -Match (Get-ProxmoxLiveTestSetting).VmNamePattern
    }

    It 'recognises a two-digit index' {
        'allive-0123abcd-12' | Should -Match (Get-ProxmoxLiveTestSetting).VmNamePattern
    }

    It 'does not recognise <Label> as a live-test VM name' -ForEach @(
        @{ Label = 'ALServer2025'; Name = 'ALServer2025' }
        @{ Label = 'allive-0123abcd'; Name = 'allive-0123abcd' }
        @{ Label = 'allive-xyz-1'; Name = 'allive-xyz-1' }
        @{ Label = 'DJSRV2025R005'; Name = 'DJSRV2025R005' }
        @{ Label = 'upper-case letters'; Name = 'ALLIVE-0123ABCD-1' }
        @{ Label = 'a trailing line feed'; Name = "allive-0123abcd-1`n" }
        @{ Label = 'a non-ASCII digit'; Name = "allive-0123abcd-$([char]0x0661)" }
        @{ Label = 'a three-digit index'; Name = 'allive-0123abcd-123' }
    ) {
        $Name | Should -Not -Match (Get-ProxmoxLiveTestSetting).VmNamePattern
    }
}

Describe 'New-ProxmoxLiveTestRunId' {
    It 'returns eight lower-case hex characters' {
        New-ProxmoxLiveTestRunId | Should -Match '^[0-9a-f]{8}$'
    }

    It 'returns a different id on every call' {
        $ids = 1..20 | ForEach-Object { New-ProxmoxLiveTestRunId }

        ($ids | Select-Object -Unique).Count | Should -Be 20
    }
}

Describe 'New-ProxmoxLiveTestVmName' {
    It 'joins prefix, run id and index' {
        New-ProxmoxLiveTestVmName -RunId 'a1b2c3d4' -Index 2 | Should -Be 'allive-a1b2c3d4-2'
    }

    It 'returns a valid DNS label of at most 63 characters' {
        $name = New-ProxmoxLiveTestVmName -RunId 'a1b2c3d4' -Index 12

        $name | Should -Match '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'
        $name.Length | Should -BeLessOrEqual 63
    }

    It 'rejects a run id that is not eight hex characters' {
        { New-ProxmoxLiveTestVmName -RunId 'XYZ' -Index 1 } | Should -Throw
    }
}

Describe 'Test-ProxmoxLiveTestApiToken' {
    It 'accepts <Token>' -ForEach @(
        @{ Token = 'root@pam!live=1a2b3c4d-1111-2222-3333-444455556666' }
        @{ Token = 'automation@pve!lab=8a4d2f9c-1b3e-4f7a-9d2c-6f0e5b8a1c23' }
    ) {
        Test-ProxmoxLiveTestApiToken -ApiToken $Token | Should -Be $true
    }

    It 'rejects the malformed token <Token>' -ForEach @(
        @{ Token = '' }
        @{ Token = $null }
        @{ Token = 'root@pam' }
        @{ Token = 'root@pam!live' }
        @{ Token = 'root!live=abc' }
        @{ Token = 'root@pam!live=abc def' }
    ) {
        Test-ProxmoxLiveTestApiToken -ApiToken $Token | Should -Be $false
    }
}

Describe 'ConvertFrom-ProxmoxLiveTestSecureString' {
    It 'returns the original text' {
        $secure = ConvertTo-SecureString -String 'abc123-XYZ' -AsPlainText -Force

        ConvertFrom-ProxmoxLiveTestSecureString -SecureString $secure | Should -Be 'abc123-XYZ'
    }
}

Describe 'ConvertTo-ProxmoxLiveTestTemplateInfo' {
    Context 'When the template carries a supported operating system tag' {
        It 'classifies <OsTag> as <Family> <Release>' -ForEach @(
            @{ OsTag = 'windows10pro'; Family = 'Client'; Release = '10'; Desktop = $true }
            @{ OsTag = 'windows10enterpriseltsc'; Family = 'Client'; Release = '10'; Desktop = $true }
            @{ OsTag = 'windows11enterpriseevaluation'; Family = 'Client'; Release = '11'; Desktop = $true }
            @{ OsTag = 'windowsserver2019datacenterevaluationdesktopexperience'; Family = 'Server'; Release = '2019'; Desktop = $true }
            @{ OsTag = 'windowsserver2022standard'; Family = 'Server'; Release = '2022'; Desktop = $false }
            @{ OsTag = 'windowsserver2019serverstandardcore'; Family = 'Server'; Release = '2019'; Desktop = $false }
            @{ OsTag = 'windowsserver2025datacenterdesktopexperience'; Family = 'Server'; Release = '2025'; Desktop = $true }
        ) {
            $info = New-RawVm -Tags 'template', $OsTag | ConvertTo-ProxmoxLiveTestTemplateInfo

            $info.IsSupported | Should -Be $true
            $info.Family | Should -Be $Family
            $info.Release | Should -Be $Release
            $info.DesktopExperience | Should -Be $Desktop
            $info.OsTag | Should -Be $OsTag
        }

        It 'ignores the position of the tags' {
            $info = New-RawVm -Tags 'windows11pro', '10.0.22631.1', 'template' | ConvertTo-ProxmoxLiveTestTemplateInfo

            $info.IsSupported | Should -Be $true
            $info.OsTag | Should -Be 'windows11pro'
            $info.VersionTag | Should -Be '10.0.22631.1'
        }

        It 'returns name, VMID and node of the template' {
            $info = New-RawVm -Name 'ALServer2025' -VmId 196 -Node 'pve2' -Tags 'template', 'windowsserver2025standard' |
                ConvertTo-ProxmoxLiveTestTemplateInfo

            $info.Name | Should -Be 'ALServer2025'
            $info.VmId | Should -Be 196
            $info.VmId | Should -BeOfType ([int])
            $info.Node | Should -Be 'pve2'
        }

        It 'accepts a VMID delivered as text' {
            $raw = [pscustomobject]@{ name = 'x'; vmid = '196'; node = 'pve1'; template = 1; tags = @('template', 'windows10pro') }

            ($raw | ConvertTo-ProxmoxLiveTestTemplateInfo).VmId | Should -Be 196
        }
    }

    Context 'When the template cannot be used' {
        It 'does not support the operating system tag <OsTag>' -ForEach @(
            @{ OsTag = 'ubuntu2404' }
            @{ OsTag = 'windowsserver2016datacenter' }
            @{ OsTag = 'windows7professional' }
        ) {
            $info = New-RawVm -Tags 'template', $OsTag | ConvertTo-ProxmoxLiveTestTemplateInfo

            $info.IsTemplate | Should -Be $true
            $info.IsSupported | Should -Be $false
            $info.Reason | Should -BeLike '*not in the supported list*'
        }

        It 'does not support a template without an operating system tag' {
            $info = New-RawVm -Tags 'template', '10.0.1.1' | ConvertTo-ProxmoxLiveTestTemplateInfo

            $info.IsSupported | Should -Be $false
            $info.Reason | Should -BeLike '*no operating system tag*'
        }

        It 'does not treat a VM that is not a template as a template' {
            $info = New-RawVm -Template 0 -Tags 'template', 'windows11pro' | ConvertTo-ProxmoxLiveTestTemplateInfo

            $info.IsTemplate | Should -Be $false
            $info.IsSupported | Should -Be $false
            $info.Reason | Should -BeLike '*not a template*'
        }

        It 'ignores a template that lacks the template tag, as AutomatedLab does' {
            $info = New-RawVm -Tags 'windows11pro' | ConvertTo-ProxmoxLiveTestTemplateInfo

            $info.IsTemplate | Should -Be $false
            $info.IsSupported | Should -Be $false
            $info.Reason | Should -BeLike "*'template' tag*"
        }

        It 'copes with a template that has no tags at all' {
            $raw = [pscustomobject]@{ name = 'x'; vmid = 5; node = 'pve1'; template = 1; tags = $null }

            $info = $raw | ConvertTo-ProxmoxLiveTestTemplateInfo

            $info.IsSupported | Should -Be $false
        }
    }
}

Describe 'Select-ProxmoxLiveTestTemplate' {
    BeforeAll {
        $script:s2025 = New-Info -Name 'S2025' -OsTag 'windowsserver2025datacenterdesktopexperience' -VmId 101
        $script:s2022 = New-Info -Name 'S2022' -OsTag 'windowsserver2022standarddesktopexperience' -VmId 102
        $script:s2019 = New-Info -Name 'S2019' -OsTag 'windowsserver2019standarddesktopexperience' -VmId 103
        $script:w11 = New-Info -Name 'W11' -OsTag 'windows11enterprise' -VmId 104
        $script:w10 = New-Info -Name 'W10' -OsTag 'windows10pro' -VmId 105
        $script:ubuntu = New-Info -Name 'U1' -OsTag 'ubuntu2404' -VmId 106
    }

    Context 'When selecting by preference' {
        It 'picks the newest server and the newest client for two templates' {
            $selected = Select-ProxmoxLiveTestTemplate -TemplateInfo $s2019, $w10, $w11, $s2022, $s2025, $ubuntu -Count 2

            @($selected).Name | Should -Be @('S2025', 'W11')
        }

        It 'explains each choice' {
            $selected = @(Select-ProxmoxLiveTestTemplate -TemplateInfo $s2025, $w11 -Count 2)

            $selected[0].Selection | Should -Be 'newest server'
            $selected[1].Selection | Should -Be 'newest client'
        }

        It 'prefers the Desktop Experience edition within a release' {
            $core = New-Info -Name 'S2022core' -OsTag 'windowsserver2022standard' -VmId 120

            $selected = Select-ProxmoxLiveTestTemplate -TemplateInfo $core, $s2022, $w11 -Count 2

            @($selected).Name | Should -Be @('S2022', 'W11')
        }

        It 'falls back to the two newest servers when there is no client' {
            $selected = Select-ProxmoxLiveTestTemplate -TemplateInfo $s2019, $s2025, $s2022 -Count 2

            @($selected).Name | Should -Be @('S2025', 'S2022')
        }

        It 'falls back to the two newest clients when there is no server' {
            $selected = Select-ProxmoxLiveTestTemplate -TemplateInfo $w10, $w11 -Count 2

            @($selected).Name | Should -Be @('W11', 'W10')
        }

        It 'returns what exists when fewer templates are available than requested' {
            $selected = Select-ProxmoxLiveTestTemplate -TemplateInfo $w10 -Count 2

            @($selected).Name | Should -Be @('W10')
        }

        It 'returns nothing when no supported template exists' {
            @(Select-ProxmoxLiveTestTemplate -TemplateInfo $ubuntu -Count 2) | Should -HaveCount 0
            @(Select-ProxmoxLiveTestTemplate -TemplateInfo @() -Count 2) | Should -HaveCount 0
        }

        It 'picks the newest server for a single template' {
            $selected = Select-ProxmoxLiveTestTemplate -TemplateInfo $w11, $s2022, $s2025 -Count 1

            @($selected).Name | Should -Be @('S2025')
        }

        It 'picks the newest client for a single template when there is no server' {
            $selected = Select-ProxmoxLiveTestTemplate -TemplateInfo $w10, $w11 -Count 1

            @($selected).Name | Should -Be @('W11')
        }

        It 'adds the next newest releases when more than two templates are requested' {
            $selected = Select-ProxmoxLiveTestTemplate -TemplateInfo $s2019, $w10, $w11, $s2022, $s2025 -Count 3

            @($selected).Name | Should -Be @('S2025', 'W11', 'S2022')
        }

        It 'selects one template per release when several templates share it' {
            $onOtherNode = New-Info -Name 'S2025b' -OsTag 'windowsserver2025datacenterdesktopexperience' -Node 'pve2' -VmId 150

            $selected = Select-ProxmoxLiveTestTemplate -TemplateInfo $onOtherNode, $s2025, $w11 -Count 3

            @($selected | Where-Object Release -eq '2025') | Should -HaveCount 1
            @($selected | Where-Object Release -eq '2025').Name | Should -Be 'S2025'
        }

        It 'accepts templates from the pipeline' {
            $selected = $s2025, $w11, $s2022 | Select-ProxmoxLiveTestTemplate -Count 2

            @($selected).Name | Should -Be @('S2025', 'W11')
        }
    }

    Context 'When templates are requested by name' {
        It 'returns the requested templates in the requested order' {
            $selected = Select-ProxmoxLiveTestTemplate -TemplateInfo $s2025, $s2019, $w10 -Name 'W10', 'S2019'

            @($selected).Name | Should -Be @('W10', 'S2019')
            @($selected)[0].Selection | Should -Be 'requested by name'
        }

        It 'matches names regardless of case' {
            $selected = Select-ProxmoxLiveTestTemplate -TemplateInfo $s2025, $w11 -Name 's2025'

            @($selected).Name | Should -Be @('S2025')
        }

        It 'fails for a name that is not among the supported templates' {
            {
                Select-ProxmoxLiveTestTemplate -TemplateInfo $s2025, $w11 -Name 'Nope'
            } | Should -Throw -ExpectedMessage "*'Nope'*not among the supported templates*"
        }

        It 'fails for a template with an unsupported operating system' {
            {
                Select-ProxmoxLiveTestTemplate -TemplateInfo $s2025, $ubuntu -Name 'U1'
            } | Should -Throw -ExpectedMessage "*'U1'*not among the supported templates*"
        }
    }
}

Describe 'Resolve-ProxmoxLiveTestConnection' {
    BeforeAll {
        $script:token = ConvertTo-SecureString -String 'root@pam!live=1a2b3c4d-1111-2222-3333-444455556666' -AsPlainText -Force
        $script:credential = [pscredential]::new('root@pam', (ConvertTo-SecureString -String 'not-a-real-password' -AsPlainText -Force))
    }

    Context 'When everything is passed explicitly' {
        It 'returns a credential connection with the default port' {
            $connection = Resolve-ProxmoxLiveTestConnection -HostName '192.0.2.10' -Credential $credential -NonInteractive

            $connection.HostName | Should -Be '192.0.2.10'
            $connection.Port | Should -Be 8006
            $connection.AuthType | Should -Be 'Credential'
            $connection.UserName | Should -Be 'root@pam'
            $connection.Credential.UserName | Should -Be 'root@pam'
        }

        It 'returns a token connection with the given port' {
            $connection = Resolve-ProxmoxLiveTestConnection -HostName 'pve1.lab.local' -Port 8443 -ApiToken $token -NonInteractive

            $connection.AuthType | Should -Be 'ApiToken'
            $connection.Port | Should -Be 8443
            $connection.ApiToken | Should -BeOfType ([securestring])
        }

        It 'accepts the host form <HostName>' -ForEach @(
            @{ HostName = '192.0.2.10' }
            @{ HostName = 'pve1' }
            @{ HostName = 'pve1.lab.local' }
            @{ HostName = 'PVE-1' }
        ) {
            (Resolve-ProxmoxLiveTestConnection -HostName $HostName -ApiToken $token -NonInteractive).HostName | Should -Be $HostName
        }

        It 'rejects the host form <HostName> without echoing it' -ForEach @(
            @{ HostName = 'https://pve:8006' }
            @{ HostName = 'pve:8006' }
            @{ HostName = 'pve/path' }
            @{ HostName = 'user:topsecret@pve' }
            @{ HostName = 'pve host' }
        ) {
            $thrown = $null
            try { Resolve-ProxmoxLiveTestConnection -HostName $HostName -ApiToken $token -NonInteractive } catch { $thrown = $_ }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -BeLike '*plain host name or IPv4 address*'
            $thrown.Exception.Message | Should -Not -BeLike '*topsecret*'
        }

        It 'rejects a port outside 1 to 65535' {
            { Resolve-ProxmoxLiveTestConnection -HostName 'pve1' -Port 70000 -ApiToken $token -NonInteractive } | Should -Throw
        }
    }

    Context 'When the input is incomplete or ambiguous' {
        It 'refuses a credential and a token at the same time' {
            {
                Resolve-ProxmoxLiveTestConnection -HostName 'pve1' -Credential $credential -ApiToken $token -NonInteractive
            } | Should -Throw -ExpectedMessage '*either -Credential or -ApiToken*'
        }

        It 'fails without prompting when no credentials are passed in non-interactive mode' {
            Mock -CommandName Read-Host
            Mock -CommandName Get-Credential

            {
                Resolve-ProxmoxLiveTestConnection -HostName 'pve1' -NonInteractive
            } | Should -Throw -ExpectedMessage '*-Credential*-ApiToken*'

            Should -Invoke -CommandName Read-Host -Times 0 -Exactly
            Should -Invoke -CommandName Get-Credential -Times 0 -Exactly
        }

        It 'fails without prompting when no host is passed in non-interactive mode' {
            Mock -CommandName Read-Host

            {
                Resolve-ProxmoxLiveTestConnection -ApiToken $token -NonInteractive
            } | Should -Throw -ExpectedMessage '*-HostName*'

            Should -Invoke -CommandName Read-Host -Times 0 -Exactly
        }

        It 'rejects a malformed token without echoing it' {
            $secretText = 'verysecret-malformed-token'
            $bad = ConvertTo-SecureString -String $secretText -AsPlainText -Force

            $thrown = $null
            try { Resolve-ProxmoxLiveTestConnection -HostName 'pve1' -ApiToken $bad -NonInteractive } catch { $thrown = $_ }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -BeLike '*USER@REALM!TOKENID=UUID*'
            $thrown.Exception.Message | Should -Not -BeLike "*$secretText*"
        }
    }

    Context 'When values are missing and prompting is allowed' {
        BeforeEach {
            Mock -CommandName Read-Host -ParameterFilter { $Prompt -like '*host*' -and -not $AsSecureString } -MockWith { '192.0.2.10' }
            Mock -CommandName Read-Host -ParameterFilter { $Prompt -like 'Authenticate*' } -MockWith { 'T' }
            Mock -CommandName Read-Host -ParameterFilter { $AsSecureString } -MockWith {
                ConvertTo-SecureString -String 'root@pam!live=1a2b3c4d-1111-2222-3333-444455556666' -AsPlainText -Force
            }
            Mock -CommandName Get-Credential -MockWith {
                [pscredential]::new('root@pam', (ConvertTo-SecureString -String 'not-a-real-password' -AsPlainText -Force))
            }
        }

        It 'asks for host, authentication method and token' {
            $connection = Resolve-ProxmoxLiveTestConnection

            $connection.HostName | Should -Be '192.0.2.10'
            $connection.AuthType | Should -Be 'ApiToken'
            Should -Invoke -CommandName Read-Host -Times 3 -Exactly
            Should -Invoke -CommandName Get-Credential -Times 0 -Exactly
        }

        It 'asks for user name and password when the user chooses P' {
            Mock -CommandName Read-Host -ParameterFilter { $Prompt -like 'Authenticate*' } -MockWith { 'p' }

            $connection = Resolve-ProxmoxLiveTestConnection

            $connection.AuthType | Should -Be 'Credential'
            $connection.UserName | Should -Be 'root@pam'
            Should -Invoke -CommandName Get-Credential -Times 1 -Exactly
        }

        It 'only prompts for what is missing' {
            $connection = Resolve-ProxmoxLiveTestConnection -HostName 'pve1' -Credential $credential

            $connection.HostName | Should -Be 'pve1'
            Should -Invoke -CommandName Read-Host -Times 0 -Exactly
            Should -Invoke -CommandName Get-Credential -Times 0 -Exactly
        }

        It 'rejects an answer that is neither T nor P' {
            Mock -CommandName Read-Host -ParameterFilter { $Prompt -like 'Authenticate*' } -MockWith { 'x' }

            { Resolve-ProxmoxLiveTestConnection } | Should -Throw -ExpectedMessage '*T or P*'
        }
    }
}

Describe 'Test-ProxmoxLiveTestAgentOption' {
    It 'accepts the agent option <Value>' -ForEach @(
        @{ Value = '1' }
        @{ Value = 'enabled=1' }
        @{ Value = 'enabled=1,fstrim_cloned_disks=1' }
        @{ Value = 'fstrim_cloned_disks=1,enabled=1' }
        @{ Value = '1,fstrim_cloned_disks=1,type=virtio' }
        @{ Value = 'enabled=true,fstrim_cloned_disks=true,type=virtio' }
        @{ Value = 'ENABLED=Yes' }
        @{ Value = 'on' }
    ) {
        Test-ProxmoxLiveTestAgentOption -Value $Value | Should -Be $true
    }

    It 'rejects the agent option <Value>' -ForEach @(
        @{ Value = '0' }
        @{ Value = 'enabled=0' }
        @{ Value = 'enabled=false,type=virtio' }
        @{ Value = 'fstrim_cloned_disks=1' }
        @{ Value = 'type=virtio' }
        @{ Value = 'enabled=maybe' }
        @{ Value = '' }
        @{ Value = $null }
    ) {
        Test-ProxmoxLiveTestAgentOption -Value $Value | Should -Be $false
    }
}

Describe 'Read-ProxmoxLiveTestGuestFile' {
    BeforeAll {
        function Get-PveNodesQemuAgentFileRead
        {
            [CmdletBinding()]
            param ($Node, $Vmid, $File)
        }

        $script:vm = [pscustomobject]@{ Name = 'allive-0123abcd-1'; Node = 'pve1'; VmId = 123 }
    }

    It 'returns the content of the guest file' {
        Mock -CommandName Get-PveNodesQemuAgentFileRead -MockWith {
            [pscustomobject]@{
                StatusCode   = 200
                ReasonPhrase = 'OK'
                Response     = [pscustomobject]@{ data = [pscustomobject]@{ content = "first line`nsecond line"; truncated = $false } }
            }
        }

        Read-ProxmoxLiveTestGuestFile -Vm $script:vm -Path 'C:\Windows\Temp\x.log' | Should -Be "first line`nsecond line"
        Should -Invoke -CommandName Get-PveNodesQemuAgentFileRead -Times 1 -Exactly -ParameterFilter {
            $Node -eq 'pve1' -and $Vmid -eq 123 -and $File -eq 'C:\Windows\Temp\x.log'
        }
    }

    It 'says why when Proxmox refuses to read the file' {
        Mock -CommandName Get-PveNodesQemuAgentFileRead -MockWith {
            [pscustomobject]@{ StatusCode = 500; ReasonPhrase = 'No such file or directory'; Response = $null }
        }

        $text = Read-ProxmoxLiveTestGuestFile -Vm $script:vm -Path 'C:\Windows\Temp\x.log'

        $text | Should -BeLike '*C:\Windows\Temp\x.log*could not be read*No such file or directory*'
    }

    It 'says why when the call itself fails, and does not throw' {
        Mock -CommandName Get-PveNodesQemuAgentFileRead -MockWith { throw 'connection reset' }

        { Read-ProxmoxLiveTestGuestFile -Vm $script:vm -Path 'C:\Windows\Temp\x.log' } | Should -Not -Throw
        Read-ProxmoxLiveTestGuestFile -Vm $script:vm -Path 'C:\Windows\Temp\x.log' | Should -BeLike '*could not be read*connection reset*'
    }
}
