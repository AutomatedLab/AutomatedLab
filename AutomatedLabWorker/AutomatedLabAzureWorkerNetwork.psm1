$PSDefaultParameterValues = @{
    '*-Azure*:Verbose' = $false
    '*-Azure*:Warning' = $false
    'Import-Module:Verbose' = $false
}

#region New-LWAzureNetworkSwitch
function New-LWAzureNetworkSwitch
{
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.VirtualNetwork[]]$VirtualNetwork,
		
        [switch]$PassThru
    )
	
    Write-LogFunctionEntry
	
    Import-LabXmlAzureNetworkConfig

    foreach ($network in $VirtualNetwork)
    {
        Write-ScreenInfo -Message "Creating Azure virtual network '$($network.Name)'" -TaskStart
        
        if ($network.DnsServers)
        {
            New-LabXmlAzureNetworkDnsServer -DnsServer $network.DnsServers
        }

        New-LabXmlAzureNetworkLocalNetwork -Name "$($network.Name)_local" -AddressSpace $network.AddressSpace -VPNGatewayAddress 1.1.1.1

        New-LabXmlAzureNetworkVirtualNetworkSite -Name $network.Name -Location $network.LocationName
        Add-LabXmlAzureNetworkVirtualNetworkSiteAddressSpace -AddressPrefix $network.AddressSpace -VirtualNetworkSiteName $network.Name        
	
        if (-not $network.Subnets)
        {
            #if this subnet connected to other VNets, there need to be place for the gateway subnet. Hence the subnets needs to be smaller
            if ($network.ConnectToVnets)
            {
                $newAddressSpace = [AutomatedLab.IPNetwork]"$($network.AddressSpace.Network)/$($network.AddressSpace.Cidr + 1)"
                Add-LabXmlAzureNetworkVirtualNetworkSiteSubnet -Name "$($network.Name)-1" -AddressPrefix $newAddressSpace -VirtualNetworkSiteName $network.Name

                $gatewayAddressSpace = [AutomatedLab.IPNetwork]"$($network.AddressSpace.LastUsable.Increment())/29"
                Add-LabXmlAzureNetworkVirtualNetworkSiteSubnet -Name GatewaySubnet -AddressPrefix $gatewayAddressSpace -VirtualNetworkSiteName $network.Name

                foreach ($connectToVnet in $network.ConnectToVnets)
                {
                    Add-LabXmlAzureNetworkVirtualNetworkSiteGateway -VirtualNetworkSiteName $network.Name -LocalNetworkName "$($connectToVnet)_local"
                }
            }
            else
            {
                Add-LabXmlAzureNetworkVirtualNetworkSiteSubnet -Name "$($network.Name)-1" -AddressPrefix $network.AddressSpace -VirtualNetworkSiteName $network.Name
            }
        }
        else
        {
            foreach ($subnet in $network.Subnets)
            {
                Add-LabXmlAzureNetworkVirtualNetworkSiteSubnet -Name $subnet.Name -AddressPrefix "$($subnet.Address)/$($subnet.Prefix)" -VirtualNetworkSiteName $network.Name
            }
        }

        if ($network.DnsServers)
        {
            Add-LabXmlAzureNetworkVirtualNetworkSiteDnsServer -VirtualNetworkSiteName $network.Name -DnsServer $network.DnsServers
        }
        
        Write-ScreenInfo -Message "Done" -TaskEnd
    }
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    Save-LabXmlAzureNetworkConfig -Path $tempFile

    #for debugging
    Copy-Item -Path $tempFile -Destination (Join-Path -Path (Get-Lab).LabPath -ChildPath AzureNetworkConfig.Xml)
	
    $result = Set-AzureVNetConfig -ConfigurationPath $tempFile -ErrorAction Stop
	
    Remove-Item -Path $tempFile
	
    $lab.AzureSettings.VnetConfig = (Get-AzureVNetConfig).XMLConfiguration
	
    Write-ScreenInfo -Message "Done"


    $lab = Get-Lab
    $createGatewaysJobsStarted = $false
    foreach ($network in $VirtualNetwork)
    {
        if (-not $network.ConnectToVnets)
        {
            Write-Verbose "The network '$($network.Name)' is not connected hence no need for creating a gateway"
        }
        else
        {
            if (-not $createGatewaysJobsStarted)
            {
                Write-ScreenInfo -Message 'Starting jobs to create dynamic gateways'
                $createGatewaysJobsStarted = $true
            }
            
            Write-Verbose "Scheduling gateway creation for network '$($network.Name)'"
            Start-Job -Name "NewAzureVNetGateway ($($network.Name))" -ScriptBlock {
                param(
                    [Parameter(Mandatory)]
                    [string]$SubscriptionName,
        
                    [Parameter(Mandatory)]
                    [string]$VirtualNetworkSiteName
                )

                Import-Module -Name Azure
                Write-Verbose "Selecting Azure Subscription '$SubscriptionName'"
                Select-AzureSubscription -Name $SubscriptionName

                Write-Verbose "Creating Gateway for virtual network site '$VirtualNetworkSiteName'"
                New-AzureVNetGateway -VNetName $VirtualNetworkSiteName -GatewayType DynamicRouting
            } -ArgumentList $lab.AzureSettings.DefaultSubscription, $network.Name | Out-Null
            #later AL has to wait for these jobs, otherwise connectivity between the VNets is not working
            #also after that has finished, the public VIP addresses need to be set for the local networks
        }
    }    
	
    Write-LogFunctionExit
}
#endregion New-LWNetworkSwitch

