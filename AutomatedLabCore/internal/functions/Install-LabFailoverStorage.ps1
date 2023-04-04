function Install-LabFailoverStorage
{
    [CmdletBinding()]
    param
    ( )

    $storageNodes = Get-LabVM -Role FailoverStorage -ErrorAction SilentlyContinue
    $failoverNodes = Get-LabVM -Role FailoverNode -ErrorAction SilentlyContinue
    if ($storageNodes.Count -gt 1)
    {
        foreach ($failoverNode in $failoverNodes)
        {
            $role = $failoverNode.Roles | Where-Object Name -eq 'FailoverNode'
            if (-not $role.Properties.ContainsKey('StorageTarget'))
            {
                Write-Error "There are $($storageNodes.Count) VMs with the 'FailoverStorage' role and the storage target is not defined for '$failoverNode'. Please define the property 'StorageTarget' with the 'FailoverStorage' role." -ErrorAction Stop
            }
        }
    }
    Start-LabVM -ComputerName (Get-LabVM -Role FailoverStorage, FailoverNode) -Wait
    
    $clusters = @{}
    $storageMapping = @{}
    
    foreach ($failoverNode in $failoverNodes) {
    
        $role = $failoverNode.Roles | Where-Object Name -eq 'FailoverNode'
        $name = $role.Properties['ClusterName']
        $storageMapping."$($failoverNode.Name)" = if ($role.Properties.ContainsKey('StorageTarget'))
        {
            $role.Properties['StorageTarget']
        }
        else
        {
            $storageNodes.Name
        }

        if (-not $name)
        {
            $name = 'ALCluster'
        }
    
        if (-not $clusters.ContainsKey($name))
        {
            $clusters[$name] = @()
        }
        $clusters[$name] += $failoverNode.Name
    }
    
    foreach ($cluster in $clusters.Clone().GetEnumerator())
    {
        $machines = $cluster.Value
        $clusterName = $cluster.Key
        $initiatorIds = Invoke-LabCommand -ActivityName 'Retrieving IQNs' -ComputerName $machines -ScriptBlock {
            Set-Service -Name MSiSCSI -StartupType Automatic
            Start-Service -Name MSiSCSI
            if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)
            {
                "IQN:$((Get-CimInstance -Namespace root\wmi -Class MSiSCSIInitiator_MethodClass).iSCSINodeName)"
            }
            else
            {
                "IQN:$((Get-WmiObject -Namespace root\wmi -Class MSiSCSIInitiator_MethodClass).iSCSINodeName)"
            }
        } -PassThru -ErrorAction Stop
    
        $clusters[$clusterName] = $initiatorIds
    }
    
    Install-LabWindowsFeature -ComputerName $storageNodes -FeatureName FS-iSCSITarget-Server

    foreach ($storageNode in $storageNodes)
    {
        foreach ($disk in $storageNode.Disks)
        {
            Write-ScreenInfo "Working on $($disk.name)"
            #$lunDrive = $role.Properties['LunDrive'][0] # Select drive letter only
            $driveLetter = $disk.DriveLetter

            Invoke-LabCommand -ActivityName "Creating iSCSI target for $($disk.name) on '$storageNode'" -ComputerName $storageNode -ScriptBlock {
                # assign drive letter if not provided
                if (-not $driveLetter)
                {
                    # http://vcloud-lab.com/entries/windows-2016-server-r2/find-next-available-free-drive-letter-using-powershell-
                    #$driveLetter = (68..90 | % {$L = [char]$_; if ((gdr).Name -notContains $L) {$L}})[0]
                    $driveLetter = $env:SystemDrive[0]
                }

                $driveInfo = [System.IO.DriveInfo] [string] $driveLetter

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
                        $offlineDisk | New-Volume -FriendlyName $disk -FileSystem ReFS -DriveLetter $driveLetter
                    }
                }

                $folderPath = Join-Path -Path $driveInfo -ChildPath $disk.Name
                $folder = New-Item -ItemType Directory -Path $folderPath -ErrorAction SilentlyContinue
                $folder = Get-Item -Path $folderPath -ErrorAction Stop

                foreach ($clu in $clusters.GetEnumerator())
                {
                    if (-not (Get-IscsiServerTarget -TargetName $clu.Key -ErrorAction SilentlyContinue))
                    {
                        New-IscsiServerTarget -TargetName $clu.Key -InitiatorIds $clu.Value
                    }
                    $diskTarget = (Join-Path -Path $folder.FullName -ChildPath "$($disk.name).vhdx")
                    $diskSize = [uint64]$disk.DiskSize*1GB
                    if (-not (Get-IscsiVirtualDisk -Path $diskTarget -ErrorAction SilentlyContinue))
                    {
                        New-IscsiVirtualDisk -Path $diskTarget -Size $diskSize
                    }
                    Add-IscsiVirtualDiskTargetMapping -TargetName $clu.Key -Path $diskTarget
                }
            } -Variable (Get-Variable -Name clusters, disk, driveletter) -ErrorAction Stop

            Invoke-LabCommand -ActivityName "Connecting iSCSI target - storage node '$storageNode' - disk '$disk'" -ComputerName (Get-LabVM -Role FailoverNode) -ScriptBlock {
                $targetAddress = $storageMapping[$env:COMPUTERNAME]
                if (-not (Get-Command New-IscsiTargetPortal -ErrorAction SilentlyContinue))
                {
                    iscsicli.exe QAddTargetPortal $targetAddress
                    $target = ((iscsicli.exe ListTargets) -match 'iqn.+target')[0].Trim()
                    iscsicli.exe QLoginTarget $target
                }
                else
                {
                    New-IscsiTargetPortal -TargetPortalAddress $targetAddress
                    Get-IscsiTarget | Where-Object {-not $_.IsConnected} | Connect-IscsiTarget -IsPersistent $true
                }
            } -Variable (Get-Variable storageMapping) -ErrorAction Stop
        }
    }
}
