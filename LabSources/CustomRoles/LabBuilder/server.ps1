Import-Module -Name Pode
Import-Module -Name AutomatedLab
Enable-LabHostRemoting -Force -NoDisplay

Start-PodeServer {
    Add-PodeEndpoint -Address 127.0.0.1 -Protocol Http
    New-PodeLoggingMethod -File -Path C:\LabBuilder -Name AlCapode_success | Enable-PodeRequestLogging
    New-PodeLoggingMethod -File -Path C:\LabBuilder -Name AlCapode_error | Enable-PodeErrorLogging
    
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
        [string]$labScript = $WebEvent.Data.LabScript

        if (-not $labScript)
        {
            Write-PodeTextResponse -StatusCode 404 -Value "No LabScript in JSON body!"
            return
        }

        $labGuid = (New-Guid).Guid
        $labScript = -join @($labScript, "`r`nInvoke-LabPester -Lab (Get-Lab) -OutputFile C:\LabBuilder\LabJobs\$($labGuid)_Result.xml")

        if (-not (Test-Path -Path C:\LabBuilder\LabJobs))
        {
            [void] (New-Item -Path C:\LabBuilder\LabJobs -ItemType Directory)
        }

        New-Item -ItemType File -Path C:\LabBuilder\LabJobs\$labGuid
        $command = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($labScript))

        # Due to runspaces used, the international module is not reliably imported. Hence, we are using Windows PowerShell.
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
