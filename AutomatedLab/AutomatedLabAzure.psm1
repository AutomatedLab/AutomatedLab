function Test-LabAzureModuleAvailability
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param 
    (
        [switch]
        $AzureStack
    )

    [hashtable[]] $modules = if ($AzureStack.IsPresent) { Get-LabConfigurationItem -Name RequiredAzStackModules } else { Get-LabConfigurationItem -Name RequiredAzModules }
    [hashtable[]] $modulesMissing = @()

    foreach ($module in $modules)
    {
        $param = @{
            Name  = $module.Name
            Force = $true
        }

        $isPresent = if ($module.MinimumVersion)
        {
            Get-Module -ListAvailable -Name $module.Name | Where-Object Version -ge $module.MinimumVersion
            $param.MinimumVersion = $module.MinimumVersion
        }
        elseif ($module.RequiredVersion)
        {
            Get-Module -ListAvailable -Name $module.Name | Where-Object Version -eq $module.RequiredVersion
            $param.RequiredVersion = $module.RequiredVersion
        }
        
        if ($isPresent)
        {
            Write-PSFMessage -Message "$($module.Name) found"
            Import-Module @param
            continue
        }

        Write-PSFMessage -Message "$($module.Name) missing"
        $modulesMissing += $module
    }
    
    if ($modulesMissing.Count -gt 0)
    {
        $missingString = $modulesMissing.ForEach({ "$($_.Name), Minimum: $($_.MinimumVersion) or required: $($_.RequiredVersion)" })
        Write-PSFMessage -Level Error -Message "Missing Az modules: $missingString"
    }

    return ($modulesMissing.Count -eq 0)
}

function Install-LabAzureRequiredModule
{
    [CmdletBinding()]
    param
    (
        [string]
        $Repository = 'PSGallery',

        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]
        $Scope = 'CurrentUser',

        [switch]
        $AzureStack
    )

    [hashtable[]] $modules = if ($AzureStack.IsPresent) { Get-LabConfigurationItem -Name RequiredAzStackModules } else { Get-LabConfigurationItem -Name RequiredAzModules }
    foreach ($module in $modules)
    {
        $isPresent = if ($module.MinimumVersion)
        {
            Get-Module -ListAvailable -Name $module.Name | Where-Object Version -ge $module.MinimumVersion
        }
        elseif ($module.RequiredVersion)
        {
            Get-Module -ListAvailable -Name $module.Name | Where-Object Version -eq $module.RequiredVersion
        }
        
        if ($isPresent)
        {
            Write-PSFMessage -Message "$($module.Name) already present"
            continue
        }

        Install-Module @module -Repository $Repository -Scope $Scope -Force
    }
}

function Update-LabAzureSettings
{
    [CmdletBinding()]
    param ( )
    if ((Get-PSCallStack).Command -contains 'Import-Lab')
    {
        $Script:lab = Get-Lab
    }
    elseif ((Get-PSCallStack).Command -contains 'Add-LabAzureSubscription')
    {
        $Script:lab = Get-LabDefinition
        if (-not $Script:lab)
        {
            $Script:lab = Get-Lab
        }
    }
    else
    {
        $Script:lab = Get-Lab -ErrorAction SilentlyContinue
    }

    if (-not $Script:lab)
    {
        $Script:lab = Get-LabDefinition
    }

    if (-not $Script:lab)
    {
        throw 'No Lab or Lab Definition available'
    }
}

