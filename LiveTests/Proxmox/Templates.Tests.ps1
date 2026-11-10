param
(
    [hashtable]$LiveTest
)

# Read-only checks of the templates the runner selected. They explain, before any VM is cloned, why a later test
# would fail: a missing guest agent option, or a second template for the same operating system.
#
# Lookup errors are caught in BeforeAll and reported by the first test. An error that escapes BeforeAll is reported
# by Pester 6 as a stray break or continue statement, which hides the real cause.

BeforeDiscovery {
    # An empty -ForEach array fails discovery in recent Pester versions, so a run without live-test data gets one
    # placeholder case. The Describe skips itself anyway.
    $templateCases = @(@{ TemplateName = 'none'; TemplateVmId = 0; Node = ''; OsTag = '' })
    if ($LiveTest -and $LiveTest.Ready)
    {
        $templateCases = @($LiveTest.Templates | ForEach-Object {
                @{
                    TemplateName = $_.Name
                    TemplateVmId = $_.VmId
                    Node         = $_.Node
                    OsTag        = $_.OsTag
                }
            })
    }
}

Describe 'Proxmox templates' -Tag 'ProxmoxLive', 'ReadOnly' -Skip:(-not ($LiveTest -and $LiveTest.Ready)) {
    It 'provides the templates selected for the run' {
        @($LiveTest.Templates).Count | Should -BeGreaterThan 0
    }
}

Describe 'Proxmox template <TemplateName>' -ForEach $templateCases -Tag 'ProxmoxLive', 'ReadOnly' -Skip:(-not ($LiveTest -and $LiveTest.Ready)) {
    BeforeAll {
        $script:lookupError = $null
        $script:allTemplates = @()
        $script:templateConfig = $null
        try
        {
            $script:allTemplates = @(Get-LWProxmoxVM -IncludeTemplates -NoCache | Where-Object { $_.template -eq 1 })

            $reply = Get-PveNodesQemuConfig -Node $Node -Vmid $TemplateVmId
            if ($reply.StatusCode -ne 200)
            {
                throw "reading the configuration failed: $($reply.ReasonPhrase)"
            }
            $script:templateConfig = $reply.Response.data
        }
        catch
        {
            $script:lookupError = $_.Exception.Message
        }
    }

    It 'can be read from the host' {
        $script:lookupError | Should -BeNullOrEmpty -Because "the template '$TemplateName' must be readable"
    }

    It 'is a template that AutomatedLab recognises' {
        if ($script:lookupError) { Set-ItResult -Skipped -Because 'the template could not be read'; return }

        $template = $script:allTemplates | Where-Object { [int]$_.vmid -eq $TemplateVmId } | Select-Object -First 1

        $template | Should -Not -BeNullOrEmpty
        @($template.tags) | Should -Contain 'template'
    }

    It 'is the only template for its operating system tag' {
        if ($script:lookupError) { Set-ItResult -Skipped -Because 'the template could not be read'; return }

        $sameOs = @($script:allTemplates | Where-Object { @($_.tags) -contains 'template' -and @($_.tags) -contains $OsTag })

        $sameOs.Count | Should -Be 1 -Because "New-LWProxmoxVM refuses to clone when several templates carry the tag '$OsTag': $(($sameOs.name) -join ', ')"
    }

    It 'has the QEMU guest agent enabled in its VM options' {
        if ($script:lookupError) { Set-ItResult -Skipped -Because 'the template could not be read'; return }

        $agent = [string]$script:templateConfig.agent

        $agent | Should -Match '^(1|enabled=1)' -Because "the option 'agent' is '$agent'. Enable it in the VM options of the template and install the QEMU guest agent in the guest"
    }
}
