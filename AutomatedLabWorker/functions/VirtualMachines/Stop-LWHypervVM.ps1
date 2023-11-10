function Stop-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [double]$TimeoutInMinutes,

        [int]$ProgressIndicator,

        [switch]$NoNewLine,

        [switch]$ShutdownFromOperatingSystem = $true
    )

    Write-LogFunctionEntry

    $start = Get-Date

    if ($ShutdownFromOperatingSystem)
    {
        $jobs = @()
        $linux, $windows = (Get-LabVM -ComputerName $ComputerName -IncludeLinux).Where({ $_.OperatingSystemType -eq 'Linux' }, 'Split')

        if ($windows)
        {
            $jobs += Invoke-LabCommand -ComputerName $windows -NoDisplay -AsJob -PassThru -ScriptBlock {
                Stop-Computer -Force -ErrorAction Stop
            }
        }

        if ($linux)
        {
            $jobs += Invoke-LabCommand -UseLocalCredential -ComputerName $linux -NoDisplay -AsJob -PassThru -ScriptBlock {
                #Sleep as background process so that job does not fail.
                [void] (Start-Job -ScriptBlock {
                        Start-Sleep -Seconds 5
                        shutdown -P now
                })
            }
        }

        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine
        $failedJobs = $jobs | Where-Object { $_.State -eq 'Failed' }
        if ($failedJobs)
        {
            Write-ScreenInfo -Message "Could not stop Hyper-V VM(s): '$($failedJobs.Location)'" -Type Error
        }

        $stopFailures = foreach ($failedJob in $failedJobs)
        {
            if (Get-LabVM -ComputerName $failedJob.Location -IncludeLinux)
            {
                $failedJob.Location
            }
        }

        if ($stopFailures)
        {
            Write-ScreenInfo -Message "Force-stopping VMs: $($stopFailures -join ',')"
            Get-LWHypervVM -Name $stopFailures | Hyper-V\Stop-VM -Force
        }
    }
    else
    {
        $jobs = @()
        foreach ($name in (Get-LabVM -ComputerName $ComputerName -IncludeLinux | Where-Object SkipDeployment -eq $false).ResourceName)
        {
            $job = Get-LWHypervVM -Name $name -ErrorAction SilentlyContinue | Hyper-V\Stop-VM -AsJob -Force -ErrorAction Stop
            $job | Add-Member -Name ComputerName -MemberType NoteProperty -Value $name
            $jobs += $job
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 5 -NoNewLine:$NoNewLine -NoDisplay

        #receive the result of all finished jobs. The result should be null except if an error occured. The error will be returned to the caller
        $jobs | Where-Object State -eq completed | Receive-Job
    }

    Write-LogFunctionExit
}
