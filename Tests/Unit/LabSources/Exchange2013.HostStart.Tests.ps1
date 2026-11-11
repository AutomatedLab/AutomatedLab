BeforeAll {
    $scriptPath = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\LabSources\CustomRoles\Exchange2013\HostStart.ps1')).Path
    $tokens = $null
    $parseErrors = $null
    $scriptAst = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors)
    $functionAsts = @($scriptAst.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true))
    $helperAst = $functionAsts | Where-Object -Property Name -EQ -Value 'Get-ExchangeInstallFile' | Select-Object -First 1
    $copyAst = $functionAsts | Where-Object -Property Name -EQ -Value 'Copy-ExchangeSources' | Select-Object -First 1

    # The role script runs top-level code that needs a deployed lab, so only the helper function is loaded from it.
    if ($helperAst)
    {
        . ([scriptblock]::Create($helperAst.Extent.Text))
    }

    function Get-LabInternetFile
    {
        [CmdletBinding()]
        param
        (
            [string]$Uri,
            [string]$Path,
            [switch]$PassThru
        )
    }
}

Describe 'Exchange2013 role: Get-ExchangeInstallFile' {
    Context 'a download link is configured' {
        It 'downloads from the link into the folder and returns the file object' {
            $link = 'https://download.example.invalid/Exchange2013-x64-cu99.exe'
            $folder = Join-Path -Path $TestDrive -ChildPath 'download-ok'
            $downloaded = [pscustomobject]@{ FileName = 'Exchange2013-x64-cu99.exe'; FullName = (Join-Path -Path $folder -ChildPath 'Exchange2013-x64-cu99.exe') }
            Mock -CommandName Get-LabInternetFile -MockWith { $downloaded }

            $result = Get-ExchangeInstallFile -DownloadLink $link -Folder $folder

            $result.FileName | Should -Be $downloaded.FileName
            $result.FullName | Should -Be $downloaded.FullName
            Should -Invoke -CommandName Get-LabInternetFile -Times 1 -Exactly -ParameterFilter { $Uri -eq $link -and $Path -eq $folder -and $PassThru }
        }

        It 'ends with a terminating error when the download fails' {
            $folder = Join-Path -Path $TestDrive -ChildPath 'download-fails'
            Mock -CommandName Get-LabInternetFile -MockWith { Write-Error -Message 'The remote server returned an error: (404) Not Found.' }
            # Pester runs a test with 'Stop'. With 'Continue' only the -ErrorAction Stop of the helper can end the run.
            $ErrorActionPreference = 'Continue'

            { Get-ExchangeInstallFile -DownloadLink 'https://download.example.invalid/Exchange2013-x64-cu99.exe' -Folder $folder } |
                Should -Throw -ExpectedMessage '*404*'
        }

        It 'uses the link even when a cached installer exists' {
            $folder = Join-Path -Path $TestDrive -ChildPath 'link-and-cache'
            $null = New-Item -Path $folder -ItemType Directory
            Set-Content -LiteralPath (Join-Path -Path $folder -ChildPath 'Exchange2013-x64-cu23.exe') -Value 'cached'
            Mock -CommandName Get-LabInternetFile -MockWith { [pscustomobject]@{ FileName = 'Exchange2013-x64-cu99.exe'; FullName = 'x' } }

            $null = Get-ExchangeInstallFile -DownloadLink 'https://download.example.invalid/Exchange2013-x64-cu99.exe' -Folder $folder

            Should -Invoke -CommandName Get-LabInternetFile -Times 1 -Exactly
        }
    }

    Context 'no download link is configured' {
        It 'returns the cached installer without downloading' {
            $folder = Join-Path -Path $TestDrive -ChildPath 'cached'
            $null = New-Item -Path $folder -ItemType Directory
            $installer = Join-Path -Path $folder -ChildPath 'Exchange2013-x64-cu23.exe'
            Set-Content -LiteralPath $installer -Value 'cached'
            Mock -CommandName Get-LabInternetFile -MockWith { throw 'The cached installer must not be downloaded again.' }

            $result = Get-ExchangeInstallFile -DownloadLink $null -Folder $folder

            $result.FileName | Should -Be 'Exchange2013-x64-cu23.exe'
            $result.FullName | Should -Be $installer
            $result.Length | Should -BeGreaterThan 0
            Should -Invoke -CommandName Get-LabInternetFile -Times 0 -Exactly
        }

        It 'treats an empty link like no link' {
            $folder = Join-Path -Path $TestDrive -ChildPath 'cached-empty-link'
            $null = New-Item -Path $folder -ItemType Directory
            Set-Content -LiteralPath (Join-Path -Path $folder -ChildPath 'Exchange2013-x64-cu23.exe') -Value 'cached'
            Mock -CommandName Get-LabInternetFile -MockWith { throw 'The cached installer must not be downloaded again.' }

            $result = Get-ExchangeInstallFile -DownloadLink '' -Folder $folder

            $result.FileName | Should -Be 'Exchange2013-x64-cu23.exe'
            Should -Invoke -CommandName Get-LabInternetFile -Times 0 -Exactly
        }

        It 'fails with a message that says how to provide the installer' {
            $folder = Join-Path -Path $TestDrive -ChildPath 'empty'
            $null = New-Item -Path $folder -ItemType Directory
            Mock -CommandName Get-LabInternetFile -MockWith { throw 'There is no link to download from.' }

            $message = try
            {
                Get-ExchangeInstallFile -DownloadLink $null -Folder $folder
            }
            catch
            {
                $_.Exception.Message
            }

            $message | Should -BeLike '*Microsoft no longer publishes*'
            $message | Should -BeLike '*IsoPath*'
            $message | Should -BeLike "*Exchange2013-x64-cu23.exe*$folder*"
            $message | Should -BeLike '*Exchange2013DownloadUrl*'
            Should -Invoke -CommandName Get-LabInternetFile -Times 0 -Exactly
        }
    }
}

Describe 'Exchange2013 role: Copy-ExchangeSources' {
    It 'gets the Exchange 2013 installer through Get-ExchangeInstallFile' {
        $copyAst | Should -Not -BeNullOrEmpty
        $commandNames = @($copyAst.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true) | ForEach-Object { $_.GetCommandName() })

        $commandNames | Should -Contain 'Get-ExchangeInstallFile'
    }

    It 'does not download the Exchange 2013 installer from a hard-wired link' {
        $downloadCalls = @($copyAst.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Get-LabInternetFile' }, $true))
        $downloadText = ($downloadCalls | ForEach-Object { $_.Extent.Text }) -join "`n"

        $downloadText | Should -Not -Match 'exchangeDownloadLink'
    }
}
