$PSDefaultParameterValues = @{
    '*-Azure*:Verbose'      = $false
    '*-Azure*:Warning'      = $false
    'Import-Module:Verbose' = $false
}

#region New-LWAzureNetworkSwitch
function New-LWAzureNetworkSwitch
{
    param
    (
        [Parameter(Mandatory)]
        [AutomatedLab.VirtualNetwork[]]
        $VirtualNetwork,

        [switch]
        $PassThru
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $lab = Get-Lab
    $jobs = @()

    Write-ScreenInfo -Message "Creating Azure virtual networks '$($VirtualNetwork.Name -join ',')'" -TaskStart
    $jobs = foreach ($network in $VirtualNetwork)
    {
        if (Get-LWAzureNetworkSwitch -VirtualNetwork $network)
        {
            Write-Verbose "Azure virtual network '$($network.Name)' already exists. Skipping..."
            continue
        }

        $azureNetworkParameters = @{
            Name              = $network.Name
            ResourceGroupName = (Get-LabAzureDefaultResourceGroup)
            Location          = (Get-LabAzureDefaultLocation)
            AddressPrefix     = $network.AddressSpace
            ErrorAction       = 'Stop'
            Tag               = @{
                AutomatedLab = $script:lab.Name
                CreationTime = Get-Date
            }
        }
         
        $azureSubnets = @()
        
        foreach ($subnet in $network.Subnets)
        {
            $azureSubnets += New-AzVirtualNetworkSubnetConfig -Name $subnet.Name -AddressPrefix $subnet.AddressSpace.ToString()
        }

        if (-not $azureSubnets)
        {
            # Add default subnet for machine
            $azureSubnets += New-AzVirtualNetworkSubnetConfig -Name 'default' -AddressPrefix $Network.AddressSpace
        }

        $azureNetworkParameters.Add('Subnet', $azureSubnets)

        New-AzVirtualNetwork @azureNetworkParameters -Force -WarningAction SilentlyContinue -AsJob
    }

    #Wait for network creation jobs and configure vnet peering
    Wait-LWLabJob -Job $jobs

    if ($jobs.State -contains 'Failed')
    {
        throw ('Creation of at least one Azure Vnet failed. Examine the jobs output. Failed jobs: {0}' -f (($jobs | Where-Object State -EQ 'Failed').Id -join ','))
    }

    Write-ScreenInfo -Message "Done" -TaskEnd
    Write-ProgressIndicator

    foreach ($network in $VirtualNetwork)
    {
        if (-not $network.ConnectToVnets)
        {
            Write-Verbose "The network '$($network.Name)' is not connected hence no need for creating a gateway"
        }
        else
        {
            $sourceNetwork = Get-AzVirtualNetwork -Name $network.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup) -WarningAction SilentlyContinue

            foreach ($connectedNetwork in $network.ConnectToVnets)
            {
                # Configure bidirectional access
                $remoteNetwork = Get-AzVirtualNetwork -Name $connectedNetwork -ResourceGroupName (Get-LabAzureDefaultResourceGroup) -WarningAction SilentlyContinue

                Write-Verbose -Message "Configuring VNet peering $($sourceNetwork.Name) <-> $($remoteNetwork.Name)"

                $existingPeerings = Get-AzVirtualNetworkPeering -VirtualNetworkName $sourceNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)
                $alreadyExists = foreach ($existingPeering in $existingPeerings)
                {
                    $targetVirtualNetwork = Get-AzResource -ResourceId $existingPeering.RemoteVirtualNetwork.Id

                    $existingPeering.VirtualNetworkName -eq $sourceNetwork.Name -and $targetVirtualNetwork.Name -eq $remoteNetwork.Name
                }

                if (-not $alreadyExists)
                {
                    Add-AzVirtualNetworkPeering -Name "$($network.Name)_to_$connectedNetwork" -VirtualNetwork $sourceNetwork -RemoteVirtualNetworkId $remoteNetwork.Id -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
                }

                $existingPeerings = Get-AzVirtualNetworkPeering -VirtualNetworkName $remoteNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)
                $alreadyExists = foreach ($existingPeering in $existingPeerings)
                {
                    $targetVirtualNetwork = Get-AzResource -ResourceId $existingPeering.RemoteVirtualNetwork.Id

                    $existingPeering.VirtualNetworkName -eq $remoteNetwork.Name -and $targetVirtualNetwork.Name -eq $sourceNetwork.Name
                }

                if (-not (Get-AzVirtualNetworkPeering -VirtualNetworkName $remoteNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)))
                {
                    Add-AzVirtualNetworkPeering -Name "$($connectedNetwork)_to_$($network.Name)" -VirtualNetwork $remoteNetwork -RemoteVirtualNetworkId $sourceNetwork.Id -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
                }
                Write-Verbose -Message 'Peering successfully configured'
            }
        }
    }

    Write-LogFunctionExit
}
#endregion New-LWNetworkSwitch
#region Remove-LWNetworkSwitch
function Remove-LWAzureNetworkSwitch
{
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.VirtualNetwork[]]$VirtualNetwork
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $lab = Get-Lab
    $resourceGroupName = Get-LabAzureDefaultResourceGroup

    Write-ScreenInfo -Message "Removing virtual network(s) '$($VirtualNetwork.Name -join ', ')'" -Type Warning    

    
    $jobs = foreach ($network in $VirtualNetwork)
    {
        Write-Verbose "Start removal of virtual network '$($network.name)'"
        Remove-AzVirtualNetwork -Name $network.Name -ResourceGroupName $resourceGroupName -AsJob -Force
    }
    
    Write-Verbose "Waiting on the removal of $($jobs.Count)"
    Wait-LWLabJob -Job $jobs

    Write-Verbose "Virtual network(s) '$($VirtualNetwork.Name -join ', ')' removed from Azure"

    Write-LogFunctionExit
}
#endregion Remove-LWNetworkSwitch

