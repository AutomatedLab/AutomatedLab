function Wait-LWLabJob
{
    Param
    (
        [Parameter(Mandatory, ParameterSetName = 'ByJob')]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.Management.Automation.Job[]]$Job,

        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]$Name,

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = (Get-LabConfigurationItem -Name DefaultProgressIndicator),

        [int]$Timeout = 120,

        [switch]$NoNewLine,

        [switch]$NoDisplay,

        [switch]$PassThru
    )

    if (-not $PSBoundParameters.ContainsKey('ProgressIndicator')) { $PSBoundParameters.Add('ProgressIndicator', $ProgressIndicator) } #enables progress indicator

    Write-LogFunctionEntry

    Write-ProgressIndicator

    if (-not $Job -and -not $Name)
    {
        Write-PSFMessage 'There is no job to wait for'
        Write-LogFunctionExit
        return
    }

    $start = (Get-Date)

    if ($Job)
    {
        $jobs = Get-Job -Id $Job.ID
    }
    else
    {
        $jobs = Get-Job -Name $Name
    }

    Write-ScreenInfo -Message "Waiting for job(s) to complete with ID(s): $($jobs.Id -join ', ')" -TaskStart

    if ($jobs -and ($jobs.State -contains 'Running' -or $jobs.State -contains 'AtBreakpoint'))
    {
        $jobs = Get-Job -Id $jobs.ID
        $ProgressIndicatorTimer = Get-Date
        do
        {
            Start-Sleep -Seconds 1
            if (((Get-Date) - $ProgressIndicatorTimer).TotalSeconds -ge $ProgressIndicator)
            {
                Write-ProgressIndicator
                $ProgressIndicatorTimer = Get-Date
            }
        }
        until (($jobs.State -notcontains 'Running' -and $jobs.State -notcontains 'AtBreakPoint') -or ((Get-Date) -gt ($Start.AddMinutes($Timeout))))
    }

    Write-ProgressIndicatorEnd

    if ((Get-Date) -gt ($Start.AddMinutes($Timeout)))
    {
        $jobs = Get-Job -Id $jobs.Id | Where-Object State -eq Running
        Write-Error -Message "Timeout while waiting for job $($jobs.ID -join ', ')"
    }
    else
    {
        Write-ScreenInfo -Message 'Job(s) no longer running' -TaskEnd

        if ($PassThru)
        {
            $result = $jobs | Receive-Job -ErrorAction SilentlyContinue -ErrorVariable jobErrors
            $result
            #PSRemotingTransportException are very likely due to restarts or problems AL cannot recover
            $jobErrors = $jobErrors | Where-Object { $_.Exception -isnot [System.Management.Automation.Remoting.PSRemotingTransportException] }
            foreach ($jobError in $jobErrors)
            {
                Write-Error -ErrorRecord $jobError
            }
        }
    }

    Write-LogFunctionExit
}
