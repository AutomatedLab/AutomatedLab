function Install-LabFailoverCluster
{
    [CmdletBinding()]
    param ( )

    $failoverNodes = Get-LabVm -Role FailoverNode -ErrorAction SilentlyContinue
    $clusters = $failoverNodes | Group-Object { ($_.Roles | Where-Object -Property Name -eq 'FailoverNode').Properties['ClusterName'] }
    $useDiskWitness = $false
    Start-LabVM -Wait -ComputerName $failoverNodes

    Install-LabWindowsFeature -ComputerName $failoverNodes -FeatureName Failover-Clustering, RSAT-Clustering -IncludeAllSubFeature

    Write-ScreenInfo -Message 'Restart post FCI Install'
    Restart-LabVM $failoverNodes -Wait

    if (Get-LabWindowsFeature -ComputerName $failoverNodes -FeatureName Failover-Clustering, RSAT-Clustering | Where InstallState -ne Installed)
    {
        Install-LabWindowsFeature -ComputerName $failoverNodes -FeatureName Failover-Clustering, RSAT-Clustering -IncludeAllSubFeature
        Write-ScreenInfo -Message 'Restart post FCI Install'
        Restart-LabVM $failoverNodes -Wait
    }

    if (Get-LabVm -Role FailoverStorage)
    {
        Write-ScreenInfo -Message 'Waiting for failover storage server to complete installation'
        Install-LabFailoverStorage
        $useDiskWitness = $true
    }

    Write-ScreenInfo -Message 'Waiting for failover nodes to complete installation'

    foreach ($cluster in $clusters)
    {
        $firstNode = $cluster.Group | Select-Object -First 1
        $clusterDomains = $cluster.Group.DomainName | Sort-Object -Unique
        $clusterNodeNames = $cluster.Group | Select-Object -Skip 1 -ExpandProperty Name
        $clusterName = $cluster.Name
        $clusterIp = ($firstNode.Roles | Where-Object -Property Name -eq 'FailoverNode').Properties['ClusterIp'] -split '\s*(?:,|;?),\s*'

        if (-not $clusterIp)
        {
            $adapterVirtualNetwork = Get-LabVirtualNetworkDefinition -Name $firstNode.NetworkAdapters[0].VirtualSwitch
            $clusterIp = $adapterVirtualNetwork.NextIpAddress().AddressAsString
        }

        if (-not $clusterName)
        {
            $clusterName = 'ALCluster'
        }

        $ignoreNetwork = foreach ($network in (Get-Lab).VirtualNetworks)
        {
            $range = Get-NetworkRange -IPAddress $network.AddressSpace.Network.AddressAsString -SubnetMask $network.AddressSpace.Cidr
            $inRange = $clusterIp | Where-Object {$_ -in $range}
            
            if (-not $inRange)
            {
                '{0}/{1}' -f $network.AddressSpace.Network.AddressAsString, $network.AddressSpace.Cidr
            }
        }

        if ($useDiskWitness -and -not ($firstNode.OperatingSystem.Version -lt 6.2))
        {
            Invoke-LabCommand -ComputerName $firstNode -ActivityName 'Preparing cluster storage' -ScriptBlock {
                if (-not (Get-ClusterAvailableDisk -ErrorAction SilentlyContinue))
                {
                    $offlineDisk = Get-Disk | Where-Object -Property OperationalStatus -eq Offline | Select-Object -First 1
                    if ($offlineDisk)
                    {
                        $offlineDisk | Set-Disk -IsOffline $false
                        $offlineDisk | Set-Disk -IsReadOnly $false
                    }

                    if (-not ($offlineDisk | Get-Partition | Get-Volume))
                    {
                        $offlineDisk | New-Volume -FriendlyName quorum -FileSystem NTFS
                    }
                }
            }

            Invoke-LabCommand -ComputerName $clusterNodeNames -ActivityName 'Preparing cluster storage on remaining nodes' -ScriptBlock {
                Get-Disk | Where-Object -Property OperationalStatus -eq Offline | Set-Disk -IsOffline $false
            }
        }

        $storageNode = Get-LabVm -Role FailoverStorage -ErrorAction SilentlyContinue
        $role = $storageNode.Roles | Where-Object Name -eq FailoverStorage

        if((-not $useDiskWitness) -or ($storageNode.Disks.Count -gt 1))
        {
            Invoke-LabCommand -ComputerName $firstNode -ActivityName 'Preparing cluster storage' -ScriptBlock {
                $diskpartCmd = 'LIST DISK'

                $disks = $diskpartCmd | diskpart.exe

                foreach ($line in $disks)
                {
                    if ($line -match 'Disk (?<DiskNumber>\d) \s+(Offline)\s+(?<Size>\d+) GB\s+(?<Free>\d+) GB')
                    {
                        $nextDriveLetter = if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)
                        {
                            [char[]](67..90) |
                            Where-Object { (Get-CimInstance -Class Win32_LogicalDisk |
                            Select-Object -ExpandProperty DeviceID) -notcontains "$($_):"} |
                            Select-Object -First 1
                        }
                        else
                        {
                            [char[]](67..90) |
                            Where-Object { (Get-WmiObject -Class Win32_LogicalDisk |
                            Select-Object -ExpandProperty DeviceID) -notcontains "$($_):"} |
                            Select-Object -First 1
                        }

                        $diskNumber = $Matches.DiskNumber

                        $diskpartCmd = "@
                            SELECT DISK $diskNumber
                            ATTRIBUTES DISK CLEAR READONLY
                            ONLINE DISK
                            CREATE PARTITION PRIMARY
                            ASSIGN LETTER=$nextDriveLetter
                            EXIT
                        @"
                        $diskpartCmd | diskpart.exe | Out-Null

                        Start-Sleep -Seconds 2

                        cmd.exe /c "echo y | format $($nextDriveLetter): /q /v:DataDisk$diskNumber"
                    }
                }
            }

            Invoke-LabCommand -ComputerName $clusterNodeNames -ActivityName 'Preparing cluster storage' -ScriptBlock {
                $diskpartCmd = 'LIST DISK'

                $disks = $diskpartCmd | diskpart.exe

                foreach ($line in $disks)
                {
                    if ($line -match 'Disk (?<DiskNumber>\d) \s+(Offline)\s+(?<Size>\d+) GB\s+(?<Free>\d+) GB')
                    {
                        $diskNumber = $Matches.DiskNumber

                        $diskpartCmd = "@
                            SELECT DISK $diskNumber
                            ATTRIBUTES DISK CLEAR READONLY
                            ONLINE DISK
                            EXIT
                        @"
                        $diskpartCmd | diskpart.exe | Out-Null
                    }
                }
            }
        }


        $clusterAccessPoint = if ($clusterDomains.Count -ne 1)
        {
            'DNS'
        }
        else
        {
            'ActiveDirectoryAndDns'
        }

        Remove-LabPSSession -ComputerName $failoverNodes
        Invoke-LabCommand -ComputerName $firstNode -ActivityName 'Enabling clustering on first node' -ScriptBlock {
            Import-Module FailoverClusters -ErrorAction Stop -WarningAction SilentlyContinue

            $clusterParameters = @{
                Name                      = $clusterName
                StaticAddress             = $clusterIp
                AdministrativeAccessPoint = $clusterAccessPoint
                ErrorAction               = 'SilentlyContinue'
                WarningAction             = 'SilentlyContinue'
            }

            if ($ignoreNetwork)
            {
                $clusterParameters.IgnoreNetwork = $ignoreNetwork
            }

            $clusterParameters = Sync-Parameter -Command (Get-Command New-Cluster) -Parameters $clusterParameters

            $null = New-Cluster @clusterParameters
        } -Variable (Get-Variable clusterName, clusterNodeNames, clusterIp, useDiskWitness, clusterAccessPoint, ignoreNetwork) -Function (Get-Command Sync-Parameter)

        Remove-LabPSSession -ComputerName $failoverNodes
        Invoke-LabCommand -ComputerName $firstNode -ActivityName 'Adding nodes' -ScriptBlock {
            Import-Module FailoverClusters -ErrorAction Stop -WarningAction SilentlyContinue

            if (-not (Get-Cluster -Name $clusterName -ErrorAction SilentlyContinue))
            {
                Write-Error "Cluster $clusterName was not deployed"
            }

            foreach ($node in $clusterNodeNames)
            {
                Add-ClusterNode -Name $node -Cluster $clusterName -ErrorAction SilentlyContinue
            }

            if (Compare-Object -ReferenceObject $clusterNodeNames -DifferenceObject (Get-ClusterNode -Cluster $clusterName).Name | Where-Object SideIndicator -eq '<=')
            {
                Write-Error -Message "Error deploying cluster $clusterName, not all nodes were added to the cluster"
            }

            if ($useDiskWitness)
            {
                $clusterDisk = Get-ClusterResource -Cluster $clusterName -ErrorAction SilentlyContinue | Where-object -Property ResourceType -eq 'Physical Disk' | Select -First 1

                if ($clusterDisk)
                {
                    Get-Cluster -Name $clusterName | Set-ClusterQuorum -DiskWitness $clusterDisk
                }
            }
        } -Variable (Get-Variable clusterName, clusterNodeNames, clusterIp, useDiskWitness, clusterAccessPoint, ignoreNetwork)
    }
}
