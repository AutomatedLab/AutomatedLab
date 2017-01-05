$PSDefaultParameterValues = @{
    '*-Azure*:Verbose' = $false
    '*-Azure*:Warning' = $false
    'Import-Module:Verbose' = $false
}

function Update-LabAzureSettings
{
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
            $choice = Read-Host -Prompt "Resource group '$rgName' already exists. Please enter 'y' to use this resource group, 'r' to recreate the resource group or any other key to cancel"

            switch -Regex ($choice)
            {
                'y' { $createResourceGroup = $false; break }
                'r' { Remove-AzureRmResourceGroup -Name $rgName -Force; break }
                default { throw "Resource group $rgName already exists. User cancelled the operation" }
            }
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
    $script:lab.AzureSettings.StorageAccounts = [AutomatedLab.Azure.AzureRmStorageAccount]::Create($storageAccounts)
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
    Write-Verbose "Added $($script:lab.AzureSettings.RoleSizes.Count) vm size information"
	
    $script:lab.AzureSettings.VNetConfig = (Get-AzureRmVirtualNetwork) | ConvertTo-Json
    Write-Verbose 'Added virtual network configuration'

    if ($global:cacheVmImages)
    {
        Write-ScreenInfo -Message 'Querying available operating system images (using cache)' -Type Info
        $vmImages = $global:cacheVmImages
    }
    else
    {
        Write-ScreenInfo -Message 'Querying available operating system images' -Type Info
        $vmImages = Get-AzureRmVMImagePublisher -Location $DefaultLocationName | Where-Object PublisherName -Like '*Microsoft*' | Get-AzureRmVMImageOffer | Get-AzureRmVMImageSku | Get-AzureRmVMImage | Group-Object Skus | foreach{$_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1}
        $global:cacheVmImages = $vmImages
    }

    $script:lab.AzureSettings.VmImages = [AutomatedLab.Azure.AzureOSImage]::Create($vmImages)
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
    param ()
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $script:lab.AzureSettings.Subscriptions
	
    Write-LogFunctionExit
}

function Get-LabAzureDefaultSubscription
{
    param ()
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $script:lab.AzureSettings.DefaultSubscription
	
    Write-LogFunctionExit
}

function Get-LabAzureLocation
{
    [cmdletBinding()]
    param (
        [string]$LocationName,

        [switch]$List
    )
	
    Write-LogFunctionEntry
	
    #Update-LabAzureSettings
	
    Import-Module -Name Azure

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
    $script:lab.AzureSettings.StorageAccounts = [AutomatedLab.Azure.AzureRmStorageAccount]::Create((Get-AzureRmStorageAccount -ErrorAction SilentlyContinue))
    Write-Verbose "Added $($script:lab.AzureSettings.StorageAccounts.Count) storage accounts"
	
    Set-LabAzureDefaultStorageAccount -Name $storageAccountName
	
    Write-LogFunctionExit
}

function Get-LabAzureDefaultResourceGroup
{
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
            $script:lab.AzureSettings.ResourceGroups.Add([AutomatedLab.Azure.AzureResourceGroup]::Create((Get-AzureRmResourceGroup -ResourceGroupName $name)))
            Write-Warning "The resource group '$name' does already exist"
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
        Write-ScreenInfo -Message "Removing the rg '$ResourceGroupName'" -Type Warning

        foreach ($name in $ResourceGroupName)
        {
            if ($resourceGroups.ResourceGroupNames -contains $name)
            {
                Remove-AzureRmResourceGroup -Name $name -Force:$Force -WarningAction SilentlyContinue
                Write-Verbose "RG '$($name)' removed"
                
                $script:lab.AzureSettings.ResourceGroups.Remove(($script:lab.AzureSettings.ResourceGroups | Where-Object ResourceGroupName -eq $name))
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
    [cmdletbinding()]
    param (
        [Parameter(Position = 0)]
        [string[]]$ResourceGroupName
    )

    Write-LogFunctionEntry

    Update-LabAzureSettings

    $resourceGroups = $script:lab.AzureSettings.ResourceGroups | Where-Object { $_.ResourceGroupName -eq $Script:lab.Name }
    
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