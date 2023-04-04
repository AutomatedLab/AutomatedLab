function Remove-LabVMSnapshot
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByNameAllSnapShots')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByNameSnapshotByName')]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByNameSnapshotByName')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'AllMachinesSnapshotByName')]
        [string]$SnapshotName,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'AllMachinesSnapshotByName')]
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'AllMachinesAllSnapshots')]
        [switch]$AllMachines,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByNameAllSnapShots')]
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'AllMachinesAllSnapshots')]
        [switch]$AllSnapShots
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
        $machines = Get-LabVm -IncludeLinux
    }

    $machines = $machines | Where-Object SkipDeployment -eq $false

    if (-not $machines)
    {
        $message = 'No machine found to remove the snapshot. Either the given name is wrong or there is no machine defined yet'
        Write-LogFunctionExitWithError -Message $message
        return
    }

    $parameters = @{
        ComputerName = $machines.ResourceName
    }

    if ($SnapshotName)
    {
        $parameters.SnapshotName = $SnapshotName
    }
    elseif ($AllSnapShots)
    {
        $parameters.All = $true
    }

    switch ($lab.DefaultVirtualizationEngine)
    {
        'HyperV' { Remove-LWHypervVMSnapshot @parameters}
        'Azure'  { Remove-LWAzureVmSnapshot @parameters}
        'VMWare' { Write-ScreenInfo -Type Warning -Message 'No VMWare snapshots possible, nothing will be removed'}
    }

    Write-LogFunctionExit
}