#region Wait-LWAzureGatewayJob
function Wait-LWAzureGatewayJob
{
    [cmdletBinding()]

    param()

    $lab = Get-Lab
    
    $jobs = Get-Job -Name NewAzureVNetGateway*
    Write-Verbose "Waiting for $($jobs.Count) NewAzureVNetGateway* jobs"
    Wait-LWLabJob -Job $jobs -Timeout 45 -NoDisplay
    Write-Verbose 'NewAzureVNetGateway* finished'

    $gateways = ([object[]](AzureVirtualNetworkGateway)) | Where-Object State -eq Provisioned
    Write-Verbose "Azure knows about $($gateways.Count) provisioned gateways in subscription '$lab.AzureSettings.DefaultSubscription.SubscriptionName'"
    $vnetSites = Get-AzureVNetSite
    Write-Verbose "Azure knows about $($vnetSites.Count) Virtual Network Sites"

	Write-Verbose 'Waiting until all gateways are provisioned...'
    
    while (Compare-Object -ReferenceObject ($vnetSites.ID) -DifferenceObject (([object[]](Get-AzureVirtualNetworkGateway)) | Where-Object State -eq Provisioned).GateWayID | Where-Object {$_.SideIndicator -eq '=>'})
    {
        Write-Verbose 'Still waiting until all gateways are provisioned...'
        Start-Sleep -Seconds 10
        $gateways = ([object[]](Get-AzureVirtualNetworkGateway)) | Where-Object State -eq Provisioned
    }
    Write-Verbose '...all gateways are provisioned now'

	Write-Verbose 'Waiting until public IP addresses are visible on all gateways...'
    while ($gateways.VIPAddress.Count -ne $gateways.Count)
    {
        Write-Verbose 'Still waiting until public IP addresses are visible on all gateways...'
        Start-Sleep -Seconds 10
        $gateways = ([object[]](AzureVirtualNetworkGateway)) | Where-Object State -eq Provisioned
    }
    Write-Verbose '...public IP addresses are visible on all gateways'

    Import-LabXmlAzureNetworkConfig

    Write-Verbose 'Setting Local Network VPN Gateway Address'
    foreach ($network in $lab.VirtualNetworks)
    {        
        $vnetSite = $vnetSites | Where-Object Name -eq $network.Name
        $gateway = $gateways | Where-Object VnetId -eq $vnetSite.Id
        $localNetName = "$($network.Name)_local"
        
        Set-LabXmlAzureNetworkLocalNetwork -Name $localNetName -VPNGatewayAddress $gateway.VIPAddress | Out-Null
        Write-Verbose "Set-LabXmlAzureNetworkLocalNetwork -Name $localNetName -VPNGatewayAddress $($gateway.VIPAddress) | Out-Null"
    }
    Write-Verbose 'Finished setting Local Network VPN Gateway Address'

    Set-LabXmlAzureNetworkConfig
    Write-Verbose 'VNet config saved to Azure'

    Write-Verbose 'Setting Azure VNet Gateway Keys'
    foreach ($network in $lab.VirtualNetworks)
    {
        foreach ($localNet in $network.ConnectToVnets)
        {
            Set-AzureVNetGatewayKey -VNetName $network.Name -LocalNetworkSiteName "$($localNet)_local" -SharedKey A1b2C3D4 | Out-Null
            Write-Verbose "Set-AzureVNetGatewayKey -VNetName $($network.Name) -LocalNetworkSiteName $($localNet)_local -SharedKey A1b2C3D4 | Out-Null"
        }
    }
    Write-Verbose 'Finished setting Azure VNet Gateway Keys'
}
#endregion Wait-LWAzureGatewayJob

#region Remove-LWNetworkSwitch
function Remove-LWAzureNetworkSwitch
{
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.VirtualNetwork[]]$VirtualNetwork
    )
	
    Write-LogFunctionEntry

    $lab = Get-Lab
	
    Write-ScreenInfo -Message "Removing virtual network '$VirtualNetwork'" -Type Warning
    Import-LabXmlAzureNetworkConfig
	
    if (-not (Get-LabXmlAzureNetworkVirtualNetworkSite -Name $name))
    {
        Write-ScreenInfo -Message "The network '$name' does not exist in Azure" -Type Warning
        return
    }

    foreach ($network in $VirtualNetwork)
    {
        Write-Verbose "Start removal of gateway for virtual network '$($network.name)'"
        $cmd = [scriptblock]::Create("Import-Module -Name Azure; Select-AzureSubscription -SubscriptionName $($lab.AzureSettings.DefaultSubscription.SubscriptionName); Remove-AzureVNetGateway -VNetName $($network.name)")
        Start-Job -Name "RemoveAzureVNetGateway ($($network.name))" -ScriptBlock $cmd | Out-Null
    }
    $jobs = Get-Job -Name RemoveAzureVNetGateway*
    Write-Verbose "Waiting on the removal of $($jobs.Count)"
    $jobs | Wait-Job | Out-Null

    $virtualNetworkSites = Get-LabXmlAzureNetworkVirtualNetworkSite

    foreach ($network in $VirtualNetwork)
    {
        $dnsServers = Get-LabXmlAzureNetworkVirtualNetworkSiteDnsServer -VirtualNetworkSiteName $network.Name
        Remove-LabXmlAzureNetworkVirtualNetworkSite -Name $network.Name
        foreach ($dnsServer in $dnsServers)
        {
            Remove-LabXmlAzureNetworkDnsServer -DnsServer $dnsServer.name
        }

        Remove-LabXmlAzureNetworkLocalNetwork -Name "$($network.Name)_local"
    }

    $tempFile = [System.IO.Path]::GetTempFileName()
    Save-LabXmlAzureNetworkConfig -Path $tempFile
	
    $result = Set-AzureVNetConfig -ConfigurationPath $tempFile
	
    Remove-Item -Path $tempFile
	
    $lab.AzureSettings.VnetConfig = (Get-AzureVNetConfig).XMLConfiguration
	
    
    Write-Verbose "Virtual network '$name' removed from Azure"
	
    Write-LogFunctionExit
}
#endregion Remove-LWNetworkSwitch

