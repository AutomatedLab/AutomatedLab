function Mount-LWIsoImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,

        [Parameter(Mandatory, Position = 1)]
        [string]$IsoPath,

        [switch]$PassThru
    )

    if (-not (Test-Path -Path $IsoPath -PathType Leaf))
    {
        Write-Error "The path '$IsoPath' could not be found or is pointing to a folder"
        return
    }

    $IsoPath = (Resolve-Path -Path $IsoPath).Path
    $machines = Get-LabVM -ComputerName $ComputerName

    foreach ($machine in $machines)
    {
        Write-PSFMessage -Message "Adding DVD drive '$IsoPath' to machine '$machine'"
        $start = (Get-Date)
        $done = $false
        $delayBeforeCheck = 5, 10, 15, 30, 45, 60
        $delayIndex = 0

        $dvdDrivesBefore = Invoke-LabCommand -ComputerName $machine -ScriptBlock {
            Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType = 5 AND FileSystem LIKE "%"' | Select-Object -ExpandProperty DeviceID
        } -PassThru -NoDisplay

        #this is required as Compare-Object cannot work with a null object
        if (-not $dvdDrivesBefore) { $dvdDrivesBefore = @() }

        while ((-not $done) -and ($delayIndex -le $delayBeforeCheck.Length))
        {
            try
            {
                $vm = Get-LWHypervVM -Name $machine.ResourceName
                if ($machine.OperatingSystem.Version -ge '6.2')
                {
                    $drive = $vm | Add-VMDvdDrive -Path $IsoPath -ErrorAction Stop -Passthru -AllowUnverifiedPaths
                }
                else
                {
                    if (-not ($vm | Get-VMDvdDrive))
                    {
                        throw "No DVD drive exist for machine '$machine'. Machine is generation 1 and DVD drive needs to be crate in advance (during creation of the machine). Cannot continue."
                    }
                    $drive = $vm | Set-VMDvdDrive -Path $IsoPath -ErrorAction Stop -Passthru -AllowUnverifiedPaths
                }

                Start-Sleep -Seconds $delayBeforeCheck[$delayIndex]

                if (($vm | Get-VMDvdDrive).Path -contains $IsoPath)
                {
                    $done = $true
                }
                else
                {
                    Write-ScreenInfo -Message "DVD drive '$IsoPath' was NOT successfully added to machine '$machine'. Retrying." -Type Error
                    $delayIndex++
                }
            }
            catch
            {
                Write-ScreenInfo -Message "Could not add DVD drive '$IsoPath' to machine '$machine'. Retrying." -Type Warning
                Start-Sleep -Seconds $delayBeforeCheck[$delayIndex]
            }
        }

        $dvdDrivesAfter = Invoke-LabCommand -ComputerName $machine -ScriptBlock {
            Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType = 5 AND FileSystem LIKE "%"' | Select-Object -ExpandProperty DeviceID
        } -PassThru -NoDisplay

        $driveLetter = (Compare-Object -ReferenceObject $dvdDrivesBefore -DifferenceObject $dvdDrivesAfter).InputObject
        $drive | Add-Member -Name DriveLetter -MemberType NoteProperty -Value $driveLetter
        $drive | Add-Member -Name InternalComputerName -MemberType NoteProperty -Value $machine.Name

        if ($PassThru) { $drive }

        if (-not $done)
        {
            throw "Could not add DVD drive '$IsoPath' to machine '$machine' after repeated attempts."
        }
    }
}
