$PSDefaultParameterValues = @{
    '*-Azure*:Verbose' = $false
    '*-Azure*:Warning' = $false
    'Import-Module:Verbose' = $false
}

function Update-LabAzureSettings
{
    # .ExternalHelp AutomatedLab.Help.xml
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
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [string]$Path,

        [string]$SubscriptionName,
		
        [string]$DefaultLocationName,
		
        [string]$DefaultStorageAccountName,

        [string]$DefaultResourceGroupName,
		
        [switch]$PassThru
    )
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
    
    if (-not $Path)
    {
        $Path = (Get-ChildItem -Path (Get-LabSourcesLocation) -Filter '*.azurermsettings' -Recurse | Sort-Object -Property TimeWritten | Select-Object -Last 1).FullName
        
        Write-ScreenInfo -Message "No ARM profile file specified. Auto-detected and using ARM profile file '$Path'" -Type Warning
    }
    
    if (-not $script:lab)
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabDefaultOperatingSystem.'
    }
 
    if (-not (Test-Path -Path $Path))
    {
        throw "The ARM profile file '$Path' could not be found"
    }
	
    #This needs to be loaded manually to import the required DLLs
    $minimumAzureModuleVersion = $MyInvocation.MyCommand.Module.PrivateData.MinimumAzureModuleVersion
    if (-not (Get-Module -Name Azure -ListAvailable | Where-Object Version -ge $minimumAzureModuleVersion))
    {
        throw "The Azure PowerShell module version $($minimumAzureModuleVersion) or greater is not available. Please download it from 'http://azure.microsoft.com/en-us/downloads/'"
    }
	
    Write-ScreenInfo -Message 'Adding Azure subscription data' -Type Info -TaskStart
    
    try
    {
        $AzureRmProfile = Select-AzureRmProfile -Path $Path -ErrorAction Stop
    }
    catch
    {
        throw "The Azure Resource Manager Profile $Path could not be loaded or is outdated. $($_.Exception.Message)"
    }

    Update-LabAzureSettings
    if (-not $script:lab.AzureSettings)
    {
        $script:lab.AzureSettings = New-Object AutomatedLab.AzureSettings
    }

    $script:lab.AzureSettings.AzureProfilePath = $Path
    $script:lab.AzureSettings.SubscriptionFileContent = Get-Content -Path $Path
    $script:lab.AzureSettings.DefaultRoleSize = $MyInvocation.MyCommand.Module.PrivateData.DefaultAzureRoleSize
    
    # Select the subscription which is associated with this AzureRmProfile
    $subscriptions = (Get-AzureRmSubscription)
    $script:lab.AzureSettings.Subscriptions = [AutomatedLab.Azure.AzureSubscription]::Create($Subscriptions)
    Write-Verbose "Added $($script:lab.AzureSettings.Subscriptions.Count) subscriptions"
    
    if ($SubscriptionName -and -not ($script:lab.AzureSettings.Subscriptions | Where-Object SubscriptionName -eq $SubscriptionName))
    {
        throw "A subscription named '$SubscriptionName' cannot be found. Make sure you specify the right subscription name or let AutomatedLab choose on by not defining a subscription name"
    }

    #select default subscription subscription
    if (-not $SubscriptionName)
    {
        $SubscriptionName = $AzureRmProfile.Context.Subscription.SubscriptionName
    }

    Write-ScreenInfo -Message "Using Azure Subscription '$SubscriptionName'" -Type Info
    $selectedSubscription = $Subscriptions | Where-Object{$_.SubscriptionName -eq $SubscriptionName}

    try
    {
        [void](Select-AzureRmSubscription -SubscriptionName $SubscriptionName -ErrorAction Stop)
    }
    catch
    {
        throw "Error selecting subscription $SubscriptionName. $($_.Exception.Message)"
    }

    $script:lab.AzureSettings.DefaultSubscription = [AutomatedLab.Azure.AzureSubscription]::Create($selectedSubscription)
    Write-Verbose "Azure subscription '$SubscriptionName' selected as default"

    $locations = Get-AzureRmLocation
    $script:lab.AzureSettings.Locations =  [AutomatedLab.Azure.AzureLocation]::Create($locations)
    Write-Verbose "Added $($script:lab.AzureSettings.Locations.Count) locations"
    
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
    # Create if no default given or default set and not existing as RG
    if(-not $DefaultResourceGroupName -or ($DefaultResourceGroupName -and -not (Get-AzureRmResourceGroup -Name $DefaultResourceGroupName -ErrorAction SilentlyContinue)))
    {
        # Create new lab resource group as default		
        $rgName = $DefaultResourceGroupName
        if (-not $rgName)
        {
            $rgName = $script:lab.Name
        }

        $rgParams = @{
            Name= $rgName
            Location = $DefaultLocationName
            Tag = @{ 
                AutomatedLab = $script:lab.Name
                CreationTime = Get-Date
            }
        }

        $createResourceGroup = $true
		
        if (Get-AzureRmResourceGroup $rgName -ErrorAction SilentlyContinue)
        {
            $createResourceGroup = $false
        }

        if ($createResourceGroup)
        {
            $DefaultResourceGroupName = (New-AzureRmResourceGroup @rgParams -ErrorAction Stop).ResourceGroupName
        }
        else
        {
            $DefaultResourceGroupName = $rgName
        }
        Write-Verbose "Selected $DefaultResourceGroupName as default resource group"
    }	

    $resourceGroups = Get-AzureRmResourceGroup
    $script:lab.AzureSettings.ResourceGroups = [AutomatedLab.Azure.AzureResourceGroup]::Create($resourceGroups)
    Write-Verbose "Added $($script:lab.AzureSettings.ResourceGroups.Count) resource groups"

    if (-not (Get-LabAzureDefaultResourceGroup -ErrorAction SilentlyContinue))
    {
        New-LabAzureResourceGroup -ResourceGroupNames (Get-LabDefinition).Name -LocationName $DefaultLocationName
    }

    $storageAccounts = Get-AzureRmStorageAccount -ResourceGroupName $DefaultResourceGroupName -WarningAction SilentlyContinue
    foreach($storageAccount in $storageAccounts)
    {
        $alStorageAccount = [AutomatedLab.Azure.AzureRmStorageAccount]::Create($storageAccount)
        $alStorageAccount.StorageAccountKey = ($storageAccount | Get-AzureRmStorageAccountKey)[0].Value
        $script:lab.AzureSettings.StorageAccounts.Add($alStorageAccount)
    }
    
    Write-Verbose "Added $($script:lab.AzureSettings.StorageAccounts.Count) storage accounts"

    if ($global:cacheAzureRoleSizes)
    {
        Write-ScreenInfo -Message "Querying available vm sizes for Azure location '$DefaultLocationName' (using cache)" -Type Info
        $roleSizes = $global:cacheAzureRoleSizes | Where-Object { $_.InstanceSize -in (Get-LabAzureDefaultLocation).VirtualMachineRoleSizes }
    }
    else
    {
        Write-ScreenInfo -Message "Querying available vm sizes for Azure location '$DefaultLocationName'" -Type Info
        $roleSizes = Get-AzureRmVmSize -Location $DefaultLocationName
        $global:cacheAzureRoleSizes = $roleSizes
    }


	$script:lab.AzureSettings.RoleSizes = [AutomatedLab.Azure.AzureRmVmSize]::Create($roleSizes)

	# Add LabSources storage
	New-LabAzureLabSourcesStorage

    $script:lab.AzureSettings.VmImages = $vmimages | %{ [AutomatedLab.Azure.AzureOSImage]::Create($_)}
    Write-Verbose "Added $($script:lab.AzureSettings.RoleSizes.Count) vm size information"
	
    $script:lab.AzureSettings.VNetConfig = (Get-AzureRmVirtualNetwork) | ConvertTo-Json
    Write-Verbose 'Added virtual network configuration'

	# Read cache
	$type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Azure.AzureOSImage

    try
    {
        $importMethodInfo = $type.GetMethod('ImportFromRegistry', [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static)
        $global:cacheVmImages = $importMethodInfo.Invoke($null, ('Cache', 'AzureOperatingSystems'))
        Write-Verbose "Read $($global:cacheVmImages.Count) OS images from the cache"
    }
    catch
    {
        Write-Verbose 'Could not read OS image info from the cache'
    }

    if ($global:cacheVmImages -and $global:cacheVmImages.TimeStamp -gt (Get-Date).AddDays(-7))
    {
        Write-ScreenInfo -Message 'Querying available operating system images (using cache)' -Type Info
        $vmImages = $global:cacheVmImages
    }
    else
    {
		if($global:cacheVmImages)
		{
			Write-Verbose ("Azure OS Cache was older than {0:yyyy-MM-dd HH:mm:ss}. Cache date was {1:yyyy-MM-dd HH:mm:ss}" -f (Get-Date).AddDays(-7) ,$global:cacheVmImages.TimeStamp)
		}
        Write-ScreenInfo -Message 'Querying available operating system images' -Type Info
        
        $vmImages = Get-AzureRmVMImagePublisher -Location $DefaultLocationName |
        Where-Object PublisherName -eq 'MicrosoftWindowsServer' |
        Get-AzureRmVMImageOffer |
        Get-AzureRmVMImageSku |
        Get-AzureRmVMImage |
        Group-Object -Property Skus, Offer |
        ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 }

        $vmImages += Get-AzureRmVMImagePublisher -Location $DefaultLocationName |
        Where-Object PublisherName -eq 'MicrosoftSQLServer' |
        Get-AzureRmVMImageOffer |
        Get-AzureRmVMImageSku |
        Get-AzureRmVMImage |
        Where-Object Skus -eq 'Enterprise' |
        Group-Object -Property Skus, Offer |
        ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 }
        
        $vmImages += Get-AzureRmVMImagePublisher -Location $DefaultLocationName |
        Where-Object PublisherName -eq 'MicrosoftVisualStudio' |
        Get-AzureRmVMImageOffer |
        Get-AzureRmVMImageSku |
        Get-AzureRmVMImage |
        Where-Object Offer -eq 'VisualStudio' |
        Group-Object -Property Skus, Offer |
        ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 }

        $global:cacheVmImages = $vmImages
    }
	
	$osImageListType = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Azure.AzureOSImage
	$script:lab.AzureSettings.VmImages = New-Object $osImageListType
	
	# Cache all images
	if($vmImages)
	{		
		$osImageList = New-Object $osImageListType
		

		foreach($vmImage in $vmImages)
		{
			$osImageList.Add([AutomatedLab.Azure.AzureOSImage]::Create($vmImage))			
            $script:lab.AzureSettings.VmImages.Add([AutomatedLab.Azure.AzureOSImage]::Create($vmImage))
		}

		$osImageList.Timestamp = Get-Date
		$osImageList.ExportToRegistry('Cache', 'AzureOperatingSystems')
	}

    Write-Verbose "Added $($script:lab.AzureSettings.VmImages.Count) virtual machine images"

    $vms = Get-AzureRmVM -WarningAction SilentlyContinue
    $script:lab.AzureSettings.VirtualMachines = [AutomatedLab.Azure.AzureVirtualMachine]::Create($vms)
    Write-Verbose "Added $($script:lab.AzureSettings.VirtualMachines.Count) virtual machines"

    #$script:lab.AzureSettings.DefaultStorageAccount cannot be set when creating the definitions but is during the import process
    if (-not $script:lab.AzureSettings.DefaultStorageAccount)
    {
        Write-ScreenInfo -Message 'No default storage account exist. Determining storage account now' -Type Info
        if (-not $DefaultStorageAccountName)
        {
            $DefaultStorageAccountName = ($script:lab.AzureSettings.StorageAccounts | Where-Object StorageAccountName -like 'automatedlab????????' | Select-Object -First 1).StorageAccountName
        }

        if (-not $DefaultStorageAccountName)
        {
            Write-ScreenInfo -Message 'No storage account for AutomatedLab found. Creating a storage account now'
            New-LabAzureDefaultStorageAccount -LocationName $DefaultLocationName -ResourceGroupName $DefaultResourceGroupName
        }
        else
        {
            try
            {
                Set-LabAzureDefaultStorageAccount -Name $DefaultStorageAccountName -ErrorAction Stop
                Write-ScreenInfo -Message "Using Azure Storage Account '$DefaultStorageAccountName'" -Type Info
            }
            catch
            {
                throw 'Cannot proceed with an invalid default storage account'
            }
        }
        Write-Verbose "Mapping storage account '$((Get-LabAzureDefaultStorageAccount).StorageAccountName)' to resource group $DefaultResourceGroupName'"
        [void](Set-AzureRmCurrentStorageAccount -Name $((Get-LabAzureDefaultStorageAccount).StorageAccountName) -ResourceGroupName $DefaultResourceGroupName)
    }    
    
    <# TODO, seems deprecated and or dangerous Add all additional Azure Services if configured
            $resourceGroupNames = (Get-LabMachine).AzureProperties.ResourceGroupName | Select-Object -Unique
            if ($resourceGroupNames)
            {
            #Rename to new-labazureresourcegroup
            New-LabAzureResourceGroup -ServiceName $resourceGroupNames -LocationName $lab.AzureSettings.DefaultLocation -ErrorAction Stop
    }#>

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
    # .ExternalHelp AutomatedLab.Help.xml
    param ()
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $script:lab.AzureSettings.Subscriptions
	
    Write-LogFunctionExit
}

