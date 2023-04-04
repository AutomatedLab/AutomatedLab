function Connect-OnPremisesWithEndpoint
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LabName,
        [Parameter(Mandatory = $true)]
        [System.String]
        $DestinationHost,
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $AddressSpace,
        [Parameter(Mandatory = $true)]
        [System.String]
        $Psk
    )

    Write-LogFunctionEntry
    Import-Lab $LabName -NoValidation

    $lab = Get-Lab
    $router = Get-LabVm -Role Routing -ErrorAction SilentlyContinue

    if (-not $router)
    {
        throw @'
        No router in your lab. Please redeploy your lab after adding e.g. the following lines:
        Add-LabVirtualNetworkDefinition -Name External -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }
        $netAdapter = @()
        $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName
        $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch External -UseDhcp
        $machineName = "ALS2SVPN$((1..7 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"
        Add-LabMachineDefinition -Name $machineName -Roles Routing -NetworkAdapter $netAdapter -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)'
'@
    }

    $externalAdapters = $router.NetworkAdapters | Where-Object { $_.VirtualSwitch.SwitchType -eq 'External' }

    if ($externalAdapters.Count -ne 1)
    {
        throw "Automatic configuration of VPN gateway can only be done if there is exactly 1 network adapter connected to an external network switch. The machine '$machine' knows about $($externalAdapters.Count) externally connected adapters"
    }

    $externalAdapter = $externalAdapters[0]
    $mac = $externalAdapter.MacAddress
    $mac = ($mac | Get-StringSection -SectionSize 2) -join '-'

    $scriptBlock = {
        param
        (
            $DestinationHost,
            $RemoteAddressSpaces
        )

        $status = Get-RemoteAccess -ErrorAction SilentlyContinue
        if ($status.VpnS2SStatus -ne 'Installed' -or $status.RoutingStatus -ne 'Installed')
        {
            Install-RemoteAccess -VpnType VPNS2S -ErrorAction Stop
        }

        Restart-Service -Name RemoteAccess

        $remoteConnection = Get-VpnS2SInterface -Name AzureS2S -ErrorAction SilentlyContinue

        if (-not $remoteConnection)
        {
            $parameters = @{
                Name                 = 'ALS2S'
                Protocol             = 'IKEv2'
                Destination          = $DestinationHost
                AuthenticationMethod = 'PskOnly'
                SharedSecret         = 'Somepass1'
                NumberOfTries        = 0
                Persistent           = $true
                PassThru             = $true
            }
            $remoteConnection = Add-VpnS2SInterface @parameters
        }

        $remoteConnection | Connect-VpnS2SInterface -ErrorAction Stop

        $dialupInterfaceIndex = (Get-NetIPInterface | Where-Object -Property InterfaceAlias -eq 'ALS2S').ifIndex

        foreach ($addressSpace in $RemoteAddressSpaces)
        {
            New-NetRoute -DestinationPrefix $addressSpace -InterfaceIndex $dialupInterfaceIndex -AddressFamily IPv4 -NextHop 0.0.0.0 -RouteMetric 1
        }
    }

    Invoke-LabCommand -ActivityName 'Enabling S2S VPN functionality and configuring S2S VPN connection' `
        -ComputerName $router `
        -ScriptBlock $scriptBlock `
        -ArgumentList @($DestinationHost, $AddressSpace) `
        -Retries 3 -RetryIntervalInSeconds 10

    Write-LogFunctionExit
}