#region NetworkConfig functions
function Import-LabXmlAzureNetworkConfig
{
    param(
        [switch]$LoadFromAzure
    )
	
    if ($LoadFromAzure)
    {
        [xml]$script:data = (Get-AzureVNetConfig).XMLConfiguration
    }
    else
    {
        $script:lab = Get-Lab -ErrorAction SilentlyContinue
        $script:data = $script:lab.AzureSettings.VnetConfig
    }
	
    if (-not $script:data)
    {
        $script:data = @'
<?xml version="1.0" encoding="utf-8"?><NetworkConfiguration xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration"><VirtualNetworkConfiguration></VirtualNetworkConfiguration></NetworkConfiguration>
'@
    }

    $script:data = [xml]$script:data
	
    $script:nsManager = New-Object System.Xml.XmlNamespaceManager($script:data.NameTable)
    $nsManager.AddNamespace('nc', 'http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration')
}

function Save-LabXmlAzureNetworkConfig
{
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
	
    $script:data.Save($Path)
}

function Get-LabXmlAzureNetworkConfig
{
    if (-not $script:data)
    {
        Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"
        return
    }

    $script:data
}

function Set-LabXmlAzureNetworkConfig
{
    param()

    if (-not $Script:data)
    {
        throw 'There is no Azure XML network config to save to Azure'
    }

    $tempFile = [System.IO.Path]::GetTempFileName()
    Save-LabXmlAzureNetworkConfig -Path $tempFile
	
    $result = Set-AzureVNetConfig -ConfigurationPath $tempFile -ErrorAction Stop

    Copy-Item -Path $tempFile -Destination (Join-Path -Path (Get-Lab).LabPath -ChildPath AzureNetworkConfig.Xml)
	
    Remove-Item -Path $tempFile
}
#endregion NetworkConfig functions

#region LocalNetwork functions
function Get-LabXmlAzureNetworkLocalNetwork
{
    [cmdletBinding(DefaultParameterSetName = 'ByName')]
	
    param (
        [Parameter(ParameterSetName = 'ByName')]
        [string]$Name,
		
        [Parameter(Mandatory, ParameterSetName = 'ByIp')]
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))/[\d]{1,2}\b')]
        [string]$Network
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }
	
    $query = if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        if ($Name)
        {
            '//nc:VirtualNetworkConfiguration/nc:LocalNetworkSites/nc:LocalNetworkSite[@name = "{0}"]' -f $Name
        }
        else
        {
            '//nc:VirtualNetworkConfiguration/nc:LocalNetworkSites/nc:LocalNetworkSite'
        }
    }
    else
    {
        '//nc:VirtualNetworkConfiguration/nc:LocalNetworkSites/nc:LocalNetworkSite[nc:AddressSpace/nc:AddressPrefix = "{0}"]' -f $Network
    }
	
    $nodeList = $Script:data.SelectNodes($query, $nsManager)

    #this is for returning an array of XmlElements in case there is more than one item
    for ($i = 0; $i -lt $nodeList.Count; $i++) 
    {
        $nodeList.Item($i)
    }
}

function New-LabXmlAzureNetworkLocalNetwork
{
    [CmdletBinding()]
    
    param
    (
        [Parameter(Mandatory)]
        [string]$Name,        
        
        [Parameter(Mandatory)]
        [string]$AddressSpace,
        
        [Parameter()]
        [string]$VPNGatewayAddress
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    if (Get-LabXmlAzureNetworkLocalNetwork -Name $Name)
    {
        Write-ScreenInfo -Message "The Azure Local Network '$Name' does already exist" -Type Warning
        return
    }

    $virtualNetworkConfiguration = $script:data.SelectSingleNode('//nc:VirtualNetworkConfiguration', $nsManager)
    $localNetworkSites = $script:data.SelectSingleNode('//nc:LocalNetworkSites', $nsManager)
    if (-not $localNetworkSites)
    {
        $localNetworkSites = $script:data.CreateElement('LocalNetworkSites', $nsManager.LookupNamespace('nc'))
        $virtualNetworkConfiguration.AppendChild($localNetworkSites) | Out-Null
    }

    $localNetworkSite = $script:data.CreateElement('LocalNetworkSite', $nsManager.LookupNamespace('nc'))
    $localNetworkSite.SetAttribute('name', $Name)
    $localNetworkSites.AppendChild($localNetworkSite) | Out-Null

    $addressSpace2 = $script:data.CreateElement('AddressSpace', $nsManager.LookupNamespace('nc'))
    $localNetworkSite.AppendChild($addressSpace2) | Out-Null

    $addressPrefix = $script:data.CreateElement('AddressPrefix', $nsManager.LookupNamespace('nc'))
    $addressPrefix.InnerText = $AddressSpace
    $addressSpace2.AppendChild($addressPrefix) | Out-Null

    $vpnGatewayAddress2 = $script:data.CreateElement('VPNGatewayAddress', $nsManager.LookupNamespace('nc'))
    $vpnGatewayAddress2.InnerText = $VPNGatewayAddress
    $localNetworkSite.AppendChild($vpnGatewayAddress2) | Out-Null
}

function Remove-LabXmlAzureNetworkLocalNetwork
{
    [cmdletBinding(DefaultParameterSetName = 'ByName')]
	
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$Name,
		
        [Parameter(Mandatory, ParameterSetName = 'ByIp')]
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))/[\d]{1,2}\b')]
        [string]$Network
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    $query = '//nc:VirtualNetworkConfiguration/nc:LocalNetworkSites'
    $localNetworkSitesNode = $script:data.SelectSingleNode($query, $nsManager)
	
    $query = if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        '//nc:VirtualNetworkConfiguration/nc:LocalNetworkSites/nc:LocalNetworkSite[@name = "{0}"]' -f $Name
    }
    else
    {
        '//nc:VirtualNetworkConfiguration/nc:LocalNetworkSites/nc:LocalNetworkSite[nc:AddressSpace/nc:AddressPrefix = "{0}"]' -f $Network
    }
	
    $localNetworkSiteNode = $Script:data.SelectSingleNode($query, $nsManager)

    if ($localNetworkSitesNode -and $localNetworkSiteNode)
    {
        $localNetworkSitesNode.RemoveChild($localNetworkSiteNode) | Out-Null
    }
}

