Import-Module Pode
Import-Module AutomatedLab
Enable-LabHostRemoting -Force -NoDisplay

Start-PodeServer {
    Add-PodeEndpoint -Address 127.0.0.1 -Protocol Http
    New-PodeLoggingMethod -File -Path C:\LabBuilder -Name Pode.log | Enable-PodeRequestLogging
    New-PodeLoggingMethod -File -Path C:\LabBuilder -Name PodeErr.log | Enable-PodeErrorLogging
    
    Enable-PodeSessionMiddleware -Duration 120 -Extend
    Add-PodeAuthIIS -Name 'IISAuth'

    Add-PodeRoute -Method Get -Path '/test' -Authentication 'IISAuth' -ScriptBlock {
        Write-PodeJsonResponse -Value @{ User = $WebEvent.Auth.User }
    }

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

            $lab = Import-Lab -Name $labName -PassThru

            if ($lab)
            {
                Write-PodeJsonResponse -Value @{ Labs = @(
                        $lab
                    ) 
                }
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

            $lab = Import-Lab -Name $labName -PassThru

            if ($lab)
            {
                Write-PodeJsonResponse -Value @{ Labs = @(
                        $lab
                    ) 
                }
            }
        }

        $labs = Get-Lab -List
        if ($labs)
        {
            Write-PodeJsonResponse -Value @{ Labs = $labs }
            return
        }

        Write-PodeJsonResponse -Value @{ Labs = @() }
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
            [hashtable[]]$jobs = Get-ChildItem -Path C:\LabBuilder\LabJobs -Directory | Foreach-Object {
                @{
                    Status = 'Running'
                    Name   = $_.Name
                }
            }

            if ($jobs.Count -gt 0)
            {
                Write-PodeJsonResponse -Value $jobs
            }
            return
        }

        $scheduledJob = Get-ScheduledJob -Name $jobGuid -ErrorAction SilentlyContinue
        $job = Get-Job -Name $jobGuid -ErrorAction SilentlyContinue

        if ($scheduledJob -and -not $job)
        {
            $jsonResponse = @{
                Status = 'Running'
                Name   = $jobGuid
            }
            Write-PodeJsonResponse -Value $jsonResponse
        }
        elseif ($scheduledJob -and $job)
        {
            $jsonResponse = @{
                Status = $job.State
                Name   = $jobGuid
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

        $scheduledJob = Get-ScheduledJob -Name $jobGuid -ErrorAction SilentlyContinue
        $job = Get-Job -Name $jobGuid -ErrorAction SilentlyContinue

        if ($scheduledJob -and -not $job)
        {
            $jsonResponse = @{
                Status = 'Running'
                Name   = $jobGuid
            }
            Write-PodeJsonResponse -Value $jsonResponse
            return
        }
        elseif ($scheduledJob -and $job)
        {
            $jsonResponse = @{
                Status = $job.State
                Name   = $jobGuid
            }
            Write-PodeJsonResponse -Value $jsonResponse
            return
        }
        Write-PodeTextResponse -StatusCode 404 -Value "Job with ID '$jobGuid' not found"
        return
    }

    Add-PodeRoute -Method Post -Path '/Lab' -Authentication 'IISAuth' -ScriptBlock {
        [string]$labScript = $WebEvent.Data.LabScript
        $labScriptBlock = [scriptblock]::Create($labScript)
        $labGuid = (New-Guid).Guid

        if (-not (Test-Path -Path C:\LabBuilder\LabJobs))
        {
            [void] (New-Item -Path C:\LabBuilder\LabJobs -ItemType Directory)
        }

        New-Item -ItemType File -Path C:\LabBuilder\LabJobs\$labGuid
        $t = New-JobTrigger -Once -At (Get-Date).AddSeconds(5)
        $job = Register-ScheduledJob -ScriptBlock $labScriptBlock -Name $labGuid -Trigger $t

        $jsonResponse = @{
            Status = 'Queued'
            Name   = $labGuid
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
    
        Write-PodeTextResponse "$labName removed"
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
    
        Write-PodeTextResponse "$labName removed"
    }
}
