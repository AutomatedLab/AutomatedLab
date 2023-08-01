function Get-LWAzureVMConnectionInfo
{
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine[]]$ComputerName
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $lab = Get-Lab -ErrorAction SilentlyContinue
    $retryCount = 5

    if (-not $lab)
    {
        Write-PSFMessage "Could not retrieve machine info for '$($ComputerName.Name -join ',')'. No lab was imported."
    }

    if (-not ((Get-AzContext).Subscription.Name -eq $lab.AzureSettings.DefaultSubscription))
    {
        Set-AzContext -Subscription $lab.AzureSettings.DefaultSubscription
    }

    $resourceGroupName = (Get-LabAzureDefaultResourceGroup).ResourceGroupName
    $azureVMs = Get-AzVM -ResourceGroupName $resourceGroupName | Where-Object Name -in $ComputerName.ResourceName
    $ips = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

    foreach ($name in $ComputerName)
    {
        $azureVM = $azureVMs | Where-Object Name -eq $name.ResourceName

        if (-not $azureVM)
        { continue }

        $net = $lab.VirtualNetworks.Where({ $_.Name -eq $name.Network[0] })
        $ip = $ips | Where-Object { $_.Tag['Vnet'] -eq $net.ResourceName }

        if (-not $ip)
        {
            $ip = $ips | Where-Object Name -eq "$($resourceGroupName)$($net.ResourceName)lbfrontendip"
        }

        if (-not $ip)
        {
            Write-ScreenInfo -Type Error -Message "No public IP address found for VM $($name.ResourceName) with tag $($net.ResourceName) or name $($resourceGroupName)$($net.ResourceName)lbfrontendip"
            continue
        }

        $result = [AutomatedLab.Azure.AzureConnectionInfo] @{
            ComputerName      = $name.Name
            DnsName           = $ip.DnsSettings.Fqdn
            HttpsName         = $ip.DnsSettings.Fqdn
            VIP               = $ip.IpAddress
            Port              = $name.LoadBalancerWinrmHttpPort
            HttpsPort         = $name.LoadBalancerWinrmHttpsPort
            RdpPort           = $name.LoadBalancerRdpPort
            SshPort           = $name.LoadBalancerSshPort
            ResourceGroupName = $azureVM.ResourceGroupName
        }

        Write-PSFMessage "Get-LWAzureVMConnectionInfo created connection info for VM '$name'"
        Write-PSFMessage "ComputerName      = $($name.Name)"
        Write-PSFMessage "DnsName           = $($ip.DnsSettings.Fqdn)"
        Write-PSFMessage "HttpsName         = $($ip.DnsSettings.Fqdn)"
        Write-PSFMessage "VIP               = $($ip.IpAddress)"
        Write-PSFMessage "Port              = $($name.LoadBalancerWinrmHttpPort)"
        Write-PSFMessage "HttpsPort         = $($name.LoadBalancerWinrmHttpsPort)"
        Write-PSFMessage "RdpPort           = $($name.LoadBalancerRdpPort)"
        Write-PSFMessage "SshPort           = $($name.LoadBalancerSshPort)"
        Write-PSFMessage "ResourceGroupName = $($azureVM.ResourceGroupName)"

        $result
    }

    Write-LogFunctionExit -ReturnValue $result
}
