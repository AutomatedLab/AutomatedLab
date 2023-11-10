function Checkpoint-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string]$SnapshotName
    )

    Write-LogFunctionEntry

    $step1 = {
        param ($Name, $DisableClusterCheck)
        $vm = Get-LWHypervVM -Name $Name -DisableClusterCheck $DisableClusterCheck -ErrorAction SilentlyContinue
        if ($vm.State -eq 'Running' -and -not ($vm | Get-VMSnapshot -Name $SnapshotName -ErrorAction SilentlyContinue))
        {
            $vm | Hyper-V\Suspend-VM -ErrorAction SilentlyContinue
            $vm | Hyper-V\Save-VM -ErrorAction SilentlyContinue

            Write-Verbose -Message "'$Name' was running"
            $Name
        }
    }
    $step2 = {
        param ($Name, $DisableClusterCheck)
        $vm = Get-LWHypervVM -Name $Name -DisableClusterCheck $DisableClusterCheck -ErrorAction SilentlyContinue
        if (-not ($vm | Get-VMSnapshot -Name $SnapshotName -ErrorAction SilentlyContinue))
        {
            $vm | Hyper-V\Checkpoint-VM -SnapshotName $SnapshotName
        }
        else
        {
            Write-Error "A snapshot with the name '$SnapshotName' already exists for machine '$Name'"
        }
    }
    $step3 = {
        param ($Name, $RunningMachines, $DisableClusterCheck)
        if ($Name -in $RunningMachines)
        {
            Write-Verbose -Message "Machine '$Name' was running, starting it."
            Get-LWHypervVM -Name $Name -DisableClusterCheck $DisableClusterCheck -ErrorAction SilentlyContinue | Hyper-V\Start-VM -ErrorAction SilentlyContinue
        }
        else
        {
            Write-Verbose -Message "Machine '$Name' was NOT running."
        }
    }

    $pool = New-RunspacePool -ThrottleLimit 20 -Variable (Get-Variable -Name SnapshotName) -Function (Get-Command Get-LWHypervVM)

    $jobsStep1 = foreach ($Name in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -ScriptBlock $step1 -Argument $Name,(Get-LabConfigurationItem -Name DoNotAddVmsToCluster -Default $false)
    }

    $runningMachines = $jobsStep1 | Receive-RunspaceJob

    $jobsStep2 = foreach ($Name in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -ScriptBlock $step2 -Argument $Name,(Get-LabConfigurationItem -Name DoNotAddVmsToCluster -Default $false)
    }

    [void] ($jobsStep2 | Wait-RunspaceJob)

    $jobsStep3 = foreach ($Name in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -ScriptBlock $step3 -Argument $Name, $runningMachines,(Get-LabConfigurationItem -Name DoNotAddVmsToCluster -Default $false)
    }

    [void] ($jobsStep3 | Wait-RunspaceJob)

    $pool | Remove-RunspacePool

    Write-LogFunctionExit
}