#region Get-LWAzureNetworkSwitch
function Get-LWAzureNetworkSwitch
{
    param
    (
        [Parameter(Mandatory)]
        [AutomatedLab.VirtualNetwork[]]
        $virtualNetwork
    )

    Test-LabHostConnected -Throw -Quiet

    $lab = Get-Lab
    $jobs = @()

    foreach ($network in $VirtualNetwork)
    {
        Write-Verbose -Message "Locating Azure virtual network '$($network.Name)'"

        $azureNetworkParameters = @{
            Name              = $network.Name
            ResourceGroupName = (Get-LabAzureDefaultResourceGroup)
            ErrorAction       = 'SilentlyContinue'
            WarningAction     = 'SilentlyContinue'
        }

        Get-AzVirtualNetwork @azureNetworkParameters
    }
}
#endregion
#endregion Remove-LWNetworkSwitch
#region New-LWAzureLoadBalancer
function New-LWAzureLoadBalancer
{
    param
    (
        [AutomatedLab.Machine[]]$ConnectedMachines,
        [switch]$PassThru,
        [switch]$Wait
    )

    Test-LabHostConnected -Throw -Quiet

    $lab = Get-Lab
    $resourceGroup = $lab.Name
    $location = $lab.AzureSettings.DefaultLocation.DisplayName

    $jobs = foreach ($vNet in $lab.VirtualNetworks)
    {
        $publicIp = Get-AzPublicIpAddress -Name "$($resourceGroup)$($vNet.Name)lbfrontendip" -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue

        $dnsLabel = "$((1..10 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"

        if ($vNet.AzureDnsLabel)
        {
            $dnsLabel = $vNet.AzureDnsLabel
        }

        if (-not $publicIp)
        {
            $publicIp = New-AzPublicIpAddress -Name "$($resourceGroup)$($vNet.Name)lbfrontendip" -ResourceGroupName $resourceGroup `
                -Location $location -AllocationMethod Static -IpAddressVersion IPv4 `
                -DomainNameLabel $dnsLabel -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }

        $frontendConfig = New-AzLoadBalancerFrontendIpConfig -Name "$($resourceGroup)$($vNet.Name)lbfrontendconfig" -PublicIpAddress $publicIp
        $backendConfig = New-AzLoadBalancerBackendAddressPoolConfig -Name "$($resourceGroup)$($vNet.Name)backendpoolconfig"

        $inboundRules = @()
        foreach ($machine in ($ConnectedMachines | Where-Object -Property Network -EQ $vNet.Name))
        {
            $inboundRules += New-AzLoadBalancerInboundNatRuleConfig -Name "$($machine.Name.ToLower())rdpin" -FrontendIpConfiguration $frontendConfig -Protocol Tcp -FrontendPort $machine.LoadBalancerRdpPort -BackendPort 3389
            $inboundRules += New-AzLoadBalancerInboundNatRuleConfig -Name "$($machine.Name.ToLower())winrmin" -FrontendIpConfiguration $frontendConfig -Protocol Tcp -FrontendPort $machine.LoadBalancerWinRmHttpPort -BackendPort 5985
            $inboundRules += New-AzLoadBalancerInboundNatRuleConfig -Name "$($machine.Name.ToLower())winrmhttpsin" -FrontendIpConfiguration $frontendConfig -Protocol Tcp -FrontendPort $machine.LoadBalancerWinrmHttpsPort -BackendPort 5986
        }

        New-AzLoadBalancer -Name "$($resourceGroup)$($vNet.Name)loadbalancer" -ResourceGroupName $resourceGroup -Location $location -FrontendIpConfiguration $frontendConfig -BackendAddressPool $backendConfig -InboundNatRule $inboundRules -Force -WarningAction SilentlyContinue -AsJob
    }

    # If Wait is not used, return either nothing or the jobs
    if (-not $Wait.IsPresent)
    {
        if ($PassThru.IsPresent)
        {
            return $jobs
        }

        return
    }

    # Wait for jobs
    Wait-LWLabJob -Job $jobs
    $failedJobs = $jobs | Where-Object -Property State -eq Failed

    if ($failedJobs)
    {
        throw "One or more load balancers could not be created. Lab deployment cannot continue. Check the output of the following cmdlet for details: Get-Job -Id $($failedJobs.Id) | Receive-Job -Keep"
    }

    if ($PassThru)
    {
        $jobs | Receive-Job -Keep
    }
}
#endregion

