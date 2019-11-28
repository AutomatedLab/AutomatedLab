New-PolarisRouteMiddleware -Name JsonBodyParser -ScriptBlock {
    if ($Request.BodyString -ne $null)
    {
        $Request.Body = $Request.BodyString | ConvertFrom-Json
    }
}

New-PolarisGetRoute -Path /Labs -ScriptBlock {
    $labs = Get-Lab -List | ConvertTo-Json
    $response.Json($labs)
}

New-PolarisPostRoute -Path /Lab -ScriptBlock {

    [string]$labScript = $request.Body.LabScript
    $labScriptBlock = [scriptblock]::Create($labScript)
    $labGuid = (New-Guid).Guid

    if (-not (Test-Path -Path C:\Polaris\LabJobs))
    {
        [void] (New-Item -Path C:\Polaris\LabJobs -ItemType Directory)
    }

    New-Item -ItemType File -Path C:\Polaris\LabJobs\$labGuid
    $t = New-JobTrigger -Once -At (Get-Date).AddSeconds(5)
    $job = Register-ScheduledJob -ScriptBlock $labScriptBlock -Name $labGuid -Trigger $t
    $response.Send($labGuid)
}

New-PolarisGetRoute -Force -Verbose -Path /Lab -ScriptBlock {

    if ($request.Query['Name'])
    {
        $labName = $request.Query['Name']

        if ((Get-Lab -List) -notcontains $labName)
        {
            $response.SetStatusCode(404)
            $response.Send("Lab '$labName' not found")
            return
        }

        $lab = Import-Lab -Name $labName -PassThru

        if ($lab)
        {
            $response.Json(($lab | ConvertTo-Json))
        }
    }
    elseif ($request.Query['Id'])
    {
        $jobGuid = $request.Query['Id']
        $scheduledJob = Get-ScheduledJob -Name $jobGuid -ErrorAction SilentlyContinue
        $job = Get-Job -Name $jobGuid -ErrorAction SilentlyContinue

        if ($scheduledJob -and -not $job)
        {
            $jsonResponse = @{
                Status = 'Running'
                Name   = $jobGuid
            } | ConvertTo-Json
            $response.Json($jsonResponse)
        }
        elseif ($scheduledJob -and $job)
        {
            $jsonResponse = @{
                Status = $job.State
                Name   = $jobGuid
            } | ConvertTo-Json
            $response.Json($jsonResponse)
        }
        else
        {
            $response.SetStatusCode(404)
            $response.Send("Job with ID '$jobGuid' not found")
        }
    }
}

New-PolarisDeleteRoute -Path /Lab -ScriptBlock {
    if ($request.Query['Name'])
    {
        $labName = $request.Query['Name']
    }
    else
    {
        $labName = $request.Body.Name
    }

    if (-not $labName)
    {
        $response.SetStatusCode(404)
        $response.Send("No lab name supplied")
        return
    }
    try
    {
        Remove-Lab -Name $labName -Confirm:$false -ErrorAction Stop
    }
    catch
    {
        $repsonse.SetStatusCode(500)
        $response.Send("Error removing $labname")
        return
    }

    $response.Send("$labName removed")
}

Start-Polaris -Port 80
while ($true)
{ Start-Sleep 1 }