function Set-LabXmlAzureNetworkLocalNetwork
{
    [cmdletBinding(DefaultParameterSetName = 'ByName')]
	
    param (
        [Parameter(Mandatory)]
        [string]$Name,
		
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))/[\d]{1,2}\b')]
        [string]$AddressPrefix,

        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))\b')]
        [string]$VPNGatewayAddress
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    if ($VPNGatewayAddress)
    {
        $query = '//nc:VirtualNetworkConfiguration/nc:LocalNetworkSites/nc:LocalNetworkSite[@name = "{0}"]/nc:VPNGatewayAddress' -f $Name
	
        $vpnGatewayAddressNode = $Script:data.SelectSingleNode($query, $nsManager)

        if (-not $vpnGatewayAddressNode)
        {
            Write-Error "There is no local network with the name '$Name'."
            return
        }

        $vpnGatewayAddressNode.InnerText = $VPNGatewayAddress
    }

    if ($AddressPrefix)
    {
        $query = '//nc:VirtualNetworkConfiguration/nc:LocalNetworkSites/nc:LocalNetworkSite[@name = "{0}"]/nc:AddressSpace/nc:AddressPrefix' -f $Name
	
        $addressPrefixNode = $Script:data.SelectSingleNode($query, $nsManager)

        if (-not $addressPrefixNode)
        {
            Write-Error "There is no local network with the name '$Name'."
            return
        }

        $addressPrefixNode.InnerText = $AddressPrefix
    }
}
#endregion LocalNetwork functions

#region VirtualNetworkSite functions
function Get-LabXmlAzureNetworkVirtualNetworkSite
{
    [cmdletBinding(DefaultParameterSetName = 'ByName')]
	
    param (
        [Parameter(ParameterSetName = 'ByName')]
        [string]$Name,
		
        [Parameter(Mandatory, ParameterSetName = 'ByIp')]
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))/[\d]{1,2}\b')]
        [string]$Network
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }
	
    $query = if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        if ($Name)
        {
            '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name = "{0}"]' -f $Name
        }
        else
        {
            '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite'
        }
    }
    else
    {
        '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[nc:AddressSpace/nc:AddressPrefix = "{0}"]' -f $Network
    }
	
    $nodeList = $Script:data.SelectNodes($query, $nsManager)

    #this is for returning an array of XmlElements in case there is more than one item
    for ($i = 0; $i -lt $nodeList.Count; $i++) 
    {
        $nodeList.Item($i)
    }
}

function New-LabXmlAzureNetworkVirtualNetworkSite
{
    param (
        [Parameter(Mandatory)]
        [string]$Name,
		
        [Parameter(Mandatory)]
        [string]$Location
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    if (Get-LabXmlAzureNetworkVirtualNetworkSite -Name $Name)
    {
        Write-ScreenInfo -Message "The Azure Virtual Site '$Name' does already exist" -Type Warning
        return
    }

    $virtualNetworkConfiguration = $script:data.SelectSingleNode('//nc:VirtualNetworkConfiguration', $nsManager)
    $virtualNetworkSites = $script:data.SelectSingleNode('//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites', $nsManager)
    if (-not $virtualNetworkSites)
    {
        $virtualNetworkSites = $script:data.CreateElement('VirtualNetworkSites', $nsManager.LookupNamespace('nc'))
        $virtualNetworkConfiguration.AppendChild($virtualNetworkSites) | Out-Null
    }
	
    $nameAtt = $script:data.CreateAttribute('name')
    $nameAtt.Value = $Name
	
    $locationAtt = $script:data.CreateAttribute('Location')
    $locationAtt.Value = $Location
	
    $addressSpaceNode = $script:data.CreateElement('AddressSpace', $nsManager.LookupNamespace('nc'))
    $subnetsNode = $script:data.CreateElement('Subnets', $nsManager.LookupNamespace('nc'))
	
    $virtualNetworkSiteNode = $script:data.CreateElement('VirtualNetworkSite', $nsManager.LookupNamespace('nc'))
    [void]$virtualNetworkSiteNode.Attributes.Append($nameAtt)
    [void]$virtualNetworkSiteNode.Attributes.Append($locationAtt)
	
    [void]$virtualNetworkSiteNode.AppendChild($addressSpaceNode)
    [void]$virtualNetworkSiteNode.AppendChild($subnetsNode)

    [void]$virtualNetworkSites.AppendChild($virtualNetworkSiteNode)
}

function Remove-LabXmlAzureNetworkVirtualNetworkSite
{	
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }
	
    $query = '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites' -f $Name	
    $virtualNetworkSitesNode = $Script:data.SelectSingleNode($query, $nsManager)
    
    $query = '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name = "{0}"]' -f $Name	
    $virtualNetworkSiteNode = $Script:data.SelectSingleNode($query, $nsManager)

    if ($virtualNetworkSitesNode -and $virtualNetworkSiteNode)
    {
        $virtualNetworkSitesNode.RemoveChild($virtualNetworkSiteNode) | Out-Null
    }
}
#endregion VirtualNetworkSite functions

