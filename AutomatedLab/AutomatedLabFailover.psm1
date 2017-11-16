#region Install-LabFailoverCluster
function Install-LabFailoverCluster
{
    [CmdletBinding()]
    param ( )

    # 1 Get-LabMachine -Role FailoverNode, Count ge 2. Wenn Machine bereits installiert, FC aktivieren, sonst Start-LabVm, DomJoin, ...
    # Validator: DomJoin, min count 2, Role FailoverStorage in Lab

    $failoverNodes = Get-LabVm -Role FailoverNode -ErrorAction SilentlyContinue

    Install-LabWindowsFeature -ComputerName $failoverNodes -FeatureName Failover-Clustering, RSAT-Clustering-PowerShell
    
    if (Get-LabVm -Role FailoverStorage)
    {
        Write-ScreenInfo -Message 'Waiting for failover storage server to complete installation'
        Install-LabFailoverStorage
    }

    Write-Screeninfo -Message 'Waiting for failover nodes to complete installation'

    $clusters = $failoverNodes | Group-Object { ($PSItem.Roles | Where-Object -Property Name -eq 'FailoverNode').Properties['ClusterName'] }

    foreach ($cluster in $clusters)
    {
        $firstNode = $cluster.Group | Select-Object -First 1
        $clusterNodeNames = $cluster.Group | Select-Object -Skip 1 -ExpandProperty Name
        $clusterName = $cluster.Name
        $clusterIp = ($firstNode.Roles | Where-Object -Property Name -eq 'FailoverNode').Properties['ClusterIp']

        if (-not $clusterIp)
        {
            $adapterVirtualNetwork = Get-LabVirtualNetworkDefinition -Name $firstNode.NetworkAdapters[0].VirtualSwitch
            $clusterIp = $adapterVirtualNetwork.NextIpAddress()
        }

        if (-not $clusterName)
        {
            $clusterName = 'ALCluster'
        }
        
        Invoke-LabCommand -ComputerName $firstNode -ActivityName 'Enabling clustering on first node' -ScriptBlock {
            New-Cluster –Name $clusterName –Node $env:COMPUTERNAME –StaticAddress $clusterIp

            while (-not (Get-Cluster -Name $clusterName -ErrorAction SilentlyContinue))
            {
                Start-Sleep -Seconds 1
            }
            
            Get-Cluster -Name $clusterName | Add-ClusterNode $clusterNodeNames
        } -Variable (Get-Variable clusterName, clusterNodeNames, clusterIp)
    }    
}
#endregion

#region Install-LabFailoverStorage
function Install-LabFailoverStorage
{
    [CmdletBinding()]
    param ( )

    $storageNode = Get-LabVm -Role FailoverStorage -ErrorAction SilentlyContinue
    $role = $storageNode.Roles | Where-Object Name -eq FailoverStorage
                        
      
    $lunSize = if ($role.Properties['LunSize'])
    {
        $role.Properties['LunSize']
    }
    else
    {
        10GB
    }

    $lunDrive = $role.Properties['LunDrive'][0] # Select drive letter only

    $initiatorIds = Invoke-LabCommand -ActivityName 'Retrieving IQNs' -ComputerName (Get-LabVm -Role FailoverNode) -ScriptBlock {
        Set-Service -Name MSiSCSI -StartupType Automatic
        Start-Service -Name MSiSCSI
        "IQN:$((Get-WmiObject -Namespace root\wmi -Class MSiSCSIInitiator_MethodClass).iSCSINodeName)"
    } -PassThru -ErrorAction Stop

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

        $lunFolder = New-Item -ItemType Directory -Path (Join-Path -Path $driveInfo -ChildPath LUNs)
        $diskTarget = (Join-Path -Path $lunFolder.FullName -ChildPath ALLun1.vhdx)
        New-IscsiVirtualDisk -Path $diskTarget -Size $lunSize
        New-IscsiServerTarget -TargetName ALTarget -InitiatorIds $initiatorIds
        Add-IscsiVirtualDiskTargetMapping -TargetName ALTarget -Path $diskTarget
    } -Variable (Get-Variable -Name initiatorIds, lunSize, lunDrive) -ErrorAction Stop

    $targetAddress = $storageNode.IpV4Address

    Invoke-LabCommand -ActivityName 'Connecting iSCSI target' -ComputerName (Get-LabVm -Role FailoverNode) -ScriptBlock {
        New-IscsiTargetPortal -TargetPortalAddress $targetAddress
        Get-IscsiTarget | Where-Object {-not $PSItem.IsConnected} | Connect-IscsiTarget
    } -Variable (Get-Variable targetAddress) -ErrorAction Stop
}
#endregion
