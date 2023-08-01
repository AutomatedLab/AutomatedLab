function Add-LabMachineDefinition
{
    [CmdletBinding(DefaultParameterSetName = 'Network')]
    [OutputType([AutomatedLab.Machine])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidatePattern("^([\'\""a-zA-Z0-9-]){1,15}$")]
        [string]$Name,

        [ValidateRange(128MB, 128GB)]
        [double]$Memory,

        [ValidateRange(128MB, 128GB)]
        [double]$MinMemory,

        [ValidateRange(128MB, 128GB)]
        [double]$MaxMemory,

        [ValidateRange(1, 64)]
        [ValidateNotNullOrEmpty()]
        [int]$Processors = 0,

        [ValidatePattern('^([a-zA-Z0-9-_]){2,30}$')]
        [string[]]$DiskName,

        [Alias('OS')]
        [AutomatedLab.OperatingSystem]$OperatingSystem = (Get-LabDefinition).DefaultOperatingSystem,

        [string]$OperatingSystemVersion,

        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^([a-zA-Z0-9])|([ ]){2,244}$')]
        [string]$Network,

        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))$')]
        [string]$IpAddress,

        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))$')]
        [string]$Gateway,

        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))$')]
        [string]$DnsServer1,

        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))$')]
        [string]$DnsServer2,

        [Parameter(ParameterSetName = 'NetworkAdapter')]
        [AutomatedLab.NetworkAdapter[]]$NetworkAdapter,

        [switch]$IsDomainJoined,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]$DefaultDomain,

        [System.Management.Automation.PSCredential]$InstallationUserCredential,

        [ValidatePattern("(?=^.{1,254}$)|([\'\""])(^(?:(?!\d+\.|-)[a-zA-Z0-9_\-]{1,63}(?<!-)\.)+(?:[a-zA-Z]{2,})$)")]
        [string]$DomainName,

        [AutomatedLab.Role[]]$Roles,

        #Created ValidateSet using: "'" + ([System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::InstalledWin32Cultures).Name -join "', '") + "'" | clip
        [ValidateScript( { $_ -in @([System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures).Name) })]
        [string]$UserLocale,

        [AutomatedLab.InstallationActivity[]]$PostInstallationActivity,

        [AutomatedLab.InstallationActivity[]]$PreInstallationActivity,

        [string]$ToolsPath,

        [string]$ToolsPathDestination,

        [AutomatedLab.VirtualizationHost]$VirtualizationHost = 'HyperV',

        [switch]$EnableWindowsFirewall,

        [string]$AutoLogonDomainName,

        [string]$AutoLogonUserName,

        [string]$AutoLogonPassword,

        [hashtable]$AzureProperties,

        [hashtable]$HypervProperties,

        [hashtable]$Notes,

        [switch]$PassThru,

        [string]$ResourceName,

        [switch]$SkipDeployment,

        [string]$AzureRoleSize,

        [string]$TimeZone,

        [string[]]$RhelPackage,

        [string[]]$SusePackage,

        [string[]]$UbuntuPackage,

        [string]$SshPublicKeyPath,

        [string]$SshPrivateKeyPath,

        [string]$OrganizationalUnit,
        
        [string]$ReferenceDisk,

        [string]$KmsServerName,

        [uint16]$KmsPort,

        [string]$KmsLookupDomain,

        [switch]$ActivateWindows,

        [string]$InitialDscConfigurationMofPath,

        [string]$InitialDscLcmConfigurationMofPath,

        [ValidateSet(1, 2)]
        [int]
        $VmGeneration
    )

    begin
    {
        Write-LogFunctionEntry
    }

    process
    {
        $machineRoles = ''
        if ($Roles)
        {
            $machineRoles = " (Roles: $($Roles.Name -join ', '))" 
        }

        $azurePropertiesValidKeys = 'ResourceGroupName', 'UseAllRoleSizes', 'RoleSize', 'LoadBalancerRdpPort', 'LoadBalancerWinRmHttpPort', 'LoadBalancerWinRmHttpsPort', 'LoadBalancerAllowedIp', 'SubnetName', 'UseByolImage', 'AutoshutdownTime', 'AutoshutdownTimezoneId', 'StorageSku', 'EnableSecureBoot', 'EnableTpm'
        $hypervPropertiesValidKeys = 'AutomaticStartAction', 'AutomaticStartDelay', 'AutomaticStopAction', 'EnableSecureBoot', 'SecureBootTemplate', 'EnableTpm'

        if (-not $VirtualizationHost -and -not (Get-LabDefinition).DefaultVirtualizationEngine)
        {
            Throw "Parameter 'VirtualizationHost' is mandatory when calling 'Add-LabMachineDefinition' if no default virtualization engine is specified"
        }

        if (-not $PSBoundParameters.ContainsKey('VirtualizationHost') -and (Get-LabDefinition).DefaultVirtualizationEngine)
        {
            $VirtualizationHost = (Get-LabDefinition).DefaultVirtualizationEngine
        }

        Write-ScreenInfo -Message (("Adding $($VirtualizationHost.ToString().Replace('HyperV', 'Hyper-V')) machine definition '$Name'").PadRight(47) + $machineRoles) -TaskStart

        if (-not (Get-LabDefinition))
        {
            throw 'Please create a lab definition by calling New-LabDefinition before adding machines'
        }

        $script:lab = Get-LabDefinition
        if (($script:lab.DefaultVirtualizationEngine -eq 'Azure' -or $VirtualizationHost -eq 'Azure') -and -not $script:lab.AzureSettings)
        {
            try
            {
                Add-LabAzureSubscription
            }
            catch
            {
                throw "No Azure subscription added yet. Please run 'Add-LabAzureSubscription' first."
            }
        }

        if ($Global:labExported)
        {
            throw 'Lab is already exported. Please create a new lab definition by calling New-LabDefinition before adding machines'
        }

        if (Get-Lab -ErrorAction SilentlyContinue)
        {
            throw 'Lab is already imported. Please create a new lab definition by calling New-LabDefinition before adding machines'
        }

        if (-not $OperatingSystem)
        {
            $os = Get-LabAvailableOperatingSystem -UseOnlyCache -NoDisplay | Where-Object -Property OperatingSystemType -eq 'Windows' | Sort-Object Version | Select-Object -Last 1

            if ($null -ne $os)
            {
                Write-ScreenInfo -Message "No operating system specified. Assuming you want $os ($(Split-Path -Leaf -Path $os.IsoPath))."
                $OperatingSystem = $os
            }
            else
            {
                throw "No operating system was defined for machine '$Name' and no default operating system defined. Please define either of these and retry. Call 'Get-LabAvailableOperatingSystem' to get a list of operating systems added to the lab."
            }
        }

        if (((Get-Command New-PSSession).Parameters.Values.Name -notcontains 'HostName') -and -not [string]::IsNullOrWhiteSpace($SshPublicKeyPath))
        {
            Write-ScreenInfo -Type Warning -Message "SSH Transport is not available from within Windows PowerShell. Please use PowerShell 6+ if you want to use remoting-cmdlets."
        }

        if ((-not [string]::IsNullOrWhiteSpace($SshPublicKeyPath) -and [string]::IsNullOrWhiteSpace($SshPrivateKeyPath)) -or ([string]::IsNullOrWhiteSpace($SshPublicKeyPath) -and -not [string]::IsNullOrWhiteSpace($SshPrivateKeyPath)))
        {
            Write-ScreenInfo -Type Warning -Message "Both SshPublicKeyPath and SshPrivateKeyPath need to be used to successfully remote to Linux VMs (Host Windows, Engine Hyper-V) and Windows VMs (Host Linux/WSL, Engine Azure)"
        }

        if ($AzureProperties)
        {
            $illegalKeys = Compare-Object -ReferenceObject $azurePropertiesValidKeys -DifferenceObject ($AzureProperties.Keys | Sort-Object -Unique) |
            Where-Object SideIndicator -eq '=>' |
            Select-Object -ExpandProperty InputObject

            if ($AzureProperties.ContainsKey('StorageSku') -and ($AzureProperties['StorageSku'] -notin (Get-LabConfigurationItem -Name AzureDiskSkus)))
            {
                throw "$($AzureProperties['StorageSku']) is not in $(Get-LabConfigurationItem -Name AzureDiskSkus)"
            }

            if ($illegalKeys)
            {
                throw "The key(s) '$($illegalKeys -join ', ')' are not supported in AzureProperties. Valid keys are '$($azurePropertiesValidKeys -join ', ')'"
            }
        }
        if ($HypervProperties)
        {
            $illegalKeys = Compare-Object -ReferenceObject $hypervPropertiesValidKeys -DifferenceObject ($HypervProperties.Keys | Sort-Object -Unique) |
            Where-Object SideIndicator -eq '=>' |
            Select-Object -ExpandProperty InputObject

            if ($illegalKeys)
            {
                throw "The key(s) '$($illegalKeys -join ', ')' are not supported in HypervProperties. Valid keys are '$($hypervPropertiesValidKeys -join ', ')'"
            }
        }

        if ($global:labNamePrefix)
        {
            $Name = "$global:labNamePrefix$Name" 
        }

        if ($null -eq $script:machines)
        {
            $errorMessage = "Create a new lab first using 'New-LabDefinition' before adding machines"
            Write-Error $errorMessage
            Write-LogFunctionExitWithError -Message $errorMessage
            return
        }

        if ($script:machines | Where-Object Name -eq $Name)
        {
            $errorMessage = "A machine with the name '$Name' does already exist"
            Write-Error $errorMessage
            Write-LogFunctionExitWithError -Message $errorMessage
            return
        }

        if ($script:machines | Where-Object IpAddress.IpAddress -eq $IpAddress)
        {
            $errorMessage = "A machine with the IP address '$IpAddress' does already exist"
            Write-Error $errorMessage
            Write-LogFunctionExitWithError -Message $errorMessage
            return
        }

        $machine = New-Object AutomatedLab.Machine
        if ($ReferenceDisk -and $script:lab.DefaultVirtualizationEngine -eq 'HyperV')
        {
            Write-ScreenInfo -Type Warning -Message "Usage of the ReferenceDisk parameter makes your lab essentially unsupportable. Don't be mad at us if we cannot reproduce your random issue if you bring your own images."
            $machine.ReferenceDiskPath = $ReferenceDisk
        }

        if ($ReferenceDisk -and $script:lab.DefaultVirtualizationEngine -ne 'HyperV')
        {
            Write-ScreenInfo -Type Warning -Message "Sorry, no custom reference disk allowed on $($script:lab.DefaultVirtualizationEngine). This parameter will be ignored."
        }

        if ($VmGeneration)
        {
            $machine.VmGeneration = $VmGeneration
        }

        $machine.Name = $Name
        $machine.FriendlyName = $ResourceName
        $machine.OrganizationalUnit = $OrganizationalUnit
        $script:machines.Add($machine)

        if ($SshPublicKeyPath -and -not (Test-Path -Path $SshPublicKeyPath))
        {
            throw "$SshPublicKeyPath does not exist. Rethink your decision."
        }
        elseif ($SshPublicKeyPath -and (Test-Path -Path $SshPublicKeyPath))
        {
            $machine.SshPublicKeyPath = $SshPublicKeyPath
            $machine.SshPublicKey = Get-Content -Raw -Path $SshPublicKeyPath
        }

        if ($SshPrivateKeyPath -and -not (Test-Path -Path $SshPrivateKeyPath))
        {
            throw "$SshPrivateKeyPath does not exist. Rethink your decision."
        }
        elseif ($SshPrivateKeyPath -and (Test-Path -Path $SshPrivateKeyPath))
        {
            $machine.SshPrivateKeyPath = $SshPrivateKeyPath
        }

        if ((Get-LabDefinition).DefaultVirtualizationEngine -and (-not $PSBoundParameters.ContainsKey('VirtualizationHost')))
        {
            $VirtualizationHost = (Get-LabDefinition).DefaultVirtualizationEngine
        }

        if ($VirtualizationHost -eq 'Azure')
        {
            $script:lab.AzureSettings.LoadBalancerPortCounter++
            $machine.LoadBalancerRdpPort = $script:lab.AzureSettings.LoadBalancerPortCounter
            $script:lab.AzureSettings.LoadBalancerPortCounter++
            $machine.LoadBalancerWinRmHttpPort = $script:lab.AzureSettings.LoadBalancerPortCounter
            $script:lab.AzureSettings.LoadBalancerPortCounter++
            $machine.LoadBalancerWinrmHttpsPort = $script:lab.AzureSettings.LoadBalancerPortCounter
            $script:lab.AzureSettings.LoadBalancerPortCounter++
            $machine.LoadBalancerSshPort = $script:lab.AzureSettings.LoadBalancerPortCounter
        }

        if ($InstallationUserCredential)
        {
            $installationUser = New-Object AutomatedLab.User($InstallationUserCredential.UserName, $InstallationUserCredential.GetNetworkCredential().Password)
        }
        else
        {
            if ((Get-LabDefinition).DefaultInstallationCredential)
            {
                $installationUser = New-Object AutomatedLab.User((Get-LabDefinition).DefaultInstallationCredential.UserName, (Get-LabDefinition).DefaultInstallationCredential.Password)
            }
            else
            {
                switch ($VirtualizationHost)
                {
                    'HyperV'
                    {
                        $installationUser = New-Object AutomatedLab.User('Administrator', 'Somepass1') 
                    }
                    'Azure'
                    {
                        $installationUser = New-Object AutomatedLab.User('Install', 'Somepass1') 
                    }
                    Default
                    {
                        $installationUser = New-Object AutomatedLab.User('Administrator', 'Somepass1') 
                    }
                }
            }
        }
        $machine.InstallationUser = $installationUser

        $machine.IsDomainJoined = $false

        if ($PSBoundParameters.ContainsKey('DefaultDomain') -and $DefaultDomain)
        {
            if (-not (Get-LabDomainDefinition))
            {
                if ($VirtualizationHost -eq 'Azure')
                {
                    Add-LabDomainDefinition -Name 'contoso.com' -AdminUser Install -AdminPassword 'Somepass1'
                }
                else
                {
                    Add-LabDomainDefinition -Name 'contoso.com' -AdminUser Administrator -AdminPassword 'Somepass1'
                }
            }

            $DomainName = (Get-LabDomainDefinition)[0].Name
        }

        if ($DomainName -or ($Roles -and $Roles.Name -match 'DC$'))
        {
            $machine.IsDomainJoined = $true
            if ($script:Lab.DefaultVirtualizationEngine -eq 'HyperV' -and (-not $Roles -or $Roles -and $Roles.Name -notmatch 'DC$'))
            {
                $machine.HasDomainJoined = $true # In order to use the correct credentials upon connecting via SSH. Hyper-V VMs join during first boot
            }

            if ($Roles.Name -eq 'RootDC' -or $Roles.Name -eq 'DC')
            {
                if (-not $DomainName)
                {
                    if (-not (Get-LabDomainDefinition))
                    {
                        $DomainName = 'contoso.com'
                        switch ($VirtualizationHost)
                        {
                            'Azure'
                            {
                                Add-LabDomainDefinition -Name $DomainName -AdminUser Install -AdminPassword Somepass1 
                            }
                            'HyperV'
                            {
                                Add-LabDomainDefinition -Name $DomainName -AdminUser Administrator -AdminPassword Somepass1 
                            }
                            'VMware'
                            {
                                Add-LabDomainDefinition -Name $DomainName -AdminUser Administrator -AdminPassword Somepass1 
                            }
                        }
                    }
                    else
                    {
                        throw 'Domain name not specified for Root Domain Controller'
                    }
                }
            }
            elseif ('FirstChildDC' -in $Roles.Name)
            {
                $role = $Roles | Where-Object Name -eq FirstChildDC
                $containsProperties = [boolean]$role.Properties
                if ($containsProperties)
                {
                    $parentDomainInProperties = $role.Properties.ParentDomain
                    $newDomainInProperties = $role.Properties.NewDomain

                    Write-PSFMessage -Message "Machine contains custom properties for FirstChildDC: 'ParentDomain'='$parentDomainInProperties', 'NewDomain'='$newDomainInProperties'"
                }

                if ((-not $containsProperties) -and (-not $DomainName))
                {
                    Write-PSFMessage -Message 'Nothing specified (no DomainName nor ANY Properties). Giving up'

                    throw 'Domain name not specified for Child Domain Controller'
                }

                if ((-not $DomainName) -and ((-not $parentDomainInProperties -or (-not $newDomainInProperties))))
                {
                    Write-PSFMessage -Message 'No DomainName or Properties for ParentName and NewDomain specified. Giving up'

                    throw 'Domain name not specified for Child Domain Controller'
                }

                if ($containsProperties -and $parentDomainInProperties -and $newDomainInProperties -and (-not $DomainName))
                {
                    Write-PSFMessage -Message 'Properties specified but DomainName is not. Then populate DomainName based on Properties'

                    $DomainName = "$($role.Properties.NewDomain).$($role.Properties.ParentDomain)"
                    Write-PSFMessage -Message "Machine contains custom properties for FirstChildDC but DomainName parameter is not specified. Setting now to '$DomainName'"
                }
                elseif (((-not $containsProperties) -or ($containsProperties -and (-not $parentDomainInProperties) -and (-not $newDomainInProperties))) -and $DomainName)
                {
                    $newDomainName = $DomainName.Substring(0, $DomainName.IndexOf('.'))
                    $parentDomainName = $DomainName.Substring($DomainName.IndexOf('.') + 1)

                    Write-PSFMessage -Message 'No Properties specified (or properties for ParentName and NewDomain omitted) but DomainName parameter is specified. Calculating/updating ParentDomain and NewDomain properties'
                    if (-not $containsProperties)
                    {
                        $role.Properties = @{ 'NewDomain' = $newDomainName }
                        $role.Properties.Add('ParentDomain', $parentDomainName)
                    }
                    else
                    {
                        if (-not $role.Properties.ContainsKey('NewDomain'))
                        {
                            $role.Properties.Add('NewDomain', $newDomainName)
                        }

                        if (-not $role.Properties.ContainsKey('ParentDomain'))
                        {
                            $role.Properties.Add('ParentDomain', $parentDomainName)
                        }
                    }
                    $parentDomainInProperties = $role.Properties.ParentDomain
                    $newDomainInProperties = $role.Properties.NewDomain
                    Write-PSFMessage -Message "ParentDomain now set to '$parentDomainInProperties'"
                    Write-PSFMessage -Message "NewDomain now set to '$newDomainInProperties'"
                }
            }

            if (-not (Get-LabDomainDefinition | Where-Object Name -eq $DomainName))
            {
                if ($VirtualizationHost -eq 'Azure')
                {
                    Add-LabDomainDefinition -Name $DomainName -AdminUser Install -AdminPassword 'Somepass1'
                }
                else
                {
                    Add-LabDomainDefinition -Name $DomainName -AdminUser Administrator -AdminPassword 'Somepass1'
                }
            }
            $machine.DomainName = $DomainName
        }

        if (-not $OperatingSystem.Version)
        {
            if ($OperatingSystemVersion)
            {
                $OperatingSystem.Version = $OperatingSystemVersion
            }
            else
            {
                throw "Could not identify the version of operating system '$($OperatingSystem.OperatingSystemName)' assigned to machine '$Name'. The version is required to continue."
            }
        }

        switch ($OperatingSystem.Version.ToString(2))
        {
            '6.0'
            {
                $level = 'Win2008' 
            }
            '6.1'
            {
                $level = 'Win2008R2' 
            }
            '6.2'
            {
                $level = 'Win2012' 
            }
            '6.3'
            {
                $level = 'Win2012R2' 
            }
            '6.4'
            {
                $level = 'WinThreshold' 
            }
            '10.0'
            {
                $level = 'WinThreshold' 
            }
        }

        $role = $roles | Where-Object Name -in ('RootDC', 'FirstChildDC', 'DC')
        if ($role)
        {
            if ($role.Properties)
            {
                if ($role.Name -eq 'RootDC')
                {
                    if (-not $role.Properties.ContainsKey('ForestFunctionalLevel'))
                    {
                        $role.Properties.Add('ForestFunctionalLevel', $level)
                    }
                }

                if ($role.Name -eq 'RootDC' -or $role.Name -eq 'FirstChildDC')
                {
                    if (-not $role.Properties.ContainsKey('DomainFunctionalLevel'))
                    {
                        $role.Properties.Add('DomainFunctionalLevel', $level)
                    }
                }
            }
            else
            {
                if ($role.Name -eq 'RootDC')
                {
                    $role.Properties = @{'ForestFunctionalLevel' = $level }
                    $role.Properties.Add('DomainFunctionalLevel', $level)
                }
                elseif ($role.Name -eq 'FirstChildDC')
                {
                    $role.Properties = @{'DomainFunctionalLevel' = $level }
                }
            }
        }

        #Virtual network detection and automatic creation
        if ($VirtualizationHost -eq 'Azure')
        {
            if (-not (Get-LabVirtualNetworkDefinition))
            {
                #No virtual networks has been specified

                Write-ScreenInfo -Message 'No virtual networks specified. Creating a network automatically' -Type Warning
                if (-not ($Global:existingAzureNetworks))
                {
                    $Global:existingAzureNetworks = Get-AzVirtualNetwork
                }

                #Virtual network name will be same as lab name
                $autoNetworkName = (Get-LabDefinition).Name

                #Priority 1. Check for existence of an Azure virtual network with same name as network name
                $existingNetwork = $Global:existingAzureNetworks | Where-Object { $_.Name -eq $autoNetworkName }
                if ($existingNetwork)
                {
                    Write-PSFMessage -Message 'Virtual switch already exists with same name as lab being deployed. Trying to re-use.'
                    $addressSpace = $existingNetwork.AddressSpace.AddressPrefixes

                    Write-ScreenInfo -Message "Creating virtual network '$autoNetworkName' with address spacee '$addressSpace'" -Type Warning
                    Add-LabVirtualNetworkDefinition -Name $autoNetworkName -AddressSpace $addressSpace[0]

                    #First automatically assigned IP address will be following+1
                    $addressSpaceIpAddress = "$($addressSpace.Split('/')[0].Split('.')[0..2] -Join '.').5"
                    $script:autoIPAddress = [AutomatedLab.IPAddress]$addressSpaceIpAddress

                    $notDone = $false
                }
                else
                {
                    Write-PSFMessage -Message 'No Azure virtual network found with same name as network name. Attempting to find unused network in the range 192.168.2.x-192.168.255.x'

                    $networkFound = $false
                    [int]$octet = 1
                    do
                    {
                        $octet++

                        $azureInUse = $false
                        foreach ($azureNetwork in $Global:existingAzureNetworks.AddressSpace.AddressPrefixes)
                        {
                            if (Test-IpInSameSameNetwork -Ip1 "192.168.$octet.0/24" -Ip2 $azureNetwork)
                            {
                                $azureInUse = $true
                            }
                        }
                        if ($azureInUse)
                        {
                            Write-PSFMessage -Message "Network '192.168.$octet.0/24' is in use by an existing Azure virtual network"
                            continue
                        }

                        $networkFound = $true
                    }
                    until ($networkFound -or $octet -ge 255)

                    if ($networkFound)
                    {
                        Write-ScreenInfo "Creating virtual network with name '$autoNetworkName' and address space '192.168.$octet.1/24'" -Type Warning
                        Add-LabVirtualNetworkDefinition -Name $autoNetworkName  -AddressSpace "192.168.$octet.1/24"
                    }
                    else
                    {
                        throw 'Virtual network could not be created. Please create virtual network manually by calling Add-LabVirtualNetworkDefinition (after calling New-LabDefinition)'
                    }

                    #First automatically asigned IP address will be following+1
                    $script:autoIPAddress = ([AutomatedLab.IPAddress]("192.168.$octet.5")).AddressAsString
                }

                #throw 'No virtual network is defined. Please call Add-LabVirtualNetworkDefinition before adding machines but after calling New-LabDefinition'
            }
        }
        elseif ($VirtualizationHost -eq 'HyperV')
        {
            Write-PSFMessage -Message 'Detect if a virtual switch already exists with same name as lab being deployed. If so, use this switch for defining network name and address space.'

            #this takes a lot of time hence it should be called only once in a deployment
            if (-not $script:existingHyperVVirtualSwitches)
            {
                $script:existingHyperVVirtualSwitches = Get-LabVirtualNetwork
            }

            $networkDefinitions = Get-LabVirtualNetworkDefinition

            if (-not $networkDefinitions)
            {
                #No virtual networks has been specified

                Write-ScreenInfo -Message 'No virtual networks specified. Creating a network automatically' -Type Warning

                #Virtual network name will be same as lab name
                $autoNetworkName = (Get-LabDefinition).Name

                #Priority 1. Check for existence of Hyper-V virtual switch with same name as network name
                $existingNetwork = $existingHyperVVirtualSwitches | Where-Object Name -eq $autoNetworkName
                if ($existingNetwork)
                {
                    Write-PSFMessage -Message 'Virtual switch already exists with same name as lab being deployed. Trying to re-use.'

                    Write-ScreenInfo -Message "Using virtual network '$autoNetworkName' with address space '$addressSpace'" -Type Info
                    Add-LabVirtualNetworkDefinition -Name $autoNetworkName -AddressSpace $existingNetwork.AddressSpace
                }
                else
                {
                    Write-PSFMessage -Message 'No virtual switch found with same name as network name. Attempting to find unused network'

                    $addressSpace = Get-LabAvailableAddresseSpace

                    if ($addressSpace)
                    {
                        Write-ScreenInfo "Creating network '$autoNetworkName' with address space '$addressSpace'" -Type Warning
                        Add-LabVirtualNetworkDefinition -Name $autoNetworkName  -AddressSpace $addressSpace
                    }
                    else
                    {
                        throw 'Virtual network could not be created. Please create virtual network manually by calling Add-LabVirtualNetworkDefinition (after calling New-LabDefinition)'
                    }
                }
            }
            else
            {
                Write-PSFMessage -Message 'One or more virtual network(s) has been specified.'

                #Using first specified virtual network '$($networkDefinitions[0])' with address space '$($networkDefinitions[0].AddressSpace)'."

                <#
                        if ($script:autoIPAddress)
                        {
                        #Network already created and IP range already found
                        Write-PSFMessage -Message 'Network already created and IP range already found'
                        }
                        else
                        {
                #>

                foreach ($networkDefinition in $networkDefinitions)
                {
                    #check for an virtual switch having already the name of the new network switch
                    $existingNetwork = $existingHyperVVirtualSwitches | Where-Object Name -eq $networkDefinition.ResourceName

                    #does the current network definition has an address space assigned
                    if ($networkDefinition.AddressSpace)
                    {
                        Write-PSFMessage -Message "Virtual network '$($networkDefinition.ResourceName)' specified with address space '$($networkDefinition.AddressSpace)'"

                        #then check if the existing network has the same address space as the new one and throw an exception if not
                        if ($existingNetwork)
                        {
                            if ($existingNetwork.SwitchType -eq 'External')
                            {
                                #Different address spaces for different labs reusing an existing External virtual switch is permitted, however this requires knowledge and support
                                # for switching / routing fabrics external to AL and the host. Note to the screen this is an advanced configuration.
                                if ($networkDefinition.AddressSpace -ne $existingNetwork.AddressSpace)
                                {
                                    Write-ScreenInfo "Address space defined '$($networkDefinition.AddressSpace)' for network '$networkDefinition' is different from the address space '$($existingNetwork.AddressSpace)' used by currently existing Hyper-V switch with same name." -Type Warning
                                    Write-ScreenInfo "This is an advanced configuration, ensure external switching and routing is configured correctly" -Type Warning
                                    Write-PSFMessage -Message 'Existing External Hyper-V virtual switch found with different address space. This is an allowed advanced configuration'
                                }
                                else
                                {
                                    Write-PSFMessage -Message 'Existing External Hyper-V virtual switch found with same name and address space as first virtual network specified. Using this.'
                                }
                            }
                            else
                            {
                                if ($networkDefinition.AddressSpace -ne $existingNetwork.AddressSpace)
                                {
                                    throw "Address space defined '$($networkDefinition.AddressSpace)' for network '$networkDefinition' is different from the address space '$($existingNetwork.AddressSpace)' used by currently existing Hyper-V switch with same name. Cannot continue."
                                }
                            }
                        }
                        else
                        {
                            #if the network does not already exist, verify if the address space if not already assigned
                            $otherHypervSwitch = $existingHyperVVirtualSwitches | Where-Object AddressSpace -eq $networkDefinition.AddressSpace
                            if ($otherHypervSwitch)
                            {
                                throw "Another Hyper-V virtual switch '$($otherHypervSwitch.Name)' is using address space specified in this lab ($($networkDefinition.AddressSpace)). Cannot continue."
                            }

                            #and also verify that the new address space is not overlapping with an exsiting one
                            $otherHypervSwitch = $existingHyperVVirtualSwitches |
                            Where-Object { $_.AddressSpace } |
                            Where-Object { [AutomatedLab.IPNetwork]::Overlap($_.AddressSpace, $networkDefinition.AddressSpace) } |
                            Select-Object -First 1

                            if ($otherHypervSwitch)
                            {
                                throw "The Hyper-V virtual switch '$($otherHypervSwitch.Name)' is using an address space ($($otherHypervSwitch.AddressSpace)) that overlaps with the specified one in this lab ($($networkDefinition.AddressSpace)). Cannot continue."
                            }

                            Write-PSFMessage -Message 'Address space specified is valid'
                        }
                    }
                    else
                    {
                        if ($networkDefinition.SwitchType -eq 'External')
                        {
                            Write-PSFMessage 'External network interfaces will not get automatic IP addresses'
                            continue
                        }

                        Write-PSFMessage -Message "Virtual network '$networkDefinition' specified but without address space specified"

                        if ($existingNetwork)
                        {
                            Write-PSFMessage -Message "Existing Hyper-V virtual switch found with same name as first virtual network name. Using it with address space '$($existingNetwork.AddressSpace)'."
                            $networkDefinition.AddressSpace = $existingNetwork.AddressSpace
                        }
                        else
                        {
                            Write-PSFMessage -Message 'No Hyper-V virtual switch found with same name as lab name. Attempting to find unused network.'

                            $addressSpace = Get-LabAvailableAddresseSpace

                            if ($addressSpace)
                            {
                                Write-ScreenInfo "Using network '$networkDefinition' with address space '$addressSpace'" -Type Warning
                                $networkDefinition.AddressSpace = $addressSpace
                            }
                            else
                            {
                                throw 'Virtual network could not be used. Please create virtual network manually by calling Add-LabVirtualNetworkDefinition (after calling New-LabDefinition)'
                            }
                        }
                    }
                }
            }
        }

        if ($Network)
        {
            $networkDefinition = Get-LabVirtualNetworkDefinition -Name $network
            if (-not $networkDefinition)
            {
                throw "A virtual network definition with the name '$Network' could not be found. To get a list of network definitions, use 'Get-LabVirtualNetworkDefinition'"
            }

            if ($networkDefinition.SwitchType -eq 'External' -and -not $networkDefinition.AddressSpace -and -not $IpAddress)
            {
                $useDhcp = $true
            }

            $NetworkAdapter = New-LabNetworkAdapterDefinition -VirtualSwitch $networkDefinition.Name -UseDhcp:$useDhcp
        }
        elseif (-not $NetworkAdapter)
        {
            if ((Get-LabVirtualNetworkDefinition).Count -eq 1)
            {
                $networkDefinition = Get-LabVirtualNetworkDefinition

                $NetworkAdapter = New-LabNetworkAdapterDefinition -VirtualSwitch $networkDefinition.Name

            }
            else
            {
                throw "Network cannot be determined for machine '$machine'. Either no networks is defined or more than one network is defined while network is not specified when calling this function"
            }
        }

        $machine.HostType = $VirtualizationHost

        foreach ($adapter in $NetworkAdapter)
        {
            $adapterVirtualNetwork = Get-LabVirtualNetworkDefinition -Name $adapter.VirtualSwitch

            #if there is no IPV4 address defined on the adapter
            if (-not $adapter.IpV4Address)
            {
                #if there is also no IP address defined on the machine and the adapter is not set to DHCP and the network the adapter is connected to does not know about an address space we cannot continue
                if (-not $IpAddress -and -not $adapter.UseDhcp -and -not $adapterVirtualNetwork.AddressSpace)
                {
                    throw "The virtual network '$adapterVirtualNetwork' defined on machine '$machine' does not have an IP address assigned and is not set to DHCP"
                }
                elseif ($IpAddress)
                {
                    if ($AzureProperties.SubnetName -and $adapterVirtualNetwork.Subnets.Count -gt 0)
                    {
                        $chosenSubnet = $adapterVirtualNetwork.Subnets | Where-Object Name -EQ $AzureProperties.SubnetName
                        if (-not $chosenSubnet)
                        {
                            throw ('No fitting subnet available. Subnet {0} could not be found in the list of available subnets {1}' -f $AzureProperties.SubnetName, ($adapterVirtualNetwork.Subnets.Name -join ','))
                        }

                        $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($IpAddress, $chosenSubnet.AddressSpace.Netmask))
                    }
                    elseif ($VirtualizationHost -eq 'Azure' -and $adapterVirtualNetwork.Subnets.Count -gt 0 -and -not $AzureProperties.SubnetName)
                    {
                        # No default subnet and no name selected. Chose fitting subnet.
                        $chosenSubnet = $adapterVirtualNetwork.Subnets | Where-Object { $IpAddress -in (Get-NetworkRange -IPAddress $_.AddressSpace.IpAddress -SubnetMask $_.AddressSpace.Netmask) }
                        if (-not $chosenSubnet)
                        {
                            throw ('No fitting subnet available. No subnet was found with a valid address range. {0} was not in the range of these subnets: ' -f $IpAddress, ($adapterVirtualNetwork.Subnets.Name -join ','))
                        }

                        $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($IpAddress, $chosenSubnet.AddressSpace.Netmask))
                    }
                    else
                    {
                        $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($IpAddress, $adapterVirtualNetwork.AddressSpace.Netmask))
                    }
                }
                elseif (-not $adapter.UseDhcp)
                {
                    $ip = $adapterVirtualNetwork.NextIpAddress()

                    if ($AzureProperties.SubnetName -and $adapterVirtualNetwork.Subnets.Count -gt 0)
                    {
                        $chosenSubnet = $adapterVirtualNetwork.Subnets | Where-Object Name -EQ $AzureProperties.SubnetName
                        if (-not $chosenSubnet)
                        {
                            throw ('No fitting subnet available. Subnet {0} could not be found in the list of available subnets {1}' -f $AzureProperties.SubnetName, ($adapterVirtualNetwork.Subnets.Name -join ','))
                        }

                        $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($ip, $chosenSubnet.AddressSpace.Netmask))
                    }
                    elseif ($VirtualizationHost -eq 'Azure' -and $adapterVirtualNetwork.Subnets.Count -gt 0 -and -not $AzureProperties.SubnetName)
                    {
                        # No default subnet and no name selected. Chose fitting subnet.
                        $chosenSubnet = $adapterVirtualNetwork.Subnets | Where-Object { $ip -in (Get-NetworkRange -IPAddress $_.AddressSpace.IpAddress -SubnetMask $_.AddressSpace.Netmask) }
                        if (-not $chosenSubnet)
                        {
                            throw ('No fitting subnet available. No subnet was found with a valid address range. {0} was not in the range of these subnets: ' -f $IpAddress, ($adapterVirtualNetwork.Subnets.Name -join ','))
                        }

                        $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($ip, $chosenSubnet.AddressSpace.Netmask))
                    }
                    else
                    {
                        $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($ip, $adapterVirtualNetwork.AddressSpace.Netmask))
                    }
                }
            }

            if ($DnsServer1)
            {
                $adapter.Ipv4DnsServers.Add($DnsServer1) 
            }
            if ($DnsServer2)
            {
                $adapter.Ipv4DnsServers.Add($DnsServer2) 
            }

            #if the virtual network is not external, the machine is not an Azure one, is domain joined and there is no DNS server configured
            if ($adapter.VirtualSwitch.SwitchType -ne 'External' -and
                $machine.HostType -ne 'Azure' -and
                #$machine.IsDomainJoined -and
                -not $adapter.UseDhcp -and
                -not ($DnsServer1 -or $DnsServer2
                ))
            {
                $adapter.Ipv4DnsServers.Add('0.0.0.0')
            }

            if ($Gateway)
            {
                $adapter.Ipv4Gateway.Add($Gateway) 
            }

            $machine.NetworkAdapters.Add($adapter)
        }

        Repair-LabDuplicateIpAddresses

        if ($processors -eq 0)
        {
            $processors = 1
            if (-not $script:processors)
            {
                $script:processors = if ($IsLinux -or $IsMacOs)
                {
                    $coreInf = Get-Content /proc/cpuinfo | Select-String 'siblings\s+:\s+\d+' | Select-Object -Unique
                    [int]($coreInf -replace 'siblings\s+:\s+')
                }
                else
                {
                    (Get-CimInstance -Namespace Root\CIMv2 -Class win32_processor | Measure-Object NumberOfLogicalProcessors -Sum).Sum
                }
            }
            if ($script:processors -ge 2)
            {
                $machine.Processors = 2
            }
        }
        else
        {
            $machine.Processors = $Processors
        }


        if ($PSBoundParameters.ContainsKey('Memory'))
        {
            $machine.Memory = $Memory
        }
        else
        {
            $machine.Memory = 1

            #Memory weight based on role of machine
            $machine.Memory = 1
            foreach ($role in $Roles)
            {
                if ((Get-LabConfigurationItem -Name "MemoryWeight_$($role.Name)") -gt $machine.Memory)
                {
                    $machine.Memory = Get-LabConfigurationItem -Name "MemoryWeight_$($role.Name)"
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('MinMemory'))
        {
            $machine.MinMemory = $MinMemory
        }
        if ($PSBoundParameters.ContainsKey('MaxMemory'))
        {
            $machine.MaxMemory = $MaxMemory
        }

        $machine.EnableWindowsFirewall = $EnableWindowsFirewall

        $machine.AutoLogonDomainName = $AutoLogonDomainName
        $machine.AutoLogonUserName = $AutoLogonUserName
        $machine.AutoLogonPassword = $AutoLogonPassword

        if ($machine.HostType -eq 'HyperV')
        {
            if ($RhelPackage)
            {
                $machine.LinuxPackageGroup = $RhelPackage
            }
            if ($SusePackage)
            {
                $machine.LinuxPackageGroup = $SusePackage
            }
            if ($UbuntuPackage)
            {
                $machine.LinuxPackageGroup = $UbuntuPackage
            }

            if ($OperatingSystem.IsoPath)
            {
                $os = $OperatingSystem
            }

            if (-not $OperatingSystem.IsoPath -and $OperatingSystemVersion)
            {
                $os = Get-LabAvailableOperatingSystem -NoDisplay | Where-Object { $_.OperatingSystemName -eq $OperatingSystem -and $_.Version -eq $OperatingSystemVersion }
            }
            elseif (-not $OperatingSystem.IsoPath -and -not $OperatingSystemVersion)
            {
                $os = Get-LabAvailableOperatingSystem -NoDisplay | Where-Object OperatingSystemName -eq $OperatingSystem
                if ($os.Count -gt 1)
                {
                    $os = $os | Group-Object -Property Version | Sort-Object -Property Name -Descending | Select-Object -First 1 | Select-Object -ExpandProperty Group
                    Write-ScreenInfo "The operating system '$OperatingSystem' is available multiple times. Choosing the one with the highest version ($($os[0].Version))" -Type Warning
                }

                if ($os.Count -gt 1)
                {
                    $os = $os | Sort-Object -Property { (Get-Item -Path $_.IsoPath).LastWriteTime } -Descending | Select-Object -First 1
                    Write-ScreenInfo "The operating system '$OperatingSystem' with the same version is available on multiple images. Choosing the one with the highest LastWriteTime to honor updated images ($((Get-Item -Path $os.IsoPath).LastWriteTime))" -Type Warning
                }
            }

            if (-not $os)
            {
                if ($OperatingSystemVersion)
                {
                    throw "The operating system '$OperatingSystem' for machine '$Name' with version '$OperatingSystemVersion' could not be found in the available operating systems. Call 'Get-LabAvailableOperatingSystem' to get a list of operating systems added to the lab."
                }
                else
                {
                    throw "The operating system '$OperatingSystem' for machine '$Name' could not be found in the available operating systems. Call 'Get-LabAvailableOperatingSystem' to get a list of operating systems added to the lab."
                }
            }
            $machine.OperatingSystem = $os
        }
        elseif ($machine.HostType -eq 'Azure')
        {
            $machine.OperatingSystem = $OperatingSystem
        }
        elseif ($machine.HostType -eq 'VMWare')
        {
            $machine.OperatingSystem = $OperatingSystem
        }

        if ($script:lab.DefaultVirtualizationEngine -eq 'HyperV' -and $InitialDscConfigurationMofPath -and -not (Test-Path $InitialDscConfigurationMofPath))
        {
            throw "$InitialDscConfigurationMofPath does not exist. Make sure it exists and is a mof"
        }
        elseif ($script:lab.DefaultVirtualizationEngine -eq 'HyperV' -and $InitialDscConfigurationMofPath -and (Test-Path $InitialDscConfigurationMofPath))
        {
            if ($Machine.OperatingSystem.Version -lt 10.0) { Write-ScreenInfo -Type Warning -Message "Integrated PowerShell version of $Machine is less than 5. Please keep in mind that DSC has been introduced in PS4 and some resources may not work with versions older than PS5."}
            $Machine.InitialDscConfigurationMofPath = $InitialDscConfigurationMofPath
        }

        if ($script:lab.DefaultVirtualizationEngine -eq 'HyperV' -and $InitialDscLcmConfigurationMofPath -and -not (Test-Path $InitialDscLcmConfigurationMofPath))
        {
            throw "$InitialDscLcmConfigurationMofPath does not exist. Make sure it exists and is a meta.mof"
        }
        elseif ($script:lab.DefaultVirtualizationEngine -eq 'HyperV' -and $InitialDscLcmConfigurationMofPath -and (Test-Path $InitialDscLcmConfigurationMofPath))
        {
            if ($Machine.OperatingSystem.Version -lt 10.0) { Write-ScreenInfo -Type Warning -Message "Integrated PowerShell version of $Machine is less than 5. Please keep in mind that DSC has been introduced in PS4 and some resources may not work with versions older than PS5."}
            $Machine.InitialDscLcmConfigurationMofPath = $InitialDscLcmConfigurationMofPath
        }

        if (-not $TimeZone)
        {
            $TimeZone = (Get-TimeZone).StandardName
        }
        $machine.Timezone = $TimeZone

        if (-not $UserLocale)
        {
            $UserLocale = (Get-Culture).Name -replace '-POSIX'
        }
        $machine.UserLocale = $UserLocale

        $machine.Roles = $Roles
        $machine.PostInstallationActivity = $PostInstallationActivity
        $machine.PreInstallationActivity = $PreInstallationActivity

        if (($KmsLookupDomain -or $KmsServerName -or $ActivateWindows.IsPresent) -and $null -eq $Notes)
        {
            $Notes = @{}
        }

        if ($KmsLookupDomain)
        {
            $Notes['KmsLookupDomain'] = $KmsLookupDomain
        }
        elseif ($KmsServerName)
        {
            $Notes['KmsServerName'] = $KmsServerName
            $Notes['KmsPort'] = $KmsPort -as [string]
        }

        if ($ActivateWindows.IsPresent)
        {
            $Notes['ActivateWindows'] = '1'
        }

        if ($HypervProperties)
        {
            $machine.HypervProperties = $HypervProperties
        }

        if ($AzureProperties)
        {
            if ($AzureRoleSize)
            {
                $AzureProperties['RoleSize'] = $AzureRoleSize # Adding keys to properties later did silently fail
            }

            $machine.AzureProperties = $AzureProperties
        }

        if ($AzureRoleSize -and -not $AzureProperties)
        {
            $machine.AzureProperties = @{ RoleSize = $AzureRoleSize }
        }

        $machine.ToolsPath = $ToolsPath.Replace('<machinename>', $machine.Name)

        $machine.ToolsPathDestination = $ToolsPathDestination

        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Disk
        $machine.Disks = New-Object $type

        if ($DiskName)
        {
            foreach ($disk in $DiskName)
            {
                $labDisk = $script:disks | Where-Object Name -eq $disk
                if (-not $labDisk)
                {
                    throw "The disk with the name '$disk' has not yet been added to the lab. Do this first using the cmdlet 'Add-LabDiskDefinition'"
                }
                $machine.Disks.Add($labDisk)
            }
        }

        $machine.SkipDeployment = $SkipDeployment
    }

    end
    {
        if ($Notes)
        {
            $machine.Notes = $Notes
        }

        Write-ScreenInfo -Message 'Done' -TaskEnd

        if ($PassThru)
        {
            $machine
        }

        Write-LogFunctionExit
    }
}
