function New-LabDefinition
{
    [CmdletBinding()]
    param (
        [string]$Name,

        [string]$VmPath = (Get-LabConfigurationItem -Name VmPath),

        [int]$ReferenceDiskSizeInGB = 50,

        [long]$MaxMemory = 0,

        [hashtable]$Notes,

        [switch]$UseAllMemory = $false,

        [switch]$UseStaticMemory = $false,

        [ValidateSet('Azure', 'HyperV', 'VMWare')]
        [string]$DefaultVirtualizationEngine,

        [switch]$Passthru
    )

    Write-LogFunctionEntry
    $global:PSLog_Indent = 0

    $hostOSVersion = ([Environment]::OSVersion).Version
    if (-Not $IsLinux -and (($hostOSVersion -lt [System.Version]'6.2') -or (($hostOSVersion -ge [System.Version]'6.4') -and ($hostOSVersion.Build -lt '14393'))))
    {
        $osName = $(([Environment]::OSVersion).VersionString.PadRight(10))
        $osBuild = $(([Environment]::OSVersion).Version.ToString().PadRight(11))
        Write-PSFMessage -Level Host '***************************************************************************'
        Write-PSFMessage -Level Host ' THIS HOST MACHINE IS NOT RUNNING AN OS SUPPORTED BY AUTOMATEDLAB!'
        Write-PSFMessage -Level Host ''
        Write-PSFMessage -Level Host '   Operating System detected as:'
        Write-PSFMessage -Level Host "     Name:  $osName"
        Write-PSFMessage -Level Host "     Build: $osBuild"
        Write-PSFMessage -Level Host ''
        Write-PSFMessage -Level Host ' AutomatedLab is supported on the following virtualization platforms'
        Write-PSFMessage -Level Host ''
        Write-PSFMessage -Level Host ' - Microsoft Azure'
        Write-PSFMessage -Level Host ' - Windows 2016 1607 or newer'
        Write-PSFMessage -Level Host ' - Windows 10 1607 or newer'
        Write-PSFMessage -Level Host ' - Windows 8.1 Professional or Enterprise'
        Write-PSFMessage -Level Host ' - Windows 2012 R2'

        Write-PSFMessage -Level Host '***************************************************************************'
    }

    if ($DefaultVirtualizationEngine -eq 'Azure')
    {
        Clear-Lab
        $null = Test-LabAzureModuleAvailability -ErrorAction SilentlyContinue
    }

    #settings for a new log

    #reset the log and its format
    $Global:AL_DeploymentStart = $null
    $Global:taskStart = @()
    $Global:indent = 0
    $global:AL_CurrentLab = $null

    $Global:labDeploymentNoNewLine = $false

    $Script:reservedAddressSpaces = $null

    Write-ScreenInfo -Message 'Initialization' -TimeDelta ([timespan]0) -TimeDelta2 ([timespan]0) -TaskStart

    $hostOsName = if (($IsLinux -or $IsMacOs) -and (Get-Command -Name lsb_release -ErrorAction SilentlyContinue)) 
    {
        lsb_release -d -s
    }
    elseif (-not ($IsLinux -or $IsMacOs)) # easier than IsWindows, which does not exist in Windows PowerShell...
    {
        (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    }
    else
    {
        'Unknown'
    }

    Write-ScreenInfo -Message "Host operating system version: '$hostOsName, $($hostOSVersion.ToString())'"

    if (-not $Name)
    {
        $reservedMacAddresses = @()

        #Microsoft
        $reservedMacAddresses += '00:03:FF'
        $reservedMacAddresses += '00:0D:3A'
        $reservedMacAddresses += '00:12:5A'
        $reservedMacAddresses += '00:15:5D'
        $reservedMacAddresses += '00:17:FA'
        $reservedMacAddresses += '00:50:F2'
        $reservedMacAddresses += '00:1D:D8'

        #VMware
        $reservedMacAddresses += '00:05:69'
        $reservedMacAddresses += '00:0C:29'
        $reservedMacAddresses += '00:1C:14'
        $reservedMacAddresses += '00:50:56'

        #Citrix
        $reservedMacAddresses += '00:16:3E'

        $macAddress = Get-OnlineAdapterHardwareAddress |
        Where-Object { $_.SubString(0, 8) -notin $reservedMacAddresses } |
        Select-Object -Unique

        $Name = "$($env:COMPUTERNAME)$($macAddress.SubString(12,2))$($macAddress.SubString(15,2))"
        Write-ScreenInfo -Message "Lab name and network name has automatically been generated as '$Name' (if not overridden)"
    }

    Write-ScreenInfo -Message "Creating new lab definition with name '$Name'"

    #remove the current lab from memory
    if (Get-Lab -ErrorAction SilentlyContinue)
    {
        Clear-Lab
    }

    $global:labExported = $false

    $global:firstAzureVMCreated = $false
    $global:existingAzureNetworks = @()

    $global:cacheVMs = $null

    $script:existingHyperVVirtualSwitches = $null

    #cleanup $PSDefaultParameterValues for entries for AL functions
    $automatedLabPSDefaultParameterValues = $global:PSDefaultParameterValues.GetEnumerator() | Where-Object { (Get-Command ($_.Name).Split(':')[0] -ErrorAction SilentlyContinue).Module -like 'Automated*' }
    if ($automatedLabPSDefaultParameterValues)
    {
        foreach ($entry in $automatedLabPSDefaultParameterValues)
        {
            $global:PSDefaultParameterValues.Remove($entry.Name)
            Write-ScreenInfo -Message "Entry '$($entry.Name)' with value '$($entry.Value)' was removed from `$PSDefaultParameterValues. If needed, modify `$PSDefaultParameterValues after calling New-LabDefinition'" -Type Warning
        }
    }

    if (Get-Variable -Name 'autoIPAddress' -Scope Script -ErrorAction SilentlyContinue)
    {
        Remove-Variable -Name 'AutoIPAddress' -Scope Script
    }

    if ($global:labNamePrefix)
    {
        $Name = "$global:labNamePrefix$Name" 
    }

    $script:labPath = "$((Get-LabConfigurationItem -Name LabAppDataRoot))/Labs/$Name"
    Write-ScreenInfo -Message "Location of lab definition files will be '$($script:labpath)'"

    $script:lab = New-Object AutomatedLab.Lab

    $script:lab.Name = $Name

    Update-LabSysinternalsTools

    while (Get-LabVirtualNetworkDefinition)
    {
        Remove-LabVirtualNetworkDefinition -Name (Get-LabVirtualNetworkDefinition)[0].Name
    }

    $machineDefinitionFilePath = Join-Path -Path $script:labPath -ChildPath (Get-LabConfigurationItem MachineFileName)
    $machineDefinitionFile = New-Object AutomatedLab.MachineDefinitionFile
    $machineDefinitionFile.Path = $machineDefinitionFilePath
    $script:lab.MachineDefinitionFiles.Add($machineDefinitionFile)

    $diskDefinitionFilePath = Join-Path -Path $script:labPath -ChildPath (Get-LabConfigurationItem DiskFileName)
    $diskDefinitionFile = New-Object AutomatedLab.DiskDefinitionFile
    $diskDefinitionFile.Path = $diskDefinitionFilePath
    $script:lab.DiskDefinitionFiles.Add($diskDefinitionFile)

    $sourcesPath = $labSources
    if (-not $sourcesPath)
    {
        $sourcesPath = New-LabSourcesFolder
    }

    Write-ScreenInfo -Message "Location of LabSources folder is '$sourcesPath'"

    if (-not (Get-LabIsoImageDefinition) -and $DefaultVirtualizationEngine -ne 'Azure')
    {
        if (-not (Get-ChildItem -Path "$(Get-LabSourcesLocation)\ISOs" -Filter *.iso -Recurse))
        {
            Write-ScreenInfo -Message "No ISO files found in $(Get-LabSourcesLocation)\ISOs folder. If using Hyper-V for lab machines, please add ISO files manually using 'Add-LabIsoImageDefinition'" -Type Warning
        }

        Write-ScreenInfo -Message 'Auto-adding ISO files' -TaskStart
        Get-LabAvailableOperatingSystem -Path "$(Get-LabSourcesLocation)\ISOs" | Out-Null #for updating the cache if necessary
        Add-LabIsoImageDefinition -Path "$(Get-LabSourcesLocation)\ISOs"
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if ($DefaultVirtualizationEngine)
    {
        $script:lab.DefaultVirtualizationEngine = $DefaultVirtualizationEngine
    }

    if ($MaxMemory -ne 0)
    {
        $script:lab.MaxMemory = $MaxMemory
    }
    if ($UseAllMemory)
    {
        $script:lab.MaxMemory = 4TB
    }

    $script:lab.UseStaticMemory = $UseStaticMemory

    $script:lab.Sources.UnattendedXml = $script:labPath
    if ($VmPath)
    {
        $Script:lab.target.Path = $vmPath
        Write-ScreenInfo -Message "Path for VMs specified as '$($script:lab.Target.Path)'" -Type Info
    }

    $script:lab.Target.ReferenceDiskSizeInGB = $ReferenceDiskSizeInGB

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Machine
    $script:machines = New-Object $type
    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Disk
    $script:disks = New-Object $type

    $script:lab.Notes = $Notes

    if ($Passthru)
    {
        $script:lab
    }

    $global:AL_CurrentLab = $script:lab

    Register-LabArgumentCompleters

    Write-LogFunctionExit
}
