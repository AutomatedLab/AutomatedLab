function Add-LabVirtualNetworkDefinition
{
    [CmdletBinding()]
    param (
        [string]$Name = (Get-LabDefinition).Name,

        [AllowNull()]
        [AutomatedLab.IPNetwork]$AddressSpace,

        [AutomatedLab.VirtualizationHost]$VirtualizationEngine,

        [hashtable[]]$HyperVProperties,

        [hashtable[]]$AzureProperties,

        [AutomatedLab.NetworkAdapter]$ManagementAdapter,

        [string]$ResourceName,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    if ((Get-LabDefinition).DefaultVirtualizationEngine -eq 'Azure' -and -not ((Get-LabDefinition).AzureSettings))
    {
        Add-LabAzureSubscription
    }

    $azurePropertiesValidKeys = 'Subnets', 'LocationName', 'DnsServers', 'ConnectToVnets', 'DnsLabel'
    $hypervPropertiesValidKeys = 'SwitchType', 'AdapterName', 'ManagementAdapter'

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

    if ($VirtualizationEngine -eq 'Azure' -and -not $script:lab.AzureSettings.DefaultResourceGroup)
    {
        Add-LabAzureSubscription
    }

    if ($AzureProperties)
    {
        $illegalKeys = Compare-Object -ReferenceObject $azurePropertiesValidKeys -DifferenceObject ($AzureProperties.Keys | Sort-Object -Unique) |
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

        if ($HyperVProperties.ManagementAdapter -eq $false -and $HyperVProperties.SwitchType -ne 'External')
        {
            throw 'Disabling the Management Adapter for private or internal VM Switch is not supported, as this will result in being unable to build labs'
        }

        if ($HyperVProperties.ManagementAdapter -eq $false -and $ManagementAdapter)
        {
            throw "A Management Adapter has been specified, however the Management Adapter for '$($Name)' has been disabled. Either re-enable the Management Adapter, or remove the -ManagementAdapter parameter"
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
    if ($ResourceName) {$network.FriendlyName = $ResourceName}
    if ($HyperVProperties.SwitchType) { $network.SwitchType = $HyperVProperties.SwitchType }
    if ($HyperVProperties.AdapterName) {$network.AdapterName = $HyperVProperties.AdapterName }
    if ($HyperVProperties.ManagementAdapter -eq $false) {$network.EnableManagementAdapter = $false }
    if ($ManagementAdapter) {$network.ManagementAdapter = $ManagementAdapter}

    #VLAN's are not supported on non-external interfaces
    if ($network.SwitchType -ne 'External' -and $network.ManagementAdapter.AccessVLANID -ne 0)
    {
        throw "A Management Adapter for Internal switch '$($network.Name)' has been specified with the -AccessVlanID parameter. This configuration is unsupported."
    }

    $network.HostType = $VirtualizationEngine

	if($AzureProperties.LocationName)
	{
		$network.LocationName = $AzureProperties.LocationName
	}

	if($AzureProperties.ConnectToVnets)
	{
		$network.ConnectToVnets = $AzureProperties.ConnectToVnets
	}

	if($AzureProperties.DnsServers)
	{
		$network.DnsServers = $AzureProperties.DnsServers
	}

	if($AzureProperties.Subnets)
	{
		foreach($subnet in $AzureProperties.Subnets.GetEnumerator())
		{
			$temp = New-Object -TypeName AutomatedLab.AzureSubnet
			$temp.Name = $subnet.Key
			$temp.AddressSpace = $subnet.Value
			$network.Subnets.Add($temp)
		}
    }

    if ($AzureProperties.DnsLabel)
    {
        $network.AzureDnsLabel = $AzureProperties.DnsLabel
    }

    if (-not $network.LocationName)
    {
        $network.LocationName = $script:lab.AzureSettings.DefaultLocation
    }

    $script:lab.VirtualNetworks.Add($network)
    Write-PSFMessage "Network '$Name' added. Lab has $($Script:lab.VirtualNetworks.Count) network(s) defined"

    if ($PassThru)
    {
        $network
    }
    Write-LogFunctionExit
}
