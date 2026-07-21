Describe 'Add-LWProxmoxIsoImage' {
    BeforeAll {
        $workerRoot = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker'
        . (Join-Path $workerRoot 'functions\ProxmoxWorkerVirtualMachines\Add-LWProxmoxIsoImage.ps1')

        function Test-LabProxmoxConnection {}
        function Get-LWProxmoxIsoImage {}
        function Remove-LWProxmoxIsoImage {}
        function Get-LabProxmoxConnectionInfo {}
        function Send-LWProxmoxIsoViaSftp { param($Node, $Storage, $File, $SshHostName, $SshCredential, $SshPort) }
        function Send-LWProxmoxIsoViaHttp { param($Node, $Storage, $File, $Checksum, $ChecksumAlgorithm, $TimeoutInSeconds) }
        function Write-LogFunctionEntry {}
        function Write-LogFunctionExit {}
        function Write-PSFMessage { param([string]$Message, [string]$Level) }
        function Write-ScreenInfo { param([string]$Message, [string]$Type) }

        function New-PamCredential {
            [PSCredential]::new('root@pam', (ConvertTo-SecureString 'pw' -AsPlainText -Force))
        }
    }

    BeforeEach {
        Mock -CommandName Test-LabProxmoxConnection -MockWith { $true }
        Mock -CommandName Get-LWProxmoxIsoImage -MockWith { }
        Mock -CommandName Remove-LWProxmoxIsoImage
        Mock -CommandName Send-LWProxmoxIsoViaSftp
        Mock -CommandName Send-LWProxmoxIsoViaHttp
        Mock -CommandName Write-LogFunctionEntry
        Mock -CommandName Write-LogFunctionExit
        Mock -CommandName Write-PSFMessage
        Mock -CommandName Write-ScreenInfo
        Mock -CommandName Get-LabProxmoxConnectionInfo -MockWith {
            [pscustomobject]@{ HostName = 'pve1'; Port = 8006; AuthType = 'Credential'; Credential = (New-PamCredential) }
        }

        $script:isoPath = Join-Path $TestDrive 'sample.iso'
        Set-Content -LiteralPath $script:isoPath -Value 'dummy-iso'

        $Global:PveTicketLast = [pscustomobject]@{
            HostName             = 'pve1'
            Port                 = 8006
            Ticket               = 'TICKET'
            CSRFPreventionToken  = 'CSRF'
            SkipCertificateCheck = $true
            ApiToken             = ''
        }
    }

    AfterEach {
        $Global:PveTicketLast = $null
    }

    Context 'input validation' {
        It 'throws when there is no connection to the cluster' {
            Mock -CommandName Test-LabProxmoxConnection -MockWith { $false }
            { Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*no connection*'
        }

        It 'throws when the ISO file does not exist' {
            { Add-LWProxmoxIsoImage -Node 'pve1' -Path (Join-Path $TestDrive 'missing.iso') -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*does not exist*'
        }

        It 'throws when the file does not have the .iso extension' {
            $txt = Join-Path $TestDrive 'file.txt'
            Set-Content -LiteralPath $txt -Value 'x'
            { Add-LWProxmoxIsoImage -Node 'pve1' -Path $txt -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*extension*'
        }

        It 'throws when Checksum is given without ChecksumAlgorithm' {
            { Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -Checksum 'abc123' -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*ChecksumAlgorithm*'
        }

        It 'throws when no Proxmox ticket is available' {
            $Global:PveTicketLast = $null
            { Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*ticket*'
        }

        It 'skips the upload when the ISO already exists and -Force is not set' {
            Mock -CommandName Get-LWProxmoxIsoImage -MockWith {
                [pscustomobject]@{ FileName = 'sample.iso'; VolId = 'local:iso/sample.iso'; Storage = 'local' }
            }

            Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -Storage 'local'

            Should -Invoke -CommandName Write-ScreenInfo -ParameterFilter {
                $Type -eq 'Warning' -and $Message -match 'already exists'
            }
            Should -Not -Invoke -CommandName Send-LWProxmoxIsoViaSftp
            Should -Not -Invoke -CommandName Send-LWProxmoxIsoViaHttp
        }
    }

    Context 'transport selection' {
        It 'uploads via SFTP by default when a @pam credential is available' {
            Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -Storage 'local'

            Should -Invoke -CommandName Send-LWProxmoxIsoViaSftp -Times 1 -Exactly
            Should -Not -Invoke -CommandName Send-LWProxmoxIsoViaHttp
        }

        It 'derives the SSH credential from a root@pam connection (realm stripped)' {
            Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -Storage 'local'

            Should -Invoke -CommandName Send-LWProxmoxIsoViaSftp -ParameterFilter {
                $SshCredential.UserName -eq 'root' -and $SshHostName -eq 'pve1'
            }
        }

        It 'falls back to HTTP when no SSH credential is available' {
            Mock -CommandName Get-LabProxmoxConnectionInfo -MockWith {
                [pscustomobject]@{ HostName = 'pve1'; Port = 8006; AuthType = 'ApiToken'; Credential = $null }
            }

            Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -Storage 'local'

            Should -Invoke -CommandName Send-LWProxmoxIsoViaHttp -Times 1 -Exactly
            Should -Not -Invoke -CommandName Send-LWProxmoxIsoViaSftp
        }

        It 'uses HTTP when -TransferMethod Http is specified even if a credential exists' {
            Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -Storage 'local' -TransferMethod Http

            Should -Invoke -CommandName Send-LWProxmoxIsoViaHttp -Times 1 -Exactly
            Should -Not -Invoke -CommandName Send-LWProxmoxIsoViaSftp
        }

        It 'uses an explicit -SshCredential over the connection credential' {
            $explicit = [PSCredential]::new('deploy', (ConvertTo-SecureString 'pw' -AsPlainText -Force))
            Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -Storage 'local' -SshCredential $explicit

            Should -Invoke -CommandName Send-LWProxmoxIsoViaSftp -ParameterFilter {
                $SshCredential.UserName -eq 'deploy'
            }
        }

        It 'throws when -TransferMethod Sftp is requested but no SSH credential is available' {
            Mock -CommandName Get-LabProxmoxConnectionInfo -MockWith {
                [pscustomobject]@{ HostName = 'pve1'; Port = 8006; AuthType = 'ApiToken'; Credential = $null }
            }

            { Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -TransferMethod Sftp -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*no SSH credential*'
        }

        It 'falls back to HTTP when the SFTP upload fails under Auto' {
            Mock -CommandName Send-LWProxmoxIsoViaSftp -MockWith { throw 'ssh down' }

            Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -Storage 'local'

            Should -Invoke -CommandName Send-LWProxmoxIsoViaSftp -Times 1 -Exactly
            Should -Invoke -CommandName Send-LWProxmoxIsoViaHttp -Times 1 -Exactly
        }

        It 'does not fall back to HTTP when SFTP fails under -TransferMethod Sftp' {
            Mock -CommandName Send-LWProxmoxIsoViaSftp -MockWith { throw 'ssh down' }

            { Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -TransferMethod Sftp -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*SFTP upload*failed*'
            Should -Not -Invoke -CommandName Send-LWProxmoxIsoViaHttp
        }
    }

    Context 'overwrite behaviour' {
        It 'removes the existing ISO before uploading when -Force is set' {
            Mock -CommandName Get-LWProxmoxIsoImage -MockWith {
                [pscustomobject]@{ FileName = 'sample.iso'; VolId = 'local:iso/sample.iso'; Storage = 'local' }
            }

            Add-LWProxmoxIsoImage -Node 'pve1' -Path $script:isoPath -Storage 'local' -Force

            Should -Invoke -CommandName Remove-LWProxmoxIsoImage -Times 1 -Exactly
            Should -Invoke -CommandName Send-LWProxmoxIsoViaSftp -Times 1 -Exactly
        }
    }
}