function Add-LabAzureSubscription
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(ParameterSetName = 'ByName')]
        [string]$SubscriptionName,

        [Parameter(ParameterSetName = 'ById')]
        [guid]$SubscriptionId,

        [string]
        $Environment,

        [string]$DefaultLocationName,

        [ObsoleteAttribute()]
        [string]$DefaultStorageAccountName,

        [string]$DefaultResourceGroupName,

        [timespan]
        $AutoShutdownTime,

        [string]
        $AutoShutdownTimeZone,

        [switch]$PassThru,

        [switch]
        $AllowBastionHost,

        [switch]
        $AzureStack
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry
    Update-LabAzureSettings

    if (-not $script:lab)
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabDefaultOperatingSystem.'
    }

    $null = Test-LabAzureModuleAvailability -AzureStack:$($AzureStack.IsPresent) -ErrorAction Stop

    Write-ScreenInfo -Message 'Adding Azure subscription data' -Type Info -TaskStart

    if ($Environment -and -not (Get-AzEnvironment -Name $Environment -ErrorAction SilentlyContinue))
    {
        throw "Azure environment $Environment cannot be found. Cannot continue. Please use Add-AzEnvironment before trying that again."
    }

    # Try to access Azure RM cmdlets. If credentials are expired, an exception will be raised
    if (-not (Get-AzContext) -or ($Environment -and (Get-AzContext).Environment.Name -ne $Environment))
    {
        Write-ScreenInfo -Message "No Azure context available or environment mismatch. Please login to your Azure account in the next step."
        $param = @{
            UseDeviceAuthentication = $true
            ErrorAction = 'SilentlyContinue' 
            WarningAction = 'Continue'
        }

        if ($Environment)
        {
            $param.Environment = $Environment
        }

        $null = Connect-AzAccount @param
    }

    # Select the proper subscription before saving the profile
    if ($SubscriptionName)
    {
        [void](Set-AzContext -Subscription $SubscriptionName -ErrorAction SilentlyContinue)
    }
    elseif ($SubscriptionId)
    {
        [void](Set-AzContext -Subscription $SubscriptionId -ErrorAction SilentlyContinue)
    }

    $AzureRmProfile = Get-AzContext
    if (-not $AzureRmProfile)
    {
        throw 'Cannot continue without a valid Azure connection.'
    }

    Update-LabAzureSettings
    if (-not $script:lab.AzureSettings)
    {
        $script:lab.AzureSettings = New-Object AutomatedLab.AzureSettings
    }

    if ($Environment)
    {
        $script:lab.AzureSettings.Environment = $Environment
    }

    $script:lab.AzureSettings.DefaultRoleSize = Get-LabConfigurationItem -Name DefaultAzureRoleSize
    $script:lab.AzureSettings.AllowBastionHost = $AllowBastionHost.IsPresent
    $script:lab.AzureSettings.IsAzureStack = $AzureStack.IsPresent

    if ($AutoShutdownTime -and -not $AzureStack.IsPresent)
    {
        if (-not $AutoShutdownTimeZone)
        {
            $AutoShutdownTimeZone = Get-TimeZone
        }

        $script:lab.AzureSettings.AutoShutdownTime = $AutoShutdownTime
        $script:lab.AzureSettings.AutoShutdownTimeZone = $AutoShutdownTimeZone.Id
    }
    
    # Select the subscription which is associated with this AzureRmProfile
    $subscriptions = Get-AzSubscription
    $script:lab.AzureSettings.Subscriptions = [AutomatedLab.Azure.AzureSubscription]::Create($Subscriptions)
    Write-PSFMessage "Added $($script:lab.AzureSettings.Subscriptions.Count) subscriptions"

    if ($SubscriptionName -and -not ($script:lab.AzureSettings.Subscriptions | Where-Object Name -eq $SubscriptionName))
    {
        throw "A subscription named '$SubscriptionName' cannot be found. Make sure you specify the right subscription name or let AutomatedLab choose on by not defining a subscription name"
    }
    if ($SubscriptionId -and -not ($script:lab.AzureSettings.Subscriptions | Where-Object Id -eq $SubscriptionId))
    {
        throw "A subscription with the ID '$SubscriptionId' cannot be found. Make sure you specify the right subscription name or let AutomatedLab choose on by not defining a subscription ID"
    }

    #select default subscription subscription
    $selectedSubscription = if (-not $SubscriptionName -and -not $SubscriptionId)
    {
        $AzureRmProfile.Subscription
    }
    elseif ($SubscriptionName)
    {
        $Subscriptions | Where-Object Name -eq $SubscriptionName
    }
    elseif ($SubscriptionId)
    {
        $Subscriptions | Where-Object Id -eq $SubscriptionId
    }

    if ($selectedSubscription.Count -gt 1)
    {
        throw "There is more than one subscription with the name '$SubscriptionName'. Please use the subscription Id to select a specific subscription."
    }

    Write-ScreenInfo -Message "Using Azure Subscription '$($selectedSubscription.Name)' ($($selectedSubscription.Id))" -Type Info

    try
    {
        [void](Set-AzContext -Subscription $selectedSubscription -ErrorAction SilentlyContinue)
    }
    catch
    {
        throw "Error selecting subscription $SubscriptionName. $($_.Exception.Message). The local Azure profile might have expired. Please try Connect-AzAccount."
    }

    $script:lab.AzureSettings.DefaultSubscription = [AutomatedLab.Azure.AzureSubscription]::Create($selectedSubscription)
    Write-PSFMessage "Azure subscription '$SubscriptionName' selected as default"

    if ($AllowBastionHost.IsPresent -and -not $AzureStack.IsPresent -and (Get-AzProviderFeature -FeatureName AllowBastionHost -ProviderNamespace Microsoft.Network).RegistrationState -eq 'NotRegistered')
    {
        # Check if resource provider allows BastionHost deployment
        $null = Register-AzProviderFeature -FeatureName AllowBastionHost -ProviderNamespace Microsoft.Network
        $null = Register-AzProviderFeature -FeatureName bastionShareableLink -ProviderNamespace Microsoft.Network
    }

    $locations = Get-AzLocation
    $script:lab.AzureSettings.Locations = [AutomatedLab.Azure.AzureLocation]::Create($locations)
    Write-PSFMessage "Added $($script:lab.AzureSettings.Locations.Count) locations"

    if (-not $DefaultLocationName)
    {
        $DefaultLocationName = Get-LabAzureLocation
    }

    try
    {
        Set-LabAzureDefaultLocation -Name $DefaultLocationName -ErrorAction Stop
        Write-ScreenInfo -Message "Using Azure Location '$DefaultLocationName'" -Type Info
    }
    catch
    {
        throw 'Cannot proceed without a valid location specified'
    }

    Write-ScreenInfo -Message "Trying to locate or create default resource group"

    #Create new lab resource group as default
    if (-not $DefaultResourceGroupName)
    {
        $DefaultResourceGroupName = $script:lab.Name
    }

    #Create if no default given or default set and not existing as RG
    $rg = Get-AzResourceGroup -Name $DefaultResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg)
    {
        $rgParams = @{
            Name     = $DefaultResourceGroupName
            Location = $DefaultLocationName
            Tag      = @{
                AutomatedLab = $script:lab.Name
                CreationTime = Get-Date
            }
        }

        $defaultResourceGroup = New-AzResourceGroup @rgParams -ErrorAction Stop
        $script:lab.AzureSettings.DefaultResourceGroup = [AutomatedLab.Azure.AzureRmResourceGroup]::Create($defaultResourceGroup)
    }
    else
    {
        $script:lab.AzureSettings.DefaultResourceGroup = [AutomatedLab.Azure.AzureRmResourceGroup]::Create((Get-AzResourceGroup -Name $DefaultResourceGroupName))
    }
    Write-PSFMessage "Selected $DefaultResourceGroupName as default resource group"

    $resourceGroups = Get-AzResourceGroup
    $script:lab.AzureSettings.ResourceGroups = [AutomatedLab.Azure.AzureRmResourceGroup]::Create($resourceGroups)
    Write-PSFMessage "Added $($script:lab.AzureSettings.ResourceGroups.Count) resource groups"

    $storageAccounts = Get-AzStorageAccount -ResourceGroupName $DefaultResourceGroupName
    foreach ($storageAccount in $storageAccounts)
    {
        $alStorageAccount = [AutomatedLab.Azure.AzureRmStorageAccount]::Create($storageAccount)
        $alStorageAccount.StorageAccountKey = ($storageAccount | Get-AzStorageAccountKey)[0].Value
        $script:lab.AzureSettings.StorageAccounts.Add($alStorageAccount)
    }

    Write-PSFMessage "Added $($script:lab.AzureSettings.StorageAccounts.Count) storage accounts"

    if ($global:cacheAzureRoleSizes)
    {
        Write-ScreenInfo -Message "Querying available vm sizes for Azure location '$DefaultLocationName' (using cache)" -Type Info
        $defaultSizes = (Get-LabAzureDefaultLocation).VirtualMachineRoleSizes
        $roleSizes = $global:cacheAzureRoleSizes | Where-Object { $_.InstanceSize -in $defaultSizes }
    }
    else
    {
        Write-ScreenInfo -Message "Querying available vm sizes for Azure location '$DefaultLocationName'" -Type Info
        $roleSizes = Get-LabAzureAvailableRoleSize -Location $DefaultLocationName
        $global:cacheAzureRoleSizes = $roleSizes
    }

    if ($roleSizes.Count -eq 0)
    {
        throw "No available role sizes in region '$DefaultLocationName'! Cannot continue."
    }

    $script:lab.AzureSettings.RoleSizes = $rolesizes

    # Add LabSources storage
    if ( -not $AzureStack.IsPresent)
    {
        New-LabAzureLabSourcesStorage
    }

    # Add ISOs
    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String, DateTime

    try
    {
        Write-PSFMessage -Message 'Get last ISO update time'
        if ($IsLinux -or $IsMacOs)
        {
            $timestamps = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
        }
        else
        {
            $timestamps = $type::ImportFromRegistry('Cache', 'Timestamps')
        }
        $lastChecked = $timestamps.AzureIsosLastChecked
        Write-PSFMessage -Message "Last check was '$lastChecked'."
    }
    catch
    {
        Write-PSFMessage -Message 'Last check time could not be retrieved. Azure ISOs never updated'
        $lastChecked = Get-Date -Year 1601
        $timestamps = New-Object $type
    }

    if ($lastChecked -lt [datetime]::Now.AddDays(-7) -and -not $AzureStack.IsPresent)
    {
        Write-PSFMessage -Message 'ISO cache outdated. Updating ISO files.'
        try
        {
            Write-ScreenInfo -Message 'Auto-adding ISO files from Azure labsources share' -TaskStart
            Add-LabIsoImageDefinition -Path "$labSources\ISOs" -ErrorAction Stop
        }
        catch
        {
            Write-ScreenInfo -Message 'No ISO files have been found in your Azure labsources share. Please make sure that they are present when you try mounting them.' -Type Warning
        }
        finally
        {
            $timestamps['AzureIsosLastChecked'] = Get-Date
            if ($IsLinux -or $IsMacOs)
            {
                $timestamps.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
            }
            else
            {
                $timestamps.ExportToRegistry('Cache', 'Timestamps')
            }

            Write-ScreenInfo -Message 'Done' -TaskEnd
        }
    }

    # Check last LabSources sync timestamp
    if ($IsLinux -or $IsMacOs)
    {
        $timestamps = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
    }
    else
    {
        $timestamps = $type::ImportFromRegistry('Cache', 'Timestamps')
    }

    $lastchecked = $timestamps.LabSourcesSynced
    $syncMaxSize = Get-LabConfigurationItem -Name LabSourcesMaxFileSizeMb
    $syncIntervalDays = Get-LabConfigurationItem -Name LabSourcesSyncIntervalDays

    if (-not (Get-LabConfigurationItem -Name DoNotPrompt -Default $false) -and -not $lastchecked -and -not $AzureStack.IsPresent)
    {
        $lastchecked = [datetime]0
        $syncText = @"
Do you want to sync the content of $(Get-LabSourcesLocationInternal -Local) to your Azure file share $($global:labsources) every $syncIntervalDays days?

By default, all files smaller than $syncMaxSize MB will be synced. Should you require more control,
execute Sync-LabAzureLabSources manually. The maximum file size for the automatic sync can also
be set in your settings with the setting LabSourcesMaxFileSizeMb.
Have a look at Get-Command -Syntax Sync-LabAzureLabSources for additional information.

To configure later:
Get/Set/Register/Unregister-PSFConfig -Module AutomatedLab -Name LabSourcesMaxFileSizeMb
Get/Set/Register/Unregister-PSFConfig -Module AutomatedLab -Name LabSourcesSyncIntervalDays
Get/Set/Register/Unregister-PSFConfig -Module AutomatedLab -Name AutoSyncLabSources
"@
        # Detecting Interactivity this way only works in .NET Full - .NET Core always defaults to $true
        # Last Resort is checking the CommandLine Args
        $choice = if (($PSVersionTable.PSEdition -eq 'Desktop' -and [Environment]::UserInteractive) -or ($PSVersionTable.PSEdition -eq 'Core' -and [string][Environment]::GetCommandLineArgs() -notmatch "-Non"))
        {
            Read-Choice -ChoiceList '&Yes', '&No, do not ask me again', 'N&o, not this time' -Caption 'Sync lab sources to Azure?' -Message $syncText -Default 0
        }
        else
        {
            2
        }

        if ($choice -eq 0)
        {
            Set-PSFConfig -Module AutomatedLab -Name AutoSyncLabSources -Value $true -PassThru | Register-PSFConfig            
        }
        elseif ($choice -eq 1)
        {
            Set-PSFConfig -Module AutomatedLab -Name AutoSyncLabSources -Value $false -PassThru | Register-PSFConfig
        }

        $timestamps.LabSourcesSynced = Get-Date
        if ($IsLinux -or $IsMacOs)
        {
            $timestamps.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
        }
        else
        {
            $timestamps.ExportToRegistry('Cache', 'Timestamps')
        }
    }

    if ((Get-LabConfigurationItem -Name AutoSyncLabSources) -and $lastchecked -lt [datetime]::Now.AddDays(-$syncIntervalDays) -and -not $AzureStack.IsPresent)
    {
        Sync-LabAzureLabSources -MaxFileSizeInMb $syncMaxSize
        $timestamps.LabSourcesSynced = Get-Date
        if ($IsLinux -or $IsMacOs)
        {
            $timestamps.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
        }
        else
        {
            $timestamps.ExportToRegistry('Cache', 'Timestamps')
        }
    }

    $script:lab.AzureSettings.VNetConfig = (Get-AzVirtualNetwork) | ConvertTo-Json
    Write-PSFMessage 'Added virtual network configuration'

    # Read cache
    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Azure.AzureOSImage

    try
    {
        if ($IsLinux -or $IsMacOs) 
        {
            $global:cacheVmImages = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/AzureOperatingSystems.xml'))
        }
        else
        {
            $global:cacheVmImages = $type::ImportFromRegistry('Cache', 'AzureOperatingSystems')
        }

        Write-PSFMessage "Read $($global:cacheVmImages.Count) OS images from the cache"

        if ($global:cacheVmImages -and $global:cacheVmImages.TimeStamp -gt (Get-Date).AddDays(-7))
        {
            Write-PSFMessage ("Azure OS Cache was older than {0:yyyy-MM-dd HH:mm:ss}. Cache date was {1:yyyy-MM-dd HH:mm:ss}" -f (Get-Date).AddDays(-7) , $global:cacheVmImages.TimeStamp)
            Write-ScreenInfo 'Querying available operating system images (using cache)'
            $vmImages = $global:cacheVmImages
        }
        else
        {
            Write-ScreenInfo 'Could not read OS image info from the cache'
            throw 'Cache outdated or empty'
        }
    }
    catch
    {
        Write-ScreenInfo 'Querying available operating system images from Azure'
        $global:cacheVmImages = Get-LabAzureAvailableSku -Location $DefaultLocationName
        $vmImages = $global:cacheVmImages
    }

    $osImageListType = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Azure.AzureOSImage
    $script:lab.AzureSettings.VmImages = New-Object $osImageListType

    # Cache all images
    if ($vmImages)
    {
        $osImageList = New-Object $osImageListType


        foreach ($vmImage in $vmImages)
        {
            $osImageList.Add([AutomatedLab.Azure.AzureOSImage]::Create($vmImage))
            $script:lab.AzureSettings.VmImages.Add([AutomatedLab.Azure.AzureOSImage]::Create($vmImage))
        }

        $osImageList.Timestamp = Get-Date
        if ($IsLinux -or $IsMacOS)
        {
            $osImageList.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/AzureOperatingSystems.xml'))
        }
        else
        {
            $osImageList.ExportToRegistry('Cache', 'AzureOperatingSystems')
        }
    }

    Write-PSFMessage "Added $($script:lab.AzureSettings.VmImages.Count) virtual machine images"

    $vms = Get-AzVM
    $script:lab.AzureSettings.VirtualMachines = [AutomatedLab.Azure.AzureVirtualMachine]::Create($vms)
    Write-PSFMessage "Added $($script:lab.AzureSettings.VirtualMachines.Count) virtual machines"

    Write-ScreenInfo -Message "Azure default resource group name will be '$($script:lab.Name)'"
    Write-ScreenInfo -Message "Azure data center location will be '$DefaultLocationName'" -Type Info
    Write-ScreenInfo -Message 'Finished adding Azure subscription data' -Type Info -TaskEnd

    if ($PassThru)
    {
        $script:lab.AzureSettings.Subscription
    }

    Write-LogFunctionExit
}

