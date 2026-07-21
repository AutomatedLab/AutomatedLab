Describe 'Get-LabProxmoxConnectionInfo' {
    BeforeAll {
        Import-Module -Name AutomatedLab -Force -ErrorAction Stop

        $functionPath = Join-Path $PSScriptRoot (
            '..\..\..\AutomatedLabCore\functions\Proxmox\Get-LabProxmoxConnectionInfo.ps1'
        )
        . $functionPath

        function New-TestCredential {
            [PSCredential]::new('root@pam', (ConvertTo-SecureString 'pw' -AsPlainText -Force))
        }
    }

    AfterEach {
        Remove-Variable -Name connectionData -Scope Script -ErrorAction SilentlyContinue
    }

    It 'returns nothing when there is no active connection' {
        $script:connectionData = $null
        Get-LabProxmoxConnectionInfo | Should -BeNullOrEmpty
    }

    It 'returns host, port and Credential auth type for a credential connection' {
        $script:connectionData = @{ HostName = 'pve1'; Port = 8006; Credential = (New-TestCredential) }

        $info = Get-LabProxmoxConnectionInfo

        $info.HostName | Should -Be 'pve1'
        $info.Port     | Should -Be 8006
        $info.AuthType | Should -Be 'Credential'
        $info.Credential | Should -BeNullOrEmpty
    }

    It 'returns the credential only when -IncludeCredential is used' {
        $script:connectionData = @{ HostName = 'pve1'; Port = 8006; Credential = (New-TestCredential) }

        (Get-LabProxmoxConnectionInfo -IncludeCredential).Credential.UserName | Should -Be 'root@pam'
    }

    It 'reports ApiToken auth type and never returns a credential for a token connection' {
        $script:connectionData = @{ HostName = 'pve1'; Port = 8006; ApiToken = 'user@pam!tok=uuid' }

        $info = Get-LabProxmoxConnectionInfo -IncludeCredential

        $info.AuthType   | Should -Be 'ApiToken'
        $info.Credential | Should -BeNullOrEmpty
    }
}