function Get-LabAzureDefaultSubscription
{
    # .ExternalHelp AutomatedLab.Help.xml
    param ()
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $script:lab.AzureSettings.DefaultSubscription
	
    Write-LogFunctionExit
}

function Get-LabAzureLocation
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [string]$LocationName,

        [switch]$List
    )
	
    Write-LogFunctionEntry
	
    #Update-LabAzureSettings
	
    Import-Module -Name Azure*

    $azureLocations = Get-AzureRmLocation
    
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
        
        $urls = @{
            'North Central US' = 'speedtestnsus.blob.core.windows.net'
            'Central US'='speedtestcus.blob.core.windows.net'
            'West Central US'='speedtestwcus.blob.core.windows.net'
            'South Central US'='speedtestscus.blob.core.windows.net'
            'West US' = 'speedtestwus.blob.core.windows.net'
            'West US 2' = 'speedtestwus2.blob.core.windows.net'
            'East US'='speedtesteus.blob.core.windows.net'
            'East US 2'='speedtesteus2.blob.core.windows.net'
            'West Europe'='speedtestwe.blob.core.windows.net'
            'North Europe'='speedtestne.blob.core.windows.net'
            'Southeast Asia'='speedtestsea.blob.core.windows.net'
            'East Asia'='speedtestea.blob.core.windows.net'
            'Japan East'='speedtestjpe.blob.core.windows.net'
            'Japan West'='speedtestjpw.blob.core.windows.net'
            'Brazil South'='speedtestbs.blob.core.windows.net'
            'Australia Southeast'='mickmel.blob.core.windows.net'
            'Australia East'='micksyd.blob.core.windows.net'
            'UK West'='speedtestukw.blob.core.windows.net'
            'UK South'='speedtestuks.blob.core.windows.net'
            'Canada Central'='speedtestcac.blob.core.windows.net'
            'Canada East'='speedtestcae.blob.core.windows.net'
        }
        
        foreach ($location in $azureLocations)
        {
            $location | Add-Member -MemberType NoteProperty -Name 'Url'     -Value ($urls."$($location.DisplayName)")
            $location | Add-Member -MemberType NoteProperty -Name 'Latency' -Value 9999
        }
        
        $jobs = @()
        foreach ($location in $azureLocations)
        {
            $url = $location.Url
            $jobs += Start-Job -Name $location.DisplayName -ScriptBlock {
                $testUrl = $using:url
                
                try
                {
                    (Test-Port -ComputerName $testUrl -Port 443 -Count 4 -ErrorAction Stop| Measure-Object -Property ResponseTime -Average).Average
                }
                catch
                {
                    9999
                    #Write-Warning "$testUrl $($_.Exception.Message)"
                }
            }
        }
            
        Wait-LWLabJob -Job $jobs -NoDisplay
        foreach ($job in $jobs)
        {
            $result =  Receive-Job -Keep -Job $job
            ($azureLocations | Where-Object {$_.DisplayName -eq $job.Name}).Latency = $result
        }
        $jobs | Remove-Job

        Write-Verbose -Message 'DisplayName            Latency' 
        foreach ($location in $azureLocations)
        {
            Write-Verbose -Message "$($location.DisplayName.PadRight(20)): $($location.Latency)" 
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
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
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
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    if ($Name -notin $script:lab.AzureSettings.Locations.DisplayName)
    {
        Microsoft.PowerShell.Utility\Write-Error "Invalid location. Please specify one of the following locations: $($script:lab.AzureSettings.Locations.DisplayName -join ', ')"
        return
    }
	
    $script:lab.AzureSettings.DefaultLocation = $script:lab.AzureSettings.Locations | Where-Object DisplayName -eq $Name
	
    Write-LogFunctionExit
}

