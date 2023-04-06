function Remove-Lab
{
    [CmdletBinding(DefaultParameterSetName = 'ByName', ConfirmImpact = 'High', SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByPath', ValueFromPipeline)]
        [string]$Path,

        [Parameter(ParameterSetName = 'ByName', ValueFromPipelineByPropertyName)]
        [string]$Name,
        
        [switch]$RemoveExternalSwitches
    )

    begin
    {
        Write-LogFunctionEntry
        $global:PSLog_Indent = 0
    }

    process
    {
        if ($Name)
        {
            Import-Lab -Name $Name -NoValidation -NoDisplay
            $labName = $Name
        }
        elseif ($Path)
        {
            Import-Lab -Path $Path -NoValidation -NoDisplay
            
        }

        if (-not $Script:data)
        {
            Write-Error 'No definitions imported, so there is nothing to remove. Please use Import-Lab against the xml file'
            return
        }

        $labName = (Get-Lab).Name

        if($pscmdlet.ShouldProcess($labName, 'Remove the lab completely'))
        {
            Write-ScreenInfo -Message "Removing lab '$labName'" -Type Warning -TaskStart
            if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and -not (Get-AzContext))
            {
                Write-ScreenInfo -Type Info -Message "Your Azure session is expired. Please log in to remove your resource group"
                $param = @{
                    UseDeviceAuthentication = $true
                    ErrorAction             = 'SilentlyContinue' 
                    WarningAction           = 'Continue'
                    Environment             = $(Get-Lab).AzureSettings.Environment
                }

                $null = Connect-AzAccount @param
            }

            try
            {
                [AutomatedLab.LabTelemetry]::Instance.LabRemoved((Get-Lab).Export())
            }
            catch
            {
                Write-PSFMessage -Message ('Error sending telemetry: {0}' -f $_.Exception)
            }

            Write-ScreenInfo -Message 'Removing lab sessions'
            Remove-LabPSSession -All
            Write-PSFMessage '...done'

            Write-ScreenInfo -Message 'Removing imported RDS certificates'
            Uninstall-LabRdsCertificate
            Write-PsfMessage '...done'

            Write-ScreenInfo -Message 'Removing lab background jobs'
            $jobs = Get-Job
            Write-PSFMessage "Removing remaining $($jobs.Count) jobs..."
            $jobs | Remove-Job -Force -ErrorAction SilentlyContinue
            Write-PSFMessage '...done'

            if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
            {
                Write-ScreenInfo -Message "Removing Resource Group '$labName' and all resources in this group"
                #without cloning the collection, a Runtime Exceptionis thrown: An error occurred while enumerating through a collection: Collection was modified; enumeration operation may not execute
                # If RG contains Recovery Vault, remove vault properly
                Remove-LWAzureRecoveryServicesVault
                @(Get-LabAzureResourceGroup -CurrentLab).Clone() | Remove-LabAzureResourceGroup -Force
            }

            $labMachines = Get-LabVM -IncludeLinux | Where-Object HostType -eq 'HyperV' | Where-Object { -not $_.SkipDeployment }
            if ($labMachines)
            {
                $labName = (Get-Lab).Name

                $removeMachines = foreach ($machine in $labMachines)
                {
                    $machineMetadata = Get-LWHypervVMDescription -ComputerName $machine.ResourceName -ErrorAction SilentlyContinue
                    $vm = Get-LWHypervVM -Name $machine.ResourceName -ErrorAction SilentlyContinue
                    if (-not $machineMetadata)
                    {
                        Write-Error -Message "Cannot remove machine '$machine' because lab meta data could not be retrieved"
                    }
                    elseif ($machineMetadata.LabName -ne $labName -and $vm)
                    {
                        Write-Error -Message "Cannot remove machine '$machine' because it does not belong to this lab"
                    }
                    else
                    {
                        $machine
                    }
                }

                if ($removeMachines)
                {
                    Remove-LabVM -Name $removeMachines

                    $disks = Get-LabVHDX -All
                    Write-PSFMessage "Lab knows about $($disks.Count) disks"

                    if ($disks)
                    {
                        Write-ScreenInfo -Message 'Removing additionally defined disks'

                        Write-PSFMessage 'Removing disks...'
                        foreach ($disk in $disks)
                        {
                            Write-PSFMessage "Removing disk '$($disk.Name)'"

                            if (Test-Path -Path $disk.Path)
                            {
                                Remove-Item -Path $disk.Path
                            }
                            else
                            {
                                Write-ScreenInfo "Disk '$($disk.Path)' does not exist" -Type Verbose
                            }
                        }
                    }

                    if ($Script:data.Target.Path)
                    {
                        $diskPath = (Join-Path -Path $Script:data.Target.Path -ChildPath Disks)
                        #Only remove disks folder if empty
                        if ((Test-Path -Path $diskPath) -and (-not (Get-ChildItem -Path $diskPath)) )
                        {
                            Remove-Item -Path $diskPath
                        }
                    }
                }

                #Only remove folder for VMs if folder is empty
                if ($Script:data.Target.Path -and (-not (Get-ChildItem -Path $Script:data.Target.Path)))
                {
                    Remove-Item -Path $Script:data.Target.Path -Recurse -Force -Confirm:$false
                }

                Write-ScreenInfo -Message 'Removing entries in the hosts file'
                Clear-HostFile -Section $Script:data.Name -ErrorAction SilentlyContinue

                if ($labMachines.SshPublicKey)
                {
                    Write-ScreenInfo -Message 'Removing SSH known hosts'
                    UnInstall-LabSshKnownHost
                }
            }

            Write-ScreenInfo -Message 'Removing virtual networks'
            Remove-LabNetworkSwitches -RemoveExternalSwitches:$RemoveExternalSwitches

            if ($Script:data.LabPath)
            {
                Write-ScreenInfo -Message 'Removing Lab XML files'
                if (Test-Path "$($Script:data.LabPath)/$(Get-LabConfigurationItem -Name LabFileName)") { Remove-Item -Path "$($Script:data.LabPath)/Lab.xml" -Force -Confirm:$false }
                if (Test-Path "$($Script:data.LabPath)/$(Get-LabConfigurationItem -Name DiskFileName)") { Remove-Item -Path "$($Script:data.LabPath)/Disks.xml" -Force -Confirm:$false }
                if (Test-Path "$($Script:data.LabPath)/$(Get-LabConfigurationItem -Name MachineFileName)") { Remove-Item -Path "$($Script:data.LabPath)/Machines.xml" -Force -Confirm:$false }
                if (Test-Path "$($Script:data.LabPath)/Unattended*.xml") { Remove-Item -Path "$($Script:data.LabPath)/Unattended*.xml" -Force -Confirm:$false }
                if (Test-Path "$($Script:data.LabPath)/armtemplate.json") { Remove-Item -Path "$($Script:data.LabPath)/armtemplate.json" -Force -Confirm:$false }
                if (Test-Path "$($Script:data.LabPath)/ks*.cfg") { Remove-Item -Path "$($Script:data.LabPath)/ks*.cfg" -Force -Confirm:$false }
                if (Test-Path "$($Script:data.LabPath)/*.bash") { Remove-Item -Path "$($Script:data.LabPath)/*.bash" -Force -Confirm:$false }
                if (Test-Path "$($Script:data.LabPath)/autoinst*.xml") { Remove-Item -Path "$($Script:data.LabPath)/autoinst*.xml" -Force -Confirm:$false }
                if (Test-Path "$($Script:data.LabPath)/cloudinit*") { Remove-Item -Path "$($Script:data.LabPath)/cloudinit*" -Force -Confirm:$false }
                if (Test-Path "$($Script:data.LabPath)/AzureNetworkConfig.Xml") { Remove-Item -Path "$($Script:data.LabPath)/AzureNetworkConfig.Xml" -Recurse -Force -Confirm:$false }
                if (Test-Path "$($Script:data.LabPath)/Certificates") { Remove-Item -Path "$($Script:data.LabPath)/Certificates" -Recurse -Force -Confirm:$false }

                #Only remove lab path folder if empty
                if ((Test-Path "$($Script:data.LabPath)") -and (-not (Get-ChildItem -Path $Script:data.LabPath)))
                {
                    Remove-Item -Path $Script:data.LabPath
                }
            }

            $Script:data = $null

            Write-ScreenInfo -Message "Done removing lab '$labName'" -TaskEnd
        }
    }

    end
    {
        Write-LogFunctionExit
    }
}
