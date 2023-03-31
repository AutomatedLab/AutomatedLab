function Import-Lab
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByPath', Position = 1)]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 1)]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'ByValue', Position = 1)]
        [byte[]]$LabBytes,

        [switch]$DoNotRemoveExistingLabPSSessions,

        [switch]$PassThru,

        [switch]$NoValidation,

        [switch]$NoDisplay
    )

    Write-LogFunctionEntry

    Clear-Lab

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

        if ((Get-PSsession) -and -not $DoNotRemoveExistingLabPSSessions)
        {
            Get-PSSession | Where-Object Name -ne WinPSCompatSession | Remove-PSSession -ErrorAction SilentlyContinue
        }

        if (-not (Test-LabHostRemoting))
        {
            Enable-LabHostRemoting -Force:$(Get-LabConfigurationItem -Name DoNotPrompt -Default $false)
        }

        if (-not ($IsLinux -or $IsMacOs) -and -not (Test-IsAdministrator))
        {
            throw 'Import-Lab needs to be called in an elevated PowerShell session.'
        }

        if (-not ($IsLinux -or $IsMacOs))
        {
            if ((Get-Item -Path Microsoft.WSMan.Management\WSMan::localhost\Client\TrustedHosts -Force).Value -ne '*')
            {
                Write-ScreenInfo 'The host system is not prepared yet. Call the cmdlet Set-LabHost to set the requirements' -Type Warning
                Write-ScreenInfo 'After installing the lab you should undo the changes for security reasons' -Type Warning
                throw "TrustedHosts need to be set to '*' in order to be able to connect to the new VMs. Please run the cmdlet 'Set-LabHostRemoting' to make the required changes."
            }

            $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1')
            if ($value -ne '*' -and $value -ne 'WSMAN/*')
            {
                throw "Please configure the local policy for allowing credentials to be delegated. Use gpedit.msc and look at the following policy: Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials. Just add '*' to the server list to be able to delegate credentials to all machines."
            }
        }

        if (-not $NoValidation)
        {
            Write-ScreenInfo -Message 'Validating lab definition' -TaskStart

            $validation = Test-LabDefinition -Path $Path -Quiet

            if ($validation)
            {
                Write-ScreenInfo -Message 'Success' -TaskEnd -Type Info
            }
            else
            {
                break
            }
        }

        if (Test-Path -Path $Path)
        {
            $Script:data = [AutomatedLab.Lab]::Import((Resolve-Path -Path $Path))

            $Script:data | Add-Member -MemberType ScriptMethod -Name GetMachineTargetPath -Value {
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
            $Script:data.Machines = $importMethodInfo.Invoke($null, $Script:data.MachineDefinitionFiles[0].Path)

            if ($Script:data.MachineDefinitionFiles.Count -gt 1)
            {
                foreach ($machineDefinitionFile in $Script:data.MachineDefinitionFiles[1..($Script:data.MachineDefinitionFiles.Count - 1)])
                {
                    $Script:data.Machines.AddFromFile($machineDefinitionFile.Path)
                }
            }

            if ($Script:data.Machines)
            {
                $Script:data.Machines | Add-Member -MemberType ScriptProperty -Name UnattendedXmlContent -Value {
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
                    if ($this.OperatingSystemType -eq 'Linux' -and $this.LinuxType -eq 'Ubuntu')
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

        $minimumAzureModuleVersion = Get-LabConfigurationItem -Name MinimumAzureModuleVersion
        if (($Script:data.Machines | Where-Object HostType -eq Azure) -and -not (Test-LabAzureModuleAvailability -AzureStack:$($script:data.AzureSettings.IsAzureStack)))
        {
            throw "The Azure PowerShell modules required to run AutomatedLab are not available. Please install them using the command 'Install-LabAzureRequiredModule'"
        }

        if (($Script:data.Machines | Where-Object HostType -eq VMWare) -and ((Get-PSSnapin -Name VMware.VimAutomation.*).Count -ne 1))
        {
            throw 'The VMWare snapin was not loaded. Maybe it is missing'
        }

        #import all the disk files referenced in the lab.xml
        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Disk
        $importMethodInfo = $type.GetMethod('Import',[System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static, [System.Type]::DefaultBinder, [Type[]]@([string]), $null)

        try
        {
            $Script:data.Disks = $importMethodInfo.Invoke($null, $Script:data.DiskDefinitionFiles[0].Path)
            if ($script:lab.DefaultVirtualizationEngine -eq 'HyperV') { $Script:data.Disks = Get-LabVHDX -All }

            if ($Script:data.DiskDefinitionFiles.Count -gt 1)
            {
                foreach ($diskDefinitionFile in $Script:data.DiskDefinitionFiles[1..($Script:data.DiskDefinitionFiles.Count - 1)])
                {
                    $Script:data.Disks.AddFromFile($diskDefinitionFile.Path)
                }
            }
        }
        catch
        {
            Write-ScreenInfo "No disks imported from file '$diskDefinitionFile': $($_.Exception.Message)" -Type Warning
        }

        if ($Script:data.VMWareSettings.DataCenterName)
        {
            Add-LabVMWareSettings -DataCenterName $Script:data.VMWareSettings.DataCenterName `
            -DataStoreName $Script:data.VMWareSettings.DataStoreName `
            -ResourcePoolName $Script:data.VMWareSettings.ResourcePoolName `
            -VCenterServerName $Script:data.VMWareSettings.VCenterServerName `
            -Credential ([System.Management.Automation.PSSerializer]::Deserialize($Script:data.VMWareSettings.Credential))
        }

        if (-not ($IsLinux -or $IsMacOs) -and (Get-LabConfigurationItem -Name OverridePowerPlan))
        {
            $powerSchemeBackup = (powercfg.exe -GETACTIVESCHEME).Split(':')[1].Trim().Split()[0]
            powercfg.exe -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        }
    }
    elseif($PSCmdlet.ParameterSetName -eq 'ByValue')
    {
        $Script:data = [AutomatedLab.Lab]::Import($LabBytes)
    }

    if ($PassThru)
    {
        $Script:data
    }

    $global:AL_CurrentLab = $Script:data

    Write-ScreenInfo ("Lab '{0}' hosted on '{1}' imported with {2} machines" -f $Script:data.Name, $Script:data.DefaultVirtualizationEngine ,$Script:data.Machines.Count) -Type Info

    Register-LabArgumentCompleters

    Write-LogFunctionExit -ReturnValue $true
}