function Set-LabAzureDefaultStorageAccount
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    if (-not ($script:lab.AzureSettings.StorageAccounts | Where-Object StorageAccountName -eq $Name))
    {
        Microsoft.PowerShell.Utility\Write-Error "Invalid storage account. Please specify one of the following storage accounts: $($script:lab.AzureSettings.StorageAccounts.StorageAccountName -join ', ')"
        return
    }
	
    $script:lab.AzureSettings.DefaultStorageAccount = $script:lab.AzureSettings.StorageAccounts | Where-Object StorageAccountName -eq $Name
	
    Write-LogFunctionExit
}

function Get-LabAzureDefaultStorageAccount
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param ()
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    if (-not $Script:lab.AzureSettings.DefaultStorageAccount)
    {
        Write-Error 'The default storage account is not defined. Use Set-LabAzureDefaultStorageAccount to define it.'
        return
    }
	
    $Script:lab.AzureSettings.DefaultStorageAccount
	
    Write-LogFunctionExit
}

function New-LabAzureDefaultStorageAccount
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [string]$LocationName,
        [Parameter(Mandatory)]
        [string]$ResourceGroupName
    )
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $storageAccountName = "automatedlab$((1..8 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"

    $param = @{
        Name= $storageAccountName
        ResourceGroupName = $ResourceGroupName
        Tag = @{
            AutomatedLab = $script:lab.Name
            CreationTime = Get-Date	
        }
        Sku = 'Standard_LRS'
    }
	
    if ($LocationName)
    {
        $location = Get-LabAzureLocation -LocationName $LocationName -ErrorAction Stop
        $param.Add('Location', $location.DisplayName)
        Write-ScreenInfo -Message "Creating a new storage account named '$storageAccountName' for location '$($param.Location)'"
    }
	
    $result = New-AzureRmStorageAccount @param -ErrorAction Stop -WarningAction SilentlyContinue
	
    if ($result.ProvisioningState -ne 'Succeeded')
    {
        throw "Could not create storage account $storageAccountName : $($result.ProvisioningState)"
    }
	
    Write-ScreenInfo -Message  'Storage account now created'

    $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName

    $ALStorageAccount = [AutomatedLab.Azure.AzureRmStorageAccount]::Create($StorageAccount)
    $ALStorageAccount.StorageAccountKey = ($StorageAccount | Get-AzureRmStorageAccountKey)[0].Value
    $script:lab.AzureSettings.StorageAccounts.Add($ALStorageAccount)

    Write-Verbose "Added $($script:lab.AzureSettings.StorageAccounts.Count) storage accounts"
	
    Set-LabAzureDefaultStorageAccount -Name $storageAccountName
	
    Write-LogFunctionExit
}

