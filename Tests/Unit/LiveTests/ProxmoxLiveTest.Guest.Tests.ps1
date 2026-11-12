BeforeAll {
    $script:guestScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\LiveTests\Proxmox\Guest\Restart-GuestAgentDuringCommand.ps1'
    $script:parseErrors = @('the guest script does not exist')

    # The guest script runs code that restarts a service, so only its selection function is loaded here.
    if (Test-Path -LiteralPath $script:guestScriptPath)
    {
        $tokens = $null
        $errors = $null
        $guestAst = [System.Management.Automation.Language.Parser]::ParseFile($script:guestScriptPath, [ref]$tokens, [ref]$errors)
        $script:parseErrors = @($errors)

        $selector = $guestAst.Find({ param ($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Select-QemuGuestAgentService' }, $true)
        if ($selector)
        {
            . ([scriptblock]::Create($selector.Extent.Text))
        }
    }

    function New-GuestService
    {
        param ($Name, $DisplayName, $PathName)

        [pscustomobject]@{ Name = $Name; DisplayName = $DisplayName; PathName = $PathName }
    }

    $script:agent = New-GuestService -Name 'QEMU-GA' -DisplayName 'QEMU Guest Agent' -PathName '"C:\Program Files\Qemu-ga\qemu-ga.exe" -d --retry-path'
    $script:vss = New-GuestService -Name 'QEMU Guest Agent VSS Provider' -DisplayName 'QEMU Guest Agent VSS Provider' -PathName 'C:\Windows\system32\dllhost.exe /Processid:{11111111-2222-3333-4444-555555555555}'
    $script:spooler = New-GuestService -Name 'Spooler' -DisplayName 'Print Spooler' -PathName 'C:\Windows\System32\spoolsv.exe'
}

Describe 'The guest script that restarts the QEMU guest agent' {
    It 'parses without errors' {
        $script:parseErrors | Should -HaveCount 0
    }

    It 'contains only ASCII characters, because the live test sends it as an encoded command' {
        (Get-Content -LiteralPath $script:guestScriptPath -Raw) | Should -Match '^[\x00-\x7F]*$'
    }
}

Describe 'Select-QemuGuestAgentService' {
    It 'picks the agent when the VSS provider is listed first' {
        (Select-QemuGuestAgentService -Service @($script:vss, $script:agent, $script:spooler)).Name | Should -Be 'QEMU-GA'
    }

    It 'picks the agent when the VSS provider is listed last' {
        (Select-QemuGuestAgentService -Service @($script:spooler, $script:agent, $script:vss)).Name | Should -Be 'QEMU-GA'
    }

    It 'finds the agent by its executable when the service has another name' {
        $renamed = New-GuestService -Name 'qemu-guest-agent' -DisplayName 'Guest Agent' -PathName '"C:\Program Files\Qemu-ga\QEMU-GA.EXE"'

        (Select-QemuGuestAgentService -Service @($script:vss, $renamed)).Name | Should -Be 'qemu-guest-agent'
    }

    It 'falls back to the service name QEMU-GA when the path is not known' {
        $noPath = New-GuestService -Name 'QEMU-GA' -DisplayName 'QEMU Guest Agent' -PathName $null

        (Select-QemuGuestAgentService -Service @($script:vss, $noPath)).Name | Should -Be 'QEMU-GA'
    }

    It 'never returns the VSS provider when the agent is not there' {
        Select-QemuGuestAgentService -Service @($script:vss, $script:spooler) | Should -BeNullOrEmpty
    }

    It 'returns nothing for a guest without QEMU services' {
        Select-QemuGuestAgentService -Service @($script:spooler) | Should -BeNullOrEmpty
    }
}
