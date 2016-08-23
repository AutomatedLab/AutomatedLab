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
		
        [switch]$PassThru
    )
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
    
    if (-not $Path)
    {
        $Path = (Get-ChildItem -Path (Get-LabSourcesLocation) -Filter '*.publishsettings' -Recurse | Sort-Object -Property TimeWritten | Select-Object -Last 1).FullName
        
        Write-ScreenInfo -Message "No publish setting file specified. Auto-detected and using publish setting file '$Path'" -Type Warning
    }
    
    if (-not $script:lab)
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabDefaultOperatingSystem.'
    }
 
    if (-not (Test-Path -Path $Path))
    {
        throw "The subscription file '$Path' could not be found"
    }
	
    #This needs to be loaded manually to import the required DLLs
    $minimumAzureModuleVersion = $MyInvocation.MyCommand.Module.PrivateData.MinimumAzureModuleVersion
    if (-not (Get-Module -Name Azure -ListAvailable | Where-Object Version -ge $minimumAzureModuleVersion))
    {
        throw "The Azure PowerShell module version $($minimumAzureModuleVersion) or greater is not available. Please download it from 'http://azure.microsoft.com/en-us/downloads/'"
    }

    try
    {
        Import-Module -Name Azure -Global -ErrorAction Stop
    }
    catch
    {
        throw $_.Exception
    }
	
    Write-ScreenInfo -Message 'Adding Azure subscription data' -Type Info -TaskStart
    
    Update-LabAzureSettings
    if (-not $script:lab.AzureSettings)
    {
        $script:lab.AzureSettings = New-Object AutomatedLab.AzureSettings
    }

    $script:lab.AzureSettings.SubscriptionFileContent = Get-Content -Path $Path
    $script:lab.AzureSettings.DefaultRoleSize = $MyInvocation.MyCommand.Module.PrivateData.DefaultAzureRoleSize
    
    #GetEnumerator is required as otherwise the list is not expanded
    $Subscriptions = (Import-AzurePublishSettingsFile -PublishSettingsFile $Path -ErrorAction Stop).GetEnumerator() | ForEach-Object { Get-AzureSubscription -SubscriptionId $_.Id[0] }
    $script:lab.AzureSettings.Subscriptions = [AutomatedLab.Azure.AzureSubscription]::Create($Subscriptions)
    Write-Verbose "Added $($script:lab.AzureSettings.Subscriptions.Count) subscriptions"

    #select subscription
    if ($SubscriptionName -and -not ($script:lab.AzureSettings.Subscriptions | Where-Object SubscriptionName -eq $SubscriptionName))
    {
        throw "A subscription named '$SubscriptionName' cannot be found. Make sure you specify the right subscription name or let AutomatedLab choose on by not defining a subscription name"
    }

    if (-not $SubscriptionName)
    {
        $SubscriptionName = $script:lab.AzureSettings.Subscriptions[0].SubscriptionName
    }

    Write-ScreenInfo -Message "Using Azure Subscription '$SubscriptionName'" -Type Info
    $selectedSubscription = Select-AzureSubscription -SubscriptionName $SubscriptionName -PassThru
    $script:lab.AzureSettings.DefaultSubscription = [AutomatedLab.Azure.AzureSubscription]::Create($selectedSubscription)
    Write-Verbose "Azure subscription '$SubscriptionName' selected as default"

    $locations = Get-AzureLocation
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

    $services = Get-AzureService 
    $script:lab.AzureSettings.Services = [AutomatedLab.Azure.AzureService]::Create($services)
    Write-Verbose "Added $($script:lab.AzureSettings.Services.Count) services"

    $storageAccounts = Get-AzureStorageAccount -WarningAction SilentlyContinue
    $script:lab.AzureSettings.StorageAccounts = [AutomatedLab.Azure.AzureStorageService]::Create($storageAccounts)
    Write-Verbose "Added $($script:lab.AzureSettings.StorageAccounts.Count) storage accounts"

    if ($global:cacheAzureRoleSizes)
    {
        Write-ScreenInfo -Message "Querying available role sizes for Azure location '$DefaultLocationName' (using cache)" -Type Info
        $roleSizes = $global:cacheAzureRoleSizes | Where-Object { $_.InstanceSize -in (Get-LabAzureDefaultLocation).VirtualMachineRoleSizes }
    }
    else
    {
        Write-ScreenInfo -Message "Querying available role sizes for Azure location '$DefaultLocationName'" -Type Info
        $roleSizes = Get-AzureRoleSize | Where-Object { $_.InstanceSize -in (Get-LabAzureDefaultLocation).VirtualMachineRoleSizes }
        $global:cacheAzureRoleSizes = $roleSizes
    }

    $script:lab.AzureSettings.RoleSizes = [AutomatedLab.Azure.AzureRoleSize]::Create($roleSizes)
    Write-Verbose "Added $($script:lab.AzureSettings.RoleSizes.Count) role size information"
	
    $script:lab.AzureSettings.VNetConfig = (Get-AzureVNetConfig).XMLConfiguration
    Write-Verbose 'Added virtual network configuration'

    if ($global:cacheVmImages)
    {
        Write-ScreenInfo -Message 'Querying available operating system images (using cache)' -Type Info
        $vmImages = $global:cacheVmImages | Group-Object -Property ImageFamily | ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 }
    }
    else
    {
        Write-ScreenInfo -Message 'Querying available operating system images' -Type Info
        $vmImages = Get-AzureVMImage | Group-Object -Property ImageFamily | ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 }
        $global:cacheVmImages = $vmImages
    }

    $script:lab.AzureSettings.VmImages = [AutomatedLab.Azure.AzureOSImage]::Create($vmImages)
    Write-Verbose "Added $($script:lab.AzureSettings.VmImages.Count) virtual machine images"

    $vms = Get-AzureVM -ServiceName $script:lab.Name -WarningAction SilentlyContinue
    $script:lab.AzureSettings.VirtualMachines = [AutomatedLab.Azure.AzureVirtualMachine]::Create($vms)
    Write-Verbose "Added $($script:lab.AzureSettings.VirtualMachines.Count) virtual machines"

    #$script:lab.AzureSettings.DefaultStorageAccount cannot be set when creating the definitions but is during the import process
    if (-not $script:lab.AzureSettings.DefaultStorageAccount)
    {
        Write-ScreenInfo -Message 'No default storage account exist. Determining storage account now' -Type Info
        if (-not $DefaultStorageAccountName)
        {
            $DefaultStorageAccountName = ($script:lab.AzureSettings.StorageAccounts | Where-Object StorageAccountName -like 'automatedlab????????').StorageAccountName
        }

        if (-not $DefaultStorageAccountName)
        {
            Write-ScreenInfo -Message 'No storage account for AutomatedLab found. Creating a storage account now'
            New-LabAzureDefaultStorageAccount -LocationName $DefaultLocationName
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
        Write-Verbose "Mapping storage account '$((Get-LabAzureDefaultStorageAccount).StorageAccountName)' to subscription '$((Get-LabAzureDefaultSubscription).SubscriptionName)'"
        Set-AzureSubscription -CurrentStorageAccountName (Get-LabAzureDefaultStorageAccount).StorageAccountName -SubscriptionId (Get-LabAzureDefaultSubscription).SubscriptionId
    }
    
    if (-not (Get-LabAzureDefaultService -ErrorAction SilentlyContinue))
    {
        New-LabAzureService -ServiceName (Get-LabDefinition).Name -LocationName $DefaultLocationName
    }
    
    #Add all additional Azure Services if configured
    $cloudServiceNames = (Get-LabMachine).AzureProperties.CloudServiceName | Select-Object -Unique
    if ($cloudServiceNames)
    {
        New-LabAzureService -ServiceName $cloudServiceNames -LocationName $lab.AzureSettings.DefaultLocation -ErrorAction Stop
    }

    Write-ScreenInfo -Message "Azure default cloud service name will be '$($script:lab.Name)'"
    
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

function Remove-LabAzureSubscription
{
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $script:lab.AzureSettings.Subscription = $null
    Get-AzureSubscription | Remove-AzureSubscription -Confirm:$false -Force -WarningAction SilentlyContinue
	
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

    $azureLocations = Get-AzureLocation
    
    if ($LocationName)
    {
        if ($LocationName -notin ($azureLocations.Name))
        {
            Write-Error "Invalid location. Please specify one of the following locations: ""'$($azureLocations.Name -join ''', ''')"
            return
        }
		
        $azureLocations | Where-Object Name -eq $LocationName
    }
    else
    {
        if ((Get-Lab -ErrorAction SilentlyContinue) -and (-not $list))
        {
            #if lab already exists, use the location used when this was deployed to create lab stickyness
            return (Get-Lab).AzureSettings.DefaultLocation.Name
        }
        
        $urls = @{
            'Central US'='speedtestcus.blob.core.windows.net'
            'South Central US'='speedtestscus.blob.core.windows.net'
            'East US'='speedtesteus.blob.core.windows.net'
            'West Europe'='speedtestwe.blob.core.windows.net'
            'North Europe'='speedtestne.blob.core.windows.net'
            'Southeast Asia'='speedtestsea.blob.core.windows.net'
            'East Asia'='speedtestea.blob.core.windows.net'
        }
        
        foreach ($location in $azureLocations)
        {
            $location | Add-Member -MemberType NoteProperty -Name 'Url'     -Value ($urls."$($location.Name)")
            $location | Add-Member -MemberType NoteProperty -Name 'Latency' -Value 9999
        }
        
        $jobs = @()
        foreach ($location in $azureLocations)
        {
            $url = $location.Url
            $jobs += Start-Job -Name $location.Name -ScriptBlock {
                $testUrl = $using:url
                
                (Test-Port -ComputerName $using:url -Port 443 -Count 4 | Measure-Object -Property ResponseTime -Average).Average
            }
        }
            
        Wait-LWLabJob -Job $jobs -NoDisplay
        foreach ($job in $jobs)
        {
            $result =  Receive-Job -Keep -Job $job
            ($azureLocations | Where-Object {$_.Name -eq $job.Name}).Latency = $result
        }
        $jobs | Remove-Job

        Write-Verbose -Message 'Name            Latency' 
        foreach ($location in $azureLocations)
        {
            Write-Verbose -Message "$($location.Name.PadRight(20)): $($location.Latency)" 
        }

        if ($List)
        {
            $azureLocations | Sort-Object -Property Latency | Format-Table Name, Latency
        }
        else
        {
            $azureLocations | Sort-Object -Property Latency | Select-Object -First 1 | Select-Object -ExpandProperty Name
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
	
    if ($Name -notin $script:lab.AzureSettings.Locations.Name)
    {
        Microsoft.PowerShell.Utility\Write-Error "Invalid location. Please specify one of the following locations: $($script:lab.AzureSettings.Locations.Name -join ', ')"
        return
    }
	
    $script:lab.AzureSettings.DefaultLocation = $script:lab.AzureSettings.Locations | Where-Object Name -eq $Name
	
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
        [string]$LocationName
    )
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $storageAccountName = "automatedlab$((1..8 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"

    $param = @{ }
    $param.Add('StorageAccountName', $storageAccountName)
    $param.Add('Description', "Auto created by AutomatedLab at $(Get-Date)")
	
    if ($LocationName)
    {
        $location = Get-LabAzureLocation -LocationName $LocationName -ErrorAction Stop
        $param.Add('Location', $location.Name)
        Write-ScreenInfo -Message "Creating a new storage account named '$($param.StorageAccountName)' for location '$($param.Location)'"
    }
	
    $result = New-AzureStorageAccount @param -ErrorAction Stop -WarningAction SilentlyContinue
	
    if ($result.OperationStatus -ne 'Succeeded')
    {
        throw "Could not create storage account: $($result.OperationStatus)"
    }
	
    Write-ScreenInfo -Message  'Storage account now created'
    $script:lab.AzureSettings.StorageAccounts = [AutomatedLab.Azure.AzureStorageService]::Create((Get-AzureStorageAccount -ErrorAction SilentlyContinue))
    Write-Verbose "Added $($script:lab.AzureSettings.StorageAccounts.Count) storage accounts"
	
    Set-LabAzureDefaultStorageAccount -Name $param.StorageAccountName
	
    Write-LogFunctionExit
}

function Get-LabAzureDefaultService
{
    [cmdletbinding()]
    param ()
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $script:lab.AzureSettings.Services | Where-Object ServiceName -eq $script:lab.Name
	
    Write-LogFunctionExit
}

function Import-LabAzureCertificate
{
    [cmdletbinding()]
    param ()
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $service = Get-LabAzureDefaultService
    $temp = [System.IO.Path]::GetTempFileName()
	
    $cert = ($service | Get-AzureCertificate).Data
	
    if ($cert)
    {
        $cert | Out-File -FilePath $temp
        certutil -addstore -f Root $temp | Out-Null
		
        Remove-Item -Path $temp
        Write-LogFunctionExit
    }
    else
    {
        Write-LogFunctionExitWithError -Message "Could not receive certificate for cloud serivice '$($service.ServiceName)'"
    }
}

function New-LabAzureCertificate
{
    [cmdletbinding()]
    param ()
	
    Write-LogFunctionEntry
	
    Update-LabAzureSettings
	
    $certSubject = "CN=$($Script:lab.Name).cloudapp.net"
    $service = Get-LabAzureDefaultService
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

function Get-LabAzureCertificate
{
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    [cmdletbinding()]
    param ()
	
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

function New-LabAzureService
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ServiceName,

        [Parameter(Mandatory, Position = 1)]
        [string]$LocationName,

        [switch]$PassThru
    )

    Write-LogFunctionEntry
    
    Update-LabAzureSettings	
    
    Write-Verbose "Creating the services '$($ServiceName -join ', ')' for location '$LocationName'"

    $existingServices = Get-AzureService

    foreach ($name in $ServiceName)
    {
        if ($existingServices | Where-Object ServiceName -eq $name)
        {
            $script:lab.AzureSettings.Services.Add([AutomatedLab.Azure.AzureService]::Create((Get-AzureService -ServiceName $name)))
            Write-Warning "The service '$name' does already exist"
            continue
        }

        $result = New-AzureService -ServiceName $name -Location $LocationName
        $script:lab.AzureSettings.Services.Add([AutomatedLab.Azure.AzureService]::Create((Get-AzureService -ServiceName $name)))
        if ($PassThru)
        {
            $result
        }

        Write-Verbose "Service '$name' created"
    }

    Write-LogFunctionExit
}

function Remove-LabAzureService
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string[]]$ServiceName,

        [switch]$Force
    )

    begin
    {
        Write-LogFunctionEntry
        
        Update-LabAzureSettings
        
        $services = Get-LabAzureService
    }

    process
    {
        Write-ScreenInfo -Message "Removing the service '$ServiceName'" -Type Warning

        foreach ($name in $ServiceName)
        {
            if ($services.ServiceName -contains $name)
            {
                Remove-AzureService -ServiceName $name -Force:$Force -WarningAction SilentlyContinue
                Write-Verbose "Service '$($name)' removed"
                
                $script:lab.AzureSettings.Services.Remove(($script:lab.AzureSettings.Services | Where-Object ServiceName -eq $name))
            }
            else
            {
                Write-ScreenInfo -Message "Service '$name' could not be found" -Type Error
            }
        }
    }

    end
    {
        Write-LogFunctionExit
    }
}

