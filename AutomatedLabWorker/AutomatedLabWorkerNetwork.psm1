#region New-LWNetworkSwitch
function New-LWHypervNetworkSwitch
{
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
            Write-ScreenInfo -Message "The network switch '$($network.Name)' already exists" -Type Warning
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
            $adapterCountWithSameMac = (Get-NetAdapter | Where-Object MacAddress -eq $adapterMac | Group-Object -Property MacAddress).Count
            if ($adapterCountWithSameMac -gt 1)
            {
                throw "The given network adapter ($($network.AdapterName)) for the external virtual switch ($($network.Name)) is already part of a network bridge and cannot be used."
            }
            
            $switch = New-VMSwitch -NetAdapterName $network.AdapterName -Name $network.Name -ErrorAction Stop
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

            Start-Sleep -Seconds 1
		
            $config = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object NetConnectionID -Match "vEthernet \($($network.Name)\) ?(\d{1,2})?" | Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration
            if (-not $config)
            {
                throw "The network adapter for network switch '$network' could not be found. Cannot set up address hence will not be able to contact the machines"
            }

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
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )
	
    Write-LogFunctionEntry
	
    if (-not (Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue))
    {
        Write-Warning 'The network switch does not exist'
        return
    }
    
    try
    {
        Remove-VMSwitch -Name $Name -Force -ErrorAction Stop
    }
    catch
    {
        Start-Sleep -Seconds 2
        Remove-VMSwitch -Name $Name -Force
    }
    
    Write-Verbose "Network switch '$Name' removed"
	
    Write-LogFunctionExit

}
#endregion Remove-LWNetworkSwitch