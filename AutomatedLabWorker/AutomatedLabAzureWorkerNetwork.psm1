$PSDefaultParameterValues = @{
    '*-Azure*:Verbose' = $false
    '*-Azure*:Warning' = $false
    'Import-Module:Verbose' = $false
}

#region New-LWAzureNetworkSwitch
function New-LWAzureNetworkSwitch
{
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.VirtualNetwork[]]$VirtualNetwork,
		
        [switch]$PassThru
    )
	
    Write-LogFunctionEntry

	$lab = Get-Lab
	
    foreach ($network in $VirtualNetwork)
    {
        Write-ScreenInfo -Message "Creating Azure virtual network '$($network.Name)'" -TaskStart
             
		$azureNetworkParameters = @{
			Name = $network.Name
			ResourceGroupName = (Get-LabAzureDefaultResourceGroup)
			Location = (Get-LabAzureDefaultLocation)
			AddressPrefix = $network.AddressSpace
			ErrorAction = 'Stop'
		}		

		if ($network.DnsServers)
        {
            $azureNetworkParameters.Add('DnsServer', $network.DnsServers)
        }
		
		Start-Job -Name "NewAzureVnet ($($network.Name))" -ScriptBlock {
		param
		(
			$profilePath,
			$Subscription,
			$azureNetworkParameters,
			$Subnets,
			$network
		)
			Import-Module -Name Azure*
			Select-AzureRmProfile -Path $profilePath
			Select-AzureRmSubscription -SubscriptionName $Subscription

			$AzureSubnets = @()

			# Do the subnets inside the job. Azure cmdlets don't work with deserialized PSSubnets...
			if($Subnets)
			{
				$AzureSubnets += New-AzureRmVirtualNetworkSubnetConfig -Name $subnet.Name -AddressPrefix "$($subnet.Address)/$($subnet.Prefix)"
			}

			if(-not $AzureSubnets)
			{
				# Add default subnet for machine
				$AzureSubnets += New-AzureRmVirtualNetworkSubnetConfig -Name 'default' -AddressPrefix $network.AddressSpace
			}

			if($AzureSubnets)
			{
				$azureNetworkParameters.Add('Subnet',$AzureSubnets)
			}
			
			$AzureNetwork = New-AzureRmVirtualNetwork @azureNetworkParameters -Force
		} -ArgumentList $lab.AzureSettings.AzureProfilePath, $lab.AzureSettings.DefaultSubscription.SubscriptionName,$azureNetworkParameters,$network.Subnets,$network

		Write-ScreenInfo -Message "Done" -TaskEnd
    }
    
    # Wait for network creation jobs and configure vnet peering

    
    while(Get-Job -Name 'NewAzureVnet*' | Where-Object -Property State -EQ Running)
	{
		Write-Verbose 'Waiting for Azure virtual network creation to finish before enabling virtual network peering'
		Start-Sleep -Seconds 1
	}

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

			foreach($connectedNetwork in $network.ConnectToVnets)
			{
				# Configure bidirectional access
				$remoteNetwork = Get-AzureRmVirtualNetwork -Name $connectedNetwork -ResourceGroupName (Get-LabAzureDefaultResourceGroup)

				Write-Verbose -Message "Configuring VNet peering $($sourceNetwork.Name) <-> $($remoteNetwork.Name)"
				if(-not (Get-AzureRmVirtualNetworkPeering -VirtualNetworkName $sourceNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)))
				{
					$null = Add-AzureRmVirtualNetworkPeering -Name "$($network.Name)_to_$connectedNetwork" -VirtualNetwork $sourceNetwork -RemoteVirtualNetworkId $remoteNetwork.Id -ErrorAction Stop
				}

				if(-not (Get-AzureRmVirtualNetworkPeering -VirtualNetworkName $remoteNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)))
				{
					$null = Add-AzureRmVirtualNetworkPeering -Name "$($connectedNetwork)_to_$($network.Name)" -VirtualNetwork $remoteNetwork -RemoteVirtualNetworkId $sourceNetwork.Id -ErrorAction Stop
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
		
        $cmd = [scriptblock]::Create("Import-Module -Name Azure*; Select-AzureRmProfile -Path $($lab.AzureSettings.AzureProfilePath);Select-AzureRmSubscription -SubscriptionName $($lab.AzureSettings.DefaultSubscription.SubscriptionName); Remove-AzureRmVirtualNetwork -Name $($network.name) -ResourceGroupName $(Get-LabAzureDefaultResourceGroup) -Force")
        Start-Job -Name "RemoveAzureVNet ($($network.name))" -ScriptBlock $cmd | Out-Null
    }
    $jobs = Get-Job -Name RemoveAzureVNet*
    Write-Verbose "Waiting on the removal of $($jobs.Count)"
    $jobs | Wait-Job | Out-Null
	
    Write-Verbose "Virtual network(s) '$($VirtualNetwork.Name -join ', ')' removed from Azure"
	
    Write-LogFunctionExit
}
#endregion Remove-LWNetworkSwitch