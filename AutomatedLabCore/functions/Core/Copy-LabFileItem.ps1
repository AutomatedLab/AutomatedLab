function Copy-LabFileItem
{
    param (
        [Parameter(Mandatory)]
        [string[]]$Path,

        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [string]$DestinationFolderPath,

        [switch]$Recurse,

        [bool]$FallbackToPSSession = $true,

        [bool]$UseAzureLabSourcesOnAzureVm = $true,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName
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

    $connectedMachines = @{ }

    foreach ($machine in $machines)
    {
        $cred = $machine.GetCredential((Get-Lab))

        if ($machine.HostType -eq 'HyperV' -or
            (-not $UseAzureLabSourcesOnAzureVm -and $machine.HostType -eq 'Azure') -or
            ($path -notlike "$labSources*" -and $machine.HostType -eq 'Azure')
        )
        {
            try
            {
                if ($DestinationFolderPath -match ':')
                {
                    $letter = ($DestinationFolderPath -split ':')[0]
                    $drive = New-PSDrive -Name "$($letter)_on_$machine" -PSProvider FileSystem -Root "\\$machine\$($letter)`$" -Credential $cred -ErrorAction Stop
                }
                else
                {
                    $drive = New-PSDrive -Name "C_on_$machine" -PSProvider FileSystem -Root "\\$machine\c$" -Credential $cred -ErrorAction Stop
                }
                Write-Debug -Message "Drive '$($drive.Name)' created"
                $connectedMachines.Add($machine.Name, $drive)
            }
            catch
            {
                if (-not $FallbackToPSSession)
                {
                    Microsoft.PowerShell.Utility\Write-Error -Message "Could not create a SMB connection to '$machine' ('\\$machine\c$'). Files could not be copied." -TargetObject $machine -Exception $_.Exception
                    continue
                }

                $session = New-LabPSSession -ComputerName $machine -IgnoreAzureLabSources
                foreach ($p in $Path)
                {

                    $destination = if (-not $DestinationFolderPath)
                    {
                        '/'
                    }
                    else
                    {
                        $DestinationFolderPath
                    }
                    try
                    {
                        Send-Directory -SourceFolderPath $p -Session $session -DestinationFolderPath $destination
                        if ($PassThru)
                        {
                            $destination
                        }
                    }
                    catch
                    {
                        Write-Error -ErrorRecord $_
                    }
                }
            }
        }
        else
        {
            foreach ($p in $Path)
            {
                $session = New-LabPSSession -ComputerName $machine
                $folderName = Split-Path -Path $p -Leaf
                $targetFolder = if ($folderName -eq "*")
                {
                    "\"
                }
                else
                {
                    $folderName
                }
                $destination = if (-not $DestinationFolderPath)
                {
                    Join-Path -Path (Get-LabConfigurationItem -Name OsRoot) -ChildPath $targetFolder
                }
                else
                {
                    Join-Path -Path $DestinationFolderPath -ChildPath $targetFolder
                }

                Invoke-LabCommand -ComputerName $machine -ActivityName Copy-LabFileItem -ScriptBlock {

                    Copy-Item -Path $p -Destination $destination -Recurse -Force

                } -NoDisplay -Variable (Get-Variable -Name p, destination)
            }

        }
    }

    Write-Verbose -Message "Copying the items '$($Path -join ', ')' to machines '$($connectedMachines.Keys -join ', ')'"

    foreach ($machine in $connectedMachines.GetEnumerator())
    {
        Write-Debug -Message "Starting copy job for machine '$($machine.Name)'..."

        if ($DestinationFolderPath)
        {
            $drive = "$($machine.Value):"
            $newDestinationFolderPath = Split-Path -Path $DestinationFolderPath -NoQualifier
            $newDestinationFolderPath = Join-Path -Path $drive -ChildPath $newDestinationFolderPath

            if (-not (Test-Path -Path $newDestinationFolderPath))
            {
                New-Item -ItemType Directory -Path $newDestinationFolderPath | Out-Null
            }
        }
        else
        {
            $newDestinationFolderPath = "$($machine.Value):\"
        }

        foreach ($p in $Path)
        {
            try
            {
                Copy-Item -Path $p -Destination $newDestinationFolderPath -Recurse -Force -ErrorAction Stop
                Write-Debug -Message '...finished'
                if ($PassThru)
                {
                    Join-Path -Path $DestinationFolderPath -ChildPath (Split-Path -Path $p -Leaf)
                }
            }
            catch
            {
                Write-Error -ErrorRecord $_
            }
        }

        $machine.Value | Remove-PSDrive
        Write-Debug -Message "Drive '$($drive.Name)' removed"
        Write-Verbose -Message "Files copied on to machine '$($machine.Name)'"
    }

    Write-LogFunctionExit
}