function Stop-LabAzureService
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string[]]$ServiceName
    )

    begin
    {
        Write-LogFunctionEntry

        $services = Get-LabAzureService
    }

    process
    {
        Write-Verbose "Stopping the services '$ServiceName'"

        foreach ($name in $ServiceName)
        {
            if ($services.ServiceName -contains $name)
            {
                Stop-AzureService -ServiceName $name
                Write-Verbose "Service '$($name)' stopped"
            }
            else
            {
                Write-Error "Service '$name' could not be found"
            }
        }
    }

    end
    {
        Write-LogFunctionExit
    }
}

function Start-LabAzureService
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string[]]$ServiceName
    )

    begin
    {
        Write-LogFunctionEntry

        $services = Get-LabAzureService
    }

    process
    {
        Write-Verbose "Starting the services '$ServiceName'"

        foreach ($name in $ServiceName)
        {
            if ($services.ServiceName -contains $name)
            {
                Start-AzureService -ServiceName $name
                Write-Verbose "Service '$($name)' started"
            }
            else
            {
                Write-Error "Service '$name' could not be found"
            }
        }
    }

    end
    {
        Write-LogFunctionExit
    }
}

function Get-LabAzureService
{
    [cmdletbinding()]
    param (
        [Parameter(Position = 0)]
        [string[]]$ServiceName
    )

    Write-LogFunctionEntry

    Update-LabAzureSettings

    $labServicesNames = $script:lab.Machines.AzureProperties.CloudServiceName | Select-Object -Unique
    $services = $script:lab.AzureSettings.Services | Where-Object { $_.ServiceName -eq $Script:lab.Name -or $_.ServiceName -in $labServicesNames }
    
    if ($ServiceName)
    {
        Write-Verbose "Getting the services '$($ServiceName -join ', ')'"
        $services | Where-Object ServiceName -in $ServiceName
    }
    else
    {
        Write-Verbose 'Getting all services'
        $services
    }
    
    Write-LogFunctionExit
}

function Add-LabAzurePublishSettingFile
{
    [cmdletbinding()]
    param
    (
        [switch]$NoDisplay
    )
    
    Write-LogFunctionEntry
    
    $publishSettingFile = (Get-ChildItem -Path (Get-LabSourcesLocation) -Filter '*ublishsetting*' -Recurse | Sort-Object -Property TimeWritten | Select-Object -Last 1).FullName
    if (-not $NoDisplay)
    {
        Write-ScreenInfo -Message "No publish setting file specified. Auto-detected and using publish setting file '$publishSettingFile'" -Type Warning
    }
    Add-LabAzureSubscription -Path $publishSettingFile
    
    Write-LogFunctionExit
}