Import-Module -Name Pode

Start-PodeServer {
    Add-PodeEndpoint -Address 127.0.0.1 -Protocol Http
    New-PodeLoggingMethod -File -Path C:\LabBuilder -Name AlCapode_success | Enable-PodeRequestLogging
    New-PodeLoggingMethod -File -Path C:\LabBuilder -Name AlCapode_error | Enable-PodeErrorLogging

    Import-PodeModule -Name Pester
    Import-PodeModule -Name PSFramework
    Import-PodeModule -Name PSLog
    Import-PodeModule -Name HostsFile
    Import-PodeModule -Name AutomatedLab.Common
    Import-PodeModule -Name AutomatedLabUnattended
    Import-PodeModule -Name AutomatedLabDefinition
    Import-PodeModule -Name PSFileTransfer
    Import-PodeModule -Name AutomatedLabWorker
    Import-PodeModule -Name AutomatedLabNotifications
    Import-PodeModule -Name AutomatedLabTest
    Import-PodeModule -Name AutomatedLab
    
    Enable-PodeSessionMiddleware -Duration 120 -Extend
    Add-PodeAuthIIS -Name 'IISAuth'

    Add-PodeRoute -Method Get -Path '/Lab/:Name' -Authentication 'IISAuth' -ScriptBlock {
        if ($WebEvent.Parameters['Name'])
        {
            $labName = $WebEvent.Parameters['Name']
        }

        if ($labName)
        {
            if ((Get-Lab -List) -notcontains $labName)
            {
                Write-PodeTextResponse -StatusCode 404 -Value "Lab '$labName' not found"
                return
            }

            $lab = Import-Lab -Name $labName -NoValidation -NoDisplay -PassThru

            if ($lab)
            {
                Write-PodeJsonResponse -Value $lab
            }
        }
    }

    Add-PodeRoute -Method Get -Path '/Lab' -Authentication 'IISAuth' -ScriptBlock {
        
        if ($WebEvent.Query['Name'])
        {
            $labName = $WebEvent.Query['Name']
        }
        else
        {
            $labName = $WebEvent.Data.Name
        }

        if ($labName)
        {
            if ((Get-Lab -List) -notcontains $labName)
            {
                Write-PodeTextResponse -StatusCode 404 -Value "Lab '$labName' not found"
                return
            }

            $lab = Import-Lab -Name $labName -PassThru -NoValidation -NoDisplay

            if ($lab)
            {
                Write-PodeJsonResponse -Value $lab
            }
        }

        $labs = Get-Lab -List | Foreach-Object { Import-Lab -NoValidation -NoDisplay -Name $_ -PassThru }
        if ($labs)
        {
            Write-PodeJsonResponse -Value $labs
            return
        }
    }

    Add-PodeRoute -Method Get -Path '/Job' -Authentication 'IISAuth' -ScriptBlock {
        if ($WebEvent.Query['Id'])
        {
            $jobGuid = $WebEvent.Query['Id']
        }
        else
        {
            $jobGuid = $WebEvent.Data.Id
        }

        if (-not $jobGuid)
        {
            [hashtable[]]$jobs = Get-ChildItem -Path C:\LabBuilder\LabJobs -File | Foreach-Object {
                $scheduledTask = Get-ScheduledTask -TaskName "DeployAutomatedLab_$($_.BaseName)" -ErrorAction SilentlyContinue
                $pPath = Join-Path -Path C:\LabBuilder\LabJobs -ChildPath "$($_)_Result.xml"
                if ($scheduledTask)
                {
                    $info = $scheduledTask | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
                    @{
                        Status       = $scheduledTask.State -as [string]
                        LastRunTime  = $info.LastRunTime
                        Result       = $info.LastTaskResult
                        PesterResult = if (Test-Path $pPath) { Get-Content $pPath } else { '' }
                        Name         = $_
                    }
                }
            }

            if ($jobs.Count -gt 0)
            {
                Write-PodeJsonResponse -Value $jobs
            }
            return
        }

        $scheduledTask = Get-ScheduledTask -TaskName "DeployAutomatedLab_$jobGuid" -ErrorAction SilentlyContinue

        if ($scheduledTask)
        {
            $info = $scheduledTask | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
            $pPath = Join-Path -Path C:\LabBuilder\LabJobs -ChildPath "$($jobGuid)_Result.xml"
            $jsonResponse = @{
                Status       = $scheduledTask.State -as [string]
                LastRunTime  = $info.LastRunTime
                Result       = $info.LastTaskResult
                PesterResult = if (Test-Path $pPath) { Get-Content $pPath } else { '' }
                Name         = $jobGuid
            }
            Write-PodeJsonResponse -Value $jsonResponse
        }
        else
        {
            Write-PodeTextResponse -StatusCode 404 -Value "Job with ID '$jobGuid' not found"
        }
        return
    }

    Add-PodeRoute -Method Get -Path '/Job/:id' -Authentication 'IISAuth' -ScriptBlock {
        if ($WebEvent.Parameters['id'])
        {
            $jobGuid = $WebEvent.Parameters['id']
        }

        $scheduledTask = Get-ScheduledTask -TaskName "DeployAutomatedLab_$jobGuid" -ErrorAction SilentlyContinue

        if ($scheduledTask)
        {
            $info = $scheduledTask | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
            $pPath = Join-Path -Path C:\LabBuilder\LabJobs -ChildPath "$($jobGuid)_Result.xml"
            $jsonResponse = @{
                Status      = $scheduledTask.State -as [string]
                LastRunTime = $info.LastRunTime
                Result      = $info.LastTaskResult
                PesterResult = if (Test-Path $pPath) { Get-Content $pPath } else { '' }
                Name        = $jobGuid
            }
            Write-PodeJsonResponse -Value $jsonResponse
            return
        }

        Write-PodeTextResponse -StatusCode 404 -Value "Job with ID '$jobGuid' not found"
        return
    }

    Add-PodeRoute -Method Post -Path '/Lab' -Authentication 'IISAuth' -ScriptBlock {
        if ($WebEvent.Data.LabScript)
        {
            [string]$labScript = $WebEvent.Data.LabScript
        }
        if ($WebEvent.Data.LabBytes)
        {
            [byte[]]$labDefinition = $WebEvent.Data.LabBytes
        }
        
        Enable-LabHostRemoting -Force -NoDisplay

        if ($labScript -and $labDefinition)
        {
            Write-PodeTextResponse -StatusCode 404 -Value "Both LabScript and LabBytes in JSON body!"
            return
        }

        if (-not $labScript -and -not $labDefinition)
        {
            Write-PodeTextResponse -StatusCode 404 -Value "No LabScript or LabBytes in JSON body!"
            return
        }

        $labGuid = (New-Guid).Guid

        if (-not $labScript -and $labDefinition)
        {
            $labDefinition | Export-Clixml -Path "C:\LabBuilder\$($labGuid).xml"
            [string] $labScript = "[byte[]]`$labDefinition = Import-Clixml -Path 'C:\LabBuilder\$($labGuid).xml'; Import-Module AutomatedLab; Remove-Item -Path -Path 'C:\LabBuilder\$($labGuid).xml'"
            $labScript = -join @($labScript, "`r`n[AutomatedLab.Lab]::Import(`$labDefinition); Install-Lab")
        }

        $labScript = -join @($labScript, "`r`nInvoke-LabPester -Lab (Get-Lab) -OutputFile C:\LabBuilder\LabJobs\$($labGuid)_Result.xml")

        if (-not (Test-Path -Path C:\LabBuilder\LabJobs))
        {
            [void] (New-Item -Path C:\LabBuilder\LabJobs -ItemType Directory)
        }

        New-Item -ItemType File -Path C:\LabBuilder\LabJobs\$labGuid
        $command = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($labScript))

        # Due to runspaces used, the international module is not reliably imported. Hence, we are using Windows PowerShell.
        Import-Module -Name C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\ScheduledTasks\ScheduledTasks.psd1
        $action = New-ScheduledTaskAction -Execute 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe' -Argument "-NoProfile -WindowStyle hidden -NoLogo -EncodedCommand $command"

        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
        $trigger.EndBoundary = (Get-Date -Format u).Replace(' ', 'T')
        $opti = New-ScheduledTaskSettingsSet -DeleteExpiredTaskAfter '1.00:00:00' -AllowStartIfOnBatteries -Hidden
        $job = Register-ScheduledTask -TaskName "DeployAutomatedLab_$labGuid" -Action $action -Trigger $trigger -Settings $opti -Force -Description "Deploying`r`n`r`n$labScript" -RunLevel Highest
        $null = $job | Start-ScheduledTask
        $job = $job | Get-ScheduledTask
        $info = $job | Get-ScheduledTaskInfo
        $jsonResponse = @{
            Status      = $job.State -as [string]
            LastRunTime = $info.LastRunTime
            Result      = $info.LastTaskResult
            PesterResult = ''
            Name        = $labGuid
        }
        Write-PodeJsonResponse -Value $jsonResponse
    }

    Add-PodeRoute -Method Delete -Path '/Lab' -Authentication 'IISAuth' -ScriptBlock {
        if ($WebEvent.Query['Name'])
        {
            $labName = $WebEvent.Query['Name']
        }
        else
        {
            $labName = $WebEvent.Data.Name
        }
    
        if (-not $labName)
        {
            Write-PodeTextResponse -StatusCode 404 -Value "No lab name supplied"
            return
        }
        try
        {
            Remove-Lab -Name $labName -Confirm:$false -ErrorAction Stop
        }
        catch
        {
            Write-PodeTextResponse -StatusCode 500 -Value "Error removing $labname"
            return
        }
    
        Write-PodeTextResponse -Value "$labName removed"
    }

    Add-PodeRoute -Method Delete -Path '/Lab/:Name' -Authentication 'IISAuth' -ScriptBlock {
        if ($WebEvent.Parameters['Name'])
        {
            $labName = $WebEvent.Parameters['Name']
        }
        elseif ($WebEvent.Query['Name'])
        {
            $labName = $WebEvent.Query['Name']
        }
        else
        {
            $labName = $WebEvent.Data.Name
        }
    
        if (-not $labName)
        {
            Write-PodeTextResponse -StatusCode 404 -Value "No lab name supplied"
            return
        }
        try
        {
            Remove-Lab -Name $labName -Confirm:$false -ErrorAction Stop
        }
        catch
        {
            Write-PodeTextResponse -StatusCode 500 -Value "Error removing $labname"
            return
        }
    
        Write-PodeTextResponse -Value "$labName removed"
    }
}