function Get-LabAzureSubscription
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    Update-LabAzureSettings

    $script:lab.AzureSettings.Subscriptions

    Write-LogFunctionExit
}

function Get-LabAzureDefaultSubscription
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    Update-LabAzureSettings

    $script:lab.AzureSettings.DefaultSubscription

    Write-LogFunctionExit
}

function Get-LabAzureLocation
{
    [CmdletBinding()]
    param (
        [string]$LocationName,

        [switch]$List
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureLocations = Get-AzLocation

    if ($LocationName)
    {
        if ($LocationName -notin ($azureLocations.DisplayName))
        {
            Write-Error "Invalid location. Please specify one of the following locations: ""'$($azureLocations.DisplayName -join ''', ''')"
            return
        }

        $azureLocations | Where-Object DisplayName -eq $LocationName
    }
    else
    {
        if ((Get-Lab -ErrorAction SilentlyContinue) -and (-not $list))
        {
            #if lab already exists, use the location used when this was deployed to create lab stickyness
            return (Get-Lab).AzureSettings.DefaultLocation.Name
        }

        $locationUrls = Get-LabConfigurationItem -Name AzureLocationsUrls

        foreach ($location in $azureLocations)
        {
            if ($locationUrls."$($location.DisplayName)")
            {
                $location | Add-Member -MemberType NoteProperty -Name 'Url' -Value ($locationUrls."$($location.DisplayName)" + '.blob.core.windows.net')
            }
            $location | Add-Member -MemberType NoteProperty -Name 'Latency' -Value 9999
        }

        $jobs = @()
        foreach ($location in ($azureLocations | Where-Object { $_.Url }))
        {
            $url = $location.Url
            $jobs += Start-Job -Name $location.DisplayName -ScriptBlock {
                $testUrl = $using:url

                try
                {
                    (Test-Port -ComputerName $testUrl -Port 443 -Count 4 -ErrorAction Stop | Measure-Object -Property ResponseTime -Average).Average
                }
                catch
                {
                    9999
                    #Write-PSFMessage -Level Warning "$testUrl $($_.Exception.Message)"
                }
            }
        }

        Wait-LWLabJob -Job $jobs -NoDisplay
        foreach ($job in $jobs)
        {
            $result = Receive-Job -Keep -Job $job
            ($azureLocations | Where-Object { $_.DisplayName -eq $job.Name }).Latency = $result
        }
        $jobs | Remove-Job

        Write-PSFMessage -Message 'DisplayName            Latency'
        foreach ($location in $azureLocations)
        {
            Write-PSFMessage -Message "$($location.DisplayName.PadRight(20)): $($location.Latency)"
        }

        if ($List)
        {
            $azureLocations | Sort-Object -Property Latency | Format-Table DisplayName, Latency
        }
        else
        {
            $azureLocations | Sort-Object -Property Latency | Select-Object -First 1 | Select-Object -ExpandProperty DisplayName
        }
    }

    Write-LogFunctionExit
}

function Get-LabAzureDefaultLocation
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    Update-LabAzureSettings

    if (-not $Script:lab.AzureSettings.DefaultLocation)
    {
        Write-Error 'The default location is not defined. Use Set-LabAzureDefaultLocation to define it.'
        return
    }

    $Script:lab.AzureSettings.DefaultLocation

    Write-LogFunctionExit
}

