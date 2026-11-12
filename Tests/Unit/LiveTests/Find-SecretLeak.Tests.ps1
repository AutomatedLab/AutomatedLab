BeforeAll {
    . (Join-Path $PSScriptRoot 'Find-SecretLeak.ps1')

    $script:secret = ConvertTo-SecureString -String 'topsecret-value' -AsPlainText -Force
}

# The unit tests of the live-test runner use this helper to prove that no secret reaches the tests. ConvertTo-Json cannot
# do that: it renders a SecureString as {"Length":n} and so hides it. These tests show that the helper can fail.
Describe 'Find-SecretLeak' {
    It 'finds a SecureString nested in a hashtable and an array' {
        $payload = @{ Options = @{ Items = @(1, @{ Token = $script:secret }) } }

        $leaks = @(Find-SecretLeak -InputObject $payload)

        $leaks | Should -HaveCount 1
        $leaks[0] | Should -BeLike '*Token*SecureString*'
    }

    It 'finds a PSCredential in a property of an object' {
        $payload = [pscustomobject]@{ Connection = [pscustomobject]@{ Credential = [pscredential]::new('root@pam', $script:secret) } }

        $leaks = @(Find-SecretLeak -InputObject $payload)

        $leaks | Should -HaveCount 1
        $leaks[0] | Should -BeLike '*Credential*PSCredential*'
    }

    It 'finds secret text in <Where>' -ForEach @(
        @{ Where = 'a value'; Payload = @{ Principal = 'root@pam!live=topsecret-value' } }
        @{ Where = 'a key'; Payload = @{ 'topsecret-value' = 1 } }
        @{ Where = 'an array element'; Payload = @('plain', 'with topsecret-value inside') }
        @{ Where = 'a property'; Payload = [pscustomobject]@{ Note = 'topsecret-value' } }
    ) {
        $leaks = @(Find-SecretLeak -InputObject $Payload -SecretText 'topsecret-value')

        $leaks | Should -HaveCount 1
        $leaks[0] | Should -BeLike '*secret text*'
    }

    It 'does not report the secret itself' {
        $leaks = @(Find-SecretLeak -InputObject @{ Principal = 'topsecret-value' } -SecretText 'topsecret-value')

        ($leaks -join ' ') | Should -Not -BeLike '*topsecret-value*'
    }

    It 'finds nothing in a graph without secrets' {
        $payload = @{
            Ready      = $true
            Port       = 8006
            Started    = [datetime]'2026-11-04'
            Mode       = [System.StringComparison]::Ordinal
            Empty      = $null
            Connection = [pscustomobject]@{ HostName = '192.0.2.10'; Principal = 'root@pam!live' }
            Templates  = @(@{ Name = 'S2025'; VmId = 196 }, @{ Name = 'W11'; VmId = 197 })
        }

        @(Find-SecretLeak -InputObject $payload -SecretText 'topsecret-value') | Should -HaveCount 0
    }

    It 'reports a graph that contains itself instead of walking it forever' {
        $cyclic = @{}
        $cyclic.Self = $cyclic

        $leaks = @(Find-SecretLeak -InputObject $cyclic)

        $leaks | Should -HaveCount 1
        $leaks[0] | Should -BeLike '*not inspected*'
    }
}
