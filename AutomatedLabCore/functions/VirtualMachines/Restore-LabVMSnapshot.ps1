function Restore-LabVMSnapshot
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [string]$SnapshotName,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [switch]$All
    )

    Write-LogFunctionEntry

    if (-not (Get-LabVM))
    {
        Write-Error 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $lab = Get-Lab

    if ($ComputerName)
    {
        $machines = Get-LabVM -IncludeLinux | Where-Object { $_.Name -in $ComputerName }
    }
    else
    {
        $machines = Get-LabVM -IncludeLinux
    }

    $machines = $machines | Where-Object SkipDeployment -eq $false

    if (-not $machines)
    {
        $message = 'No machine found to restore the snapshot. Either the given name is wrong or there is no machine defined yet'
        Write-LogFunctionExitWithError -Message $message
        return
    }

    Remove-LabPSSession -ComputerName $machines

    switch ($lab.DefaultVirtualizationEngine)
    {
        'HyperV' { Restore-LWHypervVMSnapshot -ComputerName $machines.ResourceName -SnapshotName $SnapshotName}
        'Azure'  { Restore-LWAzureVmSnapshot -ComputerName $machines.ResourceName -SnapshotName $SnapshotName}
        'VMWare' { Write-ScreenInfo -Type Error -Message 'Restoring snapshots of VMWare VMs is not yet implemented'}
    }

    Write-LogFunctionExit
}
