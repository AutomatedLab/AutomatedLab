function Dismount-LabIsoImage
{
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,

        [switch]$SupressOutput
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName | Where-Object SkipDeployment -eq $false
    if (-not $machines)
    {
        Write-LogFunctionExitWithError -Message 'The specified machines could not be found'
        return
    }
    if ($machines.Count -ne $ComputerName.Count)
    {
        $machinesNotFound = Compare-Object -ReferenceObject $ComputerName -DifferenceObject ($machines.Name)
        Write-ScreenInfo "The specified machine(s) $($machinesNotFound.InputObject -join ', ') could not be found" -Type Warning
    }
    $machines | Where-Object HostType -notin HyperV, Azure | ForEach-Object {
        Write-ScreenInfo "Using ISO images is only supported with Hyper-V VMs or on Azure. Skipping machine '$($_.Name)'" -Type Warning
    }

    $hypervMachines = $machines | Where-Object HostType -eq HyperV
    $azureMachines = $machines | Where-Object HostType -eq Azure

    if ($azureMachines)
    {
        Dismount-LWAzureIsoImage -ComputerName $azureMachines
    }

    foreach ($hypervMachine in $hypervMachines)
    {
        if (-not $SupressOutput)
        {
            Write-ScreenInfo -Message "Dismounting currently mounted ISO image on computer '$hypervMachine'." -Type Info
        }

        Dismount-LWIsoImage -ComputerName $hypervMachine
    }

    Write-LogFunctionExit
}
