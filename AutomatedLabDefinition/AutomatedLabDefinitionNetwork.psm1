#region Virtual Network Definition Functions
#region Add-LabVirtualNetworkDefinition
function Add-LabVirtualNetworkDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    [CmdletBinding()]
    param (
        [string]$Name = (Get-LabDefinition).Name,
        
        [AllowNull()]
        [AutomatedLab.IPNetwork]$AddressSpace,
        
        [AutomatedLab.VirtualizationHost]$VirtualizationEngine,

        [hashtable[]]$HyperVProperties,

        [hashtable[]]$AzureProperties,
        
        [switch]$PassThru
    )
    
    Write-LogFunctionEntry

    if ((Get-LabDefinition).DefaultVirtualizationEngine -eq 'Azure' -and -not ((Get-LabDefinition).AzureSettings))
    {
        Add-LabAzureSubscription
    }

    $azurePropertiesValidKeys = 'SubnetName', 'SubnetAddressPrefix', 'LocationName', 'DnsServers', 'ConnectToVnets'
    $hypervPropertiesValidKeys = 'SwitchType', 'AdapterName'
    
    if (-not (Get-LabDefinition))
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Add-LabVirtualNetworkDefinition.'
    }
    $script:lab = Get-LabDefinition
    
    if (-not $VirtualizationEngine)
    {
        if ((Get-LabDefinition).DefaultVirtualizationEngine)
        {
            $VirtualizationEngine = (Get-LabDefinition).DefaultVirtualizationEngine
        }
        else
        {
            Throw "Virtualization engine MUST be specified. This can be done:`n - Using parameter 'DefaultVirtualizationEngine' when calling New-LabDefinition`n - Using Set-LabDefaultVirtualizationEngine -Engine <engine>`n - Using parameter 'VirtualizationEngine' when calling Add-LabVirtualNetworkDefinition`n `nRemember to specify VirtualizationEngine parameter when adding machines if no default virtualization engine has been specified`n `n "
        }
    }
    
    if ($VirtualizationEngine -eq 'HyperV' -and (-not (Get-Module -ListAvailable -Name Hyper-V)))
    {
        throw 'The Hyper-V tools are not installed. Please install them first to use AutomatedLab with Hyper-V. Alternatively, you can use AutomatedLab with Microsoft Azure.'
    }

    if ($VirtualizationEngine -eq 'Azure' -and -not $script:lab.AzureSettings.DefaultStorageAccount)
    {
        Add-LabAzureSubscription
    }

    if ($AzureProperties)
    {
        $illegalKeys = Compare-Object -ReferenceObject $azurePropertiesValidKeys -DifferenceObject ($AzureProperties.Keys | Select-Object -Unique) |
        Where-Object SideIndicator -eq '=>' |
        Select-Object -ExpandProperty InputObject

        if ($illegalKeys)
        {
            throw "The key(s) '$($illegalKeys -join ', ')' are not supported in AzureProperties. Valid keys are '$($azurePropertiesValidKeys -join ', ')'"
        }

        if (($AzureProperties.Keys -eq 'LocationName').Count -ne 1)
        {
            throw 'Location must be speficfied exactly once in AzureProperties'
        }
    }

    if ($HyperVProperties)
    {
        $illegalKeys = Compare-Object -ReferenceObject $hypervPropertiesValidKeys -DifferenceObject ($HyperVProperties.Keys | Select-Object -Unique) |
        Where-Object SideIndicator -eq '=>' |
        Select-Object -ExpandProperty InputObject

        if ($illegalKeys)
        {
            throw "The key(s) '$($illegalKeys -join ', ')' are not supported in HyperVProperties. Valid keys are '$($hypervPropertiesValidKeys -join ', ')'"
        }

        if ($HyperVProperties.SwitchType -eq 'External' -and -not $HyperVProperties.AdapterName)
        {
            throw 'You have to provide a network adapter if you want to create an external switch'
            return
        }

        if (-not $HyperVProperties.SwitchType)
        {
            $HyperVProperties.Add('SwitchType', 'Internal')
        }
    }
    
    if ($script:lab.VirtualNetworks | Where-Object Name -eq $Name)
    {
        $errorMessage = "A network with the name '$Name' is already defined"
        Write-Error $errorMessage
        Write-LogFunctionExitWithError -Message $errorMessage
        return
    }
    
    $network = New-Object -TypeName AutomatedLab.VirtualNetwork
    $network.AddressSpace = $AddressSpace
    $network.Name = $Name
    if ($HyperVProperties.SwitchType) { $network.SwitchType = $HyperVProperties.SwitchType }
    if ($HyperVProperties.AdapterName) {$network.AdapterName = $HyperVProperties.AdapterName }
    $network.HostType = $VirtualizationEngine

    foreach ($hashtable in $AzureProperties)
    {
        if ($hashtable.ContainsKey('LocationName'))
        {		
            $network.LocationName = $hashtable.LocationName
        }
        
        if ($hashtable.ContainsKey('ConnectToVnets'))
        {
            $network.ConnectToVnets = $hashtable.ConnectToVnets
        }

        if ($hashtable.ContainsKey('DnsServers'))
        {
            $network.DnsServers = $hashtable.DnsServers
        }

        if ($hashtable.ContainsKey('SubnetName') -and $hashtable.ContainsKey('SubnetAddressPrefix'))
        {
            $network.Subnets.Add([AutomatedLab.AzureSubnet]$hashtable)
        }
    }  

    if (-not $network.LocationName)
    {
        $network.LocationName = $script:lab.AzureSettings.DefaultLocation
    }
    
    $script:lab.VirtualNetworks.Add($network)
    Write-Verbose "Network '$Name' added. Lab has $($Script:lab.VirtualNetworks.Count) network(s) defined"
    
    if ($PassThru)
    {
        $network
    }
    Write-LogFunctionExit
}
#endregion Add-LabVirtualNetworkDefinition

