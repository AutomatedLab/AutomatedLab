function Enable-LabInternalRouting
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $RoutingNetworkName
    )

    Write-LogFunctionEntry

    $routes = Get-FullMesh -List (Get-Lab).VirtualNetworks.Where( { $_.Name -ne $RoutingNetworkName }).AddressSpace.Foreach( { '{0}/{1}' -f $_.Network, $_.Cidr })
    $routers = Get-LabVm -Role Routing
    $routingConfig = @{}
    foreach ($router in $routers)
    {
        $routerAdapter = (Get-LabVM $router).NetworkAdapters.Where( { $_.VirtualSwitch.Name -eq $RoutingNetworkName })
        $routerInternalAdapter = (Get-LabVM $router).NetworkAdapters.Where( { $_.VirtualSwitch.Name -ne $RoutingNetworkName })
        $routingConfig[$router.Name] = @{
            Name          = $router.Name
            InterfaceName = $routerAdapter.InterfaceName
            RouterNetwork = [string[]]$routerInternalAdapter.IPV4Address
            TargetRoutes  = @{}
        }
    }

    foreach ($router in $routers)
    {
        $targetRoutes = $routes | Where-Object Source -in $routingConfig[$router.Name].RouterNetwork
        foreach ($route in $targetRoutes)
        {
            $nextHopVm = Get-LabVm $routingConfig.Values.Where( { $_.RouterNetwork -eq $route.Destination }).Name
            $nextHopIp = $nextHopVm.NetworkAdapters.Where( { $_.VirtualSwitch.Name -eq $RoutingNetworkName }).Ipv4Address.IPaddress.AddressAsString
            Write-ScreenInfo -Type Verbose -Message "Route on $($router.Name) to $($route.Destination) via $($nextHopVm.Name)($($nextHopIp))"
            $routingConfig[$router.Name].TargetRoutes[$route.Destination] = $nextHopIp
        }
    }

    Invoke-LabCommand -ComputerName $routers -ActivityName "Creating routes" -ScriptBlock {
        Install-RemoteAccess -VpnType RoutingOnly
        $config = $routingConfig[$env:COMPUTERNAME]
        
        foreach ($route in $config.TargetRoutes.GetEnumerator())
        {
            New-NetRoute -InterfaceAlias $config.InterfaceName -DestinationPrefix $route.Key -AddressFamily IPv4 -NextHop $route.Value -Publish Yes
        }
    } -Variable (Get-Variable routingConfig)

    Write-LogFunctionExit
}
