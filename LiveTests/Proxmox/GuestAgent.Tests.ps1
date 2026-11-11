param
(
    [hashtable]$LiveTest
)

# Clones every selected template into a throwaway VM, starts it and exercises the QEMU guest agent path that
# AutomatedLab provisioning depends on: waited commands, their failure modes and the loss of a command result when
# the agent restarts. The clones are tagged, have no network adapter and are removed afterwards.
#
# Setup errors are caught in BeforeAll and reported by the first test. An error that escapes BeforeAll is reported
# by Pester 6 as a stray break or continue statement, which hides the real cause.

BeforeDiscovery {
    # An empty -ForEach array fails discovery in recent Pester versions, so a run without live-test data gets one
    # placeholder case. The Describe skips itself anyway.
    $vmCases = @(@{ TemplateName = 'none'; TemplateVmId = 0; Node = ''; VmName = '' })
    if ($LiveTest -and $LiveTest.Ready)
    {
        $vmCases = @($LiveTest.Templates | ForEach-Object {
                @{
                    TemplateName = $_.Name
                    TemplateVmId = $_.VmId
                    Node         = $_.Node
                    VmName       = $_.VmName
                }
            })
    }
}

Describe 'QEMU guest agent live tests' -Tag 'ProxmoxLive', 'GuestAgent' -Skip:(-not ($LiveTest -and $LiveTest.Ready)) {
    It 'run against at least one template' {
        @($LiveTest.Templates).Count | Should -BeGreaterThan 0
    }
}

