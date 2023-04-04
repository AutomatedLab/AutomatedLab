function Restore-LabConnection
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SourceLab,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DestinationLab
    )

    if ((Get-Lab -List) -notcontains $SourceLab)
    {
        throw "Source lab $SourceLab does not exist."
    }

    if ((Get-Lab -List) -notcontains $DestinationLab)
    {
        throw "Destination lab $DestinationLab does not exist."
    }

    $sourceFolder = "$((Get-LabConfigurationItem -Name LabAppDataRoot))\Labs\$SourceLab"
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
    $destinationHypervisor = ([xml](Get-Content $destinationFile)).Lab.DefaultVirtualizationEngine

    if ($sourceHypervisor -eq 'Azure')
    {
        $source = $SourceLab
        $destination = $DestinationLab
    }
    else
    {
        $source = $DestinationLab
        $destination = $SourceLab
    }

    Write-PSFMessage -Message "Checking Azure lab $source"
    Import-Lab -Name $source -NoValidation
    $resourceGroup = (Get-LabAzureDefaultResourceGroup).ResourceGroupName

    $localGateway = Get-AzLocalNetworkGateway -Name onpremgw -ResourceGroupName $resourceGroup -ErrorAction Stop
    $vpnGatewayIp = Get-AzPublicIpAddress -Name s2sip -ResourceGroupName $resourceGroup -ErrorAction Stop

    try
    {
        $labIp = Get-PublicIpAddress -ErrorAction Stop
    }
    catch
    {
        Write-ScreenInfo -Message 'Public IP address could not be determined. Reconnect-Lab will probably not work.' -Type Warning
    }

    if ($localGateway.GatewayIpAddress -ne $labIp)
    {
        Write-PSFMessage -Message "Gateway address $($localGateway.GatewayIpAddress) does not match local IP $labIP and will be changed"
        $localGateway.GatewayIpAddress = $labIp
        [void] ($localGateway | Set-AzLocalNetworkGateway)
    }

    Import-Lab -Name $destination -NoValidation
    $router = Get-LabVm -Role Routing

    Invoke-LabCommand -ActivityName 'Checking S2S connection' -ComputerName $router -ScriptBlock {
        param
        (
            [System.String]
            $azureDestination
        )

        $s2sConnection = Get-VpnS2SInterface -Name AzureS2S -ErrorAction Stop -Verbose

        if ($s2sConnection.Destination -notcontains $azureDestination)
        {
            $s2sConnection.Destination += $azureDestination
            $s2sConnection | Set-VpnS2SInterface -Verbose
        }
    } -ArgumentList @($vpnGatewayIp.IpAddress)
}
