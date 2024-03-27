function Stop-LabVM
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]$ComputerName,

        [double]$ShutdownTimeoutInMinutes = (Get-LabConfigurationItem -Name Timeout_StopLabMachine_Shutdown),

        [Parameter(ParameterSetName = 'All')]
        [switch]$All,

        [switch]$Wait,

        [int]$ProgressIndicator = (Get-LabConfigurationItem -Name DefaultProgressIndicator),

        [switch]$NoNewLine,

        [switch]$KeepAzureVmProvisioned
    )

    begin
    {
        Write-LogFunctionEntry

        $lab = Get-Lab
        if (-not $lab.Machines)
        {
            Write-Error 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }

        $machines = [System.Collections.Generic.List[AutomatedLab.Machine]]::new()
    }

    process
    {
        if ($ComputerName)
        {
            $null = Get-LabVM -ComputerName $ComputerName -IncludeLinux | Where-Object SkipDeployment -eq $false | Foreach-Object {$machines.Add($_)}
        }
    }

    end
    {
        if ($All)
        {
            $null = Get-LabVM -IncludeLinux | Where-Object { -not $_.SkipDeployment }| Foreach-Object {$machines.Add($_)}
        }

        #filtering out all machines that are already stopped
        $vmStates = Get-LabVMStatus -ComputerName $machines -AsHashTable
        foreach ($vmState in $vmStates.GetEnumerator())
        {
            if ($vmState.Value -eq 'Stopped')
            {
                $machines = $machines | Where-Object Name -ne $vmState.Name
                Write-Debug "Machine $($vmState.Name) is already stopped, removing it from the list of machines to stop"
            }
        }

        if (-not $machines)
        {
            return
        }

        Remove-LabPSSession -ComputerName $machines

        $hypervVms = $machines | Where-Object HostType -eq 'HyperV'
        $azureVms = $machines | Where-Object HostType -eq 'Azure'
        $vmwareVms = $machines | Where-Object HostType -eq 'VMWare'

        if ($hypervVms)
        {
            Stop-LWHypervVM -ComputerName $hypervVms -TimeoutInMinutes $ShutdownTimeoutInMinutes -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine -ErrorAction SilentlyContinue
        }
        if ($azureVms)
        {
            Stop-LWAzureVM -ComputerName $azureVms -ErrorVariable azureErrors -ErrorAction SilentlyContinue -StayProvisioned $KeepAzureVmProvisioned
        }
        if ($vmwareVms)
        {
            Stop-LWVMWareVM -ComputerName $vmwareVms -ErrorVariable vmwareErrors -ErrorAction SilentlyContinue
        }

        $remainingTargets = @()
        if ($hypervErrors) { $remainingTargets += $hypervErrors.TargetObject }
        if ($azureErrors) { $remainingTargets += $azureErrors.TargetObject }
        if ($vmwareErrors) { $remainingTargets += $vmwareErrors.TargetObject }
        
        $remainingTargets = if ($remainingTargets.Count -gt 0) {
            foreach ($remainingTarget in $remainingTargets)
            { 
                if ($remainingTarget -is [string])
                {
                    $remainingTarget
                }
                elseif ($remainingTarget -is [AutomatedLab.Machine])
                {
                    $remainingTarget
                }
                elseif ($remainingTarget -is [System.Management.Automation.Runspaces.Runspace] -and $remainingTarget.ConnectionInfo.ComputerName -as [ipaddress])
                {
                    # Special case - return value is an IP address instead of a host name. We need to look it up.
                    $machines | Where-Object Ipv4Address -eq $remainingTarget.ConnectionInfo.ComputerName
                }
                elseif ($remainingTarget -is [System.Management.Automation.Runspaces.Runspace])
                {
                    $remainingTarget.ConnectionInfo.ComputerName
                }
                else
                {
                    Write-ScreenInfo "Unknown error in 'Stop-LabVM'. Cannot call 'Stop-LabVM2'" -Type Warning
                }
            }
            
        }

        if ($remainingTargets.Count -gt 0) {
            Stop-LabVM2 -ComputerName ($remainingTargets | Sort-Object -Unique)
        }

        if ($Wait)
        {
            Wait-LabVMShutdown -ComputerName $machines -TimeoutInMinutes $ShutdownTimeoutInMinutes
        }

        Write-LogFunctionExit
    }
}
