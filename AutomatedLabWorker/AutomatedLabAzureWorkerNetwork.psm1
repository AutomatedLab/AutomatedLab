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
    $jobs = @()
	
    foreach ($network in $VirtualNetwork)
    {
        Write-ScreenInfo -Message "Creating Azure virtual network '$($network.Name)'" -TaskStart
             
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

        <#if ($network.DnsServers)
        {
            $azureNetworkParameters.Add('DnsServer', $network.DnsServers)
        }#>
		
        $jobs += Start-Job -Name "NewAzureVnet ($($network.Name))" -ScriptBlock {
            param
            (
                $ProfilePath,
                $Subscription,
                $azureNetworkParameters,
                $Subnets,
                $Network
            )
			
            Select-AzureRmProfile -Path $ProfilePath
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
                $azureNetworkParameters.Add('Subnet',$azureSubnets)
            }
			
            $azureNetwork = New-AzureRmVirtualNetwork @azureNetworkParameters -Force
        } -ArgumentList $lab.AzureSettings.AzureProfilePath, $lab.AzureSettings.DefaultSubscription.SubscriptionName, $azureNetworkParameters, $network.Subnets,$network
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

            foreach($connectedNetwork in $network.ConnectToVnets)
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
                
                if(-not $alreadyExists)
                {
                    Add-AzureRmVirtualNetworkPeering -Name "$($network.Name)_to_$connectedNetwork" -VirtualNetwork $sourceNetwork -RemoteVirtualNetworkId $remoteNetwork.Id -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
                }
                
                $existingPeerings = Get-AzureRmVirtualNetworkPeering -VirtualNetworkName $remoteNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)
                $alreadyExists = foreach ($existingPeering in $existingPeerings)
                {
                    $targetVirtualNetwork = Get-AzureRmResource -ResourceId $existingPeering.RemoteVirtualNetwork.Id
                    
                    $existingPeering.VirtualNetworkName -eq $remoteNetwork.Name -and $targetVirtualNetwork.Name -eq $sourceNetwork.Name
                }

                if(-not (Get-AzureRmVirtualNetworkPeering -VirtualNetworkName $remoteNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)))
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