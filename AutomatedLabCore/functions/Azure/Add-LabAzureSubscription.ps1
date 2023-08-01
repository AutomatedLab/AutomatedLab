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

    $azProfile = Get-AzContext
    if (-not $azProfile)
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
        $azProfile.Subscription
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

    Register-LabAzureRequiredResourceProvider -SubscriptionName $selectedSubscription.Name

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

    if ($global:cacheAzureRoleSizes -and $global:al_PreviousDefaultLocationName -eq $DefaultLocationName)
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

    $global:al_PreviousDefaultLocationName = $DefaultLocationName

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
