function New-LWHypervNetworkSwitch
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.VirtualNetwork[]]$VirtualNetwork,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    foreach ($network in $VirtualNetwork)
    {
        if (-not $network.ResourceName)
        {
            throw 'No name specified for virtual network to be created'
        }

        Write-ScreenInfo -Message "Creating Hyper-V virtual network '$($network.ResourceName)'" -TaskStart

        if (Get-VMSwitch -Name $network.ResourceName -ErrorAction SilentlyContinue)
        {
            Write-ScreenInfo -Message "The network switch '$($network.ResourceName)' already exists, no changes will be made to configuration" -Type Warning
            continue
        }

        if ((Get-NetIPAddress -AddressFamily IPv4) -contains $network.AddressSpace.FirstUsable)
        {
            Write-ScreenInfo -Message "The IP '$($network.AddressSpace.FirstUsable)' Address for network switch '$($network.ResourceName)' is already in use" -Type Error
            return
        }

        try
        {
            $switchCreation = Get-LabConfigurationItem -Name SwitchDeploymentInProgressPath
            while (Test-Path -Path $switchCreation)
            {
                Start-Sleep -Milliseconds 250
            }

            $null = New-Item -Path $switchCreation -ItemType File -Value (Get-Lab).Name
            if ($network.SwitchType -eq 'External')
            {
                $adapterMac = (Get-NetAdapter -Name $network.AdapterName).MacAddress
                $adapterCountWithSameMac = (Get-NetAdapter | Where-Object { $_.MacAddress -eq $adapterMac -and $_.DriverDescription -ne 'Microsoft Network Adapter Multiplexor Driver' } | Group-Object -Property MacAddress).Count
                if ($adapterCountWithSameMac -gt 1)
                {
                    if (Get-NetLbfoTeam -Name $network.AdapterName)
                    {
                        Write-ScreenInfo -Message "Network Adapter ($($network.AdapterName)) is a teamed interface, ignoring duplicate MAC checking" -Type Warning
                    }
                    else
                    {
                        throw "The given network adapter ($($network.AdapterName)) for the external virtual switch ($($network.ResourceName)) is already part of a network bridge and cannot be used."
                    }
                }

                $switch = New-VMSwitch -NetAdapterName $network.AdapterName -Name $network.ResourceName -AllowManagementOS $network.EnableManagementAdapter -ErrorAction Stop
            }
            else
            {
                try
                {
                    $switch = New-VMSwitch -Name $network.ResourceName -SwitchType ([string]$network.SwitchType) -ErrorAction Stop
                }
                catch
                {
                    Start-Sleep -Seconds 2
                    $switch = New-VMSwitch -Name $network.ResourceName -SwitchType ([string]$network.SwitchType) -ErrorAction Stop
                }

                Set-LWHypervNetworkSwitchDescription -NetworkSwitchName $network.ResourceName -Hashtable @{
                    CreatedBy = '{0} ({1})' -f $PSCmdlet.MyInvocation.MyCommand.Module.Name, $PSCmdlet.MyInvocation.MyCommand.Module.Version
                    CreationTime = Get-Date
                    LabName = (Get-Lab).Name
                }
            }
        }
        finally
        {
            Remove-Item -Path $switchCreation -ErrorAction SilentlyContinue
        }

        Start-Sleep -Seconds 1

        if ($network.EnableManagementAdapter) {

            $config = Get-NetAdapter | Where-Object Name -Match "^vEthernet \($($network.ResourceName)\) ?(\d{1,2})?"
            if (-not $config)
            {
                throw "The network adapter for network switch '$network' could not be found. Cannot set up address hence will not be able to contact the machines"
            }

            if ($null -ne $network.ManagementAdapter.InterfaceName)
            {
                #A management adapter was defined, use its provided IP settings
                $adapterIpAddress = if ($network.ManagementAdapter.ipv4Address.IpAddress -eq $network.ManagementAdapter.ipv4Address.Network)
                {
                    $network.ManagementAdapter.ipv4Address.FirstUsable
                }
                else
                {
                    $network.ManagementAdapter.ipv4Address.IpAddress
                }

                $adapterCidr = if ($network.ManagementAdapter.ipv4Address.Cidr)
                {
                    $network.ManagementAdapter.ipv4Address.Cidr
                }
                else
                {
                    #default to a class C (255.255.255.0) CIDR if one wasnt supplied
                    24
                }

                #Assign the IP address to the interface, implementing a default gateway if one was supplied
                if ($network.ManagementAdapter.ipv4Gateway) {
                    $null = New-NetIPAddress -InterfaceAlias "vEthernet ($($network.ResourceName))" -IPAddress $adapterIpAddress.AddressAsString -AddressFamily IPv4 -PrefixLength $adapterCidr -DefaultGateway $network.ManagementAdapter.ipv4Gateway.AddressAsString
                }
                else
                {
                    $null = New-NetIPAddress -InterfaceAlias "vEthernet ($($network.ResourceName))" -IPAddress $adapterIpAddress.AddressAsString -AddressFamily IPv4 -PrefixLength $adapterCidr
                }

                if (-not $network.ManagementAdapter.AccessVLANID -eq 0) {
                    #VLANID has been specified for the vEthernet Adapter, so set it
                    Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName $network.ResourceName -Access -VlanId $network.ManagementAdapter.AccessVLANID
                }
            }
            else
            {
                #if no address space has been defined, the management adapter will just be left as a DHCP-enabled interface
                if ($null -ne $network.AddressSpace)
                {
                    #if the network address was defined, get the first usable IP for the network adapter
                    $adapterIpAddress = if ($network.AddressSpace.IpAddress -eq $network.AddressSpace.Network)
                    {
                        $network.AddressSpace.FirstUsable
                    }
                    else
                    {
                        $network.AddressSpace.IpAddress
                    }

                    while ($adapterIpAddress -in (Get-LabMachineDefinition).IpAddress.IpAddress)
                    {
                        $adapterIpAddress = $adapterIpAddress.Increment()
                    }

                    $null = $config | Set-NetIPInterface -Dhcp Disabled
                    $null = $config | Remove-NetIPAddress -Confirm:$false
                    $null = $config | New-NetIPAddress -IPAddress $adapterIpAddress.AddressAsString -AddressFamily IPv4 -PrefixLength $network.AddressSpace.Cidr
                }
                else
                {
                    Write-ScreenInfo -Message "Management Interface for switch '$($network.ResourceName)' on Network Adapter '$($network.AdapterName)' has no defined AddressSpace and will remain DHCP enabled, ensure this is desired behaviour." -Type Warning
                }
            }
        }
        Write-ScreenInfo -Message "Done" -TaskEnd

        if ($PassThru)
        {
            $switch
        }
    }

    Write-LogFunctionExit
}
