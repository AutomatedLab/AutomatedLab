function Add-LabIsoImageDefinition
{
    [CmdletBinding()]
    param (

        [string]$Name,

        [string]$Path,

        [Switch]$IsOperatingSystem,

        [switch]$NoDisplay
    )

    Write-LogFunctionEntry

    if ($IsOperatingSystem)
    {
        Write-ScreenInfo -Message 'The -IsOperatingSystem switch parameter is obsolete and thereby ignored' -Type Warning
    }

    if (-not $script:lab)
    {
        throw 'Please create a lab before using this cmdlet. To create a new lab, call New-LabDefinition'
    }

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.IsoImage
    #read the cache
    try
    {
        if ($IsLinux -or $IsMacOs) {
            $cachedIsos = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/LocalIsoImages.xml'))
        }
        else
        {
            $cachedIsos = $type::ImportFromRegistry('Cache', 'LocalIsoImages')
        }

        Write-PSFMessage "Read $($cachedIsos.Count) ISO images from the cache"
    }
    catch
    {
        Write-PSFMessage 'Could not read ISO images info from the cache'
        $cachedIsos = New-Object $type
    }

    $lab = try { Get-Lab -ErrorAction Stop } catch { Get-LabDefinition -ErrorAction Stop }
    if ($lab.DefaultVirtualizationEngine -eq 'Azure')
    {
        if (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $Path)
        {
            $isoRoot = 'ISOs'
            if ($Path -notmatch 'ISOs$')
            {
                # Get relative path
                $isoRoot = $Path.Replace($labSources, '')
            }

            if ($isoRoot.StartsWith('\') -or $isoRoot.StartsWith('/') )
            {
                $isoRoot = $isoRoot.Substring(1)
            }

            $isoRoot = $isoRoot.Replace('\','/')

            $isoFiles = Get-LabAzureLabSourcesContent -Path $isoRoot -RegexFilter '\.iso' -File -ErrorAction SilentlyContinue

            if ( -not $IsLinux -and [System.IO.Path]::HasExtension($Path) -or $IsLinux -and $Path -match '\.iso$')
            {
                $isoFiles = $isoFiles | Where-Object {$_.Name -eq (Split-Path -Path $Path -Leaf)}

                if (-not $isoFiles -and $Name)
                {
                    $filterPath = (Split-Path -Path $Path -Leaf) -replace '\\','/' # Due to breaking changes introduced in Az.Storage 4.7.0
                    Write-ScreenInfo -Message "Syncing $filterPath with Azure lab sources storage as it did not exist"
                    Sync-LabAzureLabSources -Filter $filterPath -NoDisplay

                    $isoFiles = Get-LabAzureLabSourcesContent -Path $isoRoot -RegexFilter '\.iso' -File -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq (Split-Path -Path $Path -Leaf)}
                }
            }
        }
        else
        {
            Write-ScreenInfo -Type Warning -Message "$Path is not on Azure LabSources $()! If you intend to use`r`nMount-LabIsoImage it will result in the ISO getting copied to the remote machine!"
            $isoFiles = Get-ChildItem -Path $Path -Filter *.iso -Recurse -ErrorAction SilentlyContinue
        }
    }
    else
    {
        $isoFiles = Get-ChildItem -Path $Path -Filter *.iso -Recurse -ErrorAction SilentlyContinue
    }

    if (-not $isoFiles)
    {
        throw "The specified iso file could not be found or no ISO file could be found in the given folder: $Path"
    }

    $isos = @()
    foreach ($isoFile in $isoFiles)
    {
        if (-not $PSBoundParameters.ContainsKey('Name'))
        {
            $Name = [guid]::NewGuid()
        }
        else
        {
            $cachedIsos.Remove(($cachedIsos | Where-Object Name -eq $name)) | Out-Null
        }

        $iso = New-Object -TypeName AutomatedLab.IsoImage
        $iso.Name = $Name
        $iso.Path = $isoFile.FullName
        $iso.Size = $isoFile.Length

        if ($cachedIsos -contains $iso)
        {
            Write-PSFMessage "The ISO '$($iso.Path)' with a size '$($iso.Size)' is already in the cache."
            $cachedIso = ($cachedIsos -eq $iso)[0]
            if ($PSBoundParameters.ContainsKey('Name'))
            {
                $cachedIso.Name = $Name
            }
            $isos += $cachedIso
        }
        else
        {
            if (-not $script:lab.DefaultVirtualizationEngine -eq 'Azure')
            {
                Write-PSFMessage "The ISO '$($iso.Path)' with a size '$($iso.Size)' is not in the cache. Reading the operating systems from ISO."
                [void] (Mount-DiskImage -ImagePath $isoFile.FullName -StorageType ISO)
                Get-PSDrive | Out-Null #This is just to refresh the drives. Somehow if this cmdlet is not called, PowerShell does not see the new drives.
                $letter = (Get-DiskImage -ImagePath $isoFile.FullName | Get-Volume).DriveLetter
                $isOperatingSystem = (Test-Path "$letter`:\Sources\Install.wim") -or (Test-Path "$letter`:\.discinfo") -or (Test-Path "$letter`:\isolinux") -or (Test-Path "$letter`:\suse")
                [void] (Dismount-DiskImage -ImagePath $isoFile.FullName)
            }

            if ($isOperatingSystem)
            {
                $oses = Get-LabAvailableOperatingSystem -Path $isoFile.FullName
                if ($oses)
                {
                    foreach ($os in $oses)
                    {
                        if ($isos.OperatingSystems -contains $os)
                        {
                            Write-ScreenInfo "The operating system '$($os.OperatingSystemName)' with version '$($os.Version)' is already added to the lab. If this is an issue with cached information, use Clear-LabCache to solve the issue." -Type Warning
                        }
                        $iso.OperatingSystems.Add($os) | Out-Null
                    }
                }
                $cachedIsos.Add($iso) #the new ISO goes into the cache
                $isos += $iso
            }
            else
            {
                $cachedIsos.Add($iso) #ISO is not an OS. Add only if 'Name' is specified. Hence, ISO is manually added
                $isos += $iso
            }
        }
    }

    $duplicateOperatingSystems = $isos | Where-Object { $_.OperatingSystems } |
    Group-Object -Property { "$($_.OperatingSystems.OperatingSystemName) $($_.OperatingSystems.Version)" } |
    Where-Object Count -gt 1

    if ($duplicateOperatingSystems)
    {
        $duplicateOperatingSystems.Group |
        ForEach-Object { $_ } -PipelineVariable iso |
        ForEach-Object { $_.OperatingSystems } |
        ForEach-Object { Write-ScreenInfo "The operating system $($_.OperatingSystemName) version $($_.Version) defined more than once in '$($iso.Path)'" -Type Warning }
    }

    if ($IsLinux -or $IsMacOs)
    {
        $cachedIsos.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/LocalIsoImages.xml'))
    }
    else
    {
        $cachedIsos.ExportToRegistry('Cache', 'LocalIsoImages')
    }

    foreach ($iso in $isos)
    {
        $isosToRemove = $script:lab.Sources.ISOs | Where-Object { $_.Name -eq $iso.Name -or $_.Path -eq $iso.Path }
        foreach ($isoToRemove in $isosToRemove)
        {
            $script:lab.Sources.ISOs.Remove($isoToRemove) | Out-Null
        }

        #$script:lab.Sources.ISOs.Remove($iso) | Out-Null
        $script:lab.Sources.ISOs.Add($iso)
        Write-ScreenInfo -Message "Added '$($iso.Path)'"
    }
    Write-PSFMessage "Final Lab ISO count: $($script:lab.Sources.ISOs.Count)"

    Write-LogFunctionExit
}