function Set-LabAzureDefaultLocation
{

    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-LogFunctionEntry

    Update-LabAzureSettings

    if (-not ($Name -in $script:lab.AzureSettings.Locations.DisplayName -or $Name -in $script:lab.AzureSettings.Locations.Location))
    {
        Microsoft.PowerShell.Utility\Write-Error "Invalid location. Please specify one of the following locations: $($script:lab.AzureSettings.Locations.DisplayName -join ', ')"
        return
    }

    $script:lab.AzureSettings.DefaultLocation = $script:lab.AzureSettings.Locations | Where-Object { $_.DisplayName -eq $Name -or $_.Location -eq $Name }

    Write-LogFunctionExit
}

function Get-LabAzureDefaultResourceGroup
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    Update-LabAzureSettings

    $script:lab.AzureSettings.ResourceGroups | Where-Object ResourceGroupName -eq $script:lab.Name

    Write-LogFunctionExit
}

#TODO use keyvault -> New AzureProp defaultKeyVaultName
function Import-LabAzureCertificate
{
    [CmdletBinding()]
    param ()

    Test-LabHostConnected -Throw -Quiet

    throw New-Object System.NotImplementedException
    Write-LogFunctionEntry

    Update-LabAzureSettings

    $resourceGroup = Get-AzResourceGroup -name (Get-LabAzureDefaultResourceGroup)
    $keyVault = Get-AzKeyVault -VaultName (Get-LabAzureDefaultKeyVault) -ResourceGroupName $resourceGroup
    $temp = [System.IO.Path]::GetTempFileName()

    $cert = ($keyVault | Get-AzKeyVaultCertificate).Data

    if ($cert)
    {
        $cert | Out-File -FilePath $temp
        certutil -addstore -f Root $temp | Out-Null

        Remove-Item -Path $temp
        Write-LogFunctionExit
    }
    else
    {
        Write-LogFunctionExitWithError -Message "Could not receive certificate for resource group '$resourceGroup'"
    }
}

