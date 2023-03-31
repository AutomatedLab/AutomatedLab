function Add-LWAzureLoadBalancedPort
{
    param
    (
        [Parameter(Mandatory)]
        [uint16]
        $Port,

        [Parameter(Mandatory)]
        [uint16]
        $DestinationPort,

        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    Test-LabHostConnected -Throw -Quiet

    if (Get-LabAzureLoadBalancedPort @PSBoundParameters)
    {
        Write-PSFMessage -Message ('Port {0} -> {1} already configured for {2}' -f $Port, $DestinationPort, $ComputerName)
        return
    }

    $lab = Get-Lab
    $resourceGroup = (Get-LabAzureDefaultResourceGroup).ResourceGroupName
    $machine = Get-LabVm -ComputerName $ComputerName
    $net = $lab.VirtualNetworks.Where({ $_.Name -eq $machine.Network[0] })

    $lb = Get-AzLoadBalancer -ResourceGroupName $resourceGroup | Where-Object {$_.Tag['Vnet'] -eq $net.ResourceName}
    if (-not $lb)
    {
        Write-PSFMessage "No load balancer found to add port rules to"
        return
    }

    $frontendConfig = $lb | Get-AzLoadBalancerFrontendIpConfig

    $lb = Add-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "$($machine.ResourceName.ToLower())-$Port-$DestinationPort" -FrontendIpConfiguration $frontendConfig -Protocol Tcp -FrontendPort $Port -BackendPort $DestinationPort
    $lb = $lb | Set-AzLoadBalancer

    $vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $machine.ResourceName
    $nic = $vm.NetworkProfile.NetworkInterfaces | Get-AzResource | Get-AzNetworkInterface
    $rules = Get-LWAzureLoadBalancedPort -ComputerName $ComputerName
    $nic.IpConfigurations[0].LoadBalancerInboundNatRules = $rules
    [void] ($nic | Set-AzNetworkInterface)

    # Extend NSG
    $nsg = Get-AzNetworkSecurityGroup -Name "nsg" -ResourceGroupName $resourceGroup

    $rule = $nsg | Get-AzNetworkSecurityRuleConfig -Name NecessaryPorts
    if (-not $rule.DestinationPortRange.Contains($DestinationPort))
    {
        $rule.DestinationPortRange.Add($DestinationPort)
        
        # Update the NSG.
        $nsg = $nsg | Set-AzNetworkSecurityRuleConfig -Name $rule.Name -DestinationPortRange $rule.DestinationPortRange -Protocol $rule.Protocol -SourcePortRange $rule.SourcePortRange -SourceAddressPrefix $rule.SourceAddressPrefix -DestinationAddressPrefix $rule.DestinationAddressPrefix -Access Allow -Priority $rule.Priority -Direction $rule.Direction
        $null = $nsg | Set-AzNetworkSecurityGroup
    }

    if (-not $machine.InternalNotes."AdditionalPort-$Port-$DestinationPort")
    {
        $machine.InternalNotes.Add("AdditionalPort-$Port-$DestinationPort", $DestinationPort)
    }

    $machine.InternalNotes."AdditionalPort-$Port-$DestinationPort" = $DestinationPort

    Export-Lab
}