function Get-LabAzureDefaultResourceGroup
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param ()
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $script:lab.AzureSettings.ResourceGroups | Where-Object ResourceGroupName -eq $script:lab.Name
	
    Write-LogFunctionExit
}

#TODO use keyvault -> New AzureProp defaultKeyVaultName
function Import-LabAzureCertificate
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param ()
	
    throw New-Object System.NotImplementedException
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $resourceGroup = Get-AzureRmResourceGroup -name (Get-LabAzureDefaultResourceGroup)
    $keyVault = Get-AzureRmKeyVault -VaultName (Get-LabAzureDefaultKeyVault) -ResourceGroupName $resourceGroup
    $temp = [System.IO.Path]::GetTempFileName()
	
    $cert = ($keyVault | Get-AzureKeyVaultCertificate).Data
	
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
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param ()
    throw New-Object System.NotImplementedException
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $certSubject = "CN=$($Script:lab.Name).cloudapp.net"
    $service = Get-LabAzureDefaultResourceGroup
    $cert = dir Cert:\LocalMachine\My | Where-Object Subject -eq $certSubject -ErrorAction SilentlyContinue
	
    if (-not $cert)
    {
        $temp = [System.IO.Path]::GetTempFileName()
	
        #not required as SSL is not used yet	
        #& 'C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Bin\makecert.exe' -r -pe -n $certSubject -b 01/01/2000 -e 01/01/2036 -eku 1.3.6.1.5.5.7.3.1, 1.3.6.1.5.5.7.3.2 -ss my -sr localMachine -sky exchange -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12 $temp
		
        certutil.exe -addstore -f Root $temp | Out-Null
		
        Remove-Item -Path $temp
		
        $cert = dir Cert:\LocalMachine\Root | Where-Object Subject -eq $certSubject
    }
	
    #not required as SSL is not used yet
    #$service | Add-AzureCertificate -CertToDeploy (Get-Item -Path "Cert:\LocalMachine\Root\$($cert.Thumbprint)")
}

