function Get-LabAvailableOperatingSystem
{
    [cmdletBinding(DefaultParameterSetName='Local')]
    [OutputType([AutomatedLab.OperatingSystem])]
    param
    (
        [Parameter(ParameterSetName='Local')]
        [string[]]$Path,

        [switch]$UseOnlyCache,

        [switch]$NoDisplay,

        [Parameter(ParameterSetName = 'Azure')]
        [switch]$Azure,

        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        $Location,

        [Parameter(Mandatory, ParameterSetName = 'Proxmox')]
        [switch]$Proxmox,

        [Parameter(ParameterSetName = 'Proxmox')]
        [string[]]$Node
    )

    Write-LogFunctionEntry

    if (-not $Path)
    {
        $Path = "$(Get-LabSourcesLocationInternal -Local)/ISOs"
    }

    $labData = if (Get-LabDefinition -ErrorAction SilentlyContinue) {Get-LabDefinition} elseif (Get-Lab -ErrorAction SilentlyContinue) {Get-Lab}
    if ($labData -and $labData.DefaultVirtualizationEngine -eq 'Azure') { $Azure = $true }
    if ($labData -and $labData.DefaultVirtualizationEngine -eq 'Proxmox' -and -not $Azure.IsPresent) { $Proxmox = $true }
    $storeLocationName = if ($Azure.IsPresent) { 'Azure' } elseif ($Proxmox.IsPresent) { 'Proxmox' } else { 'Local' }

    if ($Azure)
    {
        if (-not (Get-AzContext -ErrorAction SilentlyContinue).Subscription)
        {
            throw 'Please login to Azure before trying to list Azure image SKUs'
        }

        if (-not $Location -and $labData.AzureSettings.DefaultLocation.Location)
        {
            $Location = $labData.AzureSettings.DefaultLocation.DisplayName
        }

        if (-not $Location)
        {
            throw 'Please add your subscription using Add-LabAzureSubscription before viewing available operating systems, or use the parameters -Azure and -Location'
        }

        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Azure.AzureOSImage
        if ($IsLinux -or $IsMacOS)
        {
            $cachedSkus = try { $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath "Stores/$($storeLocationName)OperatingSystems.xml")) } catch { }
        }
        else
        {
            $cachedSkus = try { $type::ImportFromRegistry('Cache', "$($storeLocationName)OperatingSystems") } catch { }
        }

        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.OperatingSystem
        $cachedOsList = New-Object $type
        foreach ($os in $cachedSkus)
        {
            $cachedOs = [AutomatedLab.OperatingSystem]::new($os.AutomatedLabOperatingSystemName)
            if ($cachedOs.OperatingSystemName) {$cachedOsList.Add($cachedOs)}
        }

        if ($UseOnlyCache)
        {
            return $cachedOsList
        }
        
        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.OperatingSystem
        $osList = New-Object $type
        $skus = (Get-LabAzureAvailableSku -Location $Location)

        foreach ($sku in $skus)
        {
            $azureOs = [AutomatedLab.OperatingSystem]::new($sku.AutomatedLabOperatingSystemName)
            if (-not $azureOs.OperatingSystemName) { continue }

            $osList.Add($azureOs )
        }

        $osList.Timestamp = Get-Date
    
        if ($IsLinux -or $IsMacOS)
        {
            $osList.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath "Stores/$($storeLocationName)OperatingSystems.xml"))
        }
        else
        {
            $osList.ExportToRegistry('Cache', "$($storeLocationName)OperatingSystems")
        }

        return $osList.ToArray()
    }

    if ($Proxmox)
    {
        if (-not (Test-LabProxmoxConnection))
        {
            throw 'There is no active connection to a Proxmox cluster. Please call Connect-LabProxmoxCluster before listing available operating systems.'
        }

        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.OperatingSystem

        # Read local ISO-based cache once so we can reverse-map normalised Proxmox tags
        # (e.g. 'windowsserver2025datacenterevaluationdesktopexperience') back to the
        # friendly OS name expected by Add-LabMachineDefinition.
        try
        {
            if ($IsLinux -or $IsMacOS)
            {
                $localCachedOsList = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/LocalOperatingSystems.xml'))
            }
            else
            {
                $localCachedOsList = $type::ImportFromRegistry('Cache', 'LocalOperatingSystems')
            }
        }
        catch
        {
            Write-PSFMessage 'Could not read local OS image cache for Proxmox name resolution'
        }

        $nameMap = @{}

        # Seed the reverse-map from the curated ProductKeys.xml catalog (and the optional
        # user-supplied override). This covers every OS AL ships keys for, even when the
        # matching ISO is not present on this machine.
        $productKeyFiles = @(
            (Get-PSFConfigValue -FullName AutomatedLab.ProductKeyFilePath -FallBack $null)
            (Get-PSFConfigValue -FullName AutomatedLab.ProductKeyFilePathCustom -FallBack $null)
        ) | Where-Object { $_ -and (Test-Path -Path $_) }

        foreach ($productKeyFile in $productKeyFiles)
        {
            try
            {
                [xml]$productKeysXml = Get-Content -Path $productKeyFile -Raw
            }
            catch
            {
                Write-PSFMessage "Could not parse product key catalog '$productKeyFile': $_"
                continue
            }

            foreach ($entry in $productKeysXml.DocumentElement.ChildNodes)
            {
                $osName = $entry.OperatingSystemName
                if (-not $osName) { continue }
                $key = ($osName -replace '[\s\(\)]', '').ToLower()
                if (-not $nameMap.ContainsKey($key))
                {
                    $nameMap[$key] = $osName
                }
            }
        }

        # Locally scanned ISO names take precedence because they represent what is
        # actually installable on this host.
        foreach ($localOs in $localCachedOsList)
        {
            if (-not $localOs.OperatingSystemName) { continue }
            $key = ($localOs.OperatingSystemName -replace '[\s\(\)]', '').ToLower()
            $nameMap[$key] = $localOs.OperatingSystemName
        }

        if ($UseOnlyCache)
        {
            try
            {
                if ($IsLinux -or $IsMacOS)
                {
                    $cachedProxmoxOsList = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath "Stores/$($storeLocationName)OperatingSystems.xml"))
                }
                else
                {
                    $cachedProxmoxOsList = $type::ImportFromRegistry('Cache', "$($storeLocationName)OperatingSystems")
                }
            }
            catch
            {
                Write-PSFMessage 'Could not read Proxmox OS image cache'
            }

            return $cachedProxmoxOsList
        }

        $osList = New-Object $type

        $vmParam = @{ IncludeTemplates = $true; NoCache = $true }
        if ($Node) { $vmParam.Node = $Node }
        $templates = @(Get-LWProxmoxVM @vmParam | Where-Object { $_.template -eq 1 })

        Write-ScreenInfo -Message "Found $($templates.Count) Proxmox template(s) to inspect" -Type Verbose

        $versionPattern = '^\d+(\.\d+){1,3}$'

        foreach ($template in $templates)
        {
            $tags = @($template.tags | Where-Object { $_ })
            if ($tags -notcontains 'template') { continue }

            $versionTag = $tags | Where-Object { $_ -match $versionPattern } | Select-Object -First 1
            $osTag = $tags | Where-Object { $_ -ne 'template' -and $_ -ne $versionTag } | Select-Object -First 1

            if (-not $osTag) { continue }

            $osName = if ($nameMap.ContainsKey($osTag)) { $nameMap[$osTag] } else { $osTag }
            $proxmoxOs = [AutomatedLab.OperatingSystem]::new($osName)
            if (-not $proxmoxOs.OperatingSystemName) { continue }

            if ($versionTag)
            {
                try { $proxmoxOs.Version = [AutomatedLab.Version]$versionTag } catch { }
            }

            # Record the original Proxmox VM/template name so downstream callers
            # (e.g. New-LWProxmoxVM) know which template to clone, analogous to
            # VMWareImageName for vSphere deployments.
            if ($template.Name)
            {
                $proxmoxOs.ProxmoxImageName = $template.Name
            }

            $osList.Add($proxmoxOs)
        }

        $osList.Timestamp = Get-Date

        if ($IsLinux -or $IsMacOS)
        {
            $osList.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath "Stores/$($storeLocationName)OperatingSystems.xml"))
        }
        else
        {
            $osList.ExportToRegistry('Cache', "$($storeLocationName)OperatingSystems")
        }

        return $osList.ToArray()
    }

    if (-not (Test-IsAdministrator))
    {
        throw 'This function needs to be called in an elevated PowerShell session.'
    }

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.OperatingSystem
    $isoFiles = Get-ChildItem -Path $Path -Filter *.iso -Recurse
    Write-PSFMessage "Found $($isoFiles.Count) ISO files"

    #read the cache
    try
    {
        if ($IsLinux -or $IsMacOS)
        {
            $cachedOsList = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath "Stores/$($storeLocationName)OperatingSystems.xml"))
        }
        else
        {
            $cachedOsList = $type::ImportFromRegistry('Cache', "$($storeLocationName)OperatingSystems")
        }

        Write-ScreenInfo -Type Verbose -Message "found $($cachedOsList.Count) OS images in the cache"
    }
    catch
    {
        Write-PSFMessage 'Could not read OS image info from the cache'
    }

    $present, $absent = $cachedOsList.Where({$_.IsoPath -and (Test-Path $_.IsoPath)}, 'Split')
    foreach ($cachedOs in $absent)
    {
        Write-ScreenInfo -Type Verbose -Message "Evicting $cachedOs from cache"
        if ($global:AL_OperatingSystems) { $null = $global:AL_OperatingSystems.Remove($cachedOs) }
        $null = $cachedOsList.Remove($cachedOs)
    }

    if (($UseOnlyCache -and $present))
    {
        Write-ScreenInfo -Type Verbose -Message 'Returning all present ISO files - cache may not be up to date'
        return $present
    }

    $presentFiles = $present.IsoPath | Select-Object -Unique
    $allFiles = ($isoFiles | Where FullName -notin $cachedOsList.MetaData).FullName
    if ($presentFiles -and $allFiles -and -not (Compare-Object -Reference $presentFiles -Difference $allFiles -ErrorAction SilentlyContinue | Where-Object SideIndicator -eq '=>'))
    {
        Write-ScreenInfo -Type Verbose -Message 'ISO cache seems to be up to date'
        if (Test-Path -Path $Path -PathType Leaf)
        {
            return ($present | Where-Object IsoPath -eq $Path)
        }
        else
        {
            return $present
        }
    }

    if ($UseOnlyCache -and -not $present)
    {
        Write-Error -Message "Get-LabAvailableOperatingSystems is used with the switch 'UseOnlyCache', however the cache is empty. Please run 'Get-LabAvailableOperatingSystems' first by pointing to your LabSources\ISOs folder" -ErrorAction Stop
    }

    if (-not $cachedOsList)
    {
        $cachedOsList = New-Object $type
    }

    Write-ScreenInfo -Message "Scanning $($isoFiles.Count) files for operating systems" -NoNewLine

    foreach ($isoFile in $isoFiles)
    {
        if ($cachedOsList.IsoPath -contains $isoFile.FullName) { continue }
        Write-ProgressIndicator
        Write-PSFMessage "Mounting ISO image '$($isoFile.FullName)'"
        $drive = Mount-LabDiskImage -ImagePath $isoFile.FullName -StorageType ISO -PassThru

        Get-PSDrive | Out-Null #This is just to refresh the drives. Somehow if this cmdlet is not called, PowerShell does not see the new drives.

        $opSystems = if ($IsLinux)
        {
            Get-LabImageOnLinux -MountPoint $drive.DriveLetter -IsoFile $isoFile
        }
        else
        {
            Get-LabImageOnWindows -DriveLetter $drive.DriveLetter -IsoFile $isoFile
        }

        if (-not $opSystems)
        {
            $null = $cachedOsList.MetaData.Add($isoFile.FullName)
        }

        foreach ($os in $opSystems)
        {
            $cachedOsList.Add($os)
        }

        Write-PSFMessage 'Dismounting ISO'
        [void] (Dismount-LabDiskImage -ImagePath $isoFile.FullName)
        Write-ProgressIndicator
    }

    $cachedOsList.Timestamp = Get-Date

    if ($IsLinux -or $IsMacOS)
    {
        $cachedOsList.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath "Stores/$($storeLocationName)OperatingSystems.xml"))
    }
    else
    {
        $cachedOsList.ExportToRegistry('Cache', "$($storeLocationName)OperatingSystems")
    }

    if (Test-Path -Path $Path -PathType Leaf)
    {
        $cachedOsList.ToArray() | Where-Object IsoPath -eq $Path
    }
    else
    {
        $cachedOsList.ToArray()
    }

    Write-ProgressIndicatorEnd
    Write-ScreenInfo "Found $($cachedOsList.Count) OS images."
    Write-LogFunctionExit
}
