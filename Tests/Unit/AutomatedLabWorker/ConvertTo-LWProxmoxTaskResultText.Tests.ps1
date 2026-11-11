Describe 'ConvertTo-LWProxmoxTaskResultText' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker\functions\Internals\ConvertTo-LWProxmoxTaskResultText.ps1')

        $script:rbdText = "rbd snapshot base-701-disk-1/vm-7057-disk-1 to 'DJSRV2022R005_VMCheckpoint' error: Rolling back to snapshot: 0% complete...failed."
    }

    It 'returns the exit status that Wait-LWProxmoxTasksStatus returns as a string for one task' {
        ConvertTo-LWProxmoxTaskResultText -TaskResult $script:rbdText | Should -BeExactly $script:rbdText
    }

    It 'reads the exit status of a task object, which Windows PowerShell returns for one task' {
        $taskResult = [pscustomobject]@{
            Upid       = 'UPID:pve2:00001234:qmrollback:7057:root@pam:'
            ExitStatus = $script:rbdText
            Status     = 'stopped'
        }

        ConvertTo-LWProxmoxTaskResultText -TaskResult $taskResult | Should -BeExactly $script:rbdText
    }

    It 'joins the exit statuses of several tasks' {
        $taskResult = @(
            [pscustomobject]@{
                Upid       = 'UPID:1'
                ExitStatus = 'OK'
                Status     = 'stopped'
            }
            [pscustomobject]@{
                Upid       = 'UPID:2'
                ExitStatus = 'WARNINGS: 1'
                Status     = 'stopped'
            }
        )

        ConvertTo-LWProxmoxTaskResultText -TaskResult $taskResult | Should -BeExactly 'OK; WARNINGS: 1'
    }

    It 'says that no exit status arrived when the wait returned nothing' {
        ConvertTo-LWProxmoxTaskResultText -TaskResult $null -TimeoutInSeconds 600 | Should -BeExactly 'no exit status within 600 seconds'
    }
}
