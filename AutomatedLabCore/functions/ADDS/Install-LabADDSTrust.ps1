function Install-LabADDSTrust
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

    Get-LabVM -Role RootDC | ForEach-Object {
        Invoke-LabCommand -ComputerName $_ -NoDisplay -ScriptBlock {
            Write-Verbose -Message "Replicating forest `$(`$env:USERDNSDOMAIN)..."

            Write-Verbose -Message 'Getting list of DCs'
            $dcs = repadmin.exe /viewlist *
            Write-Verbose -Message "List: '$($dcs -join ', ')'"

            foreach ($dc in $dcs)
            {
                if ($dc)
                {
                    $dcName = $dc.Split()[2]
                    Write-Verbose -Message "Executing 'repadmin.exe /SyncAll /Ae $dcname'"
                    $null = repadmin.exe /SyncAll /AeP $dcName
                }
            }
            Write-Verbose '...done'
        }
    }

    $rootDcs = Get-LabVM -Role RootDC
    $trustMesh = Get-FullMesh -List $forestNames -OneWay

    foreach ($rootDc in $rootDcs)
    {
        $trusts = $trustMesh | Where-Object { $_.Source -eq $rootDc.DomainName }

        Write-PSFMessage "Creating trusts on machine $($rootDc.Name)"
        foreach ($trust in $trusts)
        {
            $domainAdministrator = ((Get-Lab).Domains | Where-Object { $_.Name -eq ($rootDcs | Where-Object { $_.DomainName -eq $trust.Destination }).DomainName }).Administrator

            $cmd = @"
                `$thisForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

                `$otherForestCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext(
                    [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Forest,
                    '$($trust.Destination)',
                    '$($domainAdministrator.UserName)',
                    '$($domainAdministrator.Password -replace "'","''" )')
                `$otherForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest(`$otherForestCtx)

                Write-Verbose "Creating forest trust between forests '`$(`$thisForest.Name)' and '`$(`$otherForest.Name)'"

                `$thisForest.CreateTrustRelationship(
                    `$otherForest,
                    [System.DirectoryServices.ActiveDirectory.TrustDirection]::Bidirectional
                )

                Write-Verbose 'Forest trust created'
"@

            Invoke-LabCommand -ComputerName $rootDc -ScriptBlock ([scriptblock]::Create($cmd)) -NoDisplay
        }
    }
}
