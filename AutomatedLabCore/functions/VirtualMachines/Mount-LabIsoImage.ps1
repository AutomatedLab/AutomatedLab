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
    $machines | Where-Object HostType -notin HyperV, Azure, Proxmox | ForEach-Object {
        Write-ScreenInfo "Using ISO images is only supported with Hyper-V, Azure, or Proxmox VMs. Skipping machine '$($_.Name)'" -Type Warning
    }

    $machines = $machines | Where-Object HostType -in HyperV, Azure, Proxmox

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
        elseif ($machine.HostType -eq 'Azure')
        {
            Mount-LWAzureIsoImage -ComputerName $machine -IsoPath $IsoPath -PassThru:$PassThru
        }
        elseif ($machine.HostType -eq 'Proxmox')
        {
            $node = $machine.ProxmoxProperties.TargetNode
            $proxmoxVm = Get-LWProxmoxVM -ComputerName $machine.ResourceName
            if (-not $proxmoxVm)
            {
                Write-ScreenInfo -Message "Proxmox VM '$($machine.Name)' could not be found on any node." -Type Error
                continue
            }

            $dvdDrivesBefore = Invoke-LabCommand -ComputerName $machine -ScriptBlock {
                Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType = 5 AND FileSystem LIKE "%"' | Select-Object -ExpandProperty DeviceID
            } -PassThru -NoDisplay

            if (-not $dvdDrivesBefore) { $dvdDrivesBefore = @() }

            $isoFileName = Split-Path -Path $IsoPath -Leaf
            $mountResult = Mount-LWProxmoxIsoImage -Node $node -VmId $proxmoxVm.vmid -IsoFile $isoFileName

            if ($PassThru -and $mountResult)
            {
                # Wait for the guest OS to recognise the new CD-ROM drive
                $driveLetter = $null
                $delaySeconds = 5, 10, 15, 30
                foreach ($delay in $delaySeconds)
                {
                    Start-Sleep -Seconds $delay

                    $dvdDrivesAfter = Invoke-LabCommand -ComputerName $machine -ScriptBlock {
                        Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType = 5 AND FileSystem LIKE "%"' | Select-Object -ExpandProperty DeviceID
                    } -PassThru -NoDisplay

                    if (-not $dvdDrivesAfter) { $dvdDrivesAfter = @() }

                    $driveLetter = (Compare-Object -ReferenceObject $dvdDrivesBefore -DifferenceObject $dvdDrivesAfter -ErrorAction SilentlyContinue).InputObject
                    if ($driveLetter) { break }
                }

                $mountResult | Add-Member -Name DriveLetter -MemberType NoteProperty -Value $driveLetter
                $mountResult | Add-Member -Name InternalComputerName -MemberType NoteProperty -Value $machine.Name
                $mountResult
            }
        }
    }

    Write-LogFunctionExit
}