#region VirtualNetworkSiteGateway functions
function Get-LabXmlAzureNetworkVirtualNetworkSiteGateway
{
    [cmdletBinding(DefaultParameterSetName = 'ByName')]
	
    param (
        [Parameter(Mandatory)]
        [string]$VirtualNetworkSiteName,

        [string]$LocalNetworkName
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }
	
    $query = if ($LocalNetworkName)
    {
        '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:Gateway/nc:ConnectionsToLocalNetwork/nc:LocalNetworkSiteRef[@name="{1}"]' -f $VirtualNetworkSiteName, $LocalNetworkName
    }
    else
    {
        '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:Gateway/nc:ConnectionsToLocalNetwork/nc:LocalNetworkSiteRef' -f $VirtualNetworkSiteName
    }
	
    $nodeList = $Script:data.SelectNodes($query, $nsManager)

    #this is for returning an array of XmlElements in case there is more than one item
    for ($i = 0; $i -lt $nodeList.Count; $i++) 
    {
        $nodeList.Item($i)
    }
}

function Add-LabXmlAzureNetworkVirtualNetworkSiteGateway
{
    param (		
        [Parameter(Mandatory)]
        [string]$VirtualNetworkSiteName,

        [Parameter(Mandatory)]
        [string]$LocalNetworkName
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    if (Get-LabXmlAzureNetworkVirtualNetworkSiteGateway -VirtualNetworkSiteName $VirtualNetworkSiteName -LocalNetworkName $LocalNetworkName)
    {
        Write-Warning "The Local Network named '$LocalNetworkName' is already assigned to the Virtual Network Site '$VirtualNetworkSiteName'"
        return
    }
	
    $query = '/nc:NetworkConfiguration/nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name = "{0}"]/nc:Gateway' -f $VirtualNetworkSiteName
    $gatewayNode = $script:data.SelectSingleNode($query, $nsManager)

    if (-not $gatewayNode)
    {
        $query = '/nc:NetworkConfiguration/nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name = "{0}"]' -f $VirtualNetworkSiteName
        $virtualNetworkSiteNode = $script:data.SelectSingleNode($query, $nsManager)

        $gatewayNode = $script:data.CreateElement('Gateway', $nsManager.LookupNamespace('nc'))
        [void]$virtualNetworkSiteNode.AppendChild($gatewayNode)
    }

    $query = '/nc:NetworkConfiguration/nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name = "{0}"]/nc:Gateway/nc:ConnectionsToLocalNetwork' -f $VirtualNetworkSiteName
    $connectionsToLocalNetworkNode = $script:data.SelectSingleNode($query, $nsManager)
    if (-not $connectionsToLocalNetworkNode)
    {
        $connectionsToLocalNetworkNode = $script:data.CreateElement('ConnectionsToLocalNetwork', $nsManager.LookupNamespace('nc'))
        [void]$gatewayNode.AppendChild($connectionsToLocalNetworkNode)
    }

    $localNetworkSiteRefNode = $script:data.CreateElement('LocalNetworkSiteRef', $nsManager.LookupNamespace('nc'))
    $nameAtt = $script:data.CreateAttribute('name')
    $nameAtt.Value = $LocalNetworkName
    [void]$localNetworkSiteRefNode.Attributes.Append($nameAtt)
    [void]$connectionsToLocalNetworkNode.AppendChild($localNetworkSiteRefNode)

    $connectionNode = $script:data.CreateElement('Connection', $nsManager.LookupNamespace('nc'))
    $typeAtt = $script:data.CreateAttribute('type')
    $typeAtt.Value = 'IPsec'
    [void]$connectionNode.Attributes.Append($typeAtt)
    [void]$localNetworkSiteRefNode.AppendChild($connectionNode)
}

function Remove-LabXmlAzureNetworkVirtualNetworkSiteGateway
{
    [cmdletBinding(DefaultParameterSetName = 'ByName')]
	
    param (
        [Parameter(Mandatory)]
        [string]$VirtualNetworkSiteName,

        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$LocalNetworkName,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }
	
    if ($All)
    {
        $query = '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:Gateway' -f $VirtualNetworkSiteName
        $gatewayNode = $Script:data.SelectSingleNode($query, $nsManager)

        $query = '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]' -f $VirtualNetworkSiteName
        $vnetNode = $Script:data.SelectSingleNode($query, $nsManager)

        if ($gatewayNode -and $vnetNode)
        {
            $vnetNode.RemoveChild($gatewayNode) | Out-Null
        }
    }
    elseif ($LocalNetworkName)
    {
        throw (New-Object System.NotImplementedException)
    }
}
#endregion VirtualNetworkSiteGateway functions

#region VirtualNetworkSiteSubnet functions
function Get-LabXmlAzureNetworkVirtualNetworkSiteSubnet
{
    [cmdletBinding(DefaultParameterSetName = 'ByName')]
	
    param (
        [Parameter(Mandatory)]
        [string]$VirtualNetworkSiteName,
		
        [Parameter(ParameterSetName = 'ByIp')]
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))/[\d]{1,2}\b')]
        [string]$AddressPrefix,

        [Parameter(ParameterSetName = 'ByName')]
        [string]$Name
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }
	
    $query = if ($AddressPrefix -and -not $Name)
    {
        '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:Subnets/nc:Subnet/nc:AddressPrefix[text() = "{1}"]' -f $VirtualNetworkSiteName, $AddressPrefix
    }
    elseif ($Name -and -not $AddressPrefix)
    {
        '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:Subnets/nc:Subnet[@name = "{1}"]' -f $VirtualNetworkSiteName, $Name
    }
    else
    {
        '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:Subnets/nc:Subnet' -f $VirtualNetworkSiteName
    }
	
    $nodeList = $Script:data.SelectNodes($query, $nsManager)

    #this is for returning an array of XmlElements in case there is more than one item
    for ($i = 0; $i -lt $nodeList.Count; $i++) 
    {
        $nodeList.Item($i)
    }
}