#TODO use keyvault -> New AzureProp defaultKeyVaultName
function Get-LabAzureCertificate
{
    # .ExternalHelp AutomatedLab.Help.xml
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    [cmdletbinding()]
    param ()
    throw New-Object System.NotImplementedException
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $certSubject = "CN=$($Script:lab.Name).cloudapp.net"
	
    $cert = dir Cert:\LocalMachine\My | Where-Object Subject -eq $certSubject -ErrorAction SilentlyContinue
	
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

function New-LabAzureResourceGroup
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ResourceGroupNames,

        [Parameter(Mandatory, Position = 1)]
        [string]$LocationName,

        [switch]$PassThru
    )

    Write-LogFunctionEntry
    
    Update-LabAzureSettings	
    
    Write-Verbose "Creating the resource groups '$($ResourceGroupNames -join ', ')' for location '$LocationName'"

    $resourceGroups = Get-AzureRmResourceGroup

    foreach ($name in $ResourceGroupNames)
    {
        if ($resourceGroups | Where-Object ResourceGroupName -eq $name)
        {
            if(-not $script:lab.AzureSettings.ResourceGroups.ResourceGroupName.Contains($name))
            {
                $script:lab.AzureSettings.ResourceGroups.Add([AutomatedLab.Azure.AzureResourceGroup]::Create((Get-AzureRmResourceGroup -ResourceGroupName $name)))
                Write-Verbose "The resource group '$name' does already exist"
            }
            continue
        }

        $result = New-AzureRmResourceGroup -Name $name -Location $LocationName
        $script:lab.AzureSettings.ResourceGroups.Add([AutomatedLab.Azure.AzureResourceGroup]::Create((Get-AzureRmResourceGroup -ResourceGroupName $name)))
        if ($PassThru)
        {
            $result
        }

        Write-Verbose "Resource group '$name' created"
    }

    Write-LogFunctionExit
}

