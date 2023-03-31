function Set-VpnDnsForwarders
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

    Import-Lab $SourceLab -NoValidation
    $sourceDcs = Get-LabVM -Role DC, RootDC, FirstChildDC

    Import-Lab $DestinationLab -NoValidation
    $destinationDcs = Get-LabVM -Role DC, RootDC, FirstChildDC

    $forestNames = @($sourceDcs) + @($destinationDcs) | Where-Object { $_.Roles.Name -Contains 'RootDC'} | Select-Object -ExpandProperty DomainName
    $forwarders = Get-FullMesh -List $forestNames

    foreach ($forwarder in $forwarders)
    {
        $targetMachine = @($sourceDcs) + @($destinationDcs) | Where-Object { $_.Roles.Name -contains 'RootDC' -and $_.DomainName -eq $forwarder.Source }
        $machineExists = Get-LabVM | Where-Object {$_.Name -eq $targetMachine.Name -and $_.IpV4Address -eq $targetMachine.IpV4Address}

        if (-not $machineExists)
        {
            if ((Get-Lab).Name -eq $SourceLab)
            {
                Import-Lab -Name $DestinationLab -NoValidation
            }
            else
            {
                Import-Lab -Name $SourceLab -NoValidation
            }
        }

        $masterServers = @($sourceDcs) + @($destinationDcs) | Where-Object {
            ($_.Roles.Name -contains 'RootDC' -or $_.Roles.Name -contains 'FirstChildDC' -or $_.Roles.Name -contains 'DC') -and $_.DomainName -eq $forwarder.Destination
        }

        $cmd = @"
            Write-PSFMessage "Creating a DNS forwarder on server '$env:COMPUTERNAME'. Forwarder name is '$($forwarder.Destination)' and target DNS server is '$($masterServers.IpV4Address)'..."
            dnscmd localhost /ZoneAdd $($forwarder.Destination) /Forwarder $($masterServers.IpV4Address)
            Write-PSFMessage '...done'
"@

        Invoke-LabCommand -ComputerName $targetMachine -ScriptBlock ([scriptblock]::Create($cmd)) -NoDisplay
    }
}
