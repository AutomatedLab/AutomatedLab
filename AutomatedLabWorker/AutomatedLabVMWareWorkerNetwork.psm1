#region Get-LWVMwareNetworkSwitch
function Get-LWVMwareNetworkSwitch
{
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.VirtualNetwork[]]$VirtualNetwork
    )

    Write-LogFunctionEntry

    foreach ($network in $VirtualNetwork)
    {
        Write-ScreenInfo -Message "Validation of network switch '$($network.Name)'" -Type Info

        # the SwitchType property does not fit very well for VMware infrastructures, translate switch types internally
        If($network.SwitchType -eq 'Internal')
        {
            $SwitchType = 'StandardSwitch'
            $network = Get-VirtualPortgroup -Name $network.Name -ErrorAction SilentlyContinue

            if (-not $network)
            {
                Write-Error "Network port group '$($network.Name)' associated with standard switch is not configured"
            }
        }
        ElseIf($network.SwitchType -eq 'External')
        {
            $SwitchType = 'DistributedSwitch'
            $network = Get-VDPortgroup -Name $network.Name -ErrorAction SilentlyContinue

            if (-not $network)
            {
                Write-Error "Network port group '$($network.Name)' associated with distributed switch is not configured"
            }
        }

        $network
    }

    Write-LogFunctionExit
}
#endregion Get-LWVMwareNetworkSwitch

#region New-LWVMwareNetworkSwitch
function New-LWVMwareNetworkSwitch
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

        # the SwitchType property does not fit very well for VMware infrastructures, translate switch types internally
        If($network.SwitchType -eq 'Internal')
        {
            $SwitchType = 'StandardSwitch'
        }
        ElseIf($network.SwitchType -eq 'External')
        {
            $SwitchType = 'DistributedSwitch'
        }

        Write-ScreenInfo -Message "Creating VMware virtual network '$($network.Name)' using $SwitchType" -TaskStart

        if ((Get-NetIPAddress -AddressFamily IPv4) -contains $network.AddressSpace.FirstUsable)
        {
            Write-ScreenInfo -Message "The IP '$($network.AddressSpace.FirstUsable)' address for network switch '$($network.Name)' is already in use" -Type Error
            return
        }

        # the SwitchType property does not fit very well for VMware infrastructures, translate switch types internally
        If($network.SwitchType -eq 'Internal')
        {
            $SwitchType = 'StandardSwitch'
            if (Get-VirtualPortgroup -Name $network.Name -ErrorAction SilentlyContinue)
            {
                Write-ScreenInfo -Message "The network standard switch '$($network.Name)' already exists" -Type Warning
                continue
            }
        }
        ElseIf($network.SwitchType -eq 'External')
        {
            $SwitchType = 'DistributedSwitch'
            
            if(Get-VDSwitch -Name $network.Name -ErrorAction SilentlyContinue)
            {
                Write-ScreenInfo -Message "The network distributed switch '$($network.Name)' already exists" -Type Warning
            }
            else
            {
                $Name = $network.Name
                $Location = $network.LocationName
                
                New-VDSwitch -Name $Name -Location $Location -ErrorAction Stop
            }
            
            if (Get-VDPortgroup -Name $network.Name -ErrorAction SilentlyContinue)
            {
                Write-ScreenInfo -Message "The network distributed switch port group '$($network.Name)' already exists" -Type Warning
                continue
            }
            else
            {
                Get-VDSwitch -Name $Name | New-VDPortgroup -Name $Name
            }
        }

        #### ToDo: implement creation of distributed port group and standard switch/port group

        Write-ScreenInfo -Message "Done" -TaskEnd

        if ($PassThru)
        {
            $switch
        }
    }

    Write-LogFunctionExit
}
#endregion New-LWVMwareNetworkSwitch