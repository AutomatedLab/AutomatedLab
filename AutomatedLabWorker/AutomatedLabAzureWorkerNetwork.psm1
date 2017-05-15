$PSDefaultParameterValues = @{
    '*-Azure*:Verbose' = $false
    '*-Azure*:Warning' = $false
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
    
    Write-LogFunctionEntry

    $lab = Get-Lab
    $jobs = @()

    Write-ScreenInfo -Message "Creating Azure virtual networks '$($VirtualNetwork.Name -join ',')'" -TaskStart
    foreach ($network in $VirtualNetwork)
    {

        if (Get-LWAzureNetworkSwitch -VirtualNetwork $network)
        {
            Write-Verbose "Azure virtual network '$($network.Name)' already exists. Skipping..."
            continue
        }
        
             
        $azureNetworkParameters = @{
            Name = $network.Name
            ResourceGroupName = (Get-LabAzureDefaultResourceGroup)
            Location = (Get-LabAzureDefaultLocation)
            AddressPrefix = $network.AddressSpace
            ErrorAction = 'Stop'
            Tag = @{ 
                AutomatedLab = $script:lab.Name
                CreationTime = Get-Date	
            }
        }
        
        $jobs += Start-Job -Name "NewAzureVnet ($($network.Name))" -ScriptBlock {
            param
            (
                $ProfilePath,
                $Subscription,
                $azureNetworkParameters,
                $Subnets,
                $Network
            )
            
            Import-AzureRmContext -Path $ProfilePath
            Set-AzureRmContext -SubscriptionName $Subscription

            $azureSubnets = @()

            # Do the subnets inside the job. Azure cmdlets don't work with deserialized PSSubnets...
            if ($Subnets)
            {
                $azureSubnets += New-AzureRmVirtualNetworkSubnetConfig -Name $subnets.Name -AddressPrefix "$($subnets.Address)/$($subnets.Prefix)"
            }

            if (-not $azureSubnets)
            {
                # Add default subnet for machine
                $azureSubnets += New-AzureRmVirtualNetworkSubnetConfig -Name 'default' -AddressPrefix $Network.AddressSpace
            }

            if ($azureSubnets)
            {
                $azureNetworkParameters.Add('Subnet', $azureSubnets)
            }
            
            $azureNetwork = New-AzureRmVirtualNetwork @azureNetworkParameters -Force
        } -ArgumentList $lab.AzureSettings.AzureProfilePath, $lab.AzureSettings.DefaultSubscription.Name, $azureNetworkParameters, $network.Subnets, $network
    }
    
    #Wait for network creation jobs and configure vnet peering    
    Wait-LWLabJob -Job $jobs
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
            $sourceNetwork = Get-AzureRmVirtualNetwork -Name $network.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)

            foreach ($connectedNetwork in $network.ConnectToVnets)
            {
                # Configure bidirectional access
                $remoteNetwork = Get-AzureRmVirtualNetwork -Name $connectedNetwork -ResourceGroupName (Get-LabAzureDefaultResourceGroup)

                Write-Verbose -Message "Configuring VNet peering $($sourceNetwork.Name) <-> $($remoteNetwork.Name)"
                
                $existingPeerings = Get-AzureRmVirtualNetworkPeering -VirtualNetworkName $sourceNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)
                $alreadyExists = foreach ($existingPeering in $existingPeerings)
                {
                    $targetVirtualNetwork = Get-AzureRmResource -ResourceId $existingPeering.RemoteVirtualNetwork.Id
                    
                    $existingPeering.VirtualNetworkName -eq $sourceNetwork.Name -and $targetVirtualNetwork.Name -eq $remoteNetwork.Name
                }
                
                if (-not $alreadyExists)
                {
                    Add-AzureRmVirtualNetworkPeering -Name "$($network.Name)_to_$connectedNetwork" -VirtualNetwork $sourceNetwork -RemoteVirtualNetworkId $remoteNetwork.Id -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
                }
                
                $existingPeerings = Get-AzureRmVirtualNetworkPeering -VirtualNetworkName $remoteNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)
                $alreadyExists = foreach ($existingPeering in $existingPeerings)
                {
                    $targetVirtualNetwork = Get-AzureRmResource -ResourceId $existingPeering.RemoteVirtualNetwork.Id
                    
                    $existingPeering.VirtualNetworkName -eq $remoteNetwork.Name -and $targetVirtualNetwork.Name -eq $sourceNetwork.Name
                }

                if (-not (Get-AzureRmVirtualNetworkPeering -VirtualNetworkName $remoteNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)))
                {
                    Add-AzureRmVirtualNetworkPeering -Name "$($connectedNetwork)_to_$($network.Name)" -VirtualNetwork $remoteNetwork -RemoteVirtualNetworkId $sourceNetwork.Id -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
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
    
    Write-LogFunctionEntry

    $lab = Get-Lab
    
    Write-ScreenInfo -Message "Removing virtual network(s) '$($VirtualNetwork.Name -join ', ')'" -Type Warning
    
    foreach ($network in $VirtualNetwork)
    {
        Write-Verbose "Start removal of virtual network '$($network.name)'"
        
        $cmd = [scriptblock]::Create("Import-Module -Name Azure*; Import-AzureRmContext -Path $($lab.AzureSettings.AzureProfilePath);Select-AzureRmSubscription -SubscriptionName $($lab.AzureSettings.DefaultSubscription.Name); Remove-AzureRmVirtualNetwork -Name $($network.name) -ResourceGroupName $(Get-LabAzureDefaultResourceGroup) -Force")
        Start-Job -Name "RemoveAzureVNet ($($network.name))" -ScriptBlock $cmd | Out-Null
    }
    $jobs = Get-Job -Name RemoveAzureVNet*
    Write-Verbose "Waiting on the removal of $($jobs.Count)"
    $jobs | Wait-Job | Out-Null
    
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
    $lab = Get-Lab
    $jobs = @()
    
    foreach ($network in $VirtualNetwork)
    {
        Write-ScreenInfo -Message "Locating Azure virtual network '$($network.Name)'" -TaskStart
         
        $azureNetworkParameters = @{
            Name = $network.Name
            ResourceGroupName = (Get-LabAzureDefaultResourceGroup)
            ErrorAction = 'SilentlyContinue'
        }
        
        Get-AzureRmVirtualNetwork @azureNetworkParameters
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

    $lab = Get-Lab
    $resourceGroup = $lab.Name
    $location = $lab.AzureSettings.DefaultLocation.DisplayName

    foreach ($vNet in $lab.VirtualNetworks)
    {
        $publicIp = Get-AzureRmPublicIpAddress -Name "$($resourceGroup)$($vNet.Name)lbfrontendip" -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue
        if (-not $publicIp)
        {
            $publicIp = New-AzureRmPublicIpAddress -Name "$($resourceGroup)$($vNet.Name)lbfrontendip" -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Static -IpAddressVersion IPv4 -DomainNameLabel "$($resourceGroup.ToLower())$($vNet.Name.ToLower())"
        }

        $frontendConfig = New-AzureRmLoadBalancerFrontendIpConfig -Name "$($resourceGroup)$($vNet.Name)lbfrontendconfig" -PublicIpAddress $publicIp
        $backendConfig = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "$($resourceGroup)$($vNet.Name)backendpoolconfig"

        $inboundRules = @()
        foreach ($machine in ($ConnectedMachines | Where-Object -Property Network -EQ $vNet.Name))
        {
            $inboundRules += New-AzureRmLoadBalancerInboundNatRuleConfig -Name "$($machine.Name.ToLower())rdpin" -FrontendIpConfiguration $frontendConfig -Protocol Tcp -FrontendPort $machine.LoadBalancerRdpPort -BackendPort 3389
            $inboundRules += New-AzureRmLoadBalancerInboundNatRuleConfig -Name "$($machine.Name.ToLower())winrmin" -FrontendIpConfiguration $frontendConfig -Protocol Tcp -FrontendPort $machine.LoadBalancerWinRmHttpPort -BackendPort 5985
            $inboundRules += New-AzureRmLoadBalancerInboundNatRuleConfig -Name "$($machine.Name.ToLower())winrmhttpsin" -FrontendIpConfiguration $frontendConfig -Protocol Tcp -FrontendPort $machine.LoadBalancerWinrmHttpsPort -BackendPort 5986
        }

        $loadBalancer = New-AzureRmLoadBalancer -Name "$($resourceGroup)$($vNet.Name)loadbalancer" -ResourceGroupName $resourceGroup -Location $location -FrontendIpConfiguration $frontendConfig -BackendAddressPool $backendConfig -InboundNatRule $inboundRules -Force
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
        $null = $azureVnet | Set-AzureRmVirtualNetwork -ErrorAction SilentlyContinue

        if ($PassThru)
        {
            $azureVnet
        }
        
        Write-ScreenInfo -Message "Successfully set DNS servers for $($network.Name)" -TaskStart
    }

    Write-LogFunctionExit
}
