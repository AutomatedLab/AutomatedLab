function Import-LabDefinition
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByPath', Position = 1)]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 1)]
        [string]$Name,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    Clear-Lab

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Machine
    $script:machines = New-Object $type
    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Disk
    $script:disks = New-Object $type
    $script:labPath = "$((Get-LabConfigurationItem -Name LabAppDataRoot))/Labs/$Name"
    $machineDefinitionFilePath = Join-Path -Path $script:labPath -ChildPath (Get-LabConfigurationItem MachineFileName)
    $diskDefinitionFilePath = Join-Path -Path $script:labPath -ChildPath (Get-LabConfigurationItem DiskFileName)
    $global:labExported = $false

    if ($PSCmdlet.ParameterSetName -in 'ByPath', 'ByName')
    {
        if ($Name)
        {
            $Path = "$((Get-LabConfigurationItem -Name LabAppDataRoot))/Labs/$Name"
        }

        if (Test-Path -Path $Path -PathType Container)
        {
            $newPath = Join-Path -Path $Path -ChildPath Lab.xml
            if (-not (Test-Path -Path $newPath -PathType Leaf))
            {
                throw "The file '$newPath' is missing. Please point to an existing lab file / folder."
            }
            else
            {
                $Path = $newPath
            }
        }
        elseif (Test-Path -Path $Path -PathType Leaf)
        {
            #file is there, do nothing
        }
        else
        {
            throw "The file '$Path' is missing. Please point to an existing lab file / folder."
        }

        if (-not ($IsLinux -or $IsMacOs) -and -not (Test-IsAdministrator))
        {
            throw 'Import-Lab needs to be called in an elevated PowerShell session.'
        }

        if (Test-Path -Path $Path)
        {
            $Script:lab = [AutomatedLab.Lab]::Import((Resolve-Path -Path $Path))

            $Script:lab | Add-Member -MemberType ScriptMethod -Name GetMachineTargetPath -Value {
                param (
                    [string]$MachineName
                )

                (Join-Path -Path $this.Target.Path -ChildPath $MachineName)
            }
        }
        else
        {
            throw 'Lab Definition File not found'
        }

        #import all the machine files referenced in the lab.xml
        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Machine
        $importMethodInfo = $type.GetMethod('Import',[System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static, [System.Type]::DefaultBinder, [Type[]]@([string]), $null)

        try
        {
            $Script:lab.Machines = $importMethodInfo.Invoke($null, $Script:lab.MachineDefinitionFiles[0].Path)

            if ($Script:lab.MachineDefinitionFiles.Count -gt 1)
            {
                foreach ($machineDefinitionFile in $Script:lab.MachineDefinitionFiles[1..($Script:lab.MachineDefinitionFiles.Count - 1)])
                {
                    $Script:lab.Machines.AddFromFile($machineDefinitionFile.Path)
                }
            }

            if ($Script:lab.Machines)
            {
                $Script:lab.Machines | Add-Member -MemberType ScriptProperty -Name UnattendedXmlContent -Value {
                    if ($this.OperatingSystem.Version -lt '6.2')
                    {
                        $Path = Join-Path -Path (Get-Lab).Sources.UnattendedXml.Value -ChildPath 'Unattended2008.xml'
                    }
                    else
                    {
                        $Path = Join-Path -Path (Get-Lab).Sources.UnattendedXml.Value -ChildPath 'Unattended2012.xml'
                    }
                    if ($this.OperatingSystemType -eq 'Linux' -and $this.LinuxType -eq 'RedHat' -and $this.OperatingSystem.Version -lt 8.0)
                    {
                        $Path = Join-Path -Path (Get-Lab).Sources.UnattendedXml.Value -ChildPath ks_defaultLegacy.cfg
                    }
                    if ($this.OperatingSystemType -eq 'Linux' -and $this.LinuxType -eq 'RedHat' -and $this.OperatingSystem.Version -ge 8.0)
                    {
                        $Path = Join-Path -Path (Get-Lab).Sources.UnattendedXml.Value -ChildPath ks_default.cfg
                    }
                    if ($this.OperatingSystemType -eq 'Linux' -and $this.LinuxType -eq 'Suse')
                    {
                        $Path = Join-Path -Path (Get-Lab).Sources.UnattendedXml.Value -ChildPath autoinst_default.xml
                    }
                    if ($this.OperatingSystemType -eq 'Linux' -and $this.LinuxType -eq 'Suse')
                    {
                        $Path = Join-Path -Path (Get-Lab).Sources.UnattendedXml.Value -ChildPath cloudinit_default.yml
                    }
                    return (Get-Content -Path $Path)
                }
            }
        }
        catch
        {
            Write-Error -Message "No machines imported from file $machineDefinitionFile" -Exception $_.Exception -ErrorAction Stop
        }

        #import all the disk files referenced in the lab.xml
        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Disk
        $importMethodInfo = $type.GetMethod('Import',[System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static, [System.Type]::DefaultBinder, [Type[]]@([string]), $null)

        try
        {
            $Script:lab.Disks = $importMethodInfo.Invoke($null, $Script:lab.DiskDefinitionFiles[0].Path)

            if ($Script:lab.DiskDefinitionFiles.Count -gt 1)
            {
                foreach ($diskDefinitionFile in $Script:lab.DiskDefinitionFiles[1..($Script:lab.DiskDefinitionFiles.Count - 1)])
                {
                    $Script:lab.Disks.AddFromFile($diskDefinitionFile.Path)
                }
            }
        }
        catch
        {
            Write-ScreenInfo "No disks imported from file '$diskDefinitionFile': $($_.Exception.Message)" -Type Warning
        }

        if ($Script:lab.VMWareSettings.DataCenterName)
        {
            Add-LabVMWareSettings -DataCenterName $Script:lab.VMWareSettings.DataCenterName `
            -DataStoreName $Script:lab.VMWareSettings.DataStoreName `
            -ResourcePoolName $Script:lab.VMWareSettings.ResourcePoolName `
            -VCenterServerName $Script:lab.VMWareSettings.VCenterServerName `
            -Credential ([System.Management.Automation.PSSerializer]::Deserialize($Script:lab.VMWareSettings.Credential))
        }

        if (-not ($IsLinux -or $IsMacOs) -and (Get-LabConfigurationItem -Name OverridePowerPlan))
        {
            $powerSchemeBackup = (powercfg.exe -GETACTIVESCHEME).Split(':')[1].Trim().Split()[0]
            powercfg.exe -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        }
    }
    elseif($PSCmdlet.ParameterSetName -eq 'ByValue')
    {
        $Script:lab = [AutomatedLab.Lab]::Import($LabBytes)
    }

    $script:machines = $script:lab.Machines
    $script:disks = $script:lab.Disks

    if ($PassThru)
    {
        $Script:lab
    }

    Write-LogFunctionExit
}
