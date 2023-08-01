function Install-LabDnsForwarder
{
    $forestNames = (Get-LabVM -Role RootDC).DomainName
    if (-not $forestNames)
    {
        Write-Error 'Could not get forest names from the lab'
        return
    }

    $forwarders = Get-FullMesh -List $forestNames

    foreach ($forwarder in $forwarders)
    {
        $targetMachine = Get-LabVM -Role RootDC | Where-Object { $_.DomainName -eq $forwarder.Source }
        $masterServers = Get-LabVM -Role DC,RootDC,FirstChildDC | Where-Object { $_.DomainName -eq $forwarder.Destination }

        $cmd = @"
            `$hostname = hostname.exe
            Write-Verbose "Creating a DNS forwarder on server '$hostname'. Forwarder name is '$($forwarder.Destination)' and target DNS server is '$($masterServers.IpV4Address)'..."
            #Add-DnsServerConditionalForwarderZone -ReplicationScope Forest -Name $($forwarder.Destination) -MasterServers $($masterServers.IpV4Address)
            dnscmd . /zoneadd $($forwarder.Destination) /dsforwarder $($masterServers.IpV4Address)
            Write-Verbose '...done'
"@

        Invoke-LabCommand -ComputerName $targetMachine -ScriptBlock ([scriptblock]::Create($cmd)) -NoDisplay
    }

    $azureRootDCs = Get-LabVM -Role RootDC | Where-Object HostType -eq Azure
    if ($azureRootDCs)
    {
        Invoke-LabCommand -ActivityName 'Configuring DNS Forwarders on Azure Root DCs' -ComputerName $azureRootDCs -ScriptBlock {
            dnscmd /ResetForwarders 168.63.129.16
        } -NoDisplay
    }
}
