function Restore-LWHypervVMSnapshot
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

    $pool = New-RunspacePool -ThrottleLimit 20 -Variable (Get-Variable SnapshotName) -Function (Get-Command Get-LWHypervVM)

    Write-PSFMessage -Message 'Remembering all running machines'
    $jobs = foreach ($n in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -Argument $n,(Get-LabConfigurationItem -Name DoNotAddVmsToCluster -Default $false) -ScriptBlock {
            param ($n, $DisableClusterCheck)

            if ((Get-LWHypervVM -Name $n -DisableClusterCheck $DisableClusterCheck -ErrorAction SilentlyContinue).State -eq 'Running')
            {
                Write-Verbose -Message "    '$n' was running"
                $n
            }
        }
    }

    $runningMachines = $jobs | Receive-RunspaceJob

    $jobs = foreach ($n in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -Argument $n -ScriptBlock {
            param ($n)
            $vm = Get-LWHypervVM -Name $n
            $vm | Hyper-V\Suspend-VM -ErrorAction SilentlyContinue
            $vm | Hyper-V\Save-VM -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 5
        }
    }

    $jobs | Wait-RunspaceJob

    $jobs = foreach  ($n in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -Argument $n -ScriptBlock {
            param (
                [string]$n
            )

            $vm = Get-LWHypervVM -Name $n
            $snapshot = $vm | Get-VMSnapshot | Where-Object Name -eq $SnapshotName

            if (-not $snapshot)
            {
                Write-Error -Message "The machine '$n' does not have a snapshot named '$SnapshotName'"
            }
            else
            {
                $snapshot | Restore-VMSnapshot -Confirm:$false
                $vm | Hyper-V\Set-VM -Notes $snapshot.Notes

                Start-Sleep -Seconds 5
            }
        }
    }

    $result = $jobs | Wait-RunspaceJob -PassThru
    if ($result.Shell.HadErrors)
    {
        foreach ($exception in $result.Shell.Streams.Error.Exception)
        {
            Write-Error -Exception $exception
        }
    }

    Write-PSFMessage -Message "Restore finished, starting the machines that were running previously ($($runningMachines.Count))"

    $jobs = foreach ($n in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -Argument $n,$runningMachines -ScriptBlock {
            param ($n, [string[]]$runningMachines)
            if ($n -in $runningMachines)
            {
                Write-Verbose -Message "Machine '$n' was running, starting it."
                Hyper-V\Start-VM -Name $n -ErrorAction SilentlyContinue
            }
            else
            {
                Write-Verbose -Message "Machine '$n' was NOT running."
            }
        }
    }

    [void] ($jobs | Wait-RunspaceJob)

    $pool | Remove-RunspacePool
    Write-LogFunctionExit
}