#TODO use keyvault -> New AzureProp defaultKeyVaultName
function New-LabAzureCertificate
{
    [CmdletBinding()]
    param ()
    throw New-Object System.NotImplementedException
    Write-LogFunctionEntry

    Update-LabAzureSettings

    $certSubject = "CN=$($Script:lab.Name).cloudapp.net"
    $service = Get-LabAzureDefaultResourceGroup
    $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object Subject -eq $certSubject -ErrorAction SilentlyContinue

    if (-not $cert)
    {
        $temp = [System.IO.Path]::GetTempFileName()

        #not required as SSL is not used yet
        #& 'C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Bin\makecert.exe' -r -pe -n $certSubject -b 01/01/2000 -e 01/01/2036 -eku 1.3.6.1.5.5.7.3.1, 1.3.6.1.5.5.7.3.2 -ss my -sr localMachine -sky exchange -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12 $temp

        certutil.exe -addstore -f Root $temp | Out-Null

        Remove-Item -Path $temp

        $cert = Get-ChildItem Cert:\LocalMachine\Root | Where-Object Subject -eq $certSubject
    }

    #not required as SSL is not used yet
    #$service | Add-AzureCertificate -CertToDeploy (Get-Item -Path "Cert:\LocalMachine\Root\$($cert.Thumbprint)")
}

#TODO use keyvault -> New AzureProp defaultKeyVaultName
function Get-LabAzureCertificate
{
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    [CmdletBinding()]
    param ()

    throw New-Object System.NotImplementedException
    Write-LogFunctionEntry

    Update-LabAzureSettings

    $certSubject = "CN=$($Script:lab.Name).cloudapp.net"

    $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object Subject -eq $certSubject -ErrorAction SilentlyContinue

    if (-not $cert)
    {
        #just returning nothing is more convenient
        #Write-LogFunctionExitWithError -Message "The required certificate does not exist"
    }
    else
    {
        $cert
    }

    Write-LogFunctionExit
}

function New-LabAzureRmResourceGroup
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ResourceGroupNames,

        [Parameter(Mandatory, Position = 1)]
        [string]$LocationName,

        [switch]$PassThru
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    Update-LabAzureSettings

    Write-PSFMessage "Creating the resource groups '$($ResourceGroupNames -join ', ')' for location '$LocationName'"

    $resourceGroups = Get-AzResourceGroup

    foreach ($name in $ResourceGroupNames)
    {
        if ($resourceGroups | Where-Object ResourceGroupName -eq $name)
        {
            if (-not $script:lab.AzureSettings.ResourceGroups.ResourceGroupName.Contains($name))
            {
                $script:lab.AzureSettings.ResourceGroups.Add([AutomatedLab.Azure.AzureRmResourceGroup]::Create((Get-AzResourceGroup -ResourceGroupName $name)))
                Write-PSFMessage "The resource group '$name' does already exist"
            }
            continue
        }

        $result = New-AzResourceGroup -Name $name -Location $LocationName -Tag @{
            AutomatedLab = $script:lab.Name
            CreationTime = Get-Date
        }

        $script:lab.AzureSettings.ResourceGroups.Add([AutomatedLab.Azure.AzureRmResourceGroup]::Create((Get-AzResourceGroup -ResourceGroupName $name)))
        if ($PassThru)
        {
            $result
        }

        Write-PSFMessage "Resource group '$name' created"
    }

    Write-LogFunctionExit
}

function Remove-LabAzureResourceGroup
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string[]]$ResourceGroupName,

        [switch]$Force
    )

    begin
    {
        Test-LabHostConnected -Throw -Quiet

        Write-LogFunctionEntry

        Update-LabAzureSettings

        $resourceGroups = Get-LabAzureResourceGroup -CurrentLab
    }

    process
    {
        foreach ($name in $ResourceGroupName)
        {
            Write-ScreenInfo -Message "Removing the Resource Group '$name'" -Type Warning
            if ($resourceGroups.ResourceGroupName -contains $name)
            {
                Remove-AzResourceGroup -Name $name -Force:$Force | Out-Null
                Write-PSFMessage "Resource Group '$($name)' removed"

                $resourceGroup = $script:lab.AzureSettings.ResourceGroups | Where-Object ResourceGroupName -eq $name
                $script:lab.AzureSettings.ResourceGroups.Remove($resourceGroup) | Out-Null
            }
            else
            {
                Write-ScreenInfo -Message "RG '$name' could not be found" -Type Error
            }
        }
    }

    end
    {
        Write-LogFunctionExit
    }
}

function Get-LabAzureResourceGroup
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName')]
        [string[]]$ResourceGroupName,

        [Parameter(Position = 0, ParameterSetName = 'ByLab')]
        [switch]$CurrentLab
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    Update-LabAzureSettings

    $resourceGroups = $script:lab.AzureSettings.ResourceGroups

    if ($ResourceGroupName)
    {
        Write-PSFMessage "Getting the resource groups '$($ResourceGroupName -join ', ')'"
        $resourceGroups | Where-Object ResourceGroupName -in $ResourceGroupName
    }
    elseif ($CurrentLab)
    {
        $result = $resourceGroups | Where-Object { $_.Tags.AutomatedLab -eq $script:lab.Name }

        if (-not $result)
        {
            $result = $script:lab.AzureSettings.DefaultResourceGroup
        }
        $result
    }
    else
    {
        Write-PSFMessage 'Getting all resource groups'
        $resourceGroups
    }

    Write-LogFunctionExit
}