function Add-LabXmlAzureNetworkVirtualNetworkSiteSubnet
{
    param (
        [Parameter(Mandatory)]
        [string]$Name,
		
        [Parameter(Mandatory)]
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))/[\d]{1,2}\b')]
        [string]$AddressPrefix,
		
        [Parameter(Mandatory)]
        [string]$VirtualNetworkSiteName
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    if (Get-LabXmlAzureNetworkVirtualNetworkSiteSubnet -VirtualNetworkSiteName $VirtualNetworkSiteName -Name $Name)
    {
        Write-ScreenInfo -Message "The subnet named '$Name' does already exist on Azure Virtual Site '$VirtualNetworkSiteName'" -Type Warning
        return
    }

    if (Get-LabXmlAzureNetworkVirtualNetworkSiteSubnet -VirtualNetworkSiteName $VirtualNetworkSiteName -AddressPrefix $AddressPrefix)
    {
        Write-ScreenInfo -Message "The subnet with the address space '$AddressPrefix' does already exist on Azure Virtual Site '$VirtualNetworkSiteName'" -Type Warning
        return
    }
	
    $query = '/nc:NetworkConfiguration/nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name = "{0}"]/nc:Subnets' -f $VirtualNetworkSiteName
    $subnetsNode = $script:data.SelectSingleNode($query, $nsManager)
	
    $subnetNode = $script:data.CreateElement('Subnet', $nsManager.LookupNamespace('nc'))
    $nameAtt = $script:data.CreateAttribute('name')
    $nameAtt.Value = $Name
	
    [void]$subnetNode.Attributes.Append($nameAtt)
	
    foreach ($item in $AddressPrefix)
    {
		
        $addressPrefixNode = $script:data.CreateElement('AddressPrefix', $nsManager.LookupNamespace('nc'))
        $addressPrefixNode.InnerText = $item
		
        [void]$subnetNode.AppendChild($addressPrefixNode)
    }
	
    [void]$subnetsNode.AppendChild($subnetNode)
}

function Remove-LabXmlAzureNetworkVirtualNetworkSiteSubnet
{
    [cmdletBinding(DefaultParameterSetName = 'ByName')]
	
    param (
        [Parameter(Mandatory)]
        [string]$VirtualNetworkSiteName,
		
        [Parameter(ParameterSetName = 'ByIp')]
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))/[\d]{1,2}\b')]
        [string]$AddressPrefix,

        [Parameter(ParameterSetName = 'ByName')]
        [string]$Name
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    $query = '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:Subnets' -f $VirtualNetworkSiteName
    $subnetsNode = $script:data.SelectSingleNode($query, $nsManager)
	
    $query = if ($AddressPrefix -and -not $Name)
    {
        '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:Subnets/nc:Subnet/nc:AddressPrefix[text() = "{1}"]' -f $VirtualNetworkSiteName, $AddressPrefix
    }
    elseif ($Name -and -not $AddressPrefix)
    {
        '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:Subnets/nc:Subnet[@name = "{1}"]' -f $VirtualNetworkSiteName, $Name
    }
	
    $subnetNode = $Script:data.SelectSingleNode($query, $nsManager)

    if (-not $subnetNode)
    {
        Write-Error "There is no subnet named $Name on the Virtual Network Site '$VirtualNetworkSiteName'"
        return
    }

    if ($subnetsNode -and $subnetNode)
    {
        $subnetsNode.RemoveChild($subnetNode) | Out-Null
    }
}
#endregion VirtualNetworkSiteSubnet functions

#region VirtualNetworkSiteAddressSpace functions
function Get-LabXmlAzureNetworkVirtualNetworkSiteAddressSpace
{
    param (
        [Parameter(Mandatory)]
        [string]$VirtualNetworkSiteName,
		
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))/[\d]{1,2}\b')]
        [string]$AddressPrefix
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }
	
    $query = if ($AddressPrefix)
    {
        '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:AddressSpace/nc:AddressPrefix[text() = "{1}"]' -f $VirtualNetworkSiteName, $AddressPrefix
    }
    else
    {
        '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:AddressSpace/nc:AddressPrefix' -f $VirtualNetworkSiteName
    }
	
    $nodeList = $Script:data.SelectNodes($query, $nsManager)

    #this is for returning an array of XmlElements in case there is more than one item
    for ($i = 0; $i -lt $nodeList.Count; $i++) 
    {
        $nodeList.Item($i)
    }
}