function Remove-LabAzureResourceGroup
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string[]]$ResourceGroupName,

        [switch]$Force
    )

    begin
    {
        Write-LogFunctionEntry
        
        Update-LabAzureSettings
        
        $resourceGroups = Get-LabAzureResourceGroup
    }

    process
    {
        Write-ScreenInfo -Message "Removing the Resource Group '$ResourceGroupName'" -Type Warning

        foreach ($name in $ResourceGroupName)
        {
            if ($resourceGroups.ResourceGroupName -contains $name)
            {
                Remove-AzureRmResourceGroup -Name $name -Force:$Force -WarningAction SilentlyContinue
                Write-Verbose "RG '$($name)' removed"
                
                $RgObject = $script:lab.AzureSettings.ResourceGroups | Where-Object ResourceGroupName -eq $name
                $Index =  $script:lab.AzureSettings.ResourceGroups.IndexOf($RgObject)
                $script:lab.AzureSettings.ResourceGroups.RemoveAt($Index)
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
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param (
        [Parameter(Position = 0)]
        [string[]]$ResourceGroupName
    )

    Write-LogFunctionEntry

    Update-LabAzureSettings

    $resourceGroups = $script:lab.AzureSettings.ResourceGroups
    
    if ($ResourceGroupName)
    {
        Write-Verbose "Getting the resource groups '$($ResourceGroupName -join ', ')'"
        $resourceGroups | Where-Object ResourceGroupName -in $ResourceGroupName
    }
    else
    {
        Write-Verbose 'Getting all resource groups'
        $resourceGroups
    }
    
    Write-LogFunctionExit
}

function Add-LabAzureProfile
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        [switch]$PassThru,
        [switch]$NoDisplay
    )
    
    Write-LogFunctionEntry
    
    $publishSettingFile = (Get-ChildItem -Path (Get-LabSourcesLocation) -Filter '*azurermsettings*' -Recurse | Sort-Object -Property TimeWritten | Select-Object -Last 1).FullName
    if (-not $NoDisplay)
    {
        Write-ScreenInfo -Message "Auto-detected and using publish setting file '$publishSettingFile'" -Type Info
    }

    if(-not $publishSettingFile)
    {
        return
    }

    if($NoDisplay)
    {
        $null = Add-LabAzureSubscription -Path $publishSettingFile -PassThru:$PassThru
    }
    else
    {
        Add-LabAzureSubscription -Path $publishSettingFile -PassThru:$PassThru
    }   
    
    Write-LogFunctionExit
}

