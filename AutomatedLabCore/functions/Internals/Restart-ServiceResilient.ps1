function Restart-ServiceResilient
{

    [cmdletbinding()]
    param
    (
        [string[]]$ComputerName,
        $ServiceName,
        [switch]$NoNewLine
    )

    Write-LogFunctionEntry

    $jobs = Invoke-LabCommand -ComputerName $ComputerName -AsJob -PassThru -NoDisplay -ActivityName "Restart service '$ServiceName' on computers '$($ComputerName -join ', ')'" -ScriptBlock `
    {
        param
        (
            [string]$ServiceName
        )

        function Get-ServiceRestartInfo
        {
            param
            (
                [string]$ServiceName,
                [switch]$WasStopped,
                [switch]$WasStarted,
                [double]$Index
            )

            $serviceDisplayName = (Get-Service $ServiceName).DisplayName

            $newestEvent = "($((Get-EventLog -LogName System -newest 1).Index)) " + (Get-EventLog -LogName System -newest 1).Message
            Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Get-ServiceRestartInfo - ServiceName: $ServiceName ($serviceDisplayName) - WasStopped: $WasStopped - WasStarted:$WasStarted - Index: $Index - Newest event: $newestEvent"


            $result = $true

            if ($WasStopped)
            {
                $events = @(Get-EventLog -LogName System -Index ($Index..($Index + 10000)) | Where-Object { $_.Message -like "*$serviceDisplayName*entered*stopped*" })
                Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Events found: $($events.count)"
                $result = ($events.count -gt 0)
            }
            if ($WasStarted)
            {
                $events = @(Get-EventLog -LogName System -Index ($Index..($Index + 10000)) | Where-Object { $_.Message -like "*$serviceDisplayName*entered*running*" })
                Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Events found: $($events.count)"
                $result = ($events.count -gt 0)
            }

            Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Result:$result"
            $result
        }


        $BackupVerbosePreference = $VerbosePreference
        $BackupDebugPreference = $DebugPreference
        $VerbosePreference = 'Continue'
        $DebugPreference = 'Continue'

        $ServiceName = 'nlasvc'

        $dependentServices = Get-Service -Name $ServiceName -DependentServices | Where-Object { $_.Status -eq 'Running' } | Select-Object -ExpandProperty Name
        Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Dependent services: '$($dependentServices -join ',')'"


        $serviceDisplayName = (Get-Service $ServiceName).DisplayName
        if ((Get-Service -Name "$ServiceName").Status -eq 'Running')
        {
            $newestEventLogIndex = (Get-EventLog -LogName System -Newest 1).Index
            $retries = 5
            do
            {
                Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Trying to stop service '$ServiceName'"
                $EAPbackup = $ErrorActionPreference
                $WAPbackup = $WarningPreference

                $ErrorActionPreference = 'SilentlyContinue'
                $WarningPreference = 'SilentlyContinue'
                Stop-Service -Name $ServiceName -Force
                $ErrorActionPreference = $EAPbackup
                $WarningPreference = $WAPbackup

                $retries--
                Start-Sleep -Seconds 1
            }
            until ((Get-ServiceRestartInfo -ServiceName $ServiceName -WasStopped -Index $newestEventLogIndex) -or $retries -le 0)
        }

        if ($retries -gt 0)
        {
            Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Service '$ServiceName' has been stopped"
        }
        else
        {
            Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Service '$ServiceName' could NOT be stopped"
            return
        }


        if (-not (Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex))
        {
            #if service did not start by itself
            $newestEventLogIndex = (Get-EventLog -LogName System -Newest 1).Index
            $retries = 5
            do
            {
                Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Trying to start service '$ServiceName'"
                Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
                $retries--
                if (-not (Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex))
                {
                    Start-Sleep -Seconds 1
                }
            }
            until ((Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex) -or $retries -le 0)
        }


        if ($retries -gt 0)
        {
            Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Service '$ServiceName' was started"
        }
        else
        {
            Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Service '$ServiceName' could NOT be started"
            return
        }

        foreach ($dependentService in $dependentServices)
        {
            if (Get-ServiceRestartInfo -ServiceName $dependentService -WasStarted -Index $newestEventLogIndex)
            {
                Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Dependent service '$dependentService' has already auto-started"
            }
            else
            {
                $newestEventLogIndex = (Get-EventLog -LogName System -Newest 1).Index
                $retries = 5
                do
                {
                    Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Trying to start depending service '$dependentService'"
                    Start-Service $dependentService -ErrorAction SilentlyContinue
                    $retries--
                }
                until ((Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex) -or $retries -le 0)

                if (Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex)
                {
                    Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Dependent service '$ServiceName' was started"
                }
                else
                {
                    Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Dependent service '$ServiceName' could NOT be started"
                }
            }
        }

        $VerbosePreference = $BackupVerbosePreference
        $DebugPreference = $BackupDebugPreference
    } -ArgumentList $ServiceName

    Wait-LWLabJob -Job $jobs -NoDisplay -Timeout 30 -NoNewLine:$NoNewLine

    Write-LogFunctionExit
}
