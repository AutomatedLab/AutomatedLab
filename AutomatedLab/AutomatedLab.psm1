#region Enable-LabHostRemoting
function Enable-LabHostRemoting
{
    # .ExternalHelp AutomatedLab.Help.xml
    Write-LogFunctionEntry
    
    if (-not (Test-IsAdministrator))
    {
        throw 'This function needs to be called in an elevated PowerShell session.'
    }
    
    if ((Get-Service -Name WinRM).Status -ne 'Running')
    {
        Start-Service -Name WinRM
        Start-Sleep -Seconds 5
    }
    
    if ((-not (Get-WSManCredSSP)[0].Contains('The machine is configured to') -and -not (Get-WSManCredSSP)[0].Contains('WSMAN/*')) -or (Get-Item -Path WSMan:\localhost\Client\Auth\CredSSP).Value -eq $false)
    {
        Write-Verbose "Enabling CredSSP on the host machine for role 'Client'. Delegated computers = *"
        Enable-WSManCredSSP -Role Client -DelegateComputer * -Force | Out-Null
    }
    else
    {
        Write-Verbose 'Remoting is enabled on the host machine'
    }
    
    $trustedHostsList = @((Get-Item -Path Microsoft.WSMan.Management\WSMan::localhost\Client\TrustedHosts).Value -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
    )
    
    if (-not ($trustedHostsList -contains '*'))
    {
        Write-Warning -Message "TrustedHosts does not include '*'. Replacing the currernt value '$($trustedHostsList -join ', ')' with '*'"
        
        Set-Item -Path Microsoft.WSMan.Management\WSMan::localhost\Client\TrustedHosts -Value '*' -Force
    }
    else
    {
        Write-Verbose '''*'' added to TrustedHosts'
    }
    
    $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1')
    if ($value -ne '*' -and $value -ne 'WSMAN/*')
    {
        Write-Warning 'Configuring the local policy for allowing credentials to be delegated to all machines (*). You can find the modified policy using gpedit.msc by navigating to: Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials'
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowFreshCredentials', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowFresh', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1', 'WSMAN/*') | Out-Null
    }
    else
    {
        Write-Verbose "Local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials' configured correctly"
    }

    $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentials', '1')
    if ($value -ne '*' -and $value -ne 'TERMSRV/*')
    {
        Write-Warning 'Configuring the local policy for allowing credentials to be delegated to all machines (*). You can find the modified policy using gpedit.msc by navigating to: Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials'
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowSavedCredentials', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowSaved', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentials', '1', 'TERMSRV/*') | Out-Null
    }
    else
    {
        Write-Verbose "Local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Saved Credentials' configured correctly"
    }
    
    $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly', '1')
    if ($value -ne '*' -and $value -ne 'WSMAN/*')
    {
        Write-Warning 'Configuring the local policy for allowing credentials to be delegated to all machines (*). You can find the modified policy using gpedit.msc by navigating to: Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials with NTLM-only server authentication'
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowFreshCredentialsWhenNTLMOnly', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowFreshNTLMOnly', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly', '1', 'WSMAN/*') | Out-Null
    }
    else
    {
        Write-Verbose "Local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials when NTLM only' configured correctly"
    }

    $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentialsWhenNTLMOnly', '1')
    if ($value -ne '*' -and $value -ne 'TERMSRV/*')
    {
        Write-Warning 'Configuring the local policy for allowing credentials to be delegated to all machines (*). You can find the modified policy using gpedit.msc by navigating to: Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials with NTLM-only server authentication'
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowSavedCredentialsWhenNTLMOnly', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowSavedNTLMOnly', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentialsWhenNTLMOnly', '1', 'TERMSRV/*') | Out-Null
    }
    else
    {
        Write-Verbose "Local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Saved Credentials when NTLM only' configured correctly"
    }
    
    Write-LogFunctionExit
}
#endregion Enable-LabHostRemoting

#region Import-Lab
function Import-Lab
{
    #.ExternalHelp AutomatedLab.help.xml
    
    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByPath')]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 1)]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'ByValue', Position = 1)]
        [byte[]]$LabBytes,
        
        [switch]$PassThru,
        
        [switch]$NoValidation
    )

    Write-LogFunctionEntry

    Clear-Lab
    
    if ($PSCmdlet.ParameterSetName -in 'ByPath', 'ByName')
    {
        if ($Name)
        {
            $Path = '{0}\AutomatedLab-Labs\{1}' -f [System.Environment]::GetFolderPath('MyDocuments'), $Name
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
            #file is there, no nothing
        }
        else
        {
            throw "The file '$Path' is missing. Please point to an existing lab file / folder."
        }
    
        if (Get-PSsession)
        {
            Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue
        }

        Enable-LabHostRemoting
    
        if (-not (Test-IsAdministrator))
        {
            throw 'This function needs to be called in an elevated PowerShell session.'
        }
    
        if ((Get-Item -Path Microsoft.WSMan.Management\WSMan::localhost\Client\TrustedHosts -Force).Value -ne '*')
        {
            Write-Warning 'The host system is not prepared yet. Call the cmdlet Set-LabHost to set the requirements'
            Write-Warning 'After installing the lab you should undo the changes for security reasons'
            throw "TrustedHosts need to be set to '*' in order to be able to connect to the new VMs. Please run the cmdlet 'Set-LabHostRemoting' to make the required changes."
        }
    
        $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1')
        if ($value -ne '*' -and $value -ne 'WSMAN/*')
        {
            throw "Please configure the local policy for allowing credentials to be delegated. Use gpedit.msc and look at the following policy: Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials. Just add '*' to the server list to be able to delegate credentials to all machines."
        }
    
        if (-not $NoValidation)
        {
            Write-ScreenInfo -Message 'Validating lab definition' -TaskStart
        
            foreach ($machine in (Get-LabMachineDefinition | Where-Object HostType -in 'HyperV', 'VMware' ))
            {
                if ((Get-HostEntry -HostName $machine) -and (Get-HostEntry -HostName $machine).IpAddress.IPAddressToString -ne $machine.IpV4Address)
                {
                    throw "There is already an entry for machine '$($machine.Name)' in the hosts file pointing to other IP address(es) ($((Get-HostEntry -HostName $machine).IpAddress.IPAddressToString -join ',')) than the machine '$($machine.Name)' in this lab will have ($($machine.IpV4Address)). Cannot continue."
                }
            }
        
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
        
            $Script:data.Machines | Add-Member -MemberType ScriptProperty -Name UnattendedXmlContent -Value {
                if ($this.OperatingSystem.Version -lt '6.2')
                {
                    $Path = Join-Path -Path (Get-Lab).Sources.UnattendedXml.Value -ChildPath 'Unattended2008.xml'
                }
                else
                {
                    $Path = Join-Path -Path (Get-Lab).Sources.UnattendedXml.Value -ChildPath 'Unattended2012.xml'
                }
                return [xml](Get-Content -Path $Path)
            }
        }
        catch
        {
            throw "No machines imported from file $machineDefinitionFile"
        }
    
        $minimumAzureModuleVersion = $MyInvocation.MyCommand.Module.PrivateData.MinimumAzureModuleVersion
        if (($Script:data.Machines | Where-Object HostType -eq Azure) -and -not (Get-Module -Name AzureRm -ListAvailable | Where-Object Version -ge $minimumAzureModuleVersion))
        {
            throw "The Azure PowerShell module version $($minimumAzureModuleVersion) or greater is not available. Please install it using the command 'Install-Module -Name AzureRm -Force'"
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
            Write-Warning "No disks imported from file '$diskDefinitionFile': $($_.Exception.Message)"
        }
    
        if($Script:data.AzureSettings.AzureProfilePath -and (Test-Path $Script:data.AzureSettings.AzureProfilePath))
        {
            Add-LabAzureSubscription -Path $Script:data.AzureSettings.AzureProfilePath -DefaultLocationName $Script:data.AzureSettings.DefaultLocation.DisplayName `
            -DefaultStorageAccountName $Script:data.AzureSettings.DefaultStorageAccount `
            -SubscriptionName $Script:data.AzureSettings.DefaultSubscription `
            -DefaultResourceGroupName $script:data.Name
        }
        elseif ($Script:data.AzureSettings.SubscriptionFileContent)
        {
            $tempFilePath = [System.IO.Path]::GetTempFileName()
            $Script:data.AzureSettings.SubscriptionFileContent | Out-File -FilePath $tempFilePath -Encoding ascii
        
            Add-LabAzureSubscription -Path $tempFilePath -DefaultLocationName $Script:data.AzureSettings.DefaultLocation.DisplayName `
            -DefaultStorageAccountName $Script:data.AzureSettings.DefaultStorageAccount `
            -SubscriptionName $Script:data.AzureSettings.DefaultSubscription `
            -DefaultResourceGroupName $script:data.Name
        
            Remove-Item -Path $tempFilePath -Force
        }

        if ($Script:data.VMWareSettings.DataCenterName)
        {
            Add-LabVMWareSettings -DataCenterName $Script:data.VMWareSettings.DataCenterName `
            -DataStoreName $Script:data.VMWareSettings.DataStoreName `
            -ResourcePoolName $Script:data.VMWareSettings.ResourcePoolName `
            -VCenterServerName $Script:data.VMWareSettings.VCenterServerName `
            -Credential ([System.Management.Automation.PSSerializer]::Deserialize($Script:data.VMWareSettings.Credential))
        }
    
        $powerSchemeBackup = (powercfg.exe -GETACTIVESCHEME).Split(':')[1].Trim().Split()[0]
        powercfg.exe -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    }
    elseif($PSCmdlet.ParameterSetName -eq 'ByValue')
    {
        $Script:data = [AutomatedLab.Lab]::Import($LabBytes)
    }
    
    if ($PassThru)
    {
        $Script:data
    }
    
    Write-ScreenInfo ("Lab '{0}' hosted on '{1}' imported with {2} machines" -f $Script:data.Name, $Script:data.DefaultVirtualizationEngine ,$Script:data.Machines.Count) -Type Info
    
    Write-LogFunctionExit -ReturnValue $true
}
#endregion Import-Lab

#region Export-Lab
function Export-Lab
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]

    param ()
    
    Write-LogFunctionEntry

    $lab = Get-Lab
    
    Remove-Item -Path $lab.LabFilePath
    
    Remove-Item -Path $lab.MachineDefinitionFiles[0].Path
    Remove-Item -Path $lab.DiskDefinitionFiles[0].Path
    
    $lab.Machines.Export($lab.MachineDefinitionFiles[0].Path)
    $lab.Disks.Export($lab.DiskDefinitionFiles[0].Path)
    $lab.Machines.Clear()
    $lab.Disks.Clear()

    $lab.Export($lab.LabFilePath)

    $lab.Disks.AddFromFile($lab.DiskDefinitionFiles[0].Path)
    $lab.Machines.AddFromFile($lab.MachineDefinitionFiles[0].Path)

    Write-LogFunctionExit
}
#endregion Export-LabDefinition

#region Get-Lab
function Get-Lab
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding()]
    [OutputType([AutomatedLab.Lab])]
    
    param (
        [switch]$List
    )
    
    if ($List)
    {
        $labsPath = '{0}\AutomatedLab-Labs' -f [System.Environment]::GetFolderPath('MyDocuments')
        
        foreach ($path in Get-ChildItem -Path $labsPath -Directory)
        {
            $labXmlPath = Join-Path -Path $path.FullName -ChildPath Lab.xml
            if (Test-Path -Path $labXmlPath)
            {
                Split-Path -Path $path -Leaf
            }
        }	
    }
    else
    {
        if ($Script:data)
        {
            $Script:data
        }
        else
        {
            Write-Error 'Lab data not available. Use Import-Lab and reference a Lab.xml to import one.'
        }
    }
}
#endregion Get-Lab

#region Clear-Lab
function Clear-Lab
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    
    param ()

    Write-LogFunctionEntry
    
    $Script:data = $null
    foreach ($module in $MyInvocation.MyCommand.Module.NestedModules | Where-Object ModuleType -eq 'Script')
    {
        & $module { $Script:data = $null }
    }

    Write-LogFunctionExit
}
#endregion Clear-Lab

#region Install-Lab
function Install-Lab
{
    #.ExternalHelp AutomatedLab.help.xml
    
    [cmdletBinding()]
    param (
        [switch]$NetworkSwitches,
        [switch]$BaseImages,
        [switch]$VMs,
        [switch]$Domains,
        [switch]$AdTrusts,
        [switch]$DHCP,
        [switch]$Routing,
        [switch]$PostInstallations,
        [switch]$SQLServers,
        [switch]$Orchestrator2012,
        [switch]$WebServers,
        [switch]$Exchange2013,
        [switch]$Exchange2016,
        [switch]$Sharepoint2013,
        [switch]$CA,
        [switch]$ADFS,
        [switch]$DSCPullServer,
        [switch]$ConfigManager2012R2,
        [switch]$VisualStudio,
        [switch]$Office2013,
        [switch]$Office2016,
        [switch]$StartRemainingMachines,
        [switch]$CreateCheckPoints,
        [int]$DelayBetweenComputers,
        [switch]$NoValidation
    )
    
    Write-LogFunctionEntry

    #perform full install if no role specific installation is requested
    $performAll = -not ($PSBoundParameters.Keys | Where-Object { $_ -notin ('NoValidation', 'DelayBetweenComputers' + [System.Management.Automation.Internal.CommonParameters].GetProperties().Name)}).Count
    
    if (-not $Global:labExported -and -not (Get-Lab -ErrorAction SilentlyContinue))
    {
        Export-LabDefinition -Force -ExportDefaultUnattendedXml
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    if ($Global:labExported -and -not (Get-Lab -ErrorAction SilentlyContinue))
    {
        if ($NoValidation)
        {
            Import-Lab -Path (Get-LabDefinition).LabFilePath -NoValidation
        }
        else
        {
            Import-Lab -Path (Get-LabDefinition).LabFilePath
        }
    }
    
    if (-not $Script:data)
    {
        Write-Error 'No definitions imported, so there is nothing to test. Please use Import-Lab against the xml file'
        return
    }
    
    Unblock-LabSources
    
    $Global:AL_DeploymentStart = Get-Date
    
    if (Get-LabMachine -All | Where-Object HostType -eq 'HyperV')
    {
        Update-LabMemorySettings
    }
    
    if ($NetworkSwitches -or $performAll)
    {
        Write-ScreenInfo -Message 'Creating virtual networks' -TaskStart
        
        New-LabNetworkSwitches
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($BaseImages -or $performAll) -and (Get-LabMachine -All | Where-Object HostType -eq 'HyperV'))
    {
        Write-ScreenInfo -Message 'Creating base images' -TaskStart
        
        New-LabBaseImages

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if ($VMs -or $performAll)
    {
        Write-ScreenInfo -Message 'Creating VMs' -TaskStart

        if (Get-LabMachine -All | Where-Object HostType -eq 'HyperV')
        {
            New-LabVHDX
        }

        #add a hosts entry for each lab machine
        $hostFileAddedEntries = 0
        foreach ($machine in $Script:data.Machines)
        {
            if ($machine.Hosttype -eq 'HyperV' -and $machine.NetworkAdapters[0].Ipv4Address)
            {
                $hostFileAddedEntries += Add-HostEntry -HostName $machine.Name -IpAddress $machine.IpV4Address -Section $Script:data.Name
            }
        }
    
        if ($hostFileAddedEntries)
        {
            Write-ScreenInfo -Message "The hosts file has been added $hostFileAddedEntries records. Clean them up using 'Remove-Lab' or manually if needed" -Type Warning
        }
        
        New-LabVM -CreateCheckPoints:$CreateCheckPoints
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    #Root DCs are installed first, then the Routing role is installed in order to allow domain joined routers in the root domains
    if (($Domains -or $performAll) -and (Get-LabMachine -Role RootDC))
    {
        Write-ScreenInfo -Message 'Installing Root Domain Controllers' -TaskStart
        if (Get-LabMachine -Role RootDC)
        {
            Write-ScreenInfo -Message "Machines with RootDC role to be installed: '$((Get-LabMachine -Role RootDC).Name -join ', ')'"
            Install-LabRootDcs -CreateCheckPoints:$CreateCheckPoints
        }
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Routing -or $performAll) -and (Get-LabMachine -Role Routing))
    {
        Write-ScreenInfo -Message 'Configuring routing' -TaskStart
        
        Install-LabRouting
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($DHCP -or $performAll) -and (Get-LabMachine -Role DHCP))
    {
        Write-ScreenInfo -Message 'Configuring DHCP servers' -TaskStart
        
        Install-DHCP
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($Domains -or $performAll) -and (Get-LabMachine -Role FirstChildDC))
    {
        Write-ScreenInfo -Message 'Installing Child Domain Controllers' -TaskStart
        if (Get-LabMachine -Role FirstChildDC)
        {
            Write-ScreenInfo -Message "Machines with FirstChildDC role to be installed: '$((Get-LabMachine -Role FirstChildDC).Name -join ', ')'"
            Install-LabFirstChildDcs -CreateCheckPoints:$CreateCheckPoints
        }

        New-LabADSubnet
        
        $allDcVMs = Get-LabMachine -Role RootDC, FirstChildDC
        
        if ($allDcVMs)
        {
            if ($CreateCheckPoints)
            {
                Write-ScreenInfo -Message 'Creating a snapshot of all domain controllers'
                Checkpoint-LabVM -ComputerName $allDcVMs -SnapshotName 'Post Forest Setup'
            }
        }
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($Domains -or $performAll) -and (Get-LabMachine -Role DC))
    {
        Write-ScreenInfo -Message 'Installing Additional Domain Controllers' -TaskStart
        
        if (Get-LabMachine -Role DC)
        {
            Write-ScreenInfo -Message "Machines with DC role to be installed: '$((Get-LabMachine -Role DC).Name -join ', ')'"
            Install-LabDcs -CreateCheckPoints:$CreateCheckPoints
        }
        
        New-LabADSubnet
        
        $allDcVMs = Get-LabMachine -Role RootDC, FirstChildDC, DC
        
        if ($allDcVMs)
        {
            if ($CreateCheckPoints)
            {
                Write-ScreenInfo -Message 'Creating a snapshot of all domain controllers'
                Checkpoint-LabVM -ComputerName $allDcVMs -SnapshotName 'Post Forest Setup'
            }
        }
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($AdTrusts -or $performAll) -and ((Get-LabMachine -Role RootDC | Measure-Object).Count -gt 1))
    {
        Write-ScreenInfo -Message 'Configuring DNS forwarding and AD trusts' -TaskStart
        Install-LabDnsForwarder
        Install-LabADDSTrust
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($CA -or $performAll) -and ((Get-LabMachine -Role CaRoot) -or (Get-LabMachine -Role CaSubordinate)))
    {
        Write-ScreenInfo -Message 'Installing Certificate Servers' -TaskStart
        Install-LabCA -CreateCheckPoints:$CreateCheckPoints
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($DSCPullServer -or $performAll) -and (Get-LabMachine -Role DSCPullServer))
    {
        Start-LabVM -RoleName DSCPullServer -ProgressIndicator 15 -PostDelaySeconds 5 -Wait
        
        Write-ScreenInfo -Message 'Installing DSC Pull Servers' -TaskStart
        Install-LabDscPullServer
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }    
    
    if (($SQLServers -or $performAll) -and (Get-LabMachine -Role SQLServer2008, SQLServer2012, SQLServer2014, SQLServer2016))
    {
        Write-ScreenInfo -Message 'Installing SQL Servers' -TaskStart
        if (Get-LabMachine -Role SQLServer2008)   { Write-ScreenInfo -Message "Machines to have SQL Server 2008 installed: '$((Get-LabMachine -Role SQLServer2008).Name -join ', ')'" }
        if (Get-LabMachine -Role SQLServer2008R2) { Write-ScreenInfo -Message "Machines to have SQL Server 2008 R2 installed: '$((Get-LabMachine -Role SQLServer2008R2).Name -join ', ')'" }
        if (Get-LabMachine -Role SQLServer2012)   { Write-ScreenInfo -Message "Machines to have SQL Server 2012 installed: '$((Get-LabMachine -Role SQLServer2012).Name -join ', ')'" }
        if (Get-LabMachine -Role SQLServer2014)   { Write-ScreenInfo -Message "Machines to have SQL Server 2014 installed: '$((Get-LabMachine -Role SQLServer2014).Name -join ', ')'" }
        if (Get-LabMachine -Role SQLServer2016)   { Write-ScreenInfo -Message "Machines to have SQL Server 2016 installed: '$((Get-LabMachine -Role SQLServer2016).Name -join ', ')'" }
        Install-LabSqlServers -CreateCheckPoints:$CreateCheckPoints
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($ADFS -or $performAll) -and (Get-LabMachine -Role ADFS))
    {
        Write-ScreenInfo -Message 'Configuring ADFS' -TaskStart
        
        Install-LabAdfs
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
        
        Write-ScreenInfo -Message 'Configuring ADFS Proxies' -TaskStart
        
        Install-LabAdfsProxy
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($WebServers -or $performAll) -and (Get-LabMachine -Role WebServer))
    {
        Write-ScreenInfo -Message 'Installing Web Servers' -TaskStart
        Write-ScreenInfo -Message "Machines to have Web Server role installed: '$((Get-LabMachine -Role WebServer).Name -join ', ')'"
        Install-LabWebServers -CreateCheckPoints:$CreateCheckPoints
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($Orchestrator2012 -or $performAll) -and (Get-LabMachine -Role Orchestrator2012))
    {
        Write-ScreenInfo -Message 'Installing Orchestrator Servers' -TaskStart
        Install-LabOrchestrator2012
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($Exchange2013 -or $performAll) -and (Get-LabMachine -Role Exchange2013))
    {
        Write-ScreenInfo -Message 'Installing Exchange 2013' -TaskStart
        
        Install-LabExchange2013 -All
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Exchange2016 -or $performAll) -and (Get-LabMachine -Role Exchange2016))
    {
        Write-ScreenInfo -Message 'Installing Exchange 2016' -TaskStart
        
        Install-LabExchange2016 -All
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($SharePoint2013 -or $performAll) -and (Get-LabMachine -Role SharePoint2013))
    {
        Write-ScreenInfo -Message 'Installing SharePoint 2013 Servers' -TaskStart
        
        Install-LabSharePoint2013
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($VisualStudio -or $performAll) -and (Get-LabMachine -Role VisualStudio2013))
    {
        Write-ScreenInfo -Message 'Installing Visual Studio 2013' -TaskStart
        
        Write-ScreenInfo -Message "Machines to have Visual Studio 2013 installed: '$((Get-LabMachine -Role VisualStudio2013).Name -join ', ')'"
        Install-VisualStudio2013
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($VisualStudio -or $performAll) -and (Get-LabMachine -Role VisualStudio2015))
    {
        Write-ScreenInfo -Message 'Installing Visual Studio 2015' -TaskStart
        
        Write-ScreenInfo -Message "Machines to have Visual Studio 2015 installed: '$((Get-LabMachine -Role VisualStudio2015).Name -join ', ')'"
        Install-VisualStudio2015
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($Office2013 -or $performAll) -and (Get-LabMachine -Role Office2013))
    {
        Write-ScreenInfo -Message 'Installing Office 2013' -TaskStart
        
        Write-ScreenInfo -Message "Machines to have Office 2013 installed: '$((Get-LabMachine -Role Office2013).Name -join ', ')'"
        Install-LabOffice2013
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($Office2016 -or $performAll) -and (Get-LabMachine -Role Office2016))
    {
        Write-ScreenInfo -Message 'Installing Office 2016' -TaskStart
        
        Write-ScreenInfo -Message "Machines to have Office 2016 installed: '$((Get-LabMachine -Role Office2016).Name -join ', ')'"
        Install-LabOffice2016
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if ($StartRemainingMachines -or $performAll)
    {
        Write-ScreenInfo -Message 'Starting remaining machines' -TaskStart
        Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewLine
        
        Start-LabVM -All -DelayBetweenComputers ([int]((Get-LabMachine).HostType -contains 'HyperV')*30) -ProgressIndicator 30 -NoNewline
        Wait-LabVM -ComputerName (Get-LabMachine) -ProgressIndicator 30 -TimeoutInMinutes 60
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if ($PostInstallations -or $performAll)
    {
        $jobs = Invoke-LabCommand -PostInstallationActivity -ActivityName 'Post-installation' -ComputerName (Get-LabMachine) -PassThru -NoDisplay 
        $jobs | Wait-Job | Out-Null
    }
    
    Write-LogFunctionExit
}
#endregion Install-Lab

#region Remove-Lab
function Remove-Lab
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding(DefaultParameterSetName = 'Path', ConfirmImpact = 'High', SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByPath')]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 1)]
        [string]$Name,
        
        [switch]$RemoveReferenceDisks
    )
    Write-LogFunctionEntry
    
    if ($Name)
    {
        $Path = '{0}\AutomatedLab-Labs\{1}' -f [System.Environment]::GetFolderPath('MyDocuments'), $Name
        $labName = $Name
    }
    else
    {
        $labName = $script:data.Name
    }

    if ($Path)
    {
        Import-Lab -Path $Path -NoValidation
    }
        
    if (-not $Script:data)
    {
        Write-Error 'No definitions imported, so there is nothing to test. Please use Import-Lab against the xml file'
        return
    }

    if($pscmdlet.ShouldProcess((Get-Lab).Name, 'Remove the lab completely'))
    {
        Write-ScreenInfo -Message "Removing lab '$($Script:data.Name)'" -Type Warning -TaskStart
    
        Write-ScreenInfo -Message 'Removing lab sessions'
        Remove-LabPSSession -All
        Write-Verbose '...done'
    
        Write-ScreenInfo -Message 'Removing lab background jobs'
        $jobs = Get-Job
        Write-Verbose "Removing remaining $($jobs.Count) jobs..."
        $jobs | Remove-Job -Force -ErrorAction SilentlyContinue
        Write-Verbose '...done'

        if (Get-LabMachine | Where-Object HostType -eq Azure)
        {
            Write-ScreenInfo -Message "Removing Resource Group '$labName' and all resources in this group"
            Remove-LabAzureResourceGroup $labName -Force
        }
        
        if (Get-LabMachine | Where-Object HostType -eq HyperV)
        {
            $labMachines = Get-LabMachine | Where-Object HostType -eq 'HyperV'
            $labName = (Get-Lab).Name

            $removeMachines = foreach ($machine in $labMachines)
            {
                $machineMetadata = Get-LWHypervVMDescription -ComputerName $machine -ErrorAction SilentlyContinue
                $vm = Get-VM -Name $machine -ErrorAction SilentlyContinue
                if ($machineMetadata.LabName -ne $labName -and $vm)
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
                Write-Verbose "Lab knows about $($disks.Count) disks"
            
                if ($disks)
                {
                    Write-ScreenInfo -Message 'Removing additionally defined disks'
                
                    Write-Verbose 'Removing disks...'
                    foreach ($disk in $disks)
                    {
                        Write-Verbose "Removing disk '($disk.Name)'"
                        Remove-Item -Path $disk.Path
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
        }	    
        
        Write-ScreenInfo -Message 'Removing virtual networks'
        Remove-LabNetworkSwitches
        
        if ($Script:data.LabPath)
        {
            Write-ScreenInfo -Message 'Removing Lab XML files'
            if (Test-Path "$($Script:data.LabPath)\Lab.xml") { Remove-Item -Path "$($Script:data.LabPath)\Lab.xml" -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)\Disks.xml") { Remove-Item -Path "$($Script:data.LabPath)\Disks.xml" -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)\Machines.xml") { Remove-Item -Path "$($Script:data.LabPath)\Machines.xml" -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)\Unattended*.xml") { Remove-Item -Path "$($Script:data.LabPath)\Unattended*.xml" -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)\AzureNetworkConfig.Xml") { Remove-Item -Path "$($Script:data.LabPath)\AzureNetworkConfig.Xml" -Recurse -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)\Certificates") { Remove-Item -Path "$($Script:data.LabPath)\Certificates" -Recurse -Force -Confirm:$false }
            
            #Only remove lab path folder if empty
            if ((Test-Path "$($Script:data.LabPath)") -and (-not (Get-ChildItem -Path $Script:data.LabPath)))
            {
                Remove-Item -Path $Script:data.LabPath
            }
        }
        
        if ($RemoveReferenceDisks)
        {
            Write-ScreenInfo -Message 'Removing Reference Disks'
            if ($Script:data.ServerReferenceDiskPath -like '*vhdx')
            {
                Remove-Item -Path $Script:data.ServerReferenceDiskPath -Confirm:$false
            }
        
            if ($Script:data.ServerReferenceDiskPath -like '*vhdx')
            {
                Remove-Item -Path $Script:data.ClientReferenceDiskPath -Confirm:$false
            }
        
            Remove-Item -Path (Split-Path -Path $Script:data.ClientReferenceDiskPath -Parent) -Confirm:$false -Recurse
        }

        $Script:data = $null
        
        Write-ScreenInfo -Message "Done removing lab '$labName'" -TaskEnd
    }
    
    Write-LogFunctionExit
}
#endregion Remove-Lab

#region Get-LabAvailableOperatingSystem
function Get-LabAvailableOperatingSystem
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    [OutputType([AutomatedLab.OperatingSystem])]
    param
    (
        [string[]]$Path
    )

    Write-LogFunctionEntry
    
    if (-not (Test-IsAdministrator))
    {
        throw 'This function needs to be called in an elevated PowerShell session.'
    }

    if (-not $Path)
    {
        $lab = Get-LabDefinition
        if (-not $lab)
        {
            $lab = Get-Lab -ErrorAction SilentlyContinue
        }

        if ($lab)
        {
            $Path = $lab.Sources.Isos | Split-Path -Parent | Select-Object -Unique
        }
        else
        {
            Write-Error 'No lab loaded and no path defined, hence it is not sure where to look for operating systems.'
            return
        }
    }
    
    $singleFile = Test-Path -Path $Path -PathType Leaf

    $isoFiles = Get-ChildItem -Path $Path -Filter *.iso -Recurse
    Write-Verbose "Found $($isoFiles.Count) ISO files"

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.OperatingSystem
    #read the cache
    try
    {
        $importMethodInfo = $type.GetMethod('ImportFromRegistry', [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static)
        $cachedOsList = $importMethodInfo.Invoke($null, ('Cache', 'LocalOperatingSystems'))
        Write-Verbose "Read $($cachedOsList.Count) OS images from the cache"
    }
    catch
    {
        Write-Verbose 'Could not read OS image info from the cache'
    }

    if ($cachedOsList -and -not $singleFile)
    {
        $cachedIsoFileSize = [long]$cachedOsList.Metadata[0]
        $actualIsoFileSize = ($isoFiles | Measure-Object -Property Length -Sum).Sum

        if ($cachedIsoFileSize -eq $actualIsoFileSize)
        {
            Write-Verbose 'Cached data is still up to date'
            Write-LogFunctionExit -ReturnValue $cachedOsList
            return $cachedOsList
        }
    
        Write-ScreenInfo -Message "ISO cache is not up to date. Analyzing all ISO files and updating the cache. This happens when running AutomatedLab for the first time and when changing contents of locations used for ISO files" -Type Warning
        Write-Verbose ('ISO file size ({0:N2}GB) does not match cached file size ({1:N2}). Reading the OS images from the ISO files and re-populating the cache' -f $actualIsoFileSize, $cachedIsoFileSize)
    }

    $osList = New-Object $type

    foreach ($isoFile in $isoFiles)
    {
        Write-Verbose "Mounting ISO image '$($isoFile.FullName)'"
        Mount-DiskImage -ImagePath $isoFile.FullName -StorageType ISO

        Get-PSDrive | Out-Null #This is just to refresh the drives. Somehow if this cmdlet is not called, PowerShell does not see the new drives.
    
        Write-Verbose 'Getting disk image of the ISO'
        $letter = (Get-DiskImage -ImagePath $isoFile.FullName | Get-Volume).DriveLetter
        Write-Verbose "Got disk image '$letter'"
        Write-Verbose "OS ISO mounted on drive letter '$letter'"
    
        $standardImagePath = "$letter`:\Sources\Install.wim"    
        if (Test-Path -Path $standardImagePath)
        {
            $images = Get-WindowsImage -ImagePath $standardImagePath
            
            Write-Verbose "The Windows Image list contains $($images.Count) items"
    
            foreach ($image in $images)
            {
                $imageInfo = Get-WindowsImage -ImagePath $standardImagePath -Index $image.ImageIndex
                
                if (-not ($imageInfo.Languages -like '*en-us*'))
                {
                    Write-Warning "The windows image '$($imageInfo.ImageName)' in the ISO '$($isoFile.Name)' has the language(s) '$($imageInfo.Languages -join ', ')'. AutomatedLab does only support images with the language 'en-us' hence this image will be skipped."
                    continue
                }

                $os = New-Object -TypeName AutomatedLab.OperatingSystem($Name, $isoFile.FullName)
                $os.OperatingSystemImageName = $imageInfo.ImageName
                $os.OperatingSystemName = $imageInfo.ImageName
                $os.Size = $imageInfo.Imagesize
                $os.Version = $imageInfo.Version
                $os.PublishedDate = $imageInfo.CreatedTime
                $os.Edition = $imageInfo.EditionId
                $os.Installation = $imageInfo.InstallationType
                $os.ImageIndex = $imageInfo.ImageIndex
        
                $osList.Add($os)
            }
        }

        $nanoImagePath = "$letter`:\NanoServer\NanoServer.wim"    
        if (Test-Path -Path $nanoImagePath)
        {
            $images = Get-WindowsImage -ImagePath $nanoImagePath
            
            Write-Verbose "The Windows Image list contains $($images.Count) items"
    
            foreach ($image in $images)
            {
                $imageInfo = Get-WindowsImage -ImagePath $nanoImagePath -Index $image.ImageIndex

                $os = New-Object -TypeName AutomatedLab.OperatingSystem($Name, $isoFile.FullName)
                $os.OperatingSystemImageName = $imageInfo.ImageName
                $os.OperatingSystemName = $imageInfo.ImageName
                $os.Size = $imageInfo.Imagesize
                $os.Version = $imageInfo.Version
                $os.PublishedDate = $imageInfo.CreatedTime
                $os.Edition = $imageInfo.EditionId
                $os.Installation = $imageInfo.InstallationType
                $os.ImageIndex = $imageInfo.ImageIndex
        
                $osList.Add($os)
            }
        }

        Write-Verbose 'Dismounting ISO'
        Dismount-DiskImage -ImagePath $isoFile.FullName
    }
    
    if (-not $singleFile)
    {
        $osList.Timestamp = Get-Date
        $osList.Metadata.Add(($isoFiles | Measure-Object -Property Length -Sum).Sum)
        $osList.ExportToRegistry('Cache', 'LocalOperatingSystems')
    }
    
    $osList.ToArray()
    
    Write-LogFunctionExit
}
#endregion Get-LabAvailableOperatingSystem

#region Update-LabIsoImage
function Update-LabIsoImage
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory)]
        [string]$SourceIsoImagePath,

        [Parameter(Mandatory)]
        [string]$TargetIsoImagePath,
        
        [Parameter(Mandatory)]
        [string]$UpdateFolderPath,
        
        [Parameter(Mandatory)]
        [int]$SourceImageIndex
    )
    
    #region Extract-IsoImage
    function Extract-IsoImage
    {
        param(
            [Parameter(Mandatory)]
            [string]$SourceIsoImagePath, 
        
            [Parameter(Mandatory)]
            [string]$OutputPath,

            [switch]$Force
        )
    
        if (-not (Test-Path -Path $SourceIsoImagePath -PathType Leaf))
        {
            Write-Error "The specified ISO image '$SourceIsoImagePath' could not be found"
            return
        }
    
        if ((Test-Path -Path $OutputPath) -and -not $Force)
        {
            Write-Error "The output folder does already exist" -TargetObject $OutputPath
            return
        }
        else
        {
            Remove-Item -Path $OutputPath -Force -Recurse -ErrorAction Ignore
        }

        mkdir -Path $OutputPath | Out-Null

        
        $image = Mount-DiskImage -ImagePath $SourceIsoImagePath -PassThru
        Get-PSDrive | Out-Null #This is just to refresh the drives. Somehow if this cmdlet is not called, PowerShell does not see the new drives.

        if($image)
        {

            $volume = Get-DiskImage -ImagePath $image.ImagePath | Get-Volume
            $source = $volume.DriveLetter + ':\*'
         
            Write-Verbose "Extracting ISO image '$source' to '$OutputPath'"            
            Copy-Item -Path $source -Destination $OutputPath -Recurse -Force
            Dismount-DiskImage -ImagePath $SourceIsoImagePath
            Write-Verbose 'Copy complete'
        }
        else
        {
            Write-Error "Could not mount ISO image '$SourceIsoImagePath'" -TargetObject $SourceIsoImagePath
            return
        }
    }
    #endregion Extract-IsoImage
    
    #region Get-IsoImageName
    function Get-IsoImageName
    {
        param(
            [Parameter(Mandatory)]
            [string]$IsoImagePath
        )
        
        if (-not (Test-Path -Path $IsoImagePath -PathType Leaf))
        {
            Write-Error "The specified ISO image '$IsoImagePath' could not be found"
            return
        }
        
        $image = Mount-DiskImage $IsoImagePath -PassThru
        $image | Get-Volume | Select-Object -ExpandProperty FileSystemLabel
        $image | Dismount-DiskImage
    }
    #endregion Get-IsoImageName
    
    $isUefi = try
    {
        Get-SecureBootUEFI -Name SetupMode
    }
    catch { }
    
    if (-not $isUefi)
    {
        throw "Updating ISO files does only work on UEFI systems due to a limitation of oscdimg.exe"
    }

    if (-not (Test-Path -Path $SourceIsoImagePath -PathType Leaf))
    {
        Write-Error "The specified ISO image '$SourceIsoImagePath' could not be found"
        return
    }
    
    if (Test-Path -Path $TargetIsoImagePath -PathType Leaf)
    {
        Write-Error "The specified target ISO image '$TargetIsoImagePath' does already exist"
        return
    }

    if ([System.IO.Path]::GetExtension($TargetIsoImagePath) -ne '.iso')
    {
        Write-Error "The specified target ISO image path must have the extension '.iso'"
        return
    }

    Write-Host 'Creating an updated ISO from'
    Write-Host "Target path             $TargetIsoImagePath"
    Write-Host "Source path             $SourceIsoImagePath"
    Write-Host "with updates from path  $UpdateFolderPath"
    Write-Host
    Write-Host "This process can take a long time, depending on the number of updates"
    $start = Get-Date
    Write-Host "Start time: $start"
    
    $extractTempFolder = mkdir -Path $labSources -Name ([guid]::NewGuid())
    $mountTempFolder = mkdir -Path $labSources -Name ([guid]::NewGuid())
    
    $isoImageName = Get-IsoImageName -IsoImagePath $SourceIsoImagePath
    
    Write-Host "Extracting ISO image '$SourceIsoImagePath' to '$extractTempFolder'"
    Extract-IsoImage -SourceIsoImagePath $SourceIsoImagePath -OutputPath $extractTempFolder -Force

    $installWim = Get-ChildItem -Path $extractTempFolder -Filter install.wim -Recurse
    Write-Host "Working with '$installWim'"
    Write-Host "Exporting install.wim to $labSources"
    Export-WindowsImage -SourceImagePath $installWim.FullName -DestinationImagePath $labSources\install.wim -SourceIndex $SourceImageIndex
    
    $windowsImage = Get-WindowsImage -ImagePath $labSources\install.wim
    Write-Host "The Windows Image exported is named '$($windowsImage.ImageName)'"
    Write-Host
    
    $patches = Get-ChildItem -Path $UpdateFolderPath\* -Include *.msu, *.cab
    Write-Host "Found $($patches.Count) patches in the UpdateFolderPath '$UpdateFolderPath'"
    
    Write-Host "Mounting Windows Image '$($windowsImage.ImagePath)' to folder "
    Mount-WindowsImage -Path $mountTempFolder -ImagePath $windowsImage.ImagePath -Index 1
    
    Write-Host
    Write-Host "Adding patches to the mounted Windows Image. This can take quite some time..."
    foreach ($patch in $patches)
    {        
        Write-Host "Adding patch '$($patch.Name)'..." -NoNewline
        Add-WindowsPackage -PackagePath $patch.FullName -Path $mountTempFolder | Out-Null
        Write-Host 'finished'
    }
    Write-Host
    
    Write-Host "Dismounting Windows Image from path '$mountTempFolder' and saving the changes. This can take quite some time again..." -NoNewline
    Dismount-WindowsImage -Path $mountTempFolder -Save
    Write-Host 'finished'
    
    Write-Host "Moving updated Windows Image '$labsources\install.wim' to '$extractTempFolder'"
    Move-Item -Path $labsources\install.wim -Destination $extractTempFolder\sources -Force
    Write-Host
    
    Write-Host "Calling oscdimg.exe to create a new bootable ISO image '$TargetIsoImagePath'..." -NoNewline
    $cmd = "$labSources\Tools\oscdimg.exe -m -o -u2 -l$isoImageName -udfver102 -bootdata:2#p0,e,b$extractTempFolder\boot\etfsboot.com#pEF,e,b$extractTempFolder\efi\microsoft\boot\efisys.bin $extractTempFolder $TargetIsoImagePath"
    Write-Verbose $cmd
    $global:oscdimgResult = Invoke-Expression -Command $cmd 2>&1
    Write-Host 'finished'

    Write-Host "Deleting temp folder '$extractTempFolder'"
    Remove-Item -Path $extractTempFolder -Recurse -Force
    
    Write-Host "Deleting temp folder '$mountTempFolder'"
    Remove-Item -Path $mountTempFolder -Recurse -Force
    
    Write-Host
    $end = Get-Date
    Write-Host "finished at $end. Runtime: $($end - $start)"
}
#endregion Update-LabIsoImage

#region Enable-LabVMRemoting
function Enable-LabVMRemoting
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [switch]$All
    )
    
    Write-LogFunctionEntry
    
    if (-not (Get-LabMachine))
    {
        Write-Error 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    if ($ComputerName)
    {
        $machines = Get-LabMachine -All | Where-Object { $_.Name -in $ComputerName }
    }
    else
    {
        $machines = Get-LabMachine -All
    }
    
    $hypervVMs = $machines | Where-Object HostType -eq 'HyperV'
    if ($hypervVMs)
    {
        Enable-LWHypervVMRemoting -ComputerName $hypervVMs
    }
        
    $azureVms = $machines | Where-Object HostType -eq 'Azure'
    if ($azureVms)
    {
        Enable-LWAzureVMRemoting -ComputerName $azureVms
    }
        
    $vmwareVms = $machines | Where-Object HostType -eq 'VmWare'
    if ($vmwareVms)
    {
        Enable-LWVMWareVMRemoting -ComputerName $vmwareVms
    }
    
    Write-LogFunctionExit
}
#endregion Enable-LabVMRemoting

#region Checkpoint-LabVM
function Checkpoint-LabVM
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [string]$SnapshotName,
        
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [switch]$All
    )
    
    Write-LogFunctionEntry
    
    if (-not (Get-LabMachine))
    {
        Write-Error 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    if ($Name)
    {
        $machines = Get-LabMachine | Where-Object { $_.Name -in $Name }
    }
    else
    {
        $machines = Get-LabMachine
    }
    
    if (-not $machines)
    {
        $message = 'No machine found to checkpoint. Either the given name is wrong or there is no machine defined yet'
        Write-LogFunctionExitWithError -Message $message
        return
    }
    
    foreach ($machine in $machines)
    {
        $ip = (Get-HostEntry -Hostname $machine).IpAddress.IPAddressToString
        $sessions = Get-PSSession | Where-Object { $_.ComputerName -eq $ip }
        if ($sessions)
        {
            Write-Verbose "Removing $($sessions.Count) open sessions to the machine"
            $sessions | Remove-PSSession
        }
    }
    
    Checkpoint-LWHypervVM -ComputerName $machines -SnapshotName $SnapshotName
    
    Write-LogFunctionExit
}
#endregion Checkpoint-LabVM

#region Restore-LabVMSnapshot
function Restore-LabVMSnapshot
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [string]$SnapshotName,
        
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [switch]$All
    )
    
    Write-LogFunctionEntry
    
    if (-not (Get-LabMachine))
    {
        Write-Error 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    if ($ComputerName)
    {
        $machines = Get-LabMachine | Where-Object { $_.Name -in $ComputerName }
    }
    else
    {
        $machines = Get-LabMachine
    }
    
    if (-not $machines)
    {
        $message = 'No machine found to restore the snapshot. Either the given name is wrong or there is no machine defined yet'
        Write-LogFunctionExitWithError -Message $message
        return
    }
    
    foreach ($machine in $machines)
    {
        $ip = (Get-HostEntry -Hostname $machine).IpAddress.IPAddressToString
        $sessions = Get-PSSession | Where-Object { $_.ComputerName -eq $ip }
        if ($sessions)
        {
            Write-Verbose "Removing $($sessions.Count) open sessions to the machine '$machine'"
            $sessions | Remove-PSSession
        }
    }
    
    Restore-LWHypervVMSnapshot -ComputerName $machines -SnapshotName $SnapshotName
    
    Write-LogFunctionExit
}
#endregion Restore-LabVMSnapshot

#region Remove-LabVMSnapshot
function Remove-LabVMSnapshot
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByNameAllSnapShots')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByNameSnapshotByName')]
        [string[]]$Name,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByNameSnapshotByName')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'AllMachinesSnapshotByName')]
        [string]$SnapshotName,
        
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'AllMachinesSnapshotByName')]
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'AllMachinesAllSnapshots')]
        [switch]$AllMachines,
        
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByNameAllSnapShots')]
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'AllMachinesAllSnapshots')]
        [switch]$AllSnapShots
    )
    
    Write-LogFunctionEntry
    
    if (-not (Get-LabMachine))
    {
        Write-Error 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    if ($Name)
    {
        $machines = Get-LabMachine | Where-Object { $_.Name -in $Name }
    }
    else
    {
        $machines = Get-LabMachine
    }
    
    if (-not $machines)
    {
        $message = 'No machine found to remove the snapshot. Either the given name is wrong or there is no machine defined yet'
        Write-LogFunctionExitWithError -Message $message
        return
    }
    
    if ($SnapshotName)
    {
        Remove-LWHypervVMSnapshot -ComputerName $machines -SnapshotName $SnapshotName
    }
    elseif ($AllSnapShots)
    {
        Remove-LWHypervVMSnapshot -ComputerName $machines -All
    }
    
    Write-LogFunctionExit
}
#endregion Remove-LabVMSnapshot

#region Install-LabWebServers
function Install-LabWebServers
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param ([switch]$CreateCheckPoints)
    
    Write-LogFunctionEntry
    
    $roleName = [AutomatedLab.Roles]::WebServer
    
    if (-not (Get-LabMachine))
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    $machines = Get-LabMachine | Where-Object { $roleName -in $_.Roles.Name }
    if (-not $machines)
    {
        Write-Warning -Message "There is no machine with the role '$roleName'"
        Write-LogFunctionExit
        return
    }
    
    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 30
    
    Write-ScreenInfo -Message 'Waiting for Web Server role to complete installation' -NoNewLine
    
    $coreMachines    = $machines | Where-Object { $_.OperatingSystem.Installation -match 'Core' }
    $nonCoreMachines = $machines | Where-Object { $_.OperatingSystem.Installation -notmatch 'Core' }
    
    $jobs = @()
    if ($coreMachines)    { $jobs += Install-LabWindowsFeature -ComputerName $coreMachines    -AsJob -PassThru -NoDisplay -IncludeAllSubFeature -FeatureName Web-WebServer, Web-Application-Proxy, Web-Health, Web-Performance, Web-Security, Web-App-Dev, Web-Ftp-Server, Web-Metabase, Web-Lgcy-Scripting, Web-WMI, Web-Scripting-Tools, Web-Mgmt-Service, Web-WHC }
    if ($nonCoreMachines) { $jobs += Install-LabWindowsFeature -ComputerName $nonCoreMachines -AsJob -PassThru -NoDisplay -IncludeAllSubFeature -FeatureName Web-Server }
    
    Start-LabVm -StartNextMachines 1 -NoNewline
    
    Wait-LWLabJob -Job $jobs -ProgressIndicator 30 -NoDisplay
    
    if ($CreateCheckPoints)
    {
        Checkpoint-LabVM -ComputerName $machines -SnapshotName 'Post Web Installation'
    }
    
    Write-LogFunctionExit
}
#endregion Install-LabWebServers

#region Get-LabWindowsFeature
function Get-LabWindowsFeature
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,
        
        [ValidateNotNullOrEmpty()]
        [string[]]$FeatureName,
        
        [switch]$UseLocalCredential,
        
        [int]$ProgressIndicator = 5,
        
        [switch]$NoDisplay   
    )
    
    Write-LogFunctionEntry
    
    $results = @()
    
    $machines = Get-LabMachine -ComputerName $ComputerName
    if (-not $machines)
    {
        Write-LogFunctionExitWithError -Message 'The specified machines could not be found'
        return
    }
    if ($machines.Count -ne $ComputerName.Count)
    {
        $machinesNotFound = Compare-Object -ReferenceObject $Name -DifferenceObject ($machines.Name)
        Write-Warning "The specified machines $($machinesNotFound.InputObject -join ', ') could not be found"
    }
    
    $activityName = "Get Windows Feature(s): '$($FeatureName -join ', ')'"
    
    $results = @()
    foreach ($machine in $machines)
    {
        if ($machine.OperatingSystem.Installation -eq 'Client')
        {
            #Add-Memer is required as the PSComputerName will be the IP address
            $cmd = { Get-WindowsOptionalFeature -Online | Add-Member -Name ComputerName -MemberType NoteProperty -Value (HOSTNAME.EXE) -PassThru }
        }
        else
        {
            #Add-Memer is required as the PSComputerName will be the IP address
            $cmd = {  Import-Module -Name ServerManager; Get-WindowsFeature | Add-Member -Name ComputerName -MemberType NoteProperty -Value (HOSTNAME.EXE) -PassThru }
        }
        
        $results += Invoke-LabCommand -ComputerName $machine -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -PassThru

        foreach ($result in $results)
        {
            $feature = New-Object AutomatedLab.WindowsFeature
            $feature.ComputerName =  $result.ComputerName

            #depending on whether the result is from a client or server machine, it is either the 'Name' or 'FeatureName' property
            if ([string]::IsNullOrEmpty($result.Name))
            {
                $feature.Name = $result.FeatureName
            }
            else
            {
                $feature.Name = $result.Name
            }

            #do not continue if the feature is not requested
            if ($FeatureName -and $feature.Name -notin $FeatureName)
            { continue }
            
            if ($result.State)
            {
                switch($result.State)
                {
                    'Disabled' { $feature.State = 'Available' }
                    'Enabled' { $feature.State = 'Installed' }
                    'DisabledWithPayloadRemoved' { $feature.State = 'Removed' }
                }
            }
            elseif ($result.InstallState)
            {
                $feature.State = [string]$result.InstallState
            }
            else
            {
                $feature.State = ?? { $result.Installed } { 'Installed' } { 'Available' }
            }

            $feature
        }
    }
    
    Write-LogFunctionExit
}
#endregion Get-LabWindowsFeature

#region Install-LabWindowsFeature
function Install-LabWindowsFeature
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FeatureName,

        [switch]$IncludeAllSubFeature,
        
        [switch]$UseLocalCredential,
        
        [int]$ProgressIndicator = 5,
        
        [switch]$NoDisplay,
        
        [switch]$PassThru,
        
        [switch]$AsJob        
    )
    
    Write-LogFunctionEntry
    
    $results = @()
    
    $machines = Get-LabMachine -ComputerName $ComputerName
    if (-not $machines)
    {
        Write-LogFunctionExitWithError -Message 'The specified machines could not be found'
        return
    }
    if ($machines.Count -ne $ComputerName.Count)
    {
        $machinesNotFound = Compare-Object -ReferenceObject $Name -DifferenceObject ($machines.Name)
        Write-Warning "The specified machines $($machinesNotFound.InputObject -join ', ') could not be found"
    }
    
    if (-not $NoDisplay)
    {
        Write-ScreenInfo -Message "Installing Windows Feature(s) '$($FeatureName -join ', ')' on computer(s) '$($ComputerName -join ', ')'" -TaskStart
        
        if ($AsJob)
        {
            if (-not $NoDisplay) { Write-ScreenInfo -Message 'Windows Feature(s) is being installed in the background' -TaskEnd }
        }
    }    
    
    Start-LabVM -ComputerName $ComputerName -Wait    
    
    $hyperVMachines = Get-LabMachine -ComputerName $ComputerName | Where-Object {$_.HostType -eq 'HyperV'}
    $azureMachines  = Get-LabMachine -ComputerName $ComputerName | Where-Object {$_.HostType -eq 'Azure'}

    if ($hyperVMachines)
    {
        foreach ($machine in $hyperVMachines)
        {
            $isoImagePath = $machine.OperatingSystem.IsoPath
            Mount-LabIsoImage -ComputerName $machine -IsoPath $isoImagePath -SupressOutput
        }
        $jobs = Install-LWHypervWindowsFeature -Machine $hyperVMachines -FeatureName $FeatureName -UseLocalCredential:$UseLocalCredential -IncludeAllSubFeature:$IncludeAllSubFeature -AsJob:$AsJob -PassThru:$PassThru
    }
    elseif ($azureMachines)
    {
        $jobs = Install-LWAzureWindowsFeature -Machine $azureMachines -FeatureName $FeatureName -UseLocalCredential:$UseLocalCredential -IncludeAllSubFeature:$IncludeAllSubFeature -AsJob:$AsJob -PassThru:$PassThru
    }
    
    if (-not $AsJob)
    {
        if ($hyperVMachines)
        {
            Dismount-LabIsoImage -ComputerName $hyperVMachines -SupressOutput
        }
        if (-not $NoDisplay) { Write-ScreenInfo -Message 'Done' -TaskEnd }
    }
    
    if ($PassThru)
    {
        $jobs
    }
    
    Write-LogFunctionExit
}
#endregion Install-LabWindowsFeature

#region Install-VisualStudio2013
function Install-VisualStudio2013
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_VisualStudio2013Installation
    )
    
    Write-LogFunctionEntry
    
    $roleName = [AutomatedLab.Roles]::VisualStudio2013
    
    if (-not (Get-LabMachine))
    {
        Write-Warning -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        Write-LogFunctionExit
        return
    }
    
    $machines = Get-LabMachine -Role $roleName | Where-Object HostType -eq 'HyperV'
    
    if (-not $machines)
    {
        return
    }
    
    $isoImage = $Script:data.Sources.ISOs | Where-Object Name -eq $roleName
    if (-not $isoImage)
    {
        Write-LogFunctionExitWithError -Message "There is no ISO image available to install the role '$roleName'. Please add the required ISO to the lab and name it '$roleName'"
        return
    }
    
    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 15
    
    $jobs = @()

    Mount-LabIsoImage -ComputerName $machines -IsoPath $isoImage.Path -SupressOutput
    
    foreach ($machine in $machines)
    {		
        $parameters = @{ }
        $parameters.Add('ComputerName', $machine.Name)
        $parameters.Add('ActivityName', 'InstallationVisualStudio2013')
        $parameters.Add('Verbose', $VerbosePreference)
        $parameters.Add('Scriptblock', {
                Write-Verbose 'Installing Visual Studio 2013'
            
                Push-Location
                Set-Location -Path (Get-WmiObject -Class Win32_CDRomDrive).Drive
                $exe = Get-ChildItem -Filter *.exe
                if ($exe.Count -gt 1)
                {
                    Write-Error 'More than one executable found, cannot proceed. Make sure you have defined the correct ISO image'
                    return
                }
                Write-Verbose "Calling '$($exe.FullName) /quiet /norestart /noweb /Log c:\VsInstall.log'"
                Invoke-Expression -Command "$($exe.FullName) /quiet /norestart /noweb /Log c:\VsInstall.log"
                Pop-Location
            
                Write-Verbose 'Waiting 120 seconds'
                Start-Sleep -Seconds 120
            
                $installationStart = Get-Date
                $installationTimeoutInMinutes = 120
                $installationFinished = $false
            
                Write-Verbose "Looping until '*Exit code: 0x<digits>, restarting: No' is detected in the VsInstall.log..."
                while (-not $installationFinished)
                {
                    if ((Get-Content -Path C:\VsInstall.log | Select-Object -Last 1) -match '(?<Text1>Exit code: 0x)(?<ReturnCode>\w*)(?<Text2>, restarting: No$)')
                    {
                        $installationFinished = $true
                        Write-Verbose 'Visual Studio installation finished'
                    }
                    else
                    {
                        Write-Verbose 'Waiting for the Visual Studio installation...'
                    }
                
                    if ($installationStart.AddMinutes($installationTimeoutInMinutes) -lt (Get-Date))
                    {
                        Write-Error "The installation of Visual Studio did not finish within the timeout of $installationTimeoutInMinutes minutes"
                        break
                    }
                
                    Start-Sleep -Seconds 5
                }
                $matches.ReturnCode
                Write-Verbose '...Installation seems to be done'
            }
        )
        
        $jobs += Invoke-LabCommand @parameters -AsJob -PassThru -NoDisplay
    }
    
    Write-ScreenInfo -Message 'Waiting for Visual Studio 2013 to complete installation' -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 60 -Timeout $InstallationTimeout -NoDisplay
    
    foreach ($job in $jobs)
    {
        $result = Receive-Job -Job $job
        if ($result -ne 0)
        {
            $ipAddress = (Get-Job -Id $job.id).Location
            $machineName = (Get-LabMachine | Where-Object {$_.IpV4Address -eq $ipAddress}).Name
            Write-ScreenInfo -Type Warning "Installation generated error or warning for machine '$machineName'. Return code is: $result"
        }
    }

    Dismount-LabIsoImage -ComputerName $machines -SupressOutput
    
    Write-LogFunctionExit
}
#endregion Install-VisualStudio2013

#region Install-VisualStudio2015
function Install-VisualStudio2015
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_VisualStudio2015Installation
    )
    
    Write-LogFunctionEntry
    
    $roleName = [AutomatedLab.Roles]::VisualStudio2015
    
    if (-not (Get-LabMachine))
    {
        Write-Warning -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        Write-LogFunctionExit
        return
    }
    
    $machines = Get-LabMachine -Role $roleName | Where-Object HostType -eq 'HyperV'
    
    if (-not $machines)
    {
        return
    }
    
    $isoImage = $Script:data.Sources.ISOs | Where-Object Name -eq $roleName
    if (-not $isoImage)
    {
        Write-LogFunctionExitWithError -Message "There is no ISO image available to install the role '$roleName'. Please add the required ISO to the lab and name it '$roleName'"
        return
    }
    
    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 15
    
    $jobs = @()

    Mount-LabIsoImage -ComputerName $machines -IsoPath $isoImage.Path -SupressOutput
    
    foreach ($machine in $machines)
    {		
        $parameters = @{ }
        $parameters.Add('ComputerName', $machine.Name)
        $parameters.Add('ActivityName', 'InstallationVisualStudio2015')
        $parameters.Add('Verbose', $VerbosePreference)
        $parameters.Add('Scriptblock', {
                Write-Verbose 'Installing Visual Studio 2015'
            
                Push-Location
                Set-Location -Path (Get-WmiObject -Class Win32_CDRomDrive).Drive
                $exe = Get-ChildItem -Filter *.exe
                if ($exe.Count -gt 1)
                {
                    Write-Error 'More than one executable found, cannot proceed. Make sure you have defined the correct ISO image'
                    return
                }
                Write-Verbose "Calling '$($exe.FullName) /quiet /norestart /noweb /Log c:\VsInstall.log'"
                $cmd = [scriptblock]::Create("$($exe.FullName) /quiet /norestart /noweb /Log c:\VsInstall.log")
                #there is something that does not work when invoked remotely. Hence a scheduled task is used to work around that.
                Register-ScheduledJob -ScriptBlock $cmd -Name VS2015Installation -RunNow | Out-Null
                
                Pop-Location
            
                Write-Verbose 'Waiting 120 seconds'
                Start-Sleep -Seconds 120
            
                $installationStart = Get-Date
                $installationTimeoutInMinutes = 120
                $installationFinished = $false
            
                Write-Verbose "Looping until '*Exit code: 0x<hex code>, restarting: No' is detected in the VsInstall.log..."
                while (-not $installationFinished)
                {
                    if ((Get-Content -Path C:\VsInstall.log | Select-Object -Last 1) -match '(?<Text1>Exit code: 0x)(?<ReturnCode>\w*)(?<Text2>, restarting: No$)')
                    {
                        $installationFinished = $true
                        Write-Verbose 'Visual Studio installation finished'
                    }
                    else
                    {
                        Write-Verbose 'Waiting for the Visual Studio installation...'
                    }
                
                    if ($installationStart.AddMinutes($installationTimeoutInMinutes) -lt (Get-Date))
                    {
                        Write-Error "The installation of Visual Studio did not finish within the timeout of $installationTimeoutInMinutes minutes"
                        break
                    }
                
                    Start-Sleep -Seconds 5
                }
                $matches.ReturnCode
                Write-Verbose '...Installation seems to be done'
            }
        )
        
        $jobs += Invoke-LabCommand @parameters -AsJob -PassThru -NoDisplay
    }
    
    Write-ScreenInfo -Message 'Waiting for Visual Studio 2015 to complete installation' -NoNewline
    
    Wait-LWLabJob -Job $jobs -ProgressIndicator 60 -Timeout $InstallationTimeout -NoDisplay
    
    foreach ($job in $jobs)
    {
        $result = Receive-Job -Job $job -Keep
        if ($result -notin '0', 'bc2') #0 == success, 0xbc2 == sucess but required reboot
        {
            $ipAddress = (Get-Job -Id $job.id).Location
            $machineName = (Get-LabMachine | Where-Object {$_.IpV4Address -eq $ipAddress}).Name
            Write-ScreenInfo -Type Warning "Installation generated error or warning for machine '$machineName'. Return code is: $result"
        }
    }
    
    Dismount-LabIsoImage -ComputerName $machines -SupressOutput
    
    Restart-LabVM -ComputerName $machines
    
    Write-LogFunctionExit
}
#endregion Install-VisualStudio2015

#region Install-LabOrchestrator2012
function Install-LabOrchestrator2012
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param ()
    
    Write-LogFunctionEntry
    
    #region prepare setup script
    function Install-LabPrivateOrchestratorRole
    {
        param (
            [Parameter(Mandatory)]
            [string]$OrchServiceUser,
            
            [Parameter(Mandatory)]
            [string]$OrchServiceUserPassword,
            
            [Parameter(Mandatory)]
            [string]$SqlServer,
            
            [Parameter(Mandatory)]
            [string]$SqlDbName
        )
        
        Write-Verbose -Message 'Installing Orchestrator'
        
        $start = Get-Date
        
        if (-not ((Get-WindowsFeature -Name NET-Framework-Features).Installed))
        {
            Write-Error "The WindowsFeature 'NET-Framework-Features' must be installed prior of installing Orchestrator. Use the cmdlet 'Install-LabWindowsFeature' to install the missing feature."
            return
        }
        
        $TimeoutInMinutes = 15
        $productName = 'Orchestrator 2012'
        $installProcessName = 'Setup'
        $installProcessDescription = 'Orchestrator Setup'
        $drive = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 5').DeviceID
        $computerDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name
        $cmd = "$drive\Setup\Setup.exe /Silent /ServiceUserName:$computerDomain\$OrchServiceUser /ServicePassword:$OrchServiceUserPassword /Components:All /DbServer:$SqlServer /DbNameNew:$SqlDbName /WebServicePort:81 /WebConsolePort:82 /OrchestratorRemote /SendCEIPReports:0 /EnableErrorReporting:never /UseMicrosoftUpdate:0"
        
        Write-Verbose 'Logs can be found here: C:\Users\<UserName>\AppData\Local\Microsoft System Center 2012\Orchestrator\Logs'
        
        #--------------------------------------------------------------------------------------
        
        Write-Verbose "Starting setup of '$productName' with the following command"
        Write-Verbose "`t$cmd"
        Write-Verbose "The timeout is $timeoutInMinutes minutes"
        
        Invoke-Expression -Command $cmd
        Start-Sleep -Milliseconds 500
        
        $timeout = Get-Date
        
        $queryExpression = "`$_.Name -eq '$installProcessName'"
        if ($installProcessDescription)
        {
            $queryExpression += "-and `$_.Description -eq '$installProcessDescription'"
        }
        $queryExpression = [scriptblock]::Create($queryExpression)
        
        Write-Verbose 'Query expression for looking for the setup process:'
        Write-Verbose "`t$queryExpression"
        
        if (-not (Get-Process | Where-Object $queryExpression))
        {
            Write-Error "Installation of '$productName' did not start"
            return
        }
        else
        {
            $p = Get-Process | Where-Object $queryExpression
            Write-Verbose "Installation process is '$($p.Name)' with ID $($p.Id)"
        }
        
        while (Get-Process | Where-Object $queryExpression)
        {
            if ((Get-Date).AddMinutes(- $TimeoutInMinutes) -gt $start)
            {
                Write-Error "Installation of '$productName' hit the timeout of 30 minutes. Killing the setup process"
                
                if ($installProcessDescription)
                {
                    Get-Process |
                    Where-Object  { $_.Name -eq $installProcessName -and $_.Description -eq 'Orchestrator Setup' } |
                    Stop-Process -Force
                }
                else
                {
                    Get-Process -Name $installProcessName | Stop-Process -Force
                }
                
                Write-Error "Installation of $productName was not successfull"
                return
            }
            
            Start-Sleep -Seconds 10
        }
        
        $end = Get-Date
        Write-Verbose "Installation finished in $($end - $start)"
    }
    #endregion
    
    $roleName = [AutomatedLab.Roles]::Orchestrator2012
    
    if (-not (Get-LabMachine))
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    $machines = Get-LabMachine -Role $roleName
    if (-not $machines)
    {
        Write-LogFunctionExitWithError -Message "There is no machine with the role $roleName"
        return
    }
    
    $isoImage = $Script:data.Sources.ISOs | Where-Object { $_.Name -eq $roleName }
    if (-not $isoImage)
    {
        Write-LogFunctionExitWithError -Message "There is no ISO image available to install the role '$roleName'. Please add the required ISO to the lab and name it '$roleName'"
        return
    }
    
    Start-LabVM -RoleName $roleName -Wait
    
    Install-LabWindowsFeature -ComputerName $machines -FeatureName RSAT, NET-Framework-Core -Verbose:$false

    Mount-LabIsoImage -ComputerName $machines -IsoPath $isoImage.Path -SupressOutput
    
    foreach ($machine in $machines)
    {
        $role = $machine.Roles | Where-Object { $_.Name -eq $roleName }
        
        $createUserScript = "
            `$user = New-ADUser -Name $($role.Properties.ServiceAccount) -AccountPassword ('$($role.Properties.ServiceAccountPassword)' | ConvertTo-SecureString -AsPlainText -Force) -Description 'Orchestrator Service Account' -Enabled `$true -PassThru
            Get-ADGroup -Identity 'Domain Admins' | Add-ADGroupMember -Members `$user
        Get-ADGroup -Identity 'Administrators' | Add-ADGroupMember -Members `$user"
        
        $dc = Get-LabMachine -All | Where-Object {
            $_.DomainName -eq $machine.DomainName -and
            $_.Roles.Name -in @([AutomatedLab.Roles]::DC, [AutomatedLab.Roles]::FirstChildDC, [AutomatedLab.Roles]::RootDC)
        } | Get-Random
        
        Write-Verbose "Domain controller for installation is '$($dc.Name)'"
        
        Invoke-LabCommand -ComputerName $dc -ScriptBlock ([scriptblock]::Create($createUserScript)) -ActivityName CreateOrchestratorServiceAccount -NoDisplay
        
        Invoke-LabCommand -ComputerName $machine -ActivityName Orchestrator2012Installation -NoDisplay -ScriptBlock (Get-Command Install-LabPrivateOrchestratorRole).ScriptBlock `
        -ArgumentList $Role.Properties.ServiceAccount, $Role.Properties.ServiceAccountPassword, $Role.Properties.DatabaseServer, $Role.Properties.DatabaseName
    }
    
    Dismount-LabIsoImage -ComputerName $machines -SupressOutput

    Write-LogFunctionExit
}
#endregion Install-LabOrchestrator2012

#region Install-LabSoftwarePackage
function Install-LabSoftwarePackage
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory, ParameterSetName = 'SinglePackage')]   
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'SingleLocalPackage')]
        [ValidateNotNullOrEmpty()]
        [string]$LocalPath,
        
        [Parameter(ParameterSetName = 'SinglePackage')]
        [Parameter(ParameterSetName = 'SingleLocalPackage')]
        [ValidateNotNullOrEmpty()]
        [string]$CommandLine,
        
        [int]$Timeout = 10,
        
        [Parameter(ParameterSetName = 'SinglePackage')]
        [Parameter(ParameterSetName = 'SingleLocalPackage')]
        [bool]$CopyFolder,
        
        [Parameter(Mandatory, ParameterSetName = 'SinglePackage')]
        [Parameter(Mandatory, ParameterSetName = 'SingleLocalPackage')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory, ParameterSetName = 'MulitPackage')]
        [AutomatedLab.Machine[]]$Machine,
        
        [Parameter(Mandatory, ParameterSetName = 'MulitPackage')]
        [AutomatedLab.SoftwarePackage]$SoftwarePackage,
        
        [switch]$DoNotUseCredSsp,
        
        [switch]$AsJob,
        
        [switch]$AsScheduledJob,
        
        [switch]$UseShellExecute,

        [switch]$PassThru,
        
        [switch]$NoDisplay,

        [int]$ProgressIndicator = 5
    )
    
    Write-LogFunctionEntry
    $parameterSetName = $PSCmdlet.ParameterSetName

    if ($Path)
    {
        if (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $Path)
        {
            $parameterSetName = 'SingleLocalPackage'
            $LocalPath = $Path
        }
    }
    
    if ($parameterSetName -eq 'SinglePackage')
    {
        if (-not (Test-Path -Path $Path))
        {
            Write-Error "The file '$Path' cannot be found. Software cannot be installed"
            return
        }

        Unblock-File -Path $Path
    }
    
    if ($parameterSetName -like 'Single*')
    {
        $Machine = Get-LabMachine -ComputerName $ComputerName

        if (-not $Machine)
        {
            Write-Error "The machine '$ComputerName' could not be found."
            return
        }

        $unknownMachines = (Compare-Object -ReferenceObject $ComputerName -DifferenceObject $Machine.Name).InputObject
        if ($unknownMachines)
        {
            Write-Warning "The machine(s) '$($unknownMachines -join ', ')' could not be found."
        }
    }
    
    if ($Path)
    {
        if (-not ($NoDisplay)) { Write-ScreenInfo -Message "Installing software package '$Path' on machines '$($ComputerName -join ', ')' " -TaskStart }
    }
    else
    {
        if (-not ($NoDisplay)) { Write-ScreenInfo -Message "Installing software package on VM '$LocalPath' on machines '$($ComputerName -join ', ')' " -TaskStart }
    }
    
    if ('Stopped' -in (Get-LabVMStatus $ComputerName -AsHashTable).Values)
    {
        if (-not ($NoDisplay)) { Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewLine }
        Start-LabVM -ComputerName $ComputerName -Wait -ProgressIndicator 30 -NoNewline
    }
    
    $jobs = @()
    
    $parameters = @{ }
    $parameters.Add('ComputerName', $ComputerName)
    $parameters.Add('DoNotUseCredSsp', $DoNotUseCredSsp)
    $parameters.Add('PassThru', $True)
    $parameters.Add('AsJob', $True)
    $parameters.Add('ScriptBlock', (Get-Command -Name Install-LWSoftwarePackage).ScriptBlock)
        
    if ($parameterSetName -eq 'SinglePackage')
    {
        $parameters.Add('ActivityName', "Installation of '$([System.IO.Path]::GetFileName($Path))'")
            
        if ($CopyFolder)
        {
            $parameters.Add('DependencyFolderPath', [System.IO.Path]::GetDirectoryName($Path))
        }
        else
        {
            $parameters.Add('DependencyFolderPath', $Path)
        }
        
        $installArgs = (Join-Path -Path C:\ -ChildPath (Split-Path -Path $Path -Leaf)), $CommandLine, $AsScheduledJob, $UseShellExecute
    }
    elseif ($parameterSetName -eq 'SingleLocalPackage')
    {
        $parameters.Add('ActivityName', "Installation of '$([System.IO.Path]::GetFileName($LocalPath))'")
            
        $installArgs = $LocalPath, $CommandLine, $AsScheduledJob, $UseShellExecute
    }
    else
    {
        $parameters.Add('ActivityName', "Installation of '$([System.IO.Path]::GetFileName($SoftwarePackage.Path))'")
            
        if ($SoftwarePackage.CopyFolder)
        {
            $parameters.Add('DependencyFolderPath', [System.IO.Path]::GetDirectoryName($SoftwarePackage.Path))
        }
        else
        {
            $parameters.Add('DependencyFolderPath', $SoftwarePackage.Path)
        }

        $installArgs = (Join-Path -Path C:\ -ChildPath (Split-Path -Path $SoftwarePackage.Path -Leaf)), $SoftwarePackage.CommandLine, $AsScheduledJob, $UseShellExecute
    }
    $parameters.Add('ArgumentList', $installArgs)
        
    Write-Verbose -Message "Starting background job for '$($parameters.ActivityName)'"
        
    $parameters.ScriptBlock = [scriptblock]::Create($parameters.ScriptBlock)
        
    $parameters.Add('NoDisplay', $True)
        
    if (-not $AsJob -and -not $NoDisplay) { Write-ScreenInfo -Message "Copying files/initiating setup on '$($ComputerName -join ', ')' and waiting for completion" -NoNewLine }
        
    $results += Invoke-LabCommand @parameters
        
    if (-not $AsJob)
    {
        Write-Verbose "Waiting on job ID '$($results.ID -join ', ')' with name '$($results.Name -join ', ')'"
        Wait-LWLabJob -Job $results -Timeout $Timeout -ProgressIndicator 30 -NoDisplay:$NoDisplay
        $results = $results | Receive-Job
        Write-Verbose "Job ID '$($results.ID -join ', ')' with name '$($results.Name -join ', ')' finished"
    }
    
    if ($AsJob)
    {
        if (-not ($NoDisplay)) { Write-ScreenInfo -Message 'Installation started in background' -TaskEnd }
    }
    else
    {
        if (-not ($NoDisplay)) { Write-ScreenInfo -Message 'Installation done' -TaskEnd }
    }
    
    if ($PassThru)
    {
        $results
    }
    
    Write-LogFunctionExit
}
#endregion Install-LabSoftwarePackage

#region Get-LabSoftwarePackage
function Get-LabSoftwarePackage
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
                    Test-Path -Path $_
                }
        )]
        [string]$Path,
        
        [string]$CommandLine,
        
        [int]$Timeout = 10
    )
    
    Write-LogFunctionEntry
    
    $pack = New-Object -TypeName AutomatedLab.SoftwarePackage
    $pack.CommandLine = $CommandLine
    $pack.CopyFolder = $CopyFolder
    $pack.Path = $Path
    $pack.Timeout = $timeout
    
    $pack
    
    Write-LogFunctionExit
}
#endregion Get-LabSoftwarePackage

#region Install-LabSoftwarePackages
function Install-LabSoftwarePackages
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [AutomatedLab.Machine[]]$Machine,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [AutomatedLab.SoftwarePackage[]]$SoftwarePackage,
        
        [switch]$WaitForInstallation,
        
        [switch]$PassThru
    )
    
    Write-LogFunctionEntry
    
    $start = Get-Date
    $jobs = @()
    
    foreach ($m in $Machine)
    {
        Write-Verbose -Message "Install-LabSoftwarePackages: Working on machine '$m'"
        foreach ($p in $SoftwarePackage)
        {
            Write-Verbose -Message "Install-LabSoftwarePackages: Building installation package for '$p'"
            
            $param = @{ }
            $param.Add('Path', $p.Path)
            if ($p.CommandLine)
            {
                $param.Add('CommandLine', $p.CommandLine)
            }
            $param.Add('Timeout', $p.Timeout)
            $param.Add('ComputerName', $m.Name)
            $param.Add('PassThru', $true)
            
            Write-Verbose -Message "Install-LabSoftwarePackages: Calling installation package '$p'"
            
            $jobs += Install-LabSoftwarePackage @param
            
            Write-Verbose -Message "Install-LabSoftwarePackages: Installation for package '$p' finished"
        }
    }
    
    Write-Verbose 'Waiting for installation jobs to finish'
    
    if ($WaitForInstallation)
    {
        Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -NoDisplay
    }
    
    $end = Get-Date
    
    Write-Verbose "Installation of all software packages took '$($end - $start)'"
    
    if ($PassThru)
    {
        $jobs
    }
    
    Write-LogFunctionExit
}
#endregion Install-LabSoftwarePackages

#region New-LabPSSession
function New-LabPSSession
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory, ParameterSetName = 'ByMachine')]
        [AutomatedLab.Machine[]]$Machine,

        #this is used to recreate a broken session
        [Parameter(Mandatory, ParameterSetName = 'BySession')]
        [System.Management.Automation.Runspaces.PSSession]$Session,
        
        [switch]$UseLocalCredential,
        
        [switch]$DoNotUseCredSsp,

        [pscredential]$Credential,

        [int]$Retries = 2,
        
        [int]$Interval = 5,

        [switch]$UseSSL
    )
    
    begin
    {
        Write-LogFunctionEntry
        $sessions = @()
        $lab = Get-Lab

        #Due to a problem in Windows 10 not being able to reach VMs from the host
        netsh.exe interface ip delete arpcache | Out-Null
    }
    
    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $Machine = Get-LabMachine -ComputerName $ComputerName

            if (-not $Machine)
            {
                Write-Error "There is no computer with the name '$ComputerName' in the lab"
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'BySession')
        {
            $internalSession = $Session
            $Machine = Get-LabMachine -ComputerName $internalSession.LabMachineName

            if ($internalSession.Runspace.ConnectionInfo.AuthenticationMechanism -ne 'Credssp')
            {
                $DoNotUseCredSsp = $true
            }
            if ($internalSession.Runspace.ConnectionInfo.Credential.UserName -like "$($Machine.Name)*")
            {
                $UseLocalCredential = $true
            }
        }
        
        foreach ($m in $Machine)
        {
            $machineRetries = $Retries

            if ($Credential)
            {
                $cred = $Credential
            }
            elseif ($UseLocalCredential)
            {
                $cred = $m.GetLocalCredential()
            }
            else
            {
                $cred = $m.GetCredential($lab)
            }
            
            $param = @{}
            $param.Add('Name', "$($m)_$([guid]::NewGuid())")
            $param.Add('Credential', $cred)
            $param.Add('UseSSL', $false)

            if ($DoNotUseCredSsp)
            {
                $param.Add('Authentication', 'Default')
            }
            else
            {
                $param.Add('Authentication', 'Credssp')
            }

            if ($m.HostType -eq 'Azure')
            {
                $param.Add('ComputerName', $m.AzureConnectionInfo.DnsName)
                $param.Add('Port', $m.AzureConnectionInfo.Port)
                if ($UseSSL)
                {
                    $param.Add('SessionOption', (New-PSSessionOption -SkipCACheck -SkipCNCheck))
                    $param.UseSSL = $true
                }
            }
            elseif ($m.HostType -eq 'HyperV' -or $m.HostType -eq 'VMWare')
            {
                $doNotUseGetHostEntry = $MyInvocation.MyCommand.Module.PrivateData.DoNotUseGetHostEntryInNewLabPSSession
                if (-not $doNotUseGetHostEntry)
                {
                    $name = (Get-HostEntry -Hostname $m).IpAddress.IpAddressToString
                }
                
                if ($name)
                {
                    $param.Add('ComputerName', $name)
                }
                else
                {
                    $param.Add('ComputerName', $m)
                }
                $param.Add('Port', 5985)
            }

            Write-Verbose ("Creating a new PSSession to machine '{0}:{1}' (UserName='{2}', Password='{3}', DoNotUseCredSsp='{4}')" -f $param.ComputerName, $param.Port, $cred.UserName, $cred.GetNetworkCredential().Password, $DoNotUseCredSsp)
    
            #session reuse. If there is a session to the machine available, return it, otherwise create a new session
            $internalSession = Get-PSSession | Where-Object {
                $_.ComputerName -eq $param.ComputerName -and
                $_.Runspace.ConnectionInfo.Port -eq $param.Port -and
                $_.Availability -eq 'Available' -and
                $_.Runspace.ConnectionInfo.AuthenticationMechanism -eq $param.Authentication -and
                $_.State -eq 'Opened' -and
                $_.Name -like "$($m)_*" -and
                $_.Runspace.ConnectionInfo.Credential.UserName -eq $param.Credential.UserName
            }

            if ($internalSession)
            {
                if ($internalSession.Runspace.ConnectionInfo.AuthenticationMechanism -eq 'CredSsp' -and
                    -not $internalSession.ALLabSourcesMapped -and
                    (Get-LabVM -ComputerName $internalSession.LabMachineName).HostType -eq 'Azure'
                )
                {
                    #remove the existing session if connecting to Azure LabSoruce did not work in case the session connects to an Azure VM.
                    Write-Warning "Removing session to '$internalSession.LabMachineName' as ALLabSourcesMapped was false"
                    Remove-LabPSSession -ComputerName $internalSession.LabMachineName
                    $internalSession = $null
                }
                
                if ($internalSession.Count -eq 1)
                {
                    Write-Verbose "Session $($internalSession.Name) is available and will be reused"
                    $sessions += $internalSession
                }
                elseif ($internalSession.Count -ne 0)
                {
                    $sessionsToRemove = $internalSession | Select-Object -Skip 1
                    Write-Verbose "Found orphaned sessions. Removing $($sessionsToRemove.Count) sessions: $($sessionsToRemove.Name -join ', ')"
                    $sessionsToRemove | Remove-PSSession
            
                    Write-Verbose "Session $($internalSession[0].Name) is available and will be reused"
                    $sessions += $internalSession[0]
                }
            }
    
            while (-not $internalSession -and $machineRetries -gt 0)
            {
                netsh.exe interface ip delete arpcache | Out-Null

                Write-Verbose "Testing port $($param.Port) on computer '$($param.ComputerName)'"
                $portTest = Test-Port -ComputerName $param.ComputerName -Port $param.Port -TCP
                if ($portTest.Open)
                {
                    Write-Verbose 'Port was open, trying to create the session'
                    $internalSession = New-PSSession @param -ErrorAction SilentlyContinue -ErrorVariable sessionError
                    $internalSession | Add-Member -Name LabMachineName -MemberType ScriptProperty -Value { $this.Name.Substring(0, $this.Name.IndexOf('_')) }

                    if ($internalSession)
                    {
                        Write-Verbose "Session to computer '$($param.ComputerName)' created"
                        $sessions += $internalSession
                        
                        if ((Get-LabMachine -ComputerName $internalSession.LabMachineName).HostType -eq 'Azure')
                        {
                            Connect-LWAzureLabSourcesDrive -Session $internalSession
                        }
                        
                    }
                    else
                    {
                        Write-Verbose -Message "Session to computer '$($param.ComputerName)' could not be created, waiting $Interval seconds ($machineRetries retries). The error was: '$($sessionError[0].FullyQualifiedErrorId)'"
                        if ($Retries -gt 1) { Start-Sleep -Seconds $Interval }
                        $machineRetries--
                    }
                }
                else
                {
                    Write-Verbose 'Port was NOT open, cannot create session.'
                    Start-Sleep -Seconds $Interval
                }
            }

            if (-not $internalSession)
            {
                Write-Error -ErrorRecord $sessionError[0]
            }
        }
    }
    
    end
    {
        Write-LogFunctionExit -ReturnValue "Session IDs: $(($sessions.ID -join ', '))"
        $sessions
    }
}
#endregion New-LabPSSession

#region Get-LabPSSession
function Get-LabPSSession
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    [OutputType([System.Management.Automation.Runspaces.PSSession])]
    
    param (
        [string[]]$ComputerName,
        
        [switch]$DoNotUseCredSsp
    )
        
    $pattern = '\w+_[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}'
        
    if ($ComputerName)
    {
        $computers = Get-LabMachine -ComputerName $ComputerName
    }
    else
    {
        $computers = Get-LabMachine
    }
    
    if (-not $computers)
    {
        Write-Error 'The machines could not be found' -TargetObject $ComputerName
    }
        
    $sessions = foreach ($computer in $computers)
    {
        $session = Get-PSSession | Where-Object { $_.Name -match $pattern -and $_.Name -like "$($computer.Name)_*" }
        
        if (-not $session -and $ComputerName)
        {
            Write-Error "No session found for computer '$computer'" -TargetObject $computer
        }
        else
        {
            $session
        }
    }
    
    if ($DoNotUseCredSsp)
    {
        $sessions | Where-Object { $_.Runspace.ConnectionInfo.AuthenticationMechanism -ne 'CredSsp' }
    }
    else
    {
        $sessions
    }
}
#endregion Get-LabPSSession

#region Remove-LabPSSession
function Remove-LabPSSession
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory, ParameterSetName = 'ByMachine')]
        [AutomatedLab.Machine[]]$Machine,
        
        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )
    
    Write-LogFunctionEntry
    $lab = Get-Lab
    $removedSessionCount = 0
    if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        $Machine = Get-LabMachine -ComputerName $ComputerName
    }
    if ($PSCmdlet.ParameterSetName -eq 'All')
    {
        $Machine = Get-LabMachine -All
    }
        
    foreach ($m in $Machine)
    {
        $param = @{}
        if ($m.HostType -eq 'Azure')
        {
            $param.Add('ComputerName', $m.AzureConnectionInfo.DnsName)
            $param.Add('Port', $m.AzureConnectionInfo.Port)
        }
        elseif ($m.HostType -eq 'HyperV' -or $m.HostType -eq 'VMWare')
        {
            if ($doNotUseGetHostEntry = $MyInvocation.MyCommand.Module.PrivateData.DoNotUseGetHostEntryInNewLabPSSession)
            {
                $param.Add('ComputerName', $m.Name)
            }
            else
            {
                $param.Add('ComputerName', (Get-HostEntry -Hostname $m).IpAddress.IpAddressToString)
            }
            $param.Add('Port', 5985)
        }

        $sessions = Get-PSSession | Where-Object {
            $_.ComputerName -eq $param.ComputerName -and
            $_.Runspace.ConnectionInfo.Port -eq $param.Port -and
        $_.Name -like "$($m)_*" }

        $sessions | Remove-PSSession -ErrorAction SilentlyContinue
        $removedSessionCount += $sessions.Count
    }

    Write-Verbose "Removed $removedSessionCount PSSessions..."
    Write-LogFunctionExit
}
#endregion Remove-LabPSSession

#region Enter-LabPSSession
function Enter-LabPSSession
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string]$ComputerName,
        
        [Parameter(Mandatory, ParameterSetName = 'ByMachine', Position = 0)]
        [AutomatedLab.Machine]$Machine,
        
        [switch]$DoNotUseCredSsp,
        
        [switch]$UseLocalCredential
    )
    
    if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        $Machine = Get-LabMachine -ComputerName $ComputerName
    }

    if ($Machine)
    {
        $session = New-LabPSSession -Machine $Machine -DoNotUseCredSsp:$DoNotUseCredSsp -UseLocalCredential:$UseLocalCredential
    
        $session | Enter-PSSession
    }
    else
    {
        Write-Error 'The specified machine could not be found in the lab.'
    }
}
#endregion Enter-LabPSSession

#region Invoke-LabCommand
function Invoke-LabCommand
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [string]$ActivityName = '<unnamed>',
        
        [Parameter(ParameterSetName = 'PostInstallationActivity')]
        [switch]$PostInstallationActivity,

        [Parameter(Mandatory, ParameterSetName = 'ScriptBlockFileContentDependency', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'ScriptFileContentDependency', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'ScriptFileNameContentDependency', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'Script', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'ScriptBlock', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'PostInstallationActivity', Position = 0)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory, ParameterSetName = 'ScriptBlockFileContentDependency', Position = 1)]
        [Parameter(Mandatory, ParameterSetName = 'ScriptBlock', Position = 1)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory, ParameterSetName = 'ScriptFileContentDependency')]
        [Parameter(Mandatory, ParameterSetName = 'Script')]
        [string]$FilePath,

        [Parameter(Mandatory, ParameterSetName = 'ScriptFileNameContentDependency')]
        [string]$FileName,
        
        [Parameter(ParameterSetName = 'ScriptFileNameContentDependency')]
        [Parameter(Mandatory, ParameterSetName = 'ScriptBlockFileContentDependency')]
        [Parameter(Mandatory, ParameterSetName = 'ScriptFileContentDependency')]
        [string]$DependencyFolderPath,
        
        [object[]]$ArgumentList,
        
        [switch]$DoNotUseCredSsp,
        
        [switch]$UseLocalCredential,

        [pscredential]$Credential,
        
        [System.Management.Automation.PSVariable[]]$Variable,
        
        [System.Management.Automation.FunctionInfo[]]$Function,

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [Parameter(ParameterSetName = 'ScriptBlockFileContentDependency')]
        [Parameter(ParameterSetName = 'ScriptFileContentDependency')]
        [Parameter(ParameterSetName = 'Script')]
        [Parameter(ParameterSetName = 'ScriptFileNameContentDependency')]
        [int]$Retries,

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [Parameter(ParameterSetName = 'ScriptBlockFileContentDependency')]
        [Parameter(ParameterSetName = 'ScriptFileContentDependency')]
        [Parameter(ParameterSetName = 'Script')]
        [Parameter(ParameterSetName = 'ScriptFileNameContentDependency')]
        [int]$RetryIntervalInSeconds,
        
        [int]$ThrottleLimit = 32,
        
        [switch]$AsJob,
        
        [switch]$PassThru,        
        
        [switch]$NoDisplay
    )
    
    Write-LogFunctionEntry

    if ($PSCmdlet.ParameterSetName -in 'Script', 'ScriptBlock', 'ScriptFileContentDependency', 'ScriptBlockFileContentDependency','ScriptFileNameContentDependency')
    {
        if (-not $Retries) { $Retries = $MyInvocation.MyCommand.Module.PrivateData.InvokeLabCommandRetries }
        if (-not $RetryIntervalInSeconds) { $RetryIntervalInSeconds = $MyInvocation.MyCommand.Module.PrivateData.InvokeLabCommandRetryIntervalInSeconds }
    }
    
    if ($AsJob)
    {
        if (-not ($NoDisplay)) { Write-ScreenInfo -Message "Executing lab command activity: '$ActivityName' on machines '$($ComputerName -join ', ')'" -TaskStart }
        
        if (-not ($NoDisplay)) { Write-ScreenInfo -Message 'Activity started in background' -TaskEnd }
    }
    else
    {
        if (-not ($NoDisplay)) { Write-ScreenInfo -Message "Executing lab command activity: '$ActivityName' on machines '$($ComputerName -join ', ')'" -TaskStart }
        
        if (-not ($NoDisplay)) { Write-ScreenInfo -Message 'Waiting for completion' }
    }
    
    Write-Verbose -Message "Executing lab command activity '$ActivityName' on machines '$($ComputerName -join ', ')'"
    
    #required to suppress verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    if (-not (Get-LabMachine))
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    if ($FilePath)
    {
        if (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $FilePath)
        {
            Write-Verbose "$FilePath is on Azure. Skipping test."
        }
        elseif (-not (Test-Path -Path $FilePath))
        {
            Write-LogFunctionExitWithError -Message "$FilePath is not on Azure and does not exist"
            return
        }
    }
    
    if ($PostInstallationActivity)
    {
        $machines = Get-LabMachine -ComputerName $ComputerName | Where-Object { $_.PostInstallationActivity }
        if (-not $machines)
        {
            Write-Verbose 'There are no machine with PostInstallationActivity defined, exiting...'
            return
        }
    }
    else
    {
        $machines = Get-LabMachine -ComputerName $ComputerName   
    }

    if (-not $machines)
    {
        Write-Warning "Cannot invoke the command '$ActivityName', as the specified machines ($($ComputerName -join ', ')) could not be found in the lab."
        return
    }
        
    if ('Stopped' -in (Get-LabVMStatus -ComputerName $machines).Values)
    {
        Start-LabVM -ComputerName $machines -Wait
    }
    
    if ($PostInstallationActivity -and $machines)
    {
        Write-ScreenInfo -Message 'Performing post-installations tasks defined for each machine' -TaskStart

        $results = @()

        foreach ($machine in $machines)
        {
            foreach ($item in $machine.PostInstallationActivity)
            {
                $ComputerName = $machine.Name
                
                $param = @{}
                $param.Add('ComputerName', $ComputerName)

                Write-Verbose "Creating session to computers) '$ComputerName'"
                $session = New-LabPSSession -ComputerName $ComputerName -DoNotUseCredSsp:$item.DoNotUseCredSsp
                if (-not $session)
                {
                    Write-LogFunctionExitWithError "Could not create a session to machine '$ComputerName'"
                    return
                }
                $param.Add('Session', $session)
                
                if ($item.DependencyFolder.Value) { $param.Add('DependencyFolderPath', $item.DependencyFolder.Value) }
                if ($item.ScriptFileName) { $param.Add('ScriptFileName',$item.ScriptFileName) }
                if ($item.ScriptFilePath) { $param.Add('ScriptFilePath', $item.ScriptFilePath) }
                if ($item.KeepFolder) { $param.Add('KeepFolder', $item.KeepFolder) }
                if ($item.ActivityName) { $param.Add('ActivityName', $item.ActivityName) }
                if ($Retries) { $param.Add('Retries', $Retries) }
                if ($RetryIntervalInSeconds) { $param.Add('RetryIntervalInSeconds', $RetryIntervalInSeconds) }
        
                $param.AsJob      = $true
                $param.PassThru   = $PassThru
                $param.Verbose    = $VerbosePreference
                if ($PSBoundParameters.ContainsKey('ThrottleLimit'))
                {
                    $param.Add('ThrottleLimit', $ThrottleLimit)
                }

                $results += Invoke-LWCommand @param
            }
        }
        
        Write-ScreenInfo -Message 'Post-installations done' -TaskEnd
    }
    else
    {
        $param = @{}
        $param.Add('ComputerName', $machines)
            
        Write-Verbose "Creating session to computer(s) '$machines'"
        $session = @(New-LabPSSession -ComputerName $machines -DoNotUseCredSsp:$DoNotUseCredSsp -UseLocalCredential:$UseLocalCredential -Credential $credential)
        if (-not $session)
        {
            Write-LogFunctionExitWithError "Could not create a session to machine '$machines'"
            return
        }
        
        if ($Function)        
        {
            Write-Verbose "Adding functions '$($Function -join ',')' to session"
            $Function | Add-FunctionToPSSession -Session $session
        }
        
        if ($Variable)
        {
            Write-Verbose "Adding variables '$($Variable -join ',')' to session"
            $Variable | Add-VariableToPSSession -Session $session
        }
        
        $param.Add('Session', $session)
            
        if ($ScriptBlock)            { $param.Add('ScriptBlock', $ScriptBlock) }
        if ($Retries)                { $param.Add('Retries', $Retries) }
        if ($RetryIntervalInSeconds) { $param.Add('RetryIntervalInSeconds', $RetryIntervalInSeconds) }
        if ($FilePath)               { $param.Add('ScriptFilePath', $FilePath) }
        if ($FileName)               { $param.Add('ScriptFileName', $FileName) }
        if ($ActivityName)           { $param.Add('ActivityName', $ActivityName) }
        if ($ArgumentList)           { $param.Add('ArgumentList', $ArgumentList) }
        if ($DependencyFolderPath)   { $param.Add('DependencyFolderPath', $DependencyFolderPath) }
        
        $param.PassThru   = $PassThru
        $param.AsJob      = $AsJob
        $param.Verbose    = $VerbosePreference
        if ($PSBoundParameters.ContainsKey('ThrottleLimit'))
        {
            $param.Add('ThrottleLimit', $ThrottleLimit)
        }

        $results = Invoke-LWCommand @param
    }

    if ($AsJob)
    {
        if (-not $NoDisplay) { Write-ScreenInfo -Message 'Activity started in background' -TaskEnd }
    }
    else
    {
        if (-not $NoDisplay) { Write-ScreenInfo -Message 'Activity done' -TaskEnd }
    }

    if ($PassThru) { $results }
    
    Write-LogFunctionExit
}
#endregion Invoke-LabCommand

#region Update-LabMemorySettings
function Update-LabMemorySettings
{
    # .ExternalHelp AutomatedLab.Help.xml
    [Cmdletbinding()]
    Param ()
    
    Write-LogFunctionEntry
    
    $machines = Get-LabMachine -All
    $lab = Get-LabDefinition

    if ($machines | Where-Object Memory -lt 32)
    {
        $totalMemoryAlreadyReservedAndClaimed = ((Get-VM -Name $machines -ErrorAction SilentlyContinue) | Measure-Object -Sum -Property MemoryStartup).Sum
        $machinesNotCreated = $machines | Where-Object { (-not (Get-VM -Name $_ -ErrorAction SilentlyContinue)) }
    
        $totalMemoryAlreadyReserved = ($machines | Where-Object { $_.Memory -ge 128 -and $_.Name -notin $machinesNotCreated.Name } | Measure-Object -Property Memory -Sum).Sum
    
        $totalMemory = (Get-WmiObject -Namespace Root\Cimv2 -Class win32_operatingsystem).FreePhysicalMemory * 1KB * 0.8 - $totalMemoryAlreadyReserved + $totalMemoryAlreadyReservedAndClaimed
    
        if ($lab.MaxMemory -ne 0 -and $lab.MaxMemory -le $totalMemory)
        {
            $totalMemory = $lab.MaxMemory
            Write-Debug -Message "Memory in lab is manually limited to: $totalmemory MB"
        }
        else
        {
            Write-Debug -Message "80% of total available (free) physical memory minus memory already reserved by machines where memory is defined: $totalmemory bytes"
        }
        
        
        $totalMemoryUnits = ($machines | Where-Object Memory -lt 32 | Measure-Object -Property Memory -Sum).Sum
        
        ForEach ($machine in $machines | Where-Object Memory -ge 128)
        {
            Write-Debug -Message "$($machine.Name.PadRight(20)) $($machine.Memory / 1GB)GB (set manually)"
        }
        
        #Test if necessary to limit memory at all
        $memoryUsagePrediction = $totalMemoryAlreadyReserved
        foreach ($machine in $machines | Where-Object Memory -lt 32)
        {
            switch ($machine.Memory)
            {
                1 { if ($lab.UseStaticMemory)
                    {
                        $memoryUsagePrediction += 768
                    }
                    else
                    {
                        $memoryUsagePrediction += 512
                    }
                }
                2 { if ($lab.UseStaticMemory)
                    {
                        $memoryUsagePrediction += 1024
                    }
                    else
                    {
                        $memoryUsagePrediction += 512
                    }
                }
                3 { if ($lab.UseStaticMemory)
                    {
                        $memoryUsagePrediction += 2048
                    }
                    else
                    {
                        $memoryUsagePrediction += 1024
                    }
                }
                4 { if ($lab.UseStaticMemory)
                    {
                        $memoryUsagePrediction += 4096
                    }
                    else
                    {
                        $memoryUsagePrediction += 1024
                    }
                }
            }
        }
        
        ForEach ($machine in $machines | Where-Object { $_.Memory -lt 32 -and -not (Get-VM -Name $_.Name -ErrorAction SilentlyContinue) })
        {
            $memoryCalculated = [int]($totalMemory / $totalMemoryUnits * $machine.Memory / 64) * 64
            if ($memoryUsagePrediction -gt $totalMemory)
            {
                $machine.Memory = $memoryCalculated
                if (-not $lab.UseStaticMemory)
                {
                    $machine.MaxMemory = $memoryCalculated * 4
                }
            }
            else
            {
                if ($lab.MaxMemory -eq 4TB)
                {
                    #If parameter UseAllMemory was used for New-LabDefinition
                    $machine.Memory = $memoryCalculated
                }
                else
                {
                    switch ($machine.Memory)
                    {
                        1 { if ($lab.UseStaticMemory)
                            {
                                $machine.Memory = 768MB
                            }
                            else
                            {
                                $machine.MinMemory = 384MB
                                $machine.Memory    = 512MB
                                $machine.MaxMemory = 1.25GB
                            }
                        }
                        2 { if ($lab.UseStaticMemory)
                            {
                                $machine.Memory = 1GB
                            }
                            else
                            {
                                $machine.MinMemory = 384MB
                                $machine.Memory    = 512MB
                                $machine.MaxMemory = 2GB
                            }
                        }
                        3 { if ($lab.UseStaticMemory)
                            {
                                $machine.Memory = 2GB
                            }
                            else
                            {
                                $machine.MinMemory = 384MB
                                $machine.Memory    = 1GB
                                $machine.MaxMemory = 4GB
                            }
                        }
                        4 { if ($lab.UseStaticMemory)
                            {
                                $machine.Memory = 4GB
                            }
                            else
                            {
                                $machine.MinMemory = 384MB
                                $machine.Memory    = 1GB
                                $machine.MaxMemory = 8GB
                            }
                        }
                    }
                }
            }
            Write-Debug -Message "$("Memory in $($machine)".PadRight(30)) $($machine.Memory / 1GB)GB (calculated)"
            if ($machine.MaxMemory)
            {
                Write-Debug -Message "$("MaxMemory in $($machine)".PadRight(30)) $($machine.MaxMemory / 1GB)GB (calculated)"
            }
            
            if ($memoryCalculated -lt 256)
            {
                Write-Warning -Message "Machine '$($machine.Name)' is now auto-configured with $($memoryCalculated / 1GB)GB of memory. This might give unsatisfactory performance. Consider adding memory to the host, raising the available memory for this lab or use fewer machines in this lab"
            }
        }
        
        <#
                $plannedMaxMemoryUsage = (Get-LabMachine -All).MaxMemory | Measure-Object -Sum | Select-Object -ExpandProperty Sum
                if ($plannedMaxMemoryUsage -le ($totalMemory/3))
                {
                foreach ($machine in (Get-LabMachine))
                {
                (Get-LabMachine -ComputerName $machine).Memory *= 2
                (Get-LabMachine -ComputerName $machine).MaxMemory *= 2
                }
                }
        #>
    }
    
    Write-LogFunctionExit
}
#endregion Update-LabMemorySettings

#region Set-LabInstallationCredential
function Set-LabInstallationCredential
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param (
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Parameter(Mandatory=$false, ParameterSetName = 'Prompt')]
        [ValidatePattern("^([\'\""a-zA-Z0-9]){2,15}$")]
        [string]$Username,
        
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Parameter(Mandatory=$false, ParameterSetName = 'Prompt')]
        [string]$Password,

        [Parameter(Mandatory, ParameterSetName = 'Prompt')]
        [switch]$Prompt
    )
    
    if (-not (Get-LabDefinition))
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabInstallationCredential.'
    }
    
    if ($PSCmdlet.ParameterSetName -eq 'All')
    {
        $user = New-Object AutomatedLab.User($Username, $Password)
        (Get-LabDefinition).DefaultInstallationCredential = $user
    }   
    else
    {
        $promptUser = Read-Host "Type desired username for admin user (or leave blank for 'Install'. Username cannot be 'Administrator' is deploying in Azure)"
        
        if (-not $promptUser)
        {
            $promptUser = 'Install'
        }
        do
        {
            $promptPassword = Read-Host "Type password for admin user (leave blank for 'Somepass1' or type 'x' to cancel )"
            
            if (-not $promptPassword)
            {
                $promptPassword = 'Somepass1'
                $checks = 5
                break
            }
            
            [int]$minLength  = 8
            [int]$numUpper   = 1
            [int]$numLower   = 1
            [int]$numNumbers = 1 
            [int]$numSpecial = 1
                
            $upper   = [regex]'[A-Z]'
            $lower   = [regex]'[a-z]'
            $number  = [regex]'[0-9]'
            $special = [regex]'[^a-zA-Z0-9]'
                
            $checks = 0
                
            if ($promptPassword.length -ge 8)                            { $checks++ }
            if ($upper.Matches($promptPassword).Count -ge $numUpper )    { $checks++ }
            if ($lower.Matches($promptPassword).Count -ge $numLower )    { $checks++ }
            if ($number.Matches($promptPassword).Count -ge $numNumbers ) { $checks++ }
                
            if ($checks -lt 4)
            {
                if ($special.Matches($promptPassword).Count -ge $numSpecial )  { $checks }
            }
                
            if ($checks -lt 4)
            {
                Write-Host 'Password must be have minimum length of 8'
                Write-Host 'Password must contain minimum one upper case character'
                Write-Host 'Password must contain minimum one lower case character'
                Write-Host 'Password must contain minimum one special character'
            }
        }
        until ($checks -ge 4 -or (-not $promptUser) -or (-not $promptPassword) -or $promptPassword -eq 'x')
            
        if ($checks -ge 4 -and $promptPassword -ne 'x') 
        {
            $user = New-Object AutomatedLab.User($promptUser, $promptPassword)
        }
    }
}
#endregion Set-LabInstallationCredential

#region Show-LabDeploymentSummary
function Show-LabDeploymentSummary
{
    # .ExternalHelp AutomatedLab.Help.xml
    [OutputType([System.TimeSpan])]
    [Cmdletbinding()]
    param (
        [switch]$Detailed
    )
    
    $ts = New-TimeSpan -Start $Global:AL_DeploymentStart -End (Get-Date)
    $hoursPlural = ''
    $minutesPlural = ''
    $secondsPlural = ''
    
    if ($ts.Hours   -gt 1) { $hoursPlural   = 's' }
    if ($ts.minutes -gt 1) { $minutesPlural = 's' }
    if ($ts.Seconds -gt 1) { $secondsPlural = 's' }

    $lab = Get-Lab
    $machines = Get-LabVM
    
    Write-ScreenInfo -Message '---------------------------------------------------------------------------'
    Write-ScreenInfo -Message ("Setting up the lab took {0} hour$hoursPlural, {1} minute$minutesPlural and {2} second$secondsPlural" -f $ts.hours, $ts.minutes, $ts.seconds)
    Write-ScreenInfo -Message "Lab name is '$($lab.Name)' and is hosted on '$($lab.DefaultVirtualizationEngine)'. There are $($machines.Count) machine(s) and $($lab.VirtualNetworks.Count) network(s) defined."
    
    if (-not $Detailed)
    {
        Write-ScreenInfo -Message '---------------------------------------------------------------------------'
    }    
    else
    {
        Write-ScreenInfo
        Write-ScreenInfo -Message '----------------------------- Network Summary -----------------------------'
        $networkInfo = $lab.VirtualNetworks | Format-Table -Property Name, AddressSpace, SwitchType, AdapterName, @{ Name = 'IssuedIpAddresses'; Expression = { $_.IssuedIpAddresses.Count } } | Out-String
        $networkInfo -split "`n" | ForEach-Object {
            if ($_) { Write-ScreenInfo -Message $_ }
        }
        
        Write-ScreenInfo -Message '----------------------------- Domain Summary ------------------------------'
        $domainInfo = $lab.Domains | Format-Table -Property Name,
        @{ Name = 'Administrator'; Expression = { $_.Administrator.UserName } },
        @{ Name = 'Password'; Expression = { $_.Administrator.Password } },
        @{ Name = 'RootDomain'; Expression = { if ($lab.GetParentDomain($_.Name).Name -ne $_.Name) { $lab.GetParentDomain($_.Name) } } } |
        Out-String
        
        $domainInfo -split "`n" | ForEach-Object {
            if ($_) { Write-ScreenInfo -Message $_ }
        }
        
        Write-ScreenInfo -Message '------------------------- Virtual Machine Summary -------------------------'
        $vmInfo = Get-LabVM | Format-Table -Property Name, DomainName, IpAddress, Roles, OperatingSystem,
        @{ Name = 'Local Admin'; Expression = { $_.InstallationUser.UserName } },
        @{ Name = 'Password'; Expression = { $_.InstallationUser.Password } } -AutoSize |
        Out-String
        
        $vmInfo -split "`n" | ForEach-Object {
            if ($_) { Write-ScreenInfo -Message $_ }
        }

        Write-ScreenInfo -Message '---------------------------------------------------------------------------'
        Write-ScreenInfo -Message 'Please use the following cmdlets to interact with the machines:'
        Write-ScreenInfo -Message '- Get-LabVMStatus, Get, Start, Restart, Stop, Wait, Connect, Save-LabVM and Wait-LabVMRestart (some of them provide a Wait switch)'
        Write-ScreenInfo -Message '- Invoke-LabCommand, Enter-LabPSSession, Install-LabSoftwarePackage and Install-LabWindowsFeature (do not require credentials and'
        Write-ScreenInfo -Message '  work the same way with Hyper-V and Azure)'
        Write-ScreenInfo -Message '- Checkpoint-LabVM, Restore-LabVMSnapshot and Get-LabVMSnapshot (only for Hyper-V)'
        Write-ScreenInfo -Message '- Get-LabInternetFile downloads files from the internet and places them on LabSources (locally or on Azure)'
        Write-ScreenInfo -Message '---------------------------------------------------------------------------'
    }
}
#endregion Show-LabDeploymentSummary

#region Set-LabGlobalNamePrefix
function Set-LabGlobalNamePrefix
{
    # .ExternalHelp AutomatedLab.Help.xml
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [ValidatePattern("^([\'\""a-zA-Z0-9]){1,4}$|()")]
        [string]$Name
    )
    
    $Global:labNamePrefix = $Name
}
#endregion Set-LabGlobalNamePrefix

#region Set-LabToolsPath
function Set-LabDefaultToolsPath
{
    # .ExternalHelp AutomatedLab.Help.xml
    [Cmdletbinding()]  
    Param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    $Global:labToolsPath = $Path
}
#endregion Set-LabToolsPath

#region Set-LabDefaultOperatingSYstem
function Set-LabDefaultOperatingSystem
{
    # .ExternalHelp AutomatedLab.Help.xml
    [Cmdletbinding()]  
    Param(
        [Parameter(Mandatory)]
        [alias('Name')]
        [string]$OperatingSystem,
        [string]$Version
    )
    
    if (Get-LabDefinition)
    {
        if ($Version)
        {
            $os = Get-LabAvailableOperatingSystem | Where-Object {$_.OperatingSystemName -eq $OperatingSystem -and $_.Version -eq $OperatingSystemVersion}
        }
        else
        {
            $os = Get-LabAvailableOperatingSystem | Where-Object {$_.OperatingSystemName -eq $OperatingSystem}
            if ($os.Count -gt 1)
            {
                $os = $os | Sort-Object Version -Descending | Select-Object -First 1
                Write-Warning "The operating system '$OperatingSystem' is available multiple times. Choosing the one with the highest version ($($os.Version)) as default operating system"
            }
        }

        if (-not $os)
        {
            throw "The operating system '$OperatingSystem' could not be found in the available operating systems. Call 'Get-LabAvailableOperatingSystem' to get a list of operating systems available to the lab."
        }
        (Get-LabDefinition).DefaultOperatingSystem = $os
    }
    else
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabDefaultOperatingSystem.'
    }
}
#endregion Set-LabDefaultOperatingSystem

#region Set-LabDefaultVirtualization
function Set-LabDefaultVirtualizationEngine
{
    # .ExternalHelp AutomatedLab.Help.xml
    [Cmdletbinding()]  
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'HyperV', 'VMware')]
        [string]$VirtualizationEngine
    )
    
    if (Get-LabDefinition)
    {
        (Get-LabDefinition).DefaultVirtualizationEngine = $VirtualizationEngine
    }
    else
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabDefaultOperatingSystem.'
    }
}
#endregion Set-LabDefaultVirtualizationEngine

#region Get-LabSourcesLocation
function Get-LabSourcesLocation
{
    # .ExternalHelp AutomatedLab.Help.xml
    $labSources
}
#endregion Get-LabSourcesLocation

#region Get-LabVariable
function Get-LabVariable
{
    # .ExternalHelp AutomatedLab.Help.xml
    $pattern = 'AL_([a-zA-Z0-9]{8})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{12})'
    Get-Variable -Scope Global | Where-Object Name -Match $pattern
}
#endregion Get-LabVariable

#region Remove-LabVariable
function Remove-LabVariable
{
    # .ExternalHelp AutomatedLab.Help.xml
    $pattern = 'AL_([a-zA-Z0-9]{8})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{12})'
    Get-LabVariable | Remove-Variable -Scope Global
}
#endregion Remove-LabVariable

#region Clear-LabCache
function Clear-LabCache
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]

    param()

    Write-LogFunctionEntry

    Remove-Item -Path Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\Software\AutomatedLab\Cache -Force -ErrorAction SilentlyContinue
    Write-Verbose 'AutomatedLab cache removed'

    Write-LogFunctionExit
}
#endregion Clear-LabCache

#region function Add-LabVMUserRight
function Add-LabVMUserRight
{
    # .ExternalHelp AutomatedLab.Help.xml
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByMachine')]
        [String[]]$ComputerName,
        [string[]]$UserName,
        [validateSet('SeNetworkLogonRight', 
                'SeRemoteInteractiveLogonRight', 
                'SeBatchLogonRight', 
                'SeInteractiveLogonRight', 
                'SeServiceLogonRight', 
                'SeDenyNetworkLogonRight', 
                'SeDenyInteractiveLogonRight', 
                'SeDenyBatchLogonRight', 
                'SeDenyServiceLogonRight', 
                'SeDenyRemoteInteractiveLogonRight', 
                'SeTcbPrivilege', 
                'SeMachineAccountPrivilege', 
                'SeIncreaseQuotaPrivilege', 
                'SeBackupPrivilege', 
                'SeChangeNotifyPrivilege', 
                'SeSystemTimePrivilege', 
                'SeCreateTokenPrivilege', 
                'SeCreatePagefilePrivilege', 
                'SeCreateGlobalPrivilege', 
                'SeDebugPrivilege', 
                'SeEnableDelegationPrivilege', 
                'SeRemoteShutdownPrivilege', 
                'SeAuditPrivilege', 
                'SeImpersonatePrivilege', 
                'SeIncreaseBasePriorityPrivilege', 
                'SeLoadDriverPrivilege', 
                'SeLockMemoryPrivilege', 
                'SeSecurityPrivilege', 
                'SeSystemEnvironmentPrivilege', 
                'SeManageVolumePrivilege', 
                'SeProfileSingleProcessPrivilege', 
                'SeSystemProfilePrivilege', 
                'SeUndockPrivilege', 
                'SeAssignPrimaryTokenPrivilege', 
                'SeRestorePrivilege', 
                'SeShutdownPrivilege', 
                'SeSynchAgentPrivilege', 
                'SeTakeOwnershipPrivilege' 
        )]
        [string[]]$Priveleges
    )
    
    $Job = @()
    
    foreach ($Computer in $ComputerName)
    {
        $param = @{}
        $param.add('UserName', $UserName)
        $param.add('Right', $Right)
        $param.add('ComputerName', $Computer)

        $Job += Invoke-LabCommand -ComputerName $Computer -ActivityName "Configure user rights '$($Priveleges -join ', ')' for user accounts: '$($UserName -join ', ')'" -NoDisplay -AsJob -PassThru -ScriptBlock {
            param
            (
                $UserName,
                $Priveleges
            )
                
            try
            {
        
                # try to access and if fails Add the type
                $dummy =  [MyLsaWrapper].FullName

            }
            catch
            {
                #region Code
                Add-Type @'
                using System;
                using System.Collections.Generic;
                using System.Text;

                namespace MyLsaWrapper
                {
                    using System.Runtime.InteropServices;
                    using System.Security;
                    using System.Management;
                    using System.Runtime.CompilerServices;
                    using System.ComponentModel;

                    using LSA_HANDLE = IntPtr;

                    [StructLayout(LayoutKind.Sequential)]
                    struct LSA_OBJECT_ATTRIBUTES
                    {
                        internal int Length;
                        internal IntPtr RootDirectory;
                        internal IntPtr ObjectName;
                        internal int Attributes;
                        internal IntPtr SecurityDescriptor;
                        internal IntPtr SecurityQualityOfService;
                    }
                    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
                    struct LSA_UNICODE_STRING
                    {
                        internal ushort Length;
                        internal ushort MaximumLength;
                        [MarshalAs(UnmanagedType.LPWStr)]
                        internal string Buffer;
                    }
                    sealed class Win32Sec
                    {
                        [DllImport("advapi32", CharSet = CharSet.Unicode, SetLastError = true),
                        SuppressUnmanagedCodeSecurityAttribute]
                        internal static extern uint LsaOpenPolicy(
                        LSA_UNICODE_STRING[] SystemName,
                        ref LSA_OBJECT_ATTRIBUTES ObjectAttributes,
                        int AccessMask,
                        out IntPtr PolicyHandle
                        );

                        [DllImport("advapi32", CharSet = CharSet.Unicode, SetLastError = true),
                        SuppressUnmanagedCodeSecurityAttribute]
                        internal static extern uint LsaAddAccountRights(
                        LSA_HANDLE PolicyHandle,
                        IntPtr pSID,
                        LSA_UNICODE_STRING[] UserRights,
                        int CountOfRights
                        );

                        [DllImport("advapi32", CharSet = CharSet.Unicode, SetLastError = true),
                        SuppressUnmanagedCodeSecurityAttribute]
                        internal static extern int LsaLookupNames2(
                        LSA_HANDLE PolicyHandle,
                        uint Flags,
                        uint Count,
                        LSA_UNICODE_STRING[] Names,
                        ref IntPtr ReferencedDomains,
                        ref IntPtr Sids
                        );

                        [DllImport("advapi32")]
                        internal static extern int LsaNtStatusToWinError(int NTSTATUS);

                        [DllImport("advapi32")]
                        internal static extern int LsaClose(IntPtr PolicyHandle);

                        [DllImport("advapi32")]
                        internal static extern int LsaFreeMemory(IntPtr Buffer);

                    }
                    /// <summary>
                    /// This class is used to grant "Log on as a service", "Log on as a batchjob", "Log on localy" etc.
                    /// to a user.
                    /// </summary>
                    public sealed class LsaWrapper : IDisposable
                    {
                        [StructLayout(LayoutKind.Sequential)]
                        struct LSA_TRUST_INFORMATION
                        {
                            internal LSA_UNICODE_STRING Name;
                            internal IntPtr Sid;
                        }
                        [StructLayout(LayoutKind.Sequential)]
                        struct LSA_TRANSLATED_SID2
                        {
                            internal SidNameUse Use;
                            internal IntPtr Sid;
                            internal int DomainIndex;
                            uint Flags;
                        }

                        [StructLayout(LayoutKind.Sequential)]
                        struct LSA_REFERENCED_DOMAIN_LIST
                        {
                            internal uint Entries;
                            internal LSA_TRUST_INFORMATION Domains;
                        }

                        enum SidNameUse : int
                        {
                            User = 1,
                            Group = 2,
                            Domain = 3,
                            Alias = 4,
                            KnownGroup = 5,
                            DeletedAccount = 6,
                            Invalid = 7,
                            Unknown = 8,
                            Computer = 9
                        }
                        
                        enum Access : int
                        {
                            POLICY_READ = 0x20006,
                            POLICY_ALL_ACCESS = 0x00F0FFF,
                            POLICY_EXECUTE = 0X20801,
                            POLICY_WRITE = 0X207F8
                        }
                        const uint STATUS_ACCESS_DENIED = 0xc0000022;
                        const uint STATUS_INSUFFICIENT_RESOURCES = 0xc000009a;
                        const uint STATUS_NO_MEMORY = 0xc0000017;

                        IntPtr lsaHandle;

                        public LsaWrapper()
                            : this(null)
                        { }
                        // // local system if systemName is null
                        public LsaWrapper(string systemName)
                        {
                            LSA_OBJECT_ATTRIBUTES lsaAttr;
                            lsaAttr.RootDirectory = IntPtr.Zero;
                            lsaAttr.ObjectName = IntPtr.Zero;
                            lsaAttr.Attributes = 0;
                            lsaAttr.SecurityDescriptor = IntPtr.Zero;
                            lsaAttr.SecurityQualityOfService = IntPtr.Zero;
                            lsaAttr.Length = Marshal.SizeOf(typeof(LSA_OBJECT_ATTRIBUTES));
                            lsaHandle = IntPtr.Zero;
                            LSA_UNICODE_STRING[] system = null;
                            if (systemName != null)
                            {
                                system = new LSA_UNICODE_STRING[1];
                                system[0] = InitLsaString(systemName);
                            }

                            uint ret = Win32Sec.LsaOpenPolicy(system, ref lsaAttr,
                            (int)Access.POLICY_ALL_ACCESS, out lsaHandle);
                            if (ret == 0)
                                return;
                            if (ret == STATUS_ACCESS_DENIED)
                            {
                                throw new UnauthorizedAccessException();
                            }
                            if ((ret == STATUS_INSUFFICIENT_RESOURCES) || (ret == STATUS_NO_MEMORY))
                            {
                                throw new OutOfMemoryException();
                            }
                            throw new Win32Exception(Win32Sec.LsaNtStatusToWinError((int)ret));
                        }

                        public void AddPrivileges(string account, string privilege)
                        {
                            IntPtr pSid = GetSIDInformation(account);
                            LSA_UNICODE_STRING[] privileges = new LSA_UNICODE_STRING[1];
                            privileges[0] = InitLsaString(privilege);
                            uint ret = Win32Sec.LsaAddAccountRights(lsaHandle, pSid, privileges, 1);
                            if (ret == 0)
                                return;
                            if (ret == STATUS_ACCESS_DENIED)
                            {
                                throw new UnauthorizedAccessException();
                            }
                            if ((ret == STATUS_INSUFFICIENT_RESOURCES) || (ret == STATUS_NO_MEMORY))
                            {
                                throw new OutOfMemoryException();
                            }
                            throw new Win32Exception(Win32Sec.LsaNtStatusToWinError((int)ret));
                        }

                        public void Dispose()
                        {
                            if (lsaHandle != IntPtr.Zero)
                            {
                                Win32Sec.LsaClose(lsaHandle);
                                lsaHandle = IntPtr.Zero;
                            }
                            GC.SuppressFinalize(this);
                        }
                        ~LsaWrapper()
                        {
                            Dispose();
                        }
                        // helper functions

                        IntPtr GetSIDInformation(string account)
                        {
                            LSA_UNICODE_STRING[] names = new LSA_UNICODE_STRING[1];
                            LSA_TRANSLATED_SID2 lts;
                            IntPtr tsids = IntPtr.Zero;
                            IntPtr tdom = IntPtr.Zero;
                            names[0] = InitLsaString(account);
                            lts.Sid = IntPtr.Zero;
                            Console.WriteLine("String account: {0}", names[0].Length);
                            int ret = Win32Sec.LsaLookupNames2(lsaHandle, 0, 1, names, ref tdom, ref tsids);
                            if (ret != 0)
                                throw new Win32Exception(Win32Sec.LsaNtStatusToWinError(ret));
                            lts = (LSA_TRANSLATED_SID2)Marshal.PtrToStructure(tsids,
                            typeof(LSA_TRANSLATED_SID2));
                            Win32Sec.LsaFreeMemory(tsids);
                            Win32Sec.LsaFreeMemory(tdom);
                            return lts.Sid;
                        }

                        static LSA_UNICODE_STRING InitLsaString(string s)
                        {
                            // Unicode strings max. 32KB
                            if (s.Length > 0x7ffe)
                                throw new ArgumentException("String too long");
                            LSA_UNICODE_STRING lus = new LSA_UNICODE_STRING();
                            lus.Buffer = s;
                            lus.Length = (ushort)(s.Length * sizeof(char));
                            lus.MaximumLength = (ushort)(lus.Length + sizeof(char));
                            return lus;
                        }
                    }
                    public class LsaWrapperCaller
                    {
                        public static void AddPrivileges(string account, string privilege)
                        {
                            using (LsaWrapper lsaWrapper = new LsaWrapper())
                            {
                                lsaWrapper.AddPrivileges(account, privilege);
                            }
                        }
                    }
                }
'@
                #endregion
            }
        
            finally
            {
                foreach ($User in $UserName)
                {
                    foreach ($Priv in $Priveleges)
                    {
                        [MyLsaWrapper.LsaWrapperCaller]::AddPrivileges($User, $Priv)
                        Start-Sleep -Milliseconds 250
                        [MyLsaWrapper.LsaWrapperCaller]::AddPrivileges($User, $Priv)
                    }
                }
            }
        } -ArgumentList $UserName, $Priveleges
    }
    Wait-LWLabJob -Job $Job -NoDisplay
}
#endregion function Add-LabVMUserRight

#New-Alias -Name Invoke-LabPostInstallActivity -Value Invoke-LabCommand -Scope Global
#New-Alias -Name Set-LabVMRemoting -Value Enable-LabVMRemoting -Scope Global
#New-Alias -Name Set-LabHostRemoting -Value Enable-LabHostRemoting -Scope Global

$dynamicLabSources = New-Object AutomatedLab.DynamicVariable 'global:labSources', { Get-LabSourcesLocationInternal }, { $null }
$executioncontext.SessionState.PSVariable.Set($dynamicLabSources)
