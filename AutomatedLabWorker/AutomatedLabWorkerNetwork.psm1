#region New-LWNetworkSwitch
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
        if (-not $network.Name)
        {
            throw 'No name specified for virtual network to be created'
        }

        Write-ScreenInfo -Message "Creating Hyper-V virtual network '$($network.Name)'" -TaskStart

        if (Get-VMSwitch -Name $network.Name -ErrorAction SilentlyContinue)
        {
            Write-ScreenInfo -Message "The network switch '$($network.Name)' already exists, no changes will be made to configuration" -Type Warning
            continue
        }

        if ((Get-NetIPAddress -AddressFamily IPv4) -contains $network.AddressSpace.FirstUsable)
        {
            Write-ScreenInfo -Message "The IP '$($network.AddressSpace.FirstUsable)' Address for network switch '$($network.Name)' is already in use" -Type Error
            return
        }

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
                    throw "The given network adapter ($($network.AdapterName)) for the external virtual switch ($($network.Name)) is already part of a network bridge and cannot be used."
                }
            }

            $switch = New-VMSwitch -NetAdapterName $network.AdapterName -Name $network.Name -AllowManagementOS $network.EnableManagementAdapter -ErrorAction Stop
        }
        else
        {
            try
            {
                $switch = New-VMSwitch -Name $network.Name -SwitchType ([string]$network.SwitchType) -ErrorAction Stop
            }
            catch
            {
                Start-Sleep -Seconds 2
                $switch = New-VMSwitch -Name $network.Name -SwitchType ([string]$network.SwitchType) -ErrorAction Stop
            }
        }

        Start-Sleep -Seconds 1

        if ($network.EnableManagementAdapter) {

            $config = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object NetConnectionID -Match "vEthernet \($($network.Name)\) ?(\d{1,2})?" | Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration
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
                    $null = New-NetIPAddress -InterfaceAlias "vEthernet ($($network.Name))" -IPAddress $adapterIpAddress.AddressAsString -AddressFamily IPv4 -PrefixLength $adapterCidr -DefaultGateway $network.ManagementAdapter.ipv4Gateway.AddressAsString
                }
                else
                {
                    $null = New-NetIPAddress -InterfaceAlias "vEthernet ($($network.Name))" -IPAddress $adapterIpAddress.AddressAsString -AddressFamily IPv4 -PrefixLength $adapterCidr
                }

                if (-not $network.ManagementAdapter.AccessVLANID -eq 0) {
                    #VLANID has been specified for the vEthernet Adapter, so set it
                    Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName $network.Name -Access -VlanId $network.ManagementAdapter.AccessVLANID
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

                    $arguments = @{
                        IPAddress = @($adapterIpAddress.AddressAsString)
                        SubnetMask = @($network.AddressSpace.Netmask.AddressAsString)
                    }

                    $result = $config | Invoke-CimMethod -MethodName EnableStatic -Arguments $arguments
                    if ($result.ReturnValue)
                    {
                        throw "Could not set the IP address '$($arguments.IPAddress)' with subnet mask '$($arguments.SubnetMask)' on adapter 'vEthernet ($($network.Name))'. The error code was $($result.ReturnValue). Lookup the documentation of the class Win32_NetworkAdapterConfiguration in the MSDN to get more information about the error code."
                    }
                }
                else
                {
                    Write-ScreenInfo -Message "Management Interface for switch '$($network.Name)' on Network Adapter '$($network.AdapterName)' has no defined AddressSpace and will remain DHCP enabled, ensure this is desired behaviour." -Type Warning
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
#endregion New-LWNetworkSwitch

#region Remove-LWNetworkSwitch
function Remove-LWNetworkSwitch
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-LogFunctionEntry

    if (-not (Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue))
    {
        Write-ScreenInfo 'The network switch does not exist' -Type Warning
        return
    }

    if ((Get-VM | Get-VMNetworkAdapter | Where-Object {$_.SwitchName -eq $Name} | Measure-Object).Count -eq 0)
    {
        try
        {
            Remove-VMSwitch -Name $Name -Force -ErrorAction Stop
        }
        catch
        {
            Start-Sleep -Seconds 2
            Remove-VMSwitch -Name $Name -Force
        }

        Write-PSFMessage "Network switch '$Name' removed"
    }
    else
    {
        Write-ScreenInfo "Network switch '$Name' is still in use, skipping removal" -Type Warning
    }

    Write-LogFunctionExit

}
#endregion Remove-LWNetworkSwitch