#region New-LabAzureLabSourcesStorage
function New-LabAzureLabSourcesStorage
{
    [CmdletBinding()]
    param
    (
        [string]$LocationName,

        [switch]$NoDisplay
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    Test-LabAzureSubscription
    $azureLabSourcesResourceGroupName = 'AutomatedLabSources'

    if (-not $LocationName)
    {
        $LocationName = (Get-LabAzureDefaultLocation -ErrorAction SilentlyContinue).DisplayName
    }
    if (-not $LocationName)
    {
        Write-Error "LocationName was not provided and could not be retrieved from a present lab. Please specify a location name or import a lab"
        return
    }
    if ($LocationName -notin (Get-AzLocation).DisplayName)
    {
        Write-Error "The location name '$LocationName' is not valid. Please invoke 'Get-AzLocation' to get a list of possible locations"
    }

    $currentSubscription = (Get-AzContext).Subscription
    Write-ScreenInfo "Looking for Azure LabSources inside subscription '$($currentSubscription.Name)'" -TaskStart

    $resourceGroup = Get-AzResourceGroup -Name $azureLabSourcesResourceGroupName -ErrorAction SilentlyContinue
    if (-not $resourceGroup)
    {
        Write-ScreenInfo "Resoure Group '$azureLabSourcesResourceGroupName' could not be found, creating it"
        $resourceGroup = New-AzResourceGroup -Name $azureLabSourcesResourceGroupName -Location $LocationName | Out-Null
    }

    $storageAccount = Get-AzStorageAccount -ResourceGroupName $azureLabSourcesResourceGroupName -ErrorAction SilentlyContinue | Where-Object StorageAccountName -like automatedlabsources?????
    if (-not $storageAccount)
    {
        Write-ScreenInfo "No storage account for AutomatedLabSources could not be found, creating it"
        $storageAccountName = "automatedlabsources$((1..5 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"
        New-AzStorageAccount -ResourceGroupName $azureLabSourcesResourceGroupName -Name $storageAccountName -Location $LocationName -Kind Storage -SkuName Standard_LRS | Out-Null
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $azureLabSourcesResourceGroupName | Where-Object StorageAccountName -like automatedlabsources?????
    }

    $share = Get-AzStorageShare -Context $StorageAccount.Context -Name labsources -ErrorAction SilentlyContinue
    if (-not $share)
    {
        Write-ScreenInfo "The share 'labsources' could not be found, creating it"
        New-AzStorageShare -Name 'labsources' -Context $storageAccount.Context | Out-Null
    }

    Write-ScreenInfo "Azure LabSources verified / created" -TaskEnd

    Write-LogFunctionExit
}
#endregion New-LabAzureLabSourcesStorage

function Get-LabAzureLabSourcesStorage
{
    [CmdletBinding()]
    param
    ()

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    Test-LabAzureSubscription
    $azureLabSourcesResourceGroupName = 'AutomatedLabSources'

    $currentSubscription = (Get-AzContext).Subscription

    $storageAccount = Get-AzStorageAccount -ResourceGroupName automatedlabsources -ErrorAction SilentlyContinue | Where-Object StorageAccountName -like automatedlabsources?????

    if (-not $storageAccount)
    {
        Write-Error "The AutomatedLabSources share on Azure does not exist"
        return
    }

    $storageAccount | Add-Member -MemberType NoteProperty -Name StorageAccountKey -Value ($storageAccount | Get-AzStorageAccountKey)[0].Value -Force
    $storageAccount | Add-Member -MemberType NoteProperty -Name Path -Value "\\$($storageAccount.StorageAccountName).file.core.windows.net\labsources" -Force
    $storageAccount | Add-Member -MemberType NoteProperty -Name SubscriptionName -Value (Get-AzContext).Subscription.Name -Force

    $storageAccount
}

function Test-LabAzureLabSourcesStorage
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param ( )

    Test-LabHostConnected -Throw -Quiet

    if ((Get-LabDefinition -ErrorAction SilentlyContinue).AzureSettings.IsAzureStack -or (Get-Lab -ErrorAction SilentlyContinue).AzureSettings.IsAzureStack) { return $false }

    $azureLabSources = Get-LabAzureLabSourcesStorage -ErrorAction SilentlyContinue

    if (-not $azureLabSources)
    {
        return $false
    }

    $azureStorageShare = Get-AzStorageShare -Context $azureLabSources.Context -ErrorAction SilentlyContinue

    [bool]$azureStorageShare
}

function Test-LabPathIsOnLabAzureLabSourcesStorage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-LabHostConnected)) { return $false }

    try
    {
        if (Test-LabAzureLabSourcesStorage)
        {
            $azureLabSources = Get-LabAzureLabSourcesStorage

            return $Path -like "$($azureLabSources.Path)*"
        }
        else
        {
            return $false
        }
    }
    catch
    {
        return $false
    }
}

function Remove-LabAzureLabSourcesStorage
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    ()

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionExit
    Test-LabAzureSubscription

    if (Test-LabAzureLabSourcesStorage)
    {
        $azureLabStorage = Get-LabAzureLabSourcesStorage

        if ($PSCmdlet.ShouldProcess($azureLabStorage.ResourceGroupName, 'Remove Resource Group'))
        {
            Remove-AzResourceGroup -Name $azureLabStorage.ResourceGroupName -Force | Out-Null
            Write-ScreenInfo "Azure Resource Group '$($azureLabStorage.ResourceGroupName)' was removed" -Type Warning
        }
    }

    Write-LogFunctionExit
}

