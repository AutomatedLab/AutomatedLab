#region Install-LabFailoverCluster
function Install-LabFailoverCluster
{
    [CmdletBinding()]
    param ( )

    # 1 Get-LabVM -Role FailoverNode, Count ge 2. Wenn Machine bereits installiert, FC aktivieren, sonst Start-LabVm, DomJoin, ...
    # Validator: DomJoin, min count 2, Role FailoverStorage in Lab

    $failoverNodes = Get-LabVm -Role FailoverNode -ErrorAction SilentlyContinue
    $clusters = $failoverNodes | Group-Object { ($PSItem.Roles | Where-Object -Property Name -eq 'FailoverNode').Properties['ClusterName'] }
    $useDiskWitness = $false

    Install-LabWindowsFeature -ComputerName $failoverNodes -FeatureName Failover-Clustering, RSAT-Clustering -IncludeAllSubFeature

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
        $clusterIp = ($firstNode.Roles | Where-Object -Property Name -eq 'FailoverNode').Properties['ClusterIp']

        if (-not $clusterIp)
        {
            $adapterVirtualNetwork = Get-LabVirtualNetworkDefinition -Name $firstNode.NetworkAdapters[0].VirtualSwitch
            $clusterIp = $adapterVirtualNetwork.NextIpAddress().AddressAsString
        }

        if (-not $clusterName)
        {
            $clusterName = 'ALCluster'
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
        else
        {
            Invoke-LabCommand -ComputerName $firstNode -ActivityName 'Preparing cluster storage' -ScriptBlock {
                $diskpartCmd = 'LIST DISK'

                $disks = $diskpartCmd | diskpart.exe

                foreach ($line in $disks)
                {
                    if ($line -match 'Disk (?<DiskNumber>\d) \s+(Offline)\s+(?<Size>\d+) GB\s+(?<Free>\d+) GB')
                    {
                        $nextDriveLetter = [char[]](67..90) |
                            Where-Object { (Get-WmiObject -Class Win32_LogicalDisk |
                                    Select-Object -ExpandProperty DeviceID) -notcontains "$($_):"} |
                            Select-Object -First 1

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

        Invoke-LabCommand -ComputerName $firstNode -ActivityName 'Enabling clustering on first node' -ScriptBlock {
            Import-Module FailoverClusters -ErrorAction Stop

            $clusterParameters = @{
                Name                      = $clusterName
                Node                      = $env:COMPUTERNAME
                StaticAddress             = $clusterIp
                AdministrativeAccessPoint = $clusterAccessPoint
                ErrorAction               = 'Stop'
                WarningAction             = 'SilentlyContinue'
            }

            $clusterParameters = Sync-Parameter -Command (Get-Command New-Cluster) -Parameters $clusterParameters

            New-Cluster @clusterParameters

            while (-not (Get-Cluster -Name $clusterName -ErrorAction SilentlyContinue))
            {
                Start-Sleep -Seconds 1
            }

            Get-Cluster -Name $clusterName | Add-ClusterNode $clusterNodeNames

            if ($useDiskWitness)
            {
                $clusterDisk = Get-ClusterResource -Cluster $clusterName -ErrorAction SilentlyContinue | Where-object -Property ResourceType -eq 'Physical Disk'

                if ($clusterDisk)
                {
                    Get-Cluster -Name $clusterName | Set-ClusterQuorum -DiskWitness $clusterDisk
                }
            }
        } -Variable (Get-Variable clusterName, clusterNodeNames, clusterIp, useDiskWitness, clusterAccessPoint) -Function (Get-Command Sync-Parameter)
    }
}
#endregion

#region Install-LabFailoverStorage
function Install-LabFailoverStorage
{
    [CmdletBinding()]
    param
    ( )

    $storageNode = Get-LabVm -Role FailoverStorage -ErrorAction SilentlyContinue
    $role = $storageNode.Roles | Where-Object Name -eq FailoverStorage

    $failoverNodes = Get-LabVm -Role FailoverNode -ErrorAction SilentlyContinue
    $clusters = @{}

    $failoverNodes | Foreach-Object {

        $name = ($PSItem.Roles | Where-Object -Property Name -eq 'FailoverNode').Properties['ClusterName']
        if (-not $name)
        {
            $name = 'ALCluster'
        }

        if (-not $clusters.ContainsKey($name))
        {
            $clusters[$name] = @()
        }
        $clusters[$name] += $_.Name
    }

    $lunDrive = $role.Properties['LunDrive'][0] # Select drive letter only

    foreach ($cluster in $clusters.Clone().GetEnumerator())
    {
        $machines = $cluster.Value
        $clusterName = $cluster.Key
        $initiatorIds = Invoke-LabCommand -ActivityName 'Retrieving IQNs' -ComputerName $machines -ScriptBlock {
            Set-Service -Name MSiSCSI -StartupType Automatic
            Start-Service -Name MSiSCSI
            "IQN:$((Get-WmiObject -Namespace root\wmi -Class MSiSCSIInitiator_MethodClass).iSCSINodeName)"
        } -PassThru -ErrorAction Stop

        $clusters[$clusterName] = $initiatorIds
    }

    Install-LabWindowsFeature -ComputerName $storageNode -FeatureName FS-iSCSITarget-Server

    Invoke-LabCommand -ActivityName 'Creating iSCSI target' -ComputerName $storageNode -ScriptBlock {
        if (-not $lunDrive)
        {
            $lunDrive = $env:SystemDrive[0]
        }

        $driveInfo = [System.IO.DriveInfo] [string] $lunDrive

        if (-not (Test-Path $driveInfo))
        {
            $offlineDisk = Get-Disk | Where-Object -Property OperationalStatus -eq Offline | Select-Object -First 1
            if ($offlineDisk)
            {
                $offlineDisk | Set-Disk -IsOffline $false
                $offlineDisk | Set-Disk -IsReadOnly $false
            }

            if (-not ($offlineDisk | Get-Partition | Get-Volume))
            {
                $offlineDisk | New-Volume -FriendlyName Luns -FileSystem ReFS -DriveLetter $lunDrive
            }
        }

        $lunFolder = New-Item -ItemType Directory -Path (Join-Path -Path $driveInfo -ChildPath LUNs) -ErrorAction SilentlyContinue
        $lunFolder = Get-Item -Path (Join-Path -Path $driveInfo -ChildPath LUNs) -ErrorAction Stop

        foreach ($clu in $clusters.GetEnumerator())
        {
            New-IscsiServerTarget -TargetName $clu.Key -InitiatorIds $clu.Value
            $diskTarget = (Join-Path -Path $lunFolder.FullName -ChildPath "$($clu.Key).vhdx")
            New-IscsiVirtualDisk -Path $diskTarget -Size 1GB
            Add-IscsiVirtualDiskTargetMapping -TargetName $clu.Key -Path $diskTarget
        }

    } -Variable (Get-Variable -Name clusters, lunDrive) -ErrorAction Stop

    $targetAddress = $storageNode.IpV4Address

    Invoke-LabCommand -ActivityName 'Connecting iSCSI target' -ComputerName (Get-LabVm -Role FailoverNode) -ScriptBlock {
        if (-not (Get-Command New-IscsiTargetPortal -ErrorAction SilentlyContinue))
        {
            iscsicli.exe QAddTargetPortal $targetAddress
            $target = ((iscsicli.exe ListTargets) -match 'iqn.+target')[0].Trim()
            iscsicli.exe QLoginTarget $target
        }
        else
        {
            New-IscsiTargetPortal -TargetPortalAddress $targetAddress
            Get-IscsiTarget | Where-Object {-not $PSItem.IsConnected} | Connect-IscsiTarget -IsPersistent $true
        }
    } -Variable (Get-Variable targetAddress) -ErrorAction Stop
}
#endregion
