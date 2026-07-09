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
    $machines | Where-Object HostType -notin HyperV, Azure, Proxmox | ForEach-Object {
        Write-ScreenInfo "Using ISO images is only supported with Hyper-V, Azure, or Proxmox VMs. Skipping machine '$($_.Name)'" -Type Warning
    }

    $hypervMachines = $machines | Where-Object HostType -eq HyperV
    $azureMachines = $machines | Where-Object HostType -eq Azure
    $proxmoxMachines = $machines | Where-Object HostType -eq Proxmox

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

    foreach ($proxmoxMachine in $proxmoxMachines)
    {
        if (-not $SupressOutput)
        {
            Write-ScreenInfo -Message "Dismounting currently mounted ISO image on computer '$proxmoxMachine'." -Type Info
        }

        $node = $proxmoxMachine.ProxmoxProperties.TargetNode
        $proxmoxVm = Get-LWProxmoxVM -ComputerName $proxmoxMachine.ResourceName
        if (-not $proxmoxVm)
        {
            Write-ScreenInfo -Message "Proxmox VM '$($proxmoxMachine.Name)' could not be found on any node." -Type Error
            continue
        }

        $null = Remove-LWProxmoxCdDrive -Node $node -VmId $proxmoxVm.vmid -All
    }

    Write-LogFunctionExit
}
