function Disconnect-Lab
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        $SourceLab,

        [Parameter(Mandatory)]
        $DestinationLab
    )

    Write-LogFunctionEntry

    foreach ($LabName in @($SourceLab, $DestinationLab))
    {
        Import-Lab -Name $LabName -ErrorAction Stop -NoValidation
        $lab = Get-Lab

        Invoke-LabCommand -ActivityName 'Remove conditional forwarders' -ComputerName (Get-LabVM -Role RootDC) -ScriptBlock {
            Get-DnsServerZone | Where-Object -Property ZoneType -EQ Forwarder | Remove-DnsServerZone -Force
        }

        if ($lab.DefaultVirtualizationEngine -eq 'Azure')
        {
            $resourceGroupName = (Get-LabAzureDefaultResourceGroup).ResourceGroupName

            Write-PSFMessage -Message ('Removing VPN resources in Azure lab {0}, Resource group {1}' -f $lab.Name, $resourceGroupName)

            $connection = Get-AzVirtualNetworkGatewayConnection -Name s2sconnection -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
            $gw = Get-AzVirtualNetworkGateway -Name s2sgw -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
            $localgw = Get-AzLocalNetworkGateway -Name onpremgw -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
            $ip = Get-AzPublicIpAddress -Name s2sip -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

            if ($connection)
            {
                $connection | Remove-AzVirtualNetworkGatewayConnection -Force
            }

            if ($gw)
            {
                $gw | Remove-AzVirtualNetworkGateway -Force
            }

            if ($ip)
            {
                $ip | Remove-AzPublicIpAddress -Force
            }

            if ($localgw)
            {
                $localgw | Remove-AzLocalNetworkGateway -Force
            }
        }
        else
        {
            $router = Get-LabVm -Role Routing -ErrorAction SilentlyContinue

            if (-not $router)
            {
                # How did this even work...
                continue
            }

            Write-PSFMessage -Message ('Disabling S2SVPN in on-prem lab {0} on router {1}' -f $lab.Name, $router.Name)

            Invoke-LabCommand -ActivityName "Disabling S2S on $($router.Name)" -ComputerName $router -ScriptBlock {
                Get-VpnS2SInterface -Name AzureS2S -ErrorAction SilentlyContinue | Remove-VpnS2SInterface -Force -ErrorAction SilentlyContinue
                Uninstall-RemoteAccess -VpnType VPNS2S -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Write-LogFunctionExit
}
