function Mount-LabIsoImage
{
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,

        [Parameter(Mandatory, Position = 1)]
        [string]$IsoPath,

        [switch]$SupressOutput,

        [switch]$PassThru
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

    $machines = $machines | Where-Object HostType -in HyperV,Azure

    foreach ($machine in $machines)
    {
        if (-not $SupressOutput)
        {
            Write-ScreenInfo -Message "Mounting ISO image '$IsoPath' to computer '$machine'" -Type Info
        }

        if ($machine.HostType -eq 'HyperV')
        {
            Mount-LWIsoImage -ComputerName $machine -IsoPath $IsoPath -PassThru:$PassThru
        }
        else
        {
            Mount-LWAzureIsoImage -ComputerName $machine -IsoPath $IsoPath -PassThru:$PassThru
        }
    }

    Write-LogFunctionExit
}
