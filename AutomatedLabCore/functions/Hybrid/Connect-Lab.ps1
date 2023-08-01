function Connect-Lab
{
    [CmdletBinding(DefaultParameterSetName = 'Lab2Lab')]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $SourceLab,

        [Parameter(Mandatory = $true, ParameterSetName = 'Lab2Lab', Position = 1)]
        [System.String]
        $DestinationLab,

        [Parameter(Mandatory = $true, ParameterSetName = 'Site2Site', Position = 1)]
        [System.String]
        $DestinationIpAddress,

        [Parameter(Mandatory = $true, ParameterSetName = 'Site2Site', Position = 2)]
        [System.String]
        $PreSharedKey,

        [Parameter(ParameterSetName = 'Site2Site', Position = 3)]
        [System.String[]]
        $AddressSpace,

        [Parameter(Mandatory = $false)]
        [System.String]
        $NetworkAdapterName = 'Ethernet'
    )

    Write-LogFunctionEntry

    if ((Get-Lab -List) -notcontains $SourceLab)
    {
        throw "Source lab $SourceLab does not exist."
    }

    if ($DestinationIpAddress)
    {
        Write-PSFMessage -Message ('Connecting {0} to {1}' -f $SourceLab, $DestinationIpAddress)
        Connect-OnPremisesWithEndpoint -LabName $SourceLab -IPAddress $DestinationIpAddress -AddressSpace $AddressSpace -Psk $PreSharedKey
        return
    }

    if ((Get-Lab -List) -notcontains $DestinationLab)
    {
        throw "Destination lab $DestinationLab does not exist."
    }

    $sourceFolder ="$((Get-LabConfigurationItem -Name LabAppDataRoot))\Labs\$SourceLab"
    $sourceFile = Join-Path -Path $sourceFolder -ChildPath Lab.xml -Resolve -ErrorAction SilentlyContinue
    if (-not $sourceFile)
    {
        throw "Lab.xml is missing for $SourceLab"
    }

    $destinationFolder = "$((Get-LabConfigurationItem -Name LabAppDataRoot))\Labs\$DestinationLab"
    $destinationFile = Join-Path -Path $destinationFolder -ChildPath Lab.xml -Resolve -ErrorAction SilentlyContinue
    if (-not $destinationFile)
    {
        throw "Lab.xml is missing for $DestinationLab"
    }

    $sourceHypervisor = ([xml](Get-Content $sourceFile)).Lab.DefaultVirtualizationEngine
    $sourceRoutedAddressSpaces = ([xml](Get-Content $sourceFile)).Lab.VirtualNetworks.VirtualNetwork.AddressSpace | ForEach-Object {
        if (-not [System.String]::IsNullOrWhiteSpace($_.IpAddress.AddressAsString))
        {
            "$($_.IpAddress.AddressAsString)/$($_.SerializationCidr)"
        }
    }

    $destinationHypervisor = ([xml](Get-Content $destinationFile)).Lab.DefaultVirtualizationEngine
    $destinationRoutedAddressSpaces = ([xml](Get-Content $destinationFile)).Lab.VirtualNetworks.VirtualNetwork.AddressSpace | ForEach-Object {
        if (-not [System.String]::IsNullOrWhiteSpace($_.IpAddress.AddressAsString))
        {
            "$($_.IpAddress.AddressAsString)/$($_.SerializationCidr)"
        }
    }

    Write-PSFMessage -Message ('Source Hypervisor: {0}, Destination Hypervisor: {1}' -f $sourceHypervisor, $destinationHypervisor)

    if (-not ($sourceHypervisor -eq 'Azure' -or $destinationHypervisor -eq 'Azure'))
    {
        throw 'On-premises to on-premises connections are currently not implemented. One or both labs need to be Azure'
    }

    if ($sourceHypervisor -eq 'Azure')
    {
        $connectionParameters = @{
            SourceLab           = $SourceLab
            DestinationLab      = $DestinationLab
            AzureAddressSpaces  = $sourceRoutedAddressSpaces
            OnPremAddressSpaces = $destinationRoutedAddressSpaces
        }
    }
    else
    {
        $connectionParameters = @{
            SourceLab           = $DestinationLab
            DestinationLab      = $SourceLab
            AzureAddressSpaces  = $destinationRoutedAddressSpaces
            OnPremAddressSpaces = $sourceRoutedAddressSpaces
        }
    }

    if ($sourceHypervisor -eq 'Azure' -and $destinationHypervisor -eq 'Azure')
    {
        Write-PSFMessage -Message ('Connecting Azure lab {0} to Azure lab {1}' -f $SourceLab, $DestinationLab)
        Connect-AzureLab -SourceLab $SourceLab -DestinationLab $DestinationLab
        return
    }

    Write-PSFMessage -Message ('Connecting on-premises lab to Azure lab. Source: {0} <-> Destination {1}' -f $SourceLab, $DestinationLab)
    Connect-OnPremisesWithAzure @connectionParameters

    Write-LogFunctionExit
}
