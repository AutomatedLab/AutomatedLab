function Remove-LWHypervVMSnapshot
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory, ParameterSetName = 'BySnapshotName')]
        [Parameter(Mandatory, ParameterSetName = 'AllSnapshots')]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'BySnapshotName')]
        [string]$SnapshotName,

        [Parameter(ParameterSetName = 'AllSnapshots')]
        [switch]$All
    )

    Write-LogFunctionEntry
    $pool = New-RunspacePool -ThrottleLimit 20 -Variable (Get-Variable -Name SnapshotName,All -ErrorAction SilentlyContinue) -Function (Get-Command Get-LWHypervVM)

    $jobs = foreach ($n in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -Argument $n,(Get-LabConfigurationItem -Name DoNotAddVmsToCluster -Default $false) -ScriptBlock {
            param ($n, $DisableClusterCheck)
            $vm = Get-LWHypervVM -Name $n -DisableClusterCheck $DisableClusterCheck
            if ($SnapshotName)
            {
                $snapshot = $vm | Get-VMSnapshot | Where-Object -FilterScript {
                    $_.Name -eq $SnapshotName
                }
            }
            else
            {
                $snapshot = $vm | Get-VMSnapshot
            }

            if (-not $snapshot)
            {
                Write-Error -Message "The machine '$n' does not have a snapshot named '$SnapshotName'"
            }
            else
            {
                $snapshot | Remove-VMSnapshot -IncludeAllChildSnapshots -ErrorAction SilentlyContinue
            }
        }
    }

    $jobs | Receive-RunspaceJob

    $pool | Remove-RunspacePool

    Write-LogFunctionExit
}
