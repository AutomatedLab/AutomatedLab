function Get-LabVMSnapshot
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string[]]
        $ComputerName,

        [Parameter()]
        [string]
        $SnapshotName
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
        $machines = Get-LabVM -IncludeLinux | Where-Object -Property Name -in $ComputerName
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
        VMName = $machines
        ErrorAction = 'SilentlyContinue'
    }

    if ($SnapshotName)
    {
        $parameters.Name = $SnapshotName
    }

    switch ($lab.DefaultVirtualizationEngine)
    {
        'HyperV' { Get-LWHypervVMSnapshot @parameters}
        'Azure'  { Get-LWAzureVmSnapshot @parameters}
        'VMWare' { Write-ScreenInfo -Type Warning -Message 'No VMWare snapshots possible, nothing will be listed'}
    }

    Write-LogFunctionExit
}
