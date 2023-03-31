function Stop-LWAzureVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]
        $ComputerName,

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = (Get-LabConfigurationItem -Name DefaultProgressIndicator),

        [switch]
        $NoNewLine,

        [switch]
        $ShutdownFromOperatingSystem,

        [bool]
        $StayProvisioned = $false
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    if (-not $PSBoundParameters.ContainsKey('ProgressIndicator')) { $PSBoundParameters.Add('ProgressIndicator', $ProgressIndicator) } #enables progress indicator

    $lab = Get-Lab
    $machines = Get-LabVm -ComputerName $ComputerName -IncludeLinux
    $azureVms = Get-AzVM -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName

    $azureVms = $azureVms | Where-Object { $_.Name -in $machines.ResourceName }

    if ($ShutdownFromOperatingSystem)
    {
        $jobs = @()
        $linux, $windows = $machines.Where( { $_.OperatingSystemType -eq 'Linux' }, 'Split')

        $jobs += Invoke-LabCommand -ComputerName $windows -NoDisplay -AsJob -PassThru -ScriptBlock {
            Stop-Computer -Force -ErrorAction Stop
        }

        $jobs += Invoke-LabCommand -UseLocalCredential -ComputerName $linux -NoDisplay -AsJob -PassThru -ScriptBlock {
            #Sleep as background process so that job does not fail.
            [void] (Start-Job {
                    Start-Sleep -Seconds 5
                    shutdown -P now
                })
        }

        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator
        $failedJobs = $jobs | Where-Object { $_.State -eq 'Failed' }
        if ($failedJobs)
        {
            Write-ScreenInfo -Message "Could not stop Azure VM(s): '$($failedJobs.Location)'" -Type Error
        }
    }
    else
    {
        $jobs = foreach ($name in $machines.ResourceName)
        {
            $vm = $azureVms | Where-Object Name -eq $name
            $vm | Stop-AzVM -Force -StayProvisioned:$StayProvisioned -AsJob
        }

        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator
        $failedJobs = $jobs | Where-Object { $_.State -eq 'Failed' }
        if ($failedJobs)
        {
            $jobNames = ($failedJobs | ForEach-Object {
                    if ($_.Name.StartsWith("StopAzureVm_"))
                    {
                        ($_.Name -split "_")[1]
                    }
                    elseif ($_.Name -match "Long Running Operation for 'Stop-AzVM' on resource '(?<MachineName>[\w-]+)'")
                    {
                        $Matches.MachineName
                    }
                }) -join ", "

            Write-ScreenInfo -Message "Could not stop Azure VM(s): '$jobNames'" -Type Error
        }
    }

    Write-ProgressIndicatorEnd

    Write-LogFunctionExit
}