function New-LabAzureLabSourcesStorage
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding()]
    param
    ()

    Write-LogFunctionEntry

    $ResourceGroupName = $script:Lab.AzureSettings.LabSourcesResourceGroupName
    $StorageAccountName = $script:Lab.AzureSettings.LabSourcesStorageAccountName

    if(-not $ResourceGroupName)
    {
        Write-Verbose 'AutomatedLab lab source resource group not set. Setting it to AutomatedLabSources'
        $ResourceGroupName = $script:Lab.AzureSettings.LabSourcesResourceGroupName = 'AutomatedLabSources'
    }


    $null = New-LabAzureResourceGroup -ResourceGroupNames $ResourceGroupName -LocationName (Get-LabAzureDefaultLocation)


    if(-not $StorageAccountName)
    {
        try
        {
            $StorageAccountName = (Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue | Where-Object StorageAccountName -like 'automatedlabsources?????')[0].StorageAccountName
        }
        catch{ }
        if(-not $StorageAccountName)
        {
            $StorageAccountName = "automatedlabsources$((1..5 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"
            Write-Verbose "Generated random storage account name $StorageAccountName"
        }
        else
        {
            Write-Verbose "Found and selected existing storage account $StorageAccountName"
        }
    }

    if(-not (Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName | Where-Object StorageAccountName -eq $StorageAccountName))
    {
        Write-Verbose "AutomatedLab lab source storage account '$StorageAccountName' does not exist. Creating it."
        New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location (Get-LabAzureDefaultLocation) -Kind Storage -SkuName Standard_LRS | Out-Null
    }

    $storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    $alStorageAccount = [AutomatedLab.Azure.AzureRmStorageAccount]::Create($storageAccount)
    $alStorageAccount.StorageAccountKey = ($storageAccount | Get-AzureRmStorageAccountKey)[0].Value


$script:Lab.AzureSettings.LabSourcesStorageAccountName = $StorageAccountName
if($script:Lab.AzureSettings.StorageAccounts -and ($script:Lab.AzureSettings.StorageAccounts.StorageAccountName).Contains($StorageAccountName))
{
	$existingGroup = $script:Lab.AzureSettings.StorageAccounts | Where-Object {$_.StorageAccountName -eq $StorageAccountName}
	if($existingGroup)
	{
		$i = $script:Lab.AzureSettings.StorageAccounts.IndexOf($existingGroup)
		$script:Lab.AzureSettings.StorageAccounts[$i] = $ALStorageAccount
	}
}
else
{
	$script:Lab.AzureSettings.StorageAccounts.Add($ALStorageAccount)
}

    if(-not (Get-AzureStorageShare -Name 'labsources' -Context $storageAccount.Context -ErrorAction SilentlyContinue))
    {
        Write-Verbose "AutomatedLab lab source file share 'labsources' does not exist. Creating it..."
        New-AzureStorageShare -Name 'labsources' -Context $storageAccount.Context | Out-Null
    }

    Write-Verbose "Successfully selected storage account $StorageAccountName in $ResourceGroupName and created labsources share"

    Write-LogFunctionExit
}

function Get-LabAzureLabSourcesStorage
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding()]
    param
    ()

    $StorageAccount = $script:Lab.AzureSettings.StorageAccounts | Where-Object {$_.ResourceGroupName -eq $script:Lab.AzureSettings.LabSourcesResourceGroupName -and $_.StorageAccountName -eq $script:Lab.AzureSettings.LabSourcesStorageAccountName}

    if(-not $StorageAccount)
    {
        $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $script:Lab.AzureSettings.LabSourcesResourceGroupName -Name $script:Lab.AzureSettings.LabSourcesStorageAccountName	
        $StorageAccount | Add-Member -MemberType NoteProperty -Name StorageAccountKey -Value ($storageAccount | Get-AzureRmStorageAccountKey)[0].Value
    }


    $StorageAccount |
    Add-Member -MemberType NoteProperty -Name 'Path' -Value "\\$($script:Lab.AzureSettings.LabSourcesStorageAccountName).file.core.windows.net\labsources" -Force

    $StorageAccount

}

function Remove-LabAzureLabSourcesStorage
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding()]
    param
    ()

    Remove-LabAzureResourceGroup -ResourceGroupName $script:Lab.AzureSettings.LabSourcesResourceGroupName -Force
}

