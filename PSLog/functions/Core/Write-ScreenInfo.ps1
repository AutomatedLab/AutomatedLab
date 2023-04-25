function Write-ScreenInfo
{

    param
    (
        [Parameter(Position = 1)]
        [string[]]$Message,

        [Parameter(Position = 2)]
        [timespan]$TimeDelta,

        [Parameter(Position = 3)]
        [timespan]$TimeDelta2,

        [ValidateSet('Error', 'Warning', 'Info', 'Verbose', 'Debug')]
        [string]$Type = 'Info',

        [switch]$NoNewLine,

        [switch]$TaskStart,

        [switch]$TaskEnd,

        [switch]$OverrideNoDisplay
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if ((Get-PSCallStack)[1].InvocationInfo.BoundParameters['NoDisplay'].IsPresent -and -not $OverrideNoDisplay)
    {
        return
    }

    if (-not $Global:AL_DeploymentStart)
    {
        $Global:AL_DeploymentStart = (Get-Date)
    }
    if (-not $Global:taskStart)
    {
        [datetime[]]$Global:taskStart = @()
        $Global:taskStart += (Get-Date)
    }
    elseif ($TaskStart)
    {
        $Global:taskStart += (Get-Date)
    }
    elseif ($TaskEnd)
    {
        $TimeDelta2 = ((Get-Date) - $Global:taskStart[-1])

        $newSize = ($Global:taskStart).Length - 1
        if ($newSize -lt 0) { $newSize = 0 }
        #Replaced Select-Object with array indexing because of https://github.com/PowerShell/PowerShell/issues/9185
        $Global:taskStart = $Global:taskStart[0..(($Global:taskStart).Length - 1)] #$Global:taskStart | Select-Object -First (($Global:taskStart).Length - 1)
    }


    if (-not $TimeDelta -and $Global:AL_DeploymentStart)
    {
        $TimeDelta = (Get-Date) - $Global:AL_DeploymentStart
    }
    if (-not $TimeDelta2 -and $Global:taskStart[-1])
    {
        $TimeDelta2 = (Get-Date) - $Global:taskStart[-1]
    }

    $timeDeltaString = '{0:d2}:{1:d2}:{2:d2}' -f $TimeDelta.Hours, $TimeDelta.Minutes, $TimeDelta.Seconds
    $timeDeltaString2 = '{0:d2}:{1:d2}:{2:d2}.{3:d3}' -f $TimeDelta2.Hours, $TimeDelta2.Minutes, $TimeDelta2.Seconds, $TimeDelta2.Milliseconds

    $date = Get-Date
    $timeCurrent = '{0:d2}:{1:d2}:{2:d2}' -f $date.Hour, $date.Minute, $date.Second

    $Message | Foreach-Object {
        Write-PSFMessage -Level Verbose $_
    }

    if ($NoNewLine)
    {
        if ($Global:PSLog_NoNewLine)
        {
            switch ($Type)
            {
                Error { Microsoft.PowerShell.Utility\Write-Host $Message -NoNewline -ForegroundColor Red }
                Warning { Microsoft.PowerShell.Utility\Write-Host $Message -NoNewline -ForegroundColor DarkYellow }
                Info { Microsoft.PowerShell.Utility\Write-Host $Message -NoNewline }
                Debug { if ($DebugPreference -eq 'Continue') { Microsoft.PowerShell.Utility\Write-Host $Message -NoNewline -ForegroundColor Cyan } }
                Verbose { if ($VerbosePreference -eq 'Continue') { Microsoft.PowerShell.Utility\Write-Host $Message -NoNewline -ForegroundColor Cyan } }
            }
        }
        else
        {
            if ($Global:PSLog_Indent -gt 0) { $Message = ('  ' * ($Global:PSLog_Indent - 1)) + '- ' + $Message }

            switch ($Type)
            {
                Error { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $Message" -NoNewline -ForegroundColor Red }
                Warning { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $Message" -NoNewline -ForegroundColor Yellow }
                Info { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $Message" -NoNewline }
                Debug { if ($DebugPreference -eq 'Continue') { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $Message" -NoNewline -ForegroundColor Cyan } }
                Verbose { if ($VerbosePreference -eq 'Continue') { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $Message" -NoNewline -ForegroundColor Cyan } }
            }

            $Message | ForEach-Object { Write-PSFMessage -Level Verbose -Message "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" }
        }
        $Global:PSLog_NoNewLine = $true
    }
    else
    {
        if ($Global:PSLog_NoNewLine)
        {
            switch ($Type)
            {
                Error
                {
                    $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host $_ -ForegroundColor Red }
                    $Global:PSLog_NoNewLine = $false
                }
                Warning
                {
                    $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host $_ -ForegroundColor Yellow }
                    $Global:PSLog_NoNewLine = $false
                }
                Info
                {
                    $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host $_ }
                    $Global:PSLog_NoNewLine = $false
                }
                Verbose
                {
                    if ($VerbosePreference -eq 'Continue')
                    {
                        $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host $_ -ForegroundColor Cyan }
                        $Global:PSLog_NoNewLine = $false
                    }
                }
                Debug
                {
                    if ($DebugPreference -eq 'Continue')
                    {
                        $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host $_ -ForegroundColor Cyan }
                        $Global:PSLog_NoNewLine = $false
                    }
                }
            }
        }
        else
        {
            if ($Global:PSLog_Indent -gt 0) { $Message = ('  ' * ($Global:PSLog_Indent - 1)) + '- ' + $Message }
            $Message | ForEach-Object { Write-PSFMessage -Level Verbose -Message "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" }
            switch ($Type)
            {
                Error
                {
                    $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" -ForegroundColor Red }
                }
                Warning
                {
                    $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" -ForegroundColor Yellow }
                }
                Info
                {
                    $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" }
                }
                Debug
                {
                    if ($DebugPreference -eq 'Continue')
                    {
                        $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" -ForegroundColor Cyan }
                    }
                }
                Verbose
                {
                    if ($VerbosePreference -eq 'Continue')
                    {
                        $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" -ForegroundColor Cyan }
                    }
                }
            }
        }
    }

    if ($TaskStart)
    {
        $Global:PSLog_Indent++
    }

    if ($TaskEnd)
    {
        $Global:PSLog_Indent--
        if ($Global:PSLog_Indent -lt 0) { $Global:PSLog_Indent = 0 }
    }

}
