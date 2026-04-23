function Wait-LabVMRestart
{
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName,

        [switch]$DoNotUseCredSsp,

        [double]$TimeoutInMinutes = (Get-LabConfigurationItem -Name Timeout_WaitLabMachine_Online),

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = (Get-LabConfigurationItem -Name DefaultProgressIndicator),

        [AutomatedLab.Machine[]]$StartMachinesWhileWaiting,

        [switch]$NoNewLine,

        $MonitorJob,

        [DateTime]$MonitoringStartTime = (Get-Date)
    )

    begin
    {
        Write-LogFunctionEntry

        if (-not $PSBoundParameters.ContainsKey('ProgressIndicator')) { $PSBoundParameters.Add('ProgressIndicator', $ProgressIndicator) } #enables progress indicator

        $lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }

        $vms = [System.Collections.Generic.List[AutomatedLab.Machine]]::new()
    }

    process
    {
        $null = Get-LabVM -ComputerName $ComputerName | Where-Object SkipDeployment -eq $false | Foreach-Object {$vms.Add($_)}
    }

    end
    {
        $azureVms = $vms | Where-Object HostType -eq 'Azure'
        $hypervVms = $vms | Where-Object HostType -eq 'HyperV'
        $proxmoxVms = $vms | Where-Object HostType -eq 'Proxmox'
        $vmwareVms = $vms | Where-Object HostType -eq 'VMWare'

        if ($azureVms)
        {
            $param = @{
                ComputerName = $azureVms
                DoNotUseCredSsp = $DoNotUseCredSsp
                TimeoutInMinutes = $TimeoutInMinutes
                ProgressIndicator = $ProgressIndicator
                NoNewLine = $NoNewLine
                ErrorAction = 'SilentlyContinue'
                ErrorVariable = 'azureWaitError'
                MonitoringStartTime = $MonitoringStartTime
            }
            Wait-LWAzureRestartVM @param
        }

        if ($hypervVms)
        {
            $param = @{
                ComputerName = $hypervVms
                TimeoutInMinutes = $TimeoutInMinutes
                ProgressIndicator = $ProgressIndicator
                NoNewLine = $NoNewLine
                StartMachinesWhileWaiting = $StartMachinesWhileWaiting
                ErrorAction = 'SilentlyContinue'
                ErrorVariable = 'hypervWaitError'
                MonitorJob = $MonitorJob
            }
            Wait-LWHypervVMRestart @param
        }

        if ($proxmoxVms)
        {
            $param = @{
                ComputerName = $proxmoxVms
                TimeoutInMinutes = $TimeoutInMinutes
                ProgressIndicator = $ProgressIndicator
                NoNewLine = $NoNewLine
                StartMachinesWhileWaiting = $StartMachinesWhileWaiting
                ErrorAction = 'SilentlyContinue'
                ErrorVariable = 'proxmoxWaitError'
                MonitoringStartTime = $MonitoringStartTime
                MonitorJob = $MonitorJob
                DoNotUseCredSsp = $DoNotUseCredSsp
            }
            Wait-LWProxmoxRestartVM @param
        }

        if ($vmwareVms)
        {
            $param = @{
                 ComputerName = $vmwareVms
                 TimeoutInMinutes = $TimeoutInMinutes
                 ProgressIndicator = $ProgressIndicator
                 ErrorAction = 'SilentlyContinue'
                 ErrorVariable = 'vmwareWaitError'
            }
            Wait-LWVMWareRestartVM @param
        }

        $waitError = New-Object System.Collections.ArrayList
        if ($azureWaitError) { $waitError.AddRange($azureWaitError) }
        if ($hypervWaitError) { $waitError.AddRange($hypervWaitError) }
        if ($proxmoxWaitError) { $waitError.AddRange($proxmoxWaitError) }
        if ($vmwareWaitError) { $waitError.AddRange($vmwareWaitError) }

        $waitError = $waitError | Where-Object { $_.Exception.Message -like 'Timeout while waiting for computers to restart*' }
        if ($waitError)
        {
            $nonRestartedMachines = $waitError.TargetObject

            Write-Error "The following machines have not restarted in the timeout of $TimeoutInMinutes minute(s): $($nonRestartedMachines -join ', ')"
        }

        Write-LogFunctionExit
    }
}
