param
(
    [Parameter()]    
    [string]
    $ApiKey
)

$ProgressPreference = 'SilentlyContinue'
Describe 'Repository tests' {
    It 'Should exist' {
        Get-PSRepository -Name Internal -ErrorAction SilentlyContinue | Should -Not -Be $null
    }

    It 'Should be able to find packages' {
        (Find-Module -Repository Internal -ErrorAction SilentlyContinue).Count | Should -BeGreaterThan 0
    }

    It 'Should be able to upload packages' {
        { Publish-Module -Path $tempDir\Modules\VoiceCommands -NuGetApiKey $ApiKey -Repository Internal -Force -ErrorAction Stop -WarningAction SilentlyContinue} | Should -Not -Throw
        Remove-Item -Path (Join-Path -Path $Path -ChildPath 'Packages\VoiceCommands') -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Should be able to download packages' {
        { Save-Module -Repository Internal -Name VoiceCommands -Path . -ErrorAction Stop } | Should -Not -Throw
        Remove-Item ./VoiceCommands -Recurse -Force -ErrorAction SilentlyContinue
    }
}