#region Remove-LWAzureLoadBalancer
function Remove-LWAzureLoadBalancer
{
    throw "Not implemented"
}
#endregion

#region Set-LWAzureDnsServer
function Set-LWAzureDnsServer
{
    param
    (
        [Parameter(Mandatory)]
        [AutomatedLab.VirtualNetwork[]]
        $VirtualNetwork,

        [switch]
        $PassThru
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    foreach ($network in $VirtualNetwork)
    {
        if ($network.DnsServers.Count -eq 0)
        {
            Write-Verbose -Message "Skipping $($network.Name) because no DNS servers are configured"
            continue
        }

        Write-ScreenInfo -Message "Setting DNS servers for $($network.Name)" -TaskStart
        $azureVnet = Get-LWAzureNetworkSwitch -VirtualNetwork $network -ErrorAction SilentlyContinue
        if (-not $azureVnet)
        {
            Write-Error "$($network.Name) does not exist"
            continue
        }

        $azureVnet.DhcpOptions.DnsServers = New-Object -TypeName System.Collections.Generic.List[string]
        $network.DnsServers.AddressAsString | ForEach-Object { $azureVnet.DhcpOptions.DnsServers.Add($PSItem)}
        $null = $azureVnet | Set-AzVirtualNetwork -ErrorAction Stop -WarningAction SilentlyContinue

        if ($PassThru)
        {
            $azureVnet
        }

        Write-ScreenInfo -Message "Successfully set DNS servers for $($network.Name)" -TaskEnd
    }

    Write-LogFunctionExit
}

function Add-LWAzureLoadBalancedPort
{
    param
    (
        [Parameter()]
        [int]
        $Port,

        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    Test-LabHostConnected -Throw -Quiet

    if (Get-LabAzureLoadBalancedPort @PSBoundParameters)
    {
        Write-Verbose -Message ('Port {0} already configured for {1}' -f $Port, $ComputerName)
        return
    }

    $lab = Get-Lab
    $resourceGroup = $lab.Name
    $machine = Get-LabVm -ComputerName $ComputerName


    $lb = Get-AzLoadBalancer -ResourceGroupName $resourceGroup -WarningAction SilentlyContinue
    if (-not $lb)
    {
        Write-Verbose "No load balancer found to add port rules to"
        return
    }

    $frontendConfig = $lb | Get-AzLoadBalancerFrontendIpConfig

    $lab.AzureSettings.LoadBalancerPortCounter++
    $remotePort = $lab.AzureSettings.LoadBalancerPortCounter

    if (-not $Port)
    {
        $Port = $remotePort
    }
    $lb = Add-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "$($machine.Name.ToLower())$Port" -FrontendIpConfiguration $frontendConfig -Protocol Tcp -FrontendPort $remotePort -BackendPort $Port
    $lb = $lb | Set-AzLoadBalancer

    $vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $ComputerName
    $nic = $vm.NetworkProfile.NetworkInterfaces | Get-AzResource | Get-AzNetworkInterface
    $rules = Get-LWAzureLoadBalancedPort -ComputerName $ComputerName
    $nic.IpConfigurations[0].LoadBalancerInboundNatRules = $rules
    [void] ($nic | Set-AzNetworkInterface)

    if (-not $machine.InternalNotes."AdditionalPort$Port")
    {
        $machine.InternalNotes.Add("AdditionalPort$Port", $remotePort)
    }

    $machine.InternalNotes."AdditionalPort$Port" = $remotePort

    Export-Lab
}

function Get-LWAzureLoadBalancedPort
{
    param
    (

        [int]
        $Port,

        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    Test-LabHostConnected -Throw -Quiet

    $lab = Get-Lab
    $resourceGroup = $lab.Name

    $lb = Get-AzLoadBalancer -ResourceGroupName $resourceGroup -WarningAction SilentlyContinue
    if (-not $lb)
    {
        Write-Verbose "No load balancer found to list port rules of"
        return
    }

    $existingConfiguration = if ($Port)
    {
        $lb | Get-AzLoadBalancerInboundNatRuleConfig | Where-Object -Property Name -eq "$ComputerName$Port"
    }
    else
    {
        $lb | Get-AzLoadBalancerInboundNatRuleConfig | Where-Object -Property Name -like "$ComputerName*"
    }


    if ($Port)
    {
        return ($existingConfiguration | Where-Object -Property BackendPort -eq $Port)
    }

    return $existingConfiguration
}

function Get-LabAzureLoadBalancedPort
{
    param
    (
        [int]
        $Port,

        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    Test-LabHostConnected -Throw -Quiet

    $lab = Get-Lab -ErrorAction SilentlyContinue

    if (-not $lab)
    {
        Write-ScreenInfo -Type Warning -Message 'Lab data not available. Cannot list ports. Use Import-Lab to import an existing lab'
        return
    }

    $machine = Get-LabVm -ComputerName $ComputerName

    if (-not $machine)
    {
        Write-Verbose -Message "$ComputerName not found. Cannot list ports."
        return
    }

    if ($Port)
    {
        $machine.InternalNotes.GetEnumerator() | Where-Object -Property Key -eq "AdditionalPort$Port" | Select-Object -ExpandProperty Value
    }
    else
    {
        $machine.InternalNotes.GetEnumerator() | Where-Object -Property Key -like 'AdditionalPort*' | Select-Object -ExpandProperty Value
    }
}
