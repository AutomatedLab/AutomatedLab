function Stop-LabVM2
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string[]]$ComputerName,

        [int]$ShutdownTimeoutInMinutes = (Get-LabConfigurationItem -Name Timeout_StopLabMachine_Shutdown)
    )

    $scriptBlock = {
        $sessions = quser.exe
        $sessionNames = $sessions |
        Select-Object -Skip 1 |
        ForEach-Object -Process {
            ($_.Trim() -split ' +')[2]
        }

        Write-Verbose -Message "There are $($sessionNames.Count) open sessions"
        foreach ($sessionName in $sessionNames)
        {
            Write-Verbose -Message "Closing session '$sessionName'"
            logoff.exe $sessionName
        }

        Start-Sleep -Seconds 2

        Write-Verbose -Message 'Stopping machine forcefully'
        Stop-Computer -Force
    }

    $jobs = Invoke-LabCommand -ComputerName $ComputerName -ActivityName Shutdown -NoDisplay -ScriptBlock $scriptBlock -AsJob -PassThru -ErrorAction SilentlyContinue
    $jobs | Wait-Job -Timeout ($ShutdownTimeoutInMinutes * 60) | Out-Null

    if (-not $jobs -or ($jobs.Count -ne ($jobs | Where-Object State -eq Completed).Count))
    {
        Write-ScreenInfo "Not all machines stopped in the timeout of $ShutdownTimeoutInMinutes" -Type Warning
    }
}