function Sync-LabAzureLabSources
{
    [CmdletBinding()]
    param
    (
        [switch]
        $SkipIsos,

        [switch]
        $DoNotSkipOsIsos,

        [int]
        $MaxFileSizeInMb,

        [string]
        $Filter,

        [switch]
        $NoDisplay
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionExit
    Test-LabAzureSubscription

    if (-not (Test-LabAzureLabSourcesStorage))
    {
        Write-Error "There is no LabSources share available in the current subscription '$((Get-AzContext).Subscription.Name)'. To create one, please call 'New-LabAzureLabSourcesStorage'."
        return
    }

    $currentSubscription = (Get-AzContext).Subscription
    Write-ScreenInfo -Message "Syncing LabSources in subscription '$($currentSubscription.Name)'" -TaskStart

    # Retrieve storage context
    $storageAccount = Get-AzStorageAccount -ResourceGroupName automatedlabsources | Where-Object StorageAccountName -like automatedlabsources?????

    $localLabsources = Get-LabSourcesLocationInternal -Local
    Unblock-LabSources -Path $localLabsources

    # Sync the lab sources
    $fileParams = @{
        Recurse     = $true
        Path        = $localLabsources
        File        = $true
        Filter      = if ($Filter) { $Filter } else { "*" }
        ErrorAction = 'SilentlyContinue'
    }

    $files = Get-ChildItem @fileParams
    $share = (Get-AzStorageShare -Name labsources -Context $storageAccount.Context).CloudFileShare

    foreach ($file in $files)
    {
        Write-ProgressIndicator
        if ($SkipIsos -and $file.Directory.Name -eq 'Isos')
        {
            Write-PSFMessage "SkipIsos is true, skipping $($file.Name)"
            continue
        }

        if ($MaxFileSizeInMb -and $file.Length / 1MB -ge $MaxFileSizeInMb)
        {
            Write-PSFMessage "MaxFileSize is $MaxFileSizeInMb MB, skipping '$($file.Name)'"
            continue
        }

        # Check if file is an OS ISO and skip
        if ($file.Extension -eq '.iso')
        {
            $isOs = [bool](Get-LabAvailableOperatingSystem -Path $file.FullName)

            if ($isOs -and -not $DoNotSkipOsIsos)
            {
                Write-PSFMessage "Skipping OS ISO $($file.FullName)"
                continue
            }
        }

        $fileName = $file.FullName.Replace("$($localLabSources)\", '')

        $azureFile = Get-AzStorageFile -Share $share -Path $fileName -ErrorAction SilentlyContinue
        if ($azureFile)
        {
            $sBuilder = [System.Text.StringBuilder]::new()
            foreach ($byte in $azureFile.FileProperties.ContentHash)
            {
                $null = $sBuilder.Append($byte.ToString("x2"))
            }
            $azureHash = $sBuilder.ToString()

            $sBuilder = [System.Text.StringBuilder]::new()
            $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
            $data = $md5.ComputeHash([System.IO.File]::ReadAllBytes($file.Fullname))
            foreach ($byte in $data)
            {
                $null = $sBuilder.Append($byte.ToString("x2"))
            }
            $localHash = $sBuilder.ToString()
            $fileHash = [System.Convert]::ToBase64String($data)
            
            # Azure expects base64 MD5 in the request, returns MD5 :)
            Write-PSFMessage "$fileName already exists in Azure. Source hash is $localHash and Azure hash is $azureHash"
        }

        if ($azureFile -and $localHash -eq $azureHash)
        {
            continue
        }

        if (-not $azureFile -or ($azureFile -and $localHash -ne $azureHash))
        {
            $null = New-LabSourcesPath -RelativePath $fileName -Share $share
            $null = Set-AzStorageFileContent -Share $share -Source $file.FullName -Path $fileName -ErrorAction SilentlyContinue -Force
            Write-PSFMessage "Azure file $fileName successfully uploaded. Updating file hash..."
        }

        # Try to set the file hash
        $uploadedFile = Get-AzStorageFile -Share $share -Path $fileName -ErrorAction SilentlyContinue
        try
        {
            $uploadedFile.CloudFile.Properties.ContentMD5 = $fileHash
            $apiResponse = $uploadedFile.CloudFile.SetProperties()
        }
        catch
        {
            Write-ScreenInfo "Could not update MD5 hash for file $fileName." -Type Warning
        }

        Write-PSFMessage "Azure file $fileName successfully uploaded and hash generated"
    }

    Write-ScreenInfo "LabSources Sync complete" -TaskEnd

    Write-LogFunctionExit
}

function New-LabSourcesPath
{
    [CmdletBinding()]
    param
    (
        [string]
        $RelativePath,

        [Microsoft.Azure.Storage.File.CloudFileShare]
        $Share
    )

    $container = Split-Path -Path $RelativePath
    if (-not $container)
    {
        New-AzStorageDirectory -Share $Share -Path $RelativePath -ErrorAction SilentlyContinue
        return
    }

    if (-not (Get-AzStorageFile -Share $Share -Path $container -ErrorAction SilentlyContinue))
    {
        New-LabSourcesPath -RelativePath $container -Share $Share
        New-AzStorageDirectory -Share $Share -Path $container -ErrorAction SilentlyContinue
    }
}

function Get-LabAzureLabSourcesContent
{
    [CmdletBinding()]
    param
    (
        [string]
        $RegexFilter,

        # Path relative to labsources file share
        [string]
        $Path,

        [switch]
        $File,

        [switch]
        $Directory
    )

    Test-LabHostConnected -Throw -Quiet

    $azureShare = Get-AzStorageShare -Name labsources -Context (Get-LabAzureLabSourcesStorage).Context

    $params = @{
        StorageContext = $azureShare
    }
    if ($Path) { $params.Path = $Path }

    $content = Get-LabAzureLabSourcesContentRecursive @params

    if (-not [string]::IsNullOrWhiteSpace($RegexFilter))
    {
        $content = $content | Where-Object -FilterScript { $PSItem.Name -match $RegexFilter }
    }

    if ($File)
    {
        $content = $content | Where-Object -FilterScript { $PSItem.GetType().FullName -eq 'Microsoft.Azure.Storage.File.CloudFile' }
    }

    if ($Directory)
    {
        $content = $content | Where-Object -FilterScript { $PSItem.GetType().FullName -eq 'Microsoft.Azure.Storage.File.CloudFileDirectory' }
    }

    $content = $content |
    Add-Member -MemberType ScriptProperty -Name FullName -Value { $this.Uri.AbsoluteUri } -Force -PassThru |
    Add-Member -MemberType ScriptProperty -Name Length -Force -Value { $this.Properties.Length } -PassThru

    return $content
}

function Get-LabAzureLabSourcesContentRecursive
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [object]$StorageContext,

        # Path relative to labsources file share
        [string]
        $Path
    )

    Test-LabHostConnected -Throw -Quiet

    $content = @()

    $temporaryContent = if ($Path)
    {
        $StorageContext | Get-AzStorageFile -Path $Path -ErrorAction SilentlyContinue
    }
    else
    {
        $StorageContext | Get-AzStorageFile
    }

    foreach ($item in $temporaryContent)
    {
        if ($item.CloudFileDirectory)
        {
            $content += $item.CloudFileDirectory
            $content += Get-LabAzureLabSourcesContentRecursive -StorageContext $item
        }
        elseif ($item.CloudFile)
        {
            $content += $item.CloudFile
        }
        else
        {
            continue
        }
    }

    return $content
}

function Test-LabAzureSubscription
{
    [CmdletBinding()]
    param ( )

    Test-LabHostConnected -Throw -Quiet

    try
    {
        $ctx = Get-AzContext
    }
    catch
    {
        throw "No Azure Context found, Please run 'Connect-AzAccount' first"
    }
}

function Get-LabAzureAvailableRoleSize
{
    [CmdletBinding(DefaultParameterSetName = 'DisplayName')]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'DisplayName')]
        [Alias('Location')]
        [string]
        $DisplayName,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]
        $LocationName
    )

    Test-LabHostConnected -Throw -Quiet

    if (-not (Get-AzContext -ErrorAction SilentlyContinue))
    {
        $param = @{
            UseDeviceAuthentication = $true
            ErrorAction             = 'SilentlyContinue' 
            WarningAction           = 'Continue'            
        }

        if ($script:lab.AzureSettings.Environment)
        {
            $param.Environment = $script:Lab.AzureSettings.Environment
        }

        $null = Connect-AzAccount @param
    }

    $azLocation = Get-AzLocation | Where-Object { $_.DisplayName -eq $DisplayName -or $_.Location -eq $LocationName }
    if (-not $azLocation)
    {
        Write-ScreenInfo -Type Error -Message "No location found matching DisplayName '$DisplayName' or Name '$LocationName'"
    }

    $availableRoleSizes = if ((Get-Command Get-AzComputeResourceSku).Parameters.ContainsKey('Location'))
    {
        Get-AzComputeResourceSku -Location $azLocation.Location | Where-Object {
            $_.ResourceType -eq 'virtualMachines' -and $_.Restrictions.ReasonCode -notcontains 'NotAvailableForSubscription' -and ($_.Capabilities | Where-Object Name -eq CpuArchitectureType).Value -notlike '*arm*'
        }
    }
    else
    {
        Get-AzComputeResourceSku | Where-Object {
            $_.Locations -contains $azLocation.Location -and $_.ResourceType -eq 'virtualMachines' -and $_.Restrictions.ReasonCode -notcontains 'NotAvailableForSubscription' -and ($_.Capabilities | Where-Object Name -eq CpuArchitectureType).Value -notlike '*arm*'
        }
    }
    

    foreach ($vms in (Get-AzVMSize -Location $azLocation.Location | Where-Object -Property Name -in $availableRoleSizes.Name))
    {
        $rsInfo = $availableRoleSizes | Where-Object Name -eq $vms.Name

            [AutomatedLab.Azure.AzureRmVmSize]@{
                NumberOfCores = $vms.NumberOfCores
                MemoryInMB = $vms.MemoryInMB
                Name = $vms.Name
                MaxDataDiskCount = $vms.MaxDataDiskCount
                ResourceDiskSizeInMB = $vms.ResourceDiskSizeInMB
                OSDiskSizeInMB = $vms.OSDiskSizeInMB
                Gen1Supported = ($rsInfo.Capabilities | Where-Object Name -eq HyperVGenerations).Value -like '*v1*'
                Gen2Supported = ($rsInfo.Capabilities | Where-Object Name -eq HyperVGenerations).Value -like '*v2*'
            }
    }
}