function Sync-LabAzureLabSources
{

# .ExternalHelp AutomatedLab.Help.xml
[CmdletBinding()]
param
(
	[switch]$SkipIsos,
	[int]$MaxFileSizeInMb
)

    Write-LogFunctionExit

    # Retrieve storage context
    $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $script:Lab.AzureSettings.LabSourcesResourceGroupName -Name $script:Lab.AzureSettings.LabSourcesStorageAccountName
    $AccountKey = ($StorageAccount | Get-AzureRmStorageAccountKey)[0].Value

    Unblock-LabSources -Path (Get-LabSourcesLocationInternal -Local)


# Create the empty folders first
foreach($Folder in (Get-ChildItem -Path (Get-LabSourcesLocationInternal -Local) -Recurse -Directory))
{
	if($SkipIsos -and $Folder.Name -eq 'Isos')
	{
		continue
	}

    $err = $Null
	$FolderName = $Folder.FullName.Replace("$(Get-LabSourcesLocationInternal -Local)\",'')

	# Use an error variable and check the HttpStatusCode since there is no cmdlet to get or test a StorageDirectory
	$null = New-AzureStorageDirectory -Share (Get-AzureStorageShare -Name labsources -Context $StorageAccount.Context) -Path $FolderName -ErrorVariable err -ErrorAction SilentlyContinue
	Write-Verbose "Created directory $FolderName in labsources"
    if($err)
    {
        $err = $Null
        $FolderName = $Folder.FullName.Replace("$(Get-LabSourcesLocationInternal -Local)\",'')

        # Use an error variable and check the HttpStatusCode since there is no cmdlet to get or test a StorageDirectory
        $null = New-AzureStorageDirectory -Share (Get-AzureStorageShare -Name labsources -Context $StorageAccount.Context) -Path $FolderName -ErrorVariable err -ErrorAction SilentlyContinue
        Write-Verbose "Created directory $FolderName in labsources"
        if($err)
        {
            if($err[0].Exception.RequestInformation.HttpStatusCode -ne 409)
            {
                throw "An error ocurred during file upload: $($err[0].Exception.Message)"
            }
        }
    }


# Sync the lab sources
foreach($File in (Get-ChildItem -Path (Get-LabSourcesLocationInternal -Local) -Recurse -File))
{
	if($SkipIsos -and $File.Directory.Name -eq 'Isos')
	{
		Write-Verbose "SkipIsos is true, skipping $($File.Name)"
		continue
	}

	if($MaxFileSizeInMb -and $File.Length/1MB -ge $MaxFileSizeInMb)
	{
		Write-Verbose "MaxFileSize is $MaxFileSizeInMb mb, skipping $($File.Name)"
		continue
	}

	# Check if file is an OS ISO and skip
	if($File.Extension -eq '.iso')
	{
		$IsoDefinition = Get-LabIsoImageDefinition | Where-Object {$_.Path -EQ $File.FullName -and $_.IsOperatingSystem}

		if($IsoDefinition)
		{
			Write-Verbose "Skipping OS ISO $($File.FullName)"
			continue
		}
	}

	$FileName = $File.FullName.Replace("$(Get-LabSourcesLocationInternal -Local)\",'')

	$AzureFile = Get-AzureStorageFile -Share (Get-AzureStorageShare -Name labsources -Context $StorageAccount.Context) -Path $FileName -ErrorAction SilentlyContinue
	if($AzureFile)
	{
		$AzureHash = $AzureFile.Properties.ContentMD5
		$FileHash = (Get-FileHash -Path $File.FullName -Algorithm MD5).Hash
		Write-Verbose "$FileName already exists in Azure. Source hash is $FileHash and Azure hash is $AzureHash"
	}

	if(-not $AzureFile -or ($AzureFile -and $FileHash -ne $AzureHash))
	{
		$null = Set-AzureStorageFileContent -Share (Get-AzureStorageShare -Name labsources -Context $StorageAccount.Context) -Source $File.FullName -Path $FileName -ErrorAction SilentlyContinue -Force
		Write-Verbose "Azure file $FileName successfully uploaded. Generating file hash..."
	}

	# Try to set the file hash
	$UploadedFile = Get-AzureStorageFile -Share (Get-AzureStorageShare -Name labsources -Context $StorageAccount.Context) -Path $FileName -ErrorAction SilentlyContinue
	$UploadedFile.Properties.ContentMD5 = (Get-FileHash -Path $File.FullName -Algorithm MD5).Hash
	$ApiResponse = $UploadedFile.SetPropertiesAsync()
	if(-not $ApiResponse.Status -eq "RanToCompletion")
	{
		Write-Warning "Could not generate MD5 hash for file $FileName. Status was $($ApiResponse.Status)"
		continue
	}

	Write-Verbose "Azure file $FileName successfully uploaded and hash generated"

	Write-LogFunctionExit
}
}