function Add-LabXmlAzureNetworkVirtualNetworkSiteAddressSpace
{
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))/[\d]{1,2}\b')]
        [string]$AddressPrefix,
		
        [Parameter(Mandatory)]
        [string]$VirtualNetworkSiteName
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    if (Get-LabXmlAzureNetworkVirtualNetworkSiteAddressSpace -VirtualNetworkSiteName $VirtualNetworkSiteName -AddressPrefix $AddressPrefix)
    {
        Write-ScreenInfo -Message "The Address Space '$AddressPrefix' for the Azure Virtual Site '$VirtualNetworkSiteName' does already exist" -Type Warning
        return
    }
	
    $query = '/nc:NetworkConfiguration/nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name = "{0}"]/nc:AddressSpace' -f $VirtualNetworkSiteName
    $addressSpaceNode = $script:data.SelectSingleNode($query, $nsManager)
	
    $addressPrefixNode = $script:data.CreateElement('AddressPrefix', $nsManager.LookupNamespace('nc'))
    $addressPrefixNode.InnerText = $AddressPrefix
	
    [void]$addressSpaceNode.AppendChild($addressPrefixNode)
}

function Remove-LabXmlAzureNetworkVirtualNetworkSiteAddressSpace
{	
    param (
        [Parameter(Mandatory)]
        [string]$VirtualNetworkSiteName,
		
        [Parameter(Mandatory)]
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))/[\d]{1,2}\b')]
        [string]$AddressPrefix
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    $query = '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:AddressSpace' -f $VirtualNetworkSiteName
    $addressSpaceNode = $script:data.SelectSingleNode($query, $nsManager)
	
    $query = '//nc:VirtualNetworkConfiguration/nc:VirtualNetworkSites/nc:VirtualNetworkSite[@name="{0}"]/nc:AddressSpace/nc:AddressPrefix[text() = "{1}"]' -f $VirtualNetworkSiteName, $AddressPrefix
    $addressPrefixNode = $script:data.SelectSingleNode($query, $nsManager)
	
    if (-not $addressPrefixNode)
    {
        Write-Error "Could not find the Address Space '$AddressPrefix' assigned to the Virtual Network Site '$VirtualNetworkSiteName'"
        return
    }

    $addressSpaceNode.RemoveChild($addressPrefixNode) | Out-Null
}
#endregion VirtualNetworkSiteAddressSpace functions

#region DnsServer functions
function Get-LabXmlAzureNetworkDnsServer
{
    [cmdletBinding()]
    param (
        [string]$DnsServer
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    if ($DnsServer)
    {
        $query = '/nc:NetworkConfiguration/nc:VirtualNetworkConfiguration/nc:Dns/nc:DnsServers/nc:DnsServer[@IPAddress = "{0}"]' -f $DnsServer
    }
    else
    {
        $query = '/nc:NetworkConfiguration/nc:VirtualNetworkConfiguration/nc:Dns/nc:DnsServers/nc:DnsServer'
    }

    $nodeList = $Script:data.SelectNodes($query, $nsManager)

    if ($DnsServer -and -not $nodeList.Count)
    {
        Write-Error "The DNS server entry '$DnsServer' is not configured in the current subscription"
        return
    }

    #this is for returning an array of XmlElements in case there is more than one item
    for ($i = 0; $i -lt $nodeList.Count; $i++) 
    {
        $nodeList.Item($i)
    }
}

function New-LabXmlAzureNetworkDnsServer
{
    param (
        [Parameter(Mandatory)]
        [string[]]$DnsServer
    )

    $virtualNetworkConfigurationNode = $data.SelectSingleNode('//nc:NetworkConfiguration/nc:VirtualNetworkConfiguration', $nsManager)

    $dnsNode = $data.SelectSingleNode('//nc:NetworkConfiguration/nc:VirtualNetworkConfiguration/nc:Dns', $nsManager)
    if (-not $dnsNode)
    {
        $dnsNode = $data.CreateElement('Dns', $nsManager.LookupNamespace('nc'))
        $virtualNetworkConfigurationNode.AppendChild($dnsNode) | Out-Null
    }

    $dnsServersNode = $script:data.SelectSingleNode('/nc:NetworkConfiguration/nc:VirtualNetworkConfiguration/nc:Dns/nc:DnsServers', $nsManager)
    if (-not $dnsServersNode)
    {
        $dnsNode = $script:data.SelectSingleNode('/nc:NetworkConfiguration/nc:VirtualNetworkConfiguration/nc:Dns', $nsManager)
        if (-not $dnsNode)
        {
            Write-Error "The node 'Dns' is missing. Cannot add DNS servers"
        }

        $dnsServersNode = $script:data.CreateElement('DnsServers', $nsManager.LookupNamespace('nc'))
        [void]$dnsNode.AppendChild($dnsServersNode)
    }

    foreach ($item in $DnsServer)
    {
        $dnsServerName = (Get-LabXmlAzureNetworkDnsServer -DnsServer $item -ErrorAction SilentlyContinue)
        if ($dnsServerName)
        {
            Write-Verbose "The DNS server '$item' does already exist"
        }
        else
        {
            $dnsServerNode = $script:data.CreateElement('DnsServer', $nsManager.LookupNamespace('nc'))
        
            $ipAddressAtt = $script:data.CreateAttribute('IPAddress')
            $ipAddressAtt.Value = $item

            $nameAtt = $script:data.CreateAttribute('name')
            $dnsServerName = $item
            $nameAtt.Value = $dnsServerName
	
            [void]$dnsServerNode.Attributes.Append($ipAddressAtt)
            [void]$dnsServerNode.Attributes.Append($nameAtt)

            [void]$dnsServersNode.AppendChild($dnsServerNode)
        }
    }
}

function Remove-LabXmlAzureNetworkDnsServer
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$DnsServer
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    $query = '/nc:NetworkConfiguration/nc:VirtualNetworkConfiguration/nc:Dns/nc:DnsServers'
    $dnsServersNode = $Script:data.SelectSingleNode($query, $nsManager)

    $dnsServerNode = Get-LabXmlAzureNetworkDnsServer -DnsServer $DnsServer -ErrorAction SilentlyContinue

    if (-not $dnsServersNode -and -not $dnsServerNode)
    {
        Write-Error "The DNS server entry '$DnsServer' does not exist in the current subscription"
        return
    }

    $dnsServersNode.RemoveChild($dnsServerNode) | Out-Null
}
#endregion DnsServer functions