function Get-LabAzureAvailableSku
{
    [CmdletBinding(DefaultParameterSetName = 'DisplayName')]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'DisplayName')]
        [Alias('Location')]
        [string]
        $DisplayName,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]
        $LocationName
    )

    Test-LabHostConnected -Throw -Quiet

    # Server
    $azLocation = Get-AzLocation | Where-Object { $_.DisplayName -eq $DisplayName -or $_.Location -eq $LocationName }
    if (-not $azLocation)
    {
        Write-ScreenInfo -Type Error -Message "No location found matching DisplayName '$DisplayName' or Name '$LocationName'"
    }
    $publishers = Get-AzVMImagePublisher -Location $azLocation.Location
    
    $publishers |
    Where-Object PublisherName -eq 'MicrosoftWindowsServer' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 }

    # Desktop
    $publishers |
    Where-Object PublisherName -eq 'MicrosoftWindowsDesktop' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 }

    # SQL
    $publishers |
    Where-Object PublisherName -eq 'MicrosoftSQLServer' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Where-Object Skus -in 'Standard','Enterprise' |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 }

    # VisualStudio
    $publishers |
    Where-Object PublisherName -eq 'MicrosoftVisualStudio' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Where-Object Offer -eq 'VisualStudio' |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 }

    # Client OS
    $publishers |
    Where-Object PublisherName -eq 'MicrosoftVisualStudio' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Where-Object Offer -eq 'Windows' |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 }

    # Sharepoint 2013 and 2016
    $publishers |
    Where-Object PublisherName -eq 'MicrosoftSharePoint' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Where-Object Offer -eq 'MicrosoftSharePointServer' |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 }
}

function Enable-LabAzureJitAccess
{
    [CmdletBinding()]
    param 
    (
        [timespan]
        $MaximumAccessRequestDuration = '05:00:00',

        [switch]
        $PassThru
    )

    $vms = Get-LWAzureVm
    $lab = Get-Lab

    if ($lab.AzureSettings.IsAzureStack)
    {
        Write-Error -Message "$($lab.Name) is running on Azure Stack and thus does not support JIT access."
        return
    }
    
    $parameters = @{
        Location          = $lab.AzureSettings.DefaultLocation.Location
        Name              = 'AutomatedLabJIT'
        ResourceGroupName = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
    }

    if (Get-AzJitNetworkAccessPolicy @parameters -ErrorAction SilentlyContinue)
    {
        Write-ScreenInfo -Type Verbose -Message 'JIT policy already configured'
        return
    }

    $weirdTimestampFormat = [System.Xml.XmlConvert]::ToString($MaximumAccessRequestDuration)

    $vmPolicies = foreach ($vm in $vms)
    {
        @{
            id    = $vm.Id
            ports = @{
                number                     = 22;
                protocol                   = "*";
                allowedSourceAddressPrefix = @("*");
                maxRequestAccessDuration   = $weirdTimestampFormat
            },
            @{
                number                     = 3389;
                protocol                   = "*";
                allowedSourceAddressPrefix = @("*");
                maxRequestAccessDuration   = $weirdTimestampFormat
            },
            @{
                number                     = 5985;
                protocol                   = "*";
                allowedSourceAddressPrefix = @("*");
                maxRequestAccessDuration   = $weirdTimestampFormat
            }
        }
    }

    $policy = Set-AzJitNetworkAccessPolicy -Kind "Basic" @parameters -VirtualMachine $vmPolicies
    while ($policy.ProvisioningState -ne 'Succeeded')
    {
        $policy = Get-AzJitNetworkAccessPolicy @parameters
    }

    if ($PassThru) { $policy }
}

function Request-LabAzureJitAccess
{
    [CmdletBinding()]
    param
    (
        [string[]]
        $ComputerName,

        # Local end time, will be converted to UTC for request
        [timespan]
        $Duration = '04:45:00'
    )

    $lab = Get-Lab

    if ($lab.AzureSettings.IsAzureStack)
    {
        Write-Error -Message "$($lab.Name) is running on Azure Stack and thus does not support JIT access."
        return
    }

    $parameters = @{
        Location          = $lab.AzureSettings.DefaultLocation.Location
        Name              = 'AutomatedLabJIT'
        ResourceGroupName = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
    }

    $policy = Get-AzJitNetworkAccessPolicy @parameters -ErrorAction SilentlyContinue
    if (-not $policy) { $policy = Enable-LabAzureJitAccess -MaximumAccessRequestDuration $Duration.Add('00:05:00') -PassThru }
    $nodes = if ($ComputerName.Count -eq 0) { Get-LabVm } else { Get-LabVm -ComputerName $ComputerName }
    $vms = Get-LWAzureVm -ComputerName $nodes.ResourceName
    $end = (Get-Date).Add($Duration)
    $utcEnd = $end.ToUniversalTime().ToString('u')

    $jitRequests = foreach ($vm in $vms)
    {
        @{
            id    = $vm.Id
            ports = @{
                number                     = 22;
                endTimeUtc                 = $utcEnd
                allowedSourceAddressPrefix = @('*')
            }, @{
                number                     = 3389;
                endTimeUtc                 = $utcEnd
                allowedSourceAddressPrefix = @('*')
            }, @{
                number                     = 5985;
                endTimeUtc                 = $utcEnd
                allowedSourceAddressPrefix = @('*')
            }
        }
    }

    Set-PSFConfig -Module AutomatedLab -Name AzureJitTimestamp -Value $end -Validation datetime -Hidden
    $null = Start-AzJitNetworkAccessPolicy -ResourceId $policy.Id -VirtualMachine $jitRequests
}
