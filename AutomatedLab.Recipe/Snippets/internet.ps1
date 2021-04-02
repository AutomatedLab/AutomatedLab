$snippet = {
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'NoDefaultSwitch')]
        [switch]
        $NoDefaultSwitch,

        [Parameter(Mandatory, ParameterSetName = 'NoDefaultSwitch')]
        [string]
        $AdapterName
    )

    $externalNetworkName, $adapter = if ($NoDefaultSwitch)
    {
        '{0}EXT' -f (Get-LabDefinition).Name
        $AdapterName
    }
    else
    {
        'Default switch'
        'Ethernet' # unnecessary but required
    }

    Add-LabVirtualNetworkDefinition -Name $externalNetworkName -HyperVProperties @{ SwitchType = 'External'; AdapterName = $adapter }

    $adapters = @(
        New-LabNetworkAdapterDefinition -VirtualSwitch (Get-LabDefinition).Name
        New-LabNetworkAdapterDefinition -VirtualSwitch $externalNetworkName -UseDhcp
    )

    $router = Add-LabMachineDefinition -Name ('{0}GW01' -f $AutomatedLabVmNamePrefix) -Roles Routing -NetworkAdapter $adapters -PassThru
    $PSDefaultParameterValues['Add-LabMachineDefinition:Gateway'] = $router.NetworkAdapters.Where( { $_.VirtualSwitch.ResourceName -eq (Get-LabDefinition).Name }).Ipv4Address.IpAddress.ToString()
}

New-LabSnippet -Name InternetConnectivity -Description 'Basic snippet to add a router and external switch to the lab' -Tag Definition, Routing, Internet -Type Snippet -ScriptBlock $snippet -DependsOn LabDefinition -NoExport -Force