#region VirtualNetworkSiteDnsServer functions
#region VirtualNetworkSiteDnsServer functions
function Get-LabXmlAzureNetworkVirtualNetworkSiteDnsServer
{
    [cmdletBinding(DefaultParameterSetName = 'ByName')]
	
    param (
        [Parameter(Mandatory)]
        [string]$VirtualNetworkSiteName,
		
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))')]
        [string[]]$DnsServer
    )
    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    $virtualNetworkSiteNode = Get-LabXmlAzureNetworkVirtualNetworkSite -Name $VirtualNetworkSiteName -ErrorAction SilentlyContinue

    if (-not $virtualNetworkSiteNode)
    {
        Write-Error "The Virtual Network Site '$VirtualNetworkSiteName' could not be found"
        return
    }

    if (-not $virtualNetworkSiteNode.DnsServersRef)
    {
        return
    }
    else
    {
        if ($DnsServer)
        {
            $virtualNetworkSiteNode.DnsServersRef.DnsServerRef | Where-Object { $_.name -in $DnsServer }
        }
        else
        {
            $virtualNetworkSiteNode.DnsServersRef.DnsServerRef
        }
    }
}
#endregion VirtualNetworkSiteDnsServer functions

function Add-LabXmlAzureNetworkVirtualNetworkSiteDnsServer
{
    param (
        [Parameter(Mandatory)]
        [string]$VirtualNetworkSiteName,
		
        [Parameter(Mandatory)]
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))')]
        [string[]]$DnsServer,

        [switch]$DoNotVerify
    )
    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    $virtualNetworkSiteNode  = Get-LabXmlAzureNetworkVirtualNetworkSite -Name $VirtualNetworkSiteName -ErrorAction SilentlyContinue

    if (-not $virtualNetworkSiteNode)
    {
        Write-Error "The Virtual Network Site '$VirtualNetworkSiteName' could not be found"
        return
    }

    if (-not $virtualNetworkSiteNode.DnsServersRef)
    {
        $dnsServersRefNode = $script:data.CreateElement('DnsServersRef', $nsManager.LookupNamespace('nc'))
        $virtualNetworkSiteNode.AppendChild($dnsServersRefNode) | Out-Null
    }

    foreach ($item in $DnsServer)
    {
        $dnsServerNode = Get-LabXmlAzureNetworkDnsServer -DnsServer $item -ErrorAction SilentlyContinue
        if (-not $dnsServerNode)
        {
            Write-Error "The DNS Server '$item' is not configured hence cannot be added"
            continue
        }

        if ((Get-LabXmlAzureNetworkVirtualNetworkSiteDnsServer -VirtualNetworkSiteName $VirtualNetworkSiteName -DnsServer $item))
        {
            Write-Verbose "The DNS Server '$item' has been already aded to the Virtual Network Site '$VirtualNetworkSiteName'"
            continue
        }

        $dnsServerRefNode = $script:data.CreateElement('DnsServerRef', $nsManager.LookupNamespace('nc'))
        $dnsServerRefNode.SetAttribute('name', $dnsServerNode.name)
        $dnsServersRefNode.AppendChild($dnsServerRefNode) | Out-Null

        $virtualNetworkSiteNode.AppendChild($dnsServersRefNode) | Out-Null
    }    
}

function Remove-LabXmlAzureNetworkVirtualNetworkSiteDnsServer
{
    param (
        [Parameter(Mandatory)]
        [string]$VirtualNetworkSiteName,
		
        [Parameter(Mandatory)]
        [ValidatePattern('\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))')]
        [string[]]$DnsServer
    )

    if (-not $script:data) { Write-Error "No network data avaialble. Call 'Import-LabXmlAzureNetworkConfig' first"; return }

    $VirtualNetworkSiteNode = Get-LabXmlAzureNetworkVirtualNetworkSite -Name $VirtualNetworkSiteName -ErrorAction SilentlyContinue
    if (-not $VirtualNetworkSiteNode)
    {
        Write-Error "The Virtual Netork Site '$VirtualNetworkSiteName' does not exist'"
        return
    }

    $existingDnsServerRefs = Get-LabXmlAzureNetworkVirtualNetworkSiteDnsServer -VirtualNetworkSiteName $VirtualNetworkSiteName -DnsServer $DnsServer -ErrorAction SilentlyContinue
    if (-not $existingDnsServerRefs)
    {
        Write-Error "The DNS Server(s) $($DnsServer -join ', ') are not references by the Virtual Network Site '$VirtualNetworkSiteName'"
        return
    }

    foreach ($existingDnsServerRef in $existingDnsServerRefs)
    {
        $VirtualNetworkSiteNode.DnsServersRef.RemoveChild($existingDnsServerRef) | Out-Null
    }    
}
#endregion VirtualNetworkSiteDnsServer functions