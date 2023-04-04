function Wait-LabADReady
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [int]$TimeoutInMinutes = 15,

        [int]$ProgressIndicator,

        [switch]$NoNewLine
    )

    Write-LogFunctionEntry

    $start = Get-Date

    $machines = Get-LabVM -ComputerName $ComputerName
    $machines | Add-Member -Name AdRetries -MemberType NoteProperty -Value 2 -Force

    $ProgressIndicatorTimer = (Get-Date)
    do
    {
        foreach ($machine in $machines)
        {
            if ($machine.AdRetries)
            {
                $adReady = Test-LabADReady -ComputerName $machine

                if ($DebugPreference)
                {
                    Write-Debug -Message "Return '$adReady' from '$($machine)'"
                }

                if ($adReady)
                {
                    $machine.AdRetries--
                }
            }

            if (-not $machine.AdRetries)
            {
                Write-PSFMessage -Message "Active Directory is now ready on Domain Controller '$machine'"
            }
            else
            {
                Write-Debug "Active Directory is NOT ready yet on Domain Controller: '$machine'"
            }
        }

        if (((Get-Date) - $ProgressIndicatorTimer).TotalSeconds -ge $ProgressIndicator)
        {
            if ($ProgressIndicator)
            {
                Write-ProgressIndicator
            }
            $ProgressIndicatorTimer = (Get-Date)
        }

        if ($DebugPreference)
        {
            $machines | ForEach-Object {
                Write-Debug -Message "$($_.Name.PadRight(18)) $($_.AdRetries)"
            }
        }

        if ($machines | Where-Object { $_.AdRetries })
        {
            Start-Sleep -Seconds 3
        }
    }
    until (($machines.AdRetries | Measure-Object -Maximum).Maximum -le 0 -or (Get-Date).AddMinutes(-$TimeoutInMinutes) -gt $start)

    if ($ProgressIndicator -and -not $NoNewLine)
    {
        Write-ProgressIndicatorEnd
    }

    if (($machines.AdRetries | Measure-Object -Maximum).Maximum -le 0)
    {
        Write-PSFMessage -Message 'Domain Controllers specified are now ready:'
        Write-PSFMessage -Message ($machines.Name -join ', ')
    }
    else
    {
        $machines | Where-Object { $_.AdRetries -gt 0 } | ForEach-Object {
            Write-Error -Message "Timeout occured waiting for Active Directory to be ready on Domain Controller: $_. Retry count is $($_.AdRetries)" -TargetObject $_
        }
    }

    Write-LogFunctionExit
}