Describe 'QEMU guest agent in a clone of <TemplateName>' -ForEach $vmCases -Tag 'ProxmoxLive', 'GuestAgent' -Skip:(-not ($LiveTest -and $LiveTest.Ready)) {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'ProxmoxLiveTest.Support.ps1')

        $script:vm = $null
        $script:setupError = $null
        try
        {
            $template = [pscustomobject]@{ Name = $TemplateName; VmId = $TemplateVmId; Node = $Node }
            $cloneParameters = @{
                Template  = $template
                Name      = $VmName
                FullClone = [bool]$LiveTest.Options.FullClone
            }
            if ($LiveTest.Options.Storage)
            {
                $cloneParameters.Storage = $LiveTest.Options.Storage
            }

            $script:vm = New-ProxmoxLiveTestVm @cloneParameters
            $null = Start-ProxmoxLiveTestVm -Vm $script:vm
            Wait-ProxmoxLiveTestVmReady -Vm $script:vm
        }
        catch
        {
            $script:setupError = $_.Exception.Message
        }
    }

    AfterAll {
        if ($script:vm -and -not $LiveTest.Options.KeepVm)
        {
            try
            {
                $null = Remove-ProxmoxLiveTestVm -Vm $script:vm -Confirm:$false
            }
            catch
            {
                Write-Warning "Could not remove the live-test VM '$($script:vm.Name)': $($_.Exception.Message) Use -RemoveLeftovers."
            }
        }
    }

    It 'starts the clone and finds its guest agent ready' {
        $script:setupError | Should -BeNullOrEmpty -Because "the clone of '$TemplateName' must start with a working guest agent"
    }

    It 'answers a guest agent ping' {
        if ($script:setupError) { Set-ItResult -Skipped -Because 'the clone could not be set up'; return }

        (New-PveNodesQemuAgentPing -Node $script:vm.Node -Vmid $script:vm.VmId).StatusCode | Should -Be 200
    }

    It 'runs a command and waits for it to succeed' {
        if ($script:setupError) { Set-ItResult -Skipped -Because 'the clone could not be set up'; return }

        $failure = Invoke-ProxmoxLiveTestWorkerCommand -ArgumentList $script:vm.Name -ScriptBlock {
            param ($name)

            try { Start-LWProxmoxAgentExecutionOnVM -ComputerName $name -Command 'cmd /c ver' -Wait } catch { $_ }
        }

        $failure | Should -BeNullOrEmpty -Because "the command failed with: $failure"
    }

    It 'fails with the exit code of a command that fails' {
        if ($script:setupError) { Set-ItResult -Skipped -Because 'the clone could not be set up'; return }

        $failure = Invoke-ProxmoxLiveTestWorkerCommand -ArgumentList $script:vm.Name -ScriptBlock {
            param ($name)

            try { Start-LWProxmoxAgentExecutionOnVM -ComputerName $name -Command 'cmd /c exit 3' -Wait } catch { $_ }
        }

        $failure | Should -Not -BeNullOrEmpty
        $failure.Exception.Message | Should -BeLike '*exit code 3*'
    }

    It 'gives up on a command that outlasts -TimeoutSeconds' {
        if ($script:setupError) { Set-ItResult -Skipped -Because 'the clone could not be set up'; return }

        $failure = Invoke-ProxmoxLiveTestWorkerCommand -ArgumentList $script:vm.Name -ScriptBlock {
            param ($name)

            try { Start-LWProxmoxAgentExecutionOnVM -ComputerName $name -Command 'powershell.exe -NoProfile -Command Start-Sleep -Seconds 60' -Wait -TimeoutSeconds 5 } catch { $_ }
        }

        $failure | Should -Not -BeNullOrEmpty
        $failure.Exception.Message | Should -BeLike '*did not finish within 5 seconds*'
    }

    It 'words an unknown process id the way AutomatedLab expects' {
        if ($script:setupError) { Set-ItResult -Skipped -Because 'the clone could not be set up'; return }

        $reply = Get-PveNodesQemuAgentExecStatus -Node $script:vm.Node -Vmid $script:vm.VmId -Pid_ 2000000000

        $reply.StatusCode | Should -Not -Be 200
        # Keep this pattern in sync with $unknownProcessPattern in Start-LWProxmoxAgentExecutionOnVM.
        $reply.ReasonPhrase | Should -Match '(?i)invalid parameter .pid.|\bpid(\s+\S+)?\s+does not exist\b' -Because "AutomatedLab recognises a lost command result by this wording; Proxmox answered '$($reply.ReasonPhrase)'"
    }

    Context 'When the guest agent restarts during a command' -Tag 'Outage' -Skip:(-not ($LiveTest -and $LiveTest.Ready -and $LiveTest.Capabilities.OutageHandling)) {
        It 'reports the lost result, and the agent runs commands again afterwards' {
            if ($script:setupError) { Set-ItResult -Skipped -Because 'the clone could not be set up'; return }

            # A task running as SYSTEM restarts the agent service eight seconds from now. The task lives outside the
            # agent's process tree, so the restart cannot take itself down.
            $restartScript = @'
$ErrorActionPreference = 'Stop'
$service = Get-Service | Where-Object { $_.Name -eq 'QEMU-GA' -or $_.DisplayName -like '*QEMU*Guest*Agent*' } | Select-Object -First 1
if (-not $service) { throw 'The QEMU guest agent service was not found in the guest.' }
$command = "Start-Sleep -Seconds 8; Restart-Service -Name '$($service.Name)' -Force"
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -NonInteractive -Command "{0}"' -f $command)
Register-ScheduledTask -TaskName 'ALLiveRestartAgent' -Action $action -User 'SYSTEM' -RunLevel Highest -Force | Out-Null
Start-ScheduledTask -TaskName 'ALLiveRestartAgent'
'@
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($restartScript))

            $scheduleFailure = Invoke-ProxmoxLiveTestWorkerCommand -ArgumentList $script:vm.Name, "powershell.exe -NoProfile -NonInteractive -EncodedCommand $encoded" -ScriptBlock {
                param ($name, $command)

                try { Start-LWProxmoxAgentExecutionOnVM -ComputerName $name -Command $command -Wait } catch { $_ }
            }
            $scheduleFailure | Should -BeNullOrEmpty -Because "scheduling the agent restart failed: $scheduleFailure"

            $failure = Invoke-ProxmoxLiveTestWorkerCommand -ArgumentList $script:vm.Name -ScriptBlock {
                param ($name)

                try { Start-LWProxmoxAgentExecutionOnVM -ComputerName $name -Command 'powershell.exe -NoProfile -Command Start-Sleep -Seconds 90' -Wait -TimeoutSeconds 150 -StatusFailureToleranceSeconds 120 } catch { $_ }
            }

            $failure | Should -Not -BeNullOrEmpty -Because 'the command ran to its end, so the agent was not restarted while it ran'
            $failure.FullyQualifiedErrorId | Should -Match '^ProxmoxAgentCommandResultLost(,|$)' -Because "the error was: $($failure.Exception.Message)"

            $ready = Invoke-ProxmoxLiveTestWorkerCommand -ArgumentList $script:vm.Node, $script:vm.VmId, $script:vm.Name -ScriptBlock {
                param ($node, $vmid, $name)

                Wait-LWProxmoxGuestAgentReady -Node $node -Vmid $vmid -Name $name -TimeoutSeconds 300 -RequireExec
            }
            @($ready)[-1] | Should -Be $true
        }
    }
}
