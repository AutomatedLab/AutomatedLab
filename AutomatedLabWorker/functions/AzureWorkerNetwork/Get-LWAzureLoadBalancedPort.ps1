function Get-LWAzureLoadBalancedPort
{
    param
    (
        [Parameter()]
        [uint16]
        $Port,

        [Parameter()]
        [uint16]
        $DestinationPort,

        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    Test-LabHostConnected -Throw -Quiet

    $lab = Get-Lab
    $resourceGroup = $lab.Name
    $machine = Get-LabVm -ComputerName $ComputerName
    $net = $lab.VirtualNetworks.Where({ $_.Name -eq $machine.Network[0] })

    $lb = Get-AzLoadBalancer -ResourceGroupName $resourceGroup | Where-Object {$_.Tag['Vnet'] -eq $net.ResourceName}
    if (-not $lb)
    {
        Write-PSFMessage "No load balancer found to list port rules of"
        return
    }

    $existingConfiguration = $lb | Get-AzLoadBalancerInboundNatRuleConfig

    # Port müssen unique sein, destination port + computername müssen unique sein
    if ($Port)
    {
        $filteredRules = $existingConfiguration | Where-Object -Property FrontendPort -eq $Port

        if (($filteredRules | Where-Object Name -notlike "$($machine.ResourceName)*"))
        {
            $err = ($filteredRules | Where-Object Name -notlike "$($machine.ResourceName)*")[0].Name
            $existingComputer = $err.Substring(0, $err.IndexOf('-'))
            Write-Error -Message ("Incoming port {0} is already mapped to {1}!" -f $Port, $existingComputer)
            return
        }

        return $filteredRules
    }

    if ($DestinationPort)
    {
        return ($existingConfiguration | Where-Object {$_.BackendPort -eq $DestinationPort -and $_.Name -like "$($machine.ResourceName)*"})
    }

    return ($existingConfiguration | Where-Object -Property Name -like "$($machine.ResourceName)*")
}
