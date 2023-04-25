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

    Write-ScreenInfo -Message "Creating Azure virtual networks '$($VirtualNetwork.ResourceName -join ',')'" -TaskStart
    $jobs = foreach ($network in $VirtualNetwork)
    {
        if (Get-LWAzureNetworkSwitch -VirtualNetwork $network)
        {
            Write-PSFMessage "Azure virtual network '$($network.ResourceName)' already exists. Skipping..."
            continue
        }

        $azureNetworkParameters = @{
            Name              = $network.ResourceName
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

        New-AzVirtualNetwork @azureNetworkParameters -Force -AsJob
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
            Write-PSFMessage "The network '$($network.ResourceName)' is not connected hence no need for creating a gateway"
        }
        else
        {
            $sourceNetwork = Get-AzVirtualNetwork -Name $network.ResourceName -ResourceGroupName (Get-LabAzureDefaultResourceGroup)

            foreach ($connectedNetwork in $network.ConnectToVnets)
            {
                # Configure bidirectional access
                $remoteNetwork = Get-AzVirtualNetwork -Name $connectedNetwork -ResourceGroupName (Get-LabAzureDefaultResourceGroup)

                Write-PSFMessage -Message "Configuring VNet peering $($sourceNetwork.Name) <-> $($remoteNetwork.Name)"

                $existingPeerings = Get-AzVirtualNetworkPeering -VirtualNetworkName $sourceNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)
                $alreadyExists = foreach ($existingPeering in $existingPeerings)
                {
                    $targetVirtualNetwork = Get-AzResource -ResourceId $existingPeering.RemoteVirtualNetwork.Id

                    $existingPeering.VirtualNetworkName -eq $sourceNetwork.Name -and $targetVirtualNetwork.Name -eq $remoteNetwork.Name
                }

                if (-not $alreadyExists)
                {
                    Add-AzVirtualNetworkPeering -Name "$($network.ResourceName)_to_$connectedNetwork" -VirtualNetwork $sourceNetwork -RemoteVirtualNetworkId $remoteNetwork.Id -ErrorAction Stop | Out-Null
                }

                $existingPeerings = Get-AzVirtualNetworkPeering -VirtualNetworkName $remoteNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)
                $alreadyExists = foreach ($existingPeering in $existingPeerings)
                {
                    $targetVirtualNetwork = Get-AzResource -ResourceId $existingPeering.RemoteVirtualNetwork.Id

                    $existingPeering.VirtualNetworkName -eq $remoteNetwork.Name -and $targetVirtualNetwork.Name -eq $sourceNetwork.Name
                }

                if (-not (Get-AzVirtualNetworkPeering -VirtualNetworkName $remoteNetwork.Name -ResourceGroupName (Get-LabAzureDefaultResourceGroup)))
                {
                    Add-AzVirtualNetworkPeering -Name "$($connectedNetwork)_to_$($network.ResourceName)" -VirtualNetwork $remoteNetwork -RemoteVirtualNetworkId $sourceNetwork.Id -ErrorAction Stop | Out-Null
                }
                Write-PSFMessage -Message 'Peering successfully configured'
            }
        }
    }

    Write-LogFunctionExit
}