#region Get-LabVirtualNetworkDefinition
function Get-LabVirtualNetworkDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    [CmdletBinding()]
    [OutputType([AutomatedLab.VirtualNetwork])]

    param(
        [Parameter(ParameterSetName = 'ByName')]
        [string]$Name,
        
        [Parameter(Mandatory, ParameterSetName = 'ByAddressSpace')]
        [string]$AddressSpace
    )

    Write-LogFunctionEntry
    
    if ($PSCmdlet.ParameterSetName -eq 'ByAddressSpace')
    {
        return $script:lab.VirtualNetworks | Where-Object AddressSpace -eq $AddressSpace
    }
    else
    {
        if ($Name)
        {
            return $script:lab.VirtualNetworks | Where-Object Name -eq $Name
        }
        else
        {
            return $script:lab.VirtualNetworks
        }
    }
    
    Write-LogFunctionExit
}
#endregion Get-LabVirtualNetworkDefinition

#region Remove-LabVirtualNetworkDefinition
function Remove-LabVirtualNetworkDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Name
    )
    
    Write-LogFunctionEntry
    
    foreach ($n in $Name)
    {
        $network = $script:lab.VirtualNetworks | Where-Object Name -eq $n
    
        if (-not $network)
        {
            Write-Warning "There is no network defined with the name '$n'"
        }
        else
        {
            [Void]$script:lab.VirtualNetworks.Remove($network)
            Write-Verbose "Network '$n' removed. Lab has $($Script:lab.VirtualNetworks.Count) network(s) defined"
        }
    }
    
    Write-LogFunctionExit
}
#endregion Remove-LabVirtualNetworkDefinition
#endregion #region Virtual Network Definition Functions

#region New-LabNetworkAdapterDefinition
function New-LabNetworkAdapterDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    [CmdletBinding(DefaultParameterSetName = 'manual')]
    param (
        [Parameter(Mandatory)]
        [string]$VirtualSwitch,

        [string]$InterfaceName = 'Ethernet',

        [Parameter(ParameterSetName = 'dhcp')]
        [switch]$UseDhcp,

        [Parameter(ParameterSetName = 'manual')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))/([3][0-1]|[1-2][0-9]|[2-9])$')]
        [AutomatedLab.IPNetwork[]]$Ipv4Address,
        
        [Parameter(ParameterSetName = 'manual')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))$')]
        [AutomatedLab.IPAddress]$Ipv4Gateway,

        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))$')]
        [AutomatedLab.IPAddress[]]$Ipv4DNSServers,

        [Parameter(ParameterSetName = 'manual')]
        [AutomatedLab.IPNetwork[]]$IPv6Address,
        
        [Parameter(ParameterSetName = 'manual')]
        [ValidateRange(1, 128)]
        [int]$IPv6AddressPrefix,
        
        [Parameter(ParameterSetName = 'manual')]
        [string]$IPv6Gateway,

        [string[]]$IPv6DNSServers,
        
        [string]$ConnectionSpecificDNSSuffix,

        [boolean]$AppendParentSuffixes,

        [string[]]$AppendDNSSuffixes,

        [boolean]$RegisterInDNS = $true,

        [boolean]$DnsSuffixInDnsRegistration,

        [ValidateSet('Default', 'Enabled', 'Disabled')]
        [string]$NetBIOSOptions = 'Default'
    )
    
    Write-LogFunctionEntry
    
    if (-not (Get-LabDefinition))
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabDefaultOperatingSystem.'
    }	
    
    $adapter = New-Object -TypeName AutomatedLab.NetworkAdapter
    
    if ($VirtualSwitch)
    {
        $adapter.VirtualSwitch = Get-LabVirtualNetworkDefinition | Where-Object Name -eq $VirtualSwitch
    }
    else
    {
        $adapter.VirtualSwitch = Get-LabVirtualNetworkDefinition | Select-Object -First 1
    }

    if (-not $adapter.VirtualSwitch)
    {
        throw "Could not find the virtual switch '$VirtualSwitch' nor create one automatically"
    }
    
    $adapter.InterfaceName = $InterfaceName
    
    foreach ($item in $Ipv4Address)
    {
        $adapter.Ipv4Address.Add($item)
    }
    
    foreach ($item in $Ipv4DnsServers)
    {
        $adapter.Ipv4DnsServers.Add($item)
    }

    foreach ($item in $Ipv6Address)
    {
        $adapter.Ipv6Address.Add($item)
    }
    
    foreach ($item in $Ipv6DnsServers)
    {
        $adapter.Ipv6DnsServers.Add($item)
    }
    
    if ($Ipv4Gateway) { $adapter.Ipv4Gateway = $Ipv4Gateway }
    if ($Ipv6Gateway) { $adapter.Ipv6Gateway = $Ipv6Gateway }
    $adapter.ConnectionSpecificDNSSuffix = $ConnectionSpecificDNSSuffix
    $adapter.AppendParentSuffixes        = $AppendParentSuffixes
    $adapter.AppendDNSSuffixes           = $AppendDNSSuffixes
    $adapter.RegisterInDNS               = $RegisterInDNS
    $adapter.DnsSuffixInDnsRegistration  = $DnsSuffixInDnsRegistration
    $adapter.NetBIOSOptions              = $NetBIOSOptions
    $adapter.UseDhcp = $UseDhcp
    
    $adapter
    
    Write-LogFunctionExit
}
#endregion New-LabNetworkAdapterDefinition