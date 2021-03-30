# Workshops - DFSHC - Azure

INSERT TEXT HERE

```powershell
$labName = 'DFSHC<SOME UNIQUE DATA>' #THIS NAME MUST BE GLOBALLY UNIQUE

$azureDefaultLocation = 'West Europe' #COMMENT OUT -DefaultLocationName BELOW TO USE THE FASTEST LOCATION

$autoFolderCount = 1000
$runBreakScripts = $true

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine Azure

Add-LabAzureSubscription -DefaultLocationName $azureDefaultLocation

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.56.0/24

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

#these credentials are used for connecting to the machines. As this is a lab we use clear-text passwords
Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:DnsServer1' = '192.168.56.9'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
    }

Add-LabDiskDefinition -Name DFS-FS-A-D -DiskSizeInGb 60
Add-LabDiskDefinition -Name DFS-FS-B-D -DiskSizeInGb 60
Add-LabDiskDefinition -Name DFS-FS-C-D -DiskSizeInGb 60

#Domain Controller
$roles = Get-LabMachineRoleDefinition -Role RootDC @{ DomainFunctionalLevel = 'Win2008'; ForestFunctionalLevel = 'Win2008' }
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
Add-LabMachineDefinition -Name DFS-DC1 -Roles $roles -IpAddress 192.168.56.9 -PostInstallationActivity $postInstallActivity

#DFS Namespace Servers
Add-LabMachineDefinition -Name DFS-NS-A -IpAddress 192.168.56.10
Add-LabMachineDefinition -Name DFS-NS-B -IpAddress 192.168.56.17

#File servers
Add-LabMachineDefinition -Name DFS-FS-A -Roles FileServer -IpAddress 192.168.56.11 -DiskName DFS-FS-A-D
Add-LabMachineDefinition -Name DFS-FS-B -Roles FileServer -IpAddress 192.168.56.18 -DiskName DFS-FS-B-D
Add-LabMachineDefinition -Name DFS-FS-C -Roles FileServer -IpAddress 192.168.56.25 -DiskName DFS-FS-C-D

#Client
Add-LabMachineDefinition -Name DFS-Client -IpAddress 192.168.56.12

Install-Lab

#Install software to all lab machines
$machines = Get-LabVM
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

#Install management tools and DFS features on all machines
Install-LabWindowsFeature -ComputerName $machines -FeatureName RSAT -IncludeAllSubFeature
Install-LabWindowsFeature -ComputerName $machines -FeatureName FS-DFS-Namespace, FS-DFS-Replication

Install-LabWindowsFeature -ComputerName DFS-Client -FeatureName NET-Framework-Core -AsJob


#------------------------------------------------------------------
#------------ Configurations --------------------------------------
#------------------------------------------------------------------

#region Content of 'New-DfsrConfiguration.ps1'
$contentNewDfsrConfiguration = @'
##########################################################
#
#    Copyright (c) Microsoft. All rights reserved.
#    This code is licensed under the Microsoft Public License.
#    THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
#    ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
#    IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
#    PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
#
##########################################################

<#
    .SYNOPSIS
        Creates a new DFSR replication group and one replicated folder on the specified file
        servers with the connection topology between them.
    .DESCRIPTION
        Creates a new replication group and a new replicated folder, adds member computers and the
        desired connection topology, and then configures memberships.  The local computer (where
        this script is run) must be running either Windows Server 2012 R2 with the DFSR role
        installed ('Install-WindowsFeature RSAT-DFS-Mgmt-Con'), or Windows 8.1 with RSAT installed
        from the Microsoft Download Center.  All member computers must be running Windows Server
        2012 R2 or later with the DFSR role installed.  All DFSR objects will be created in the
        current user's domain.
    .EXAMPLE
        .\New-DfsrConfiguration.ps1 -GroupName RG01 -FolderName RF01 -ComputerName SRV01,SRV02,SRV03 -PrimaryComputerName SRV01 -ContentPath C:\RF01 -Verbose

        - Creates a new replication group named "RG01" and a replicated folder named "RF01".
        - Adds the member computers named SRV01, SRV02, and SRV03 to "RG01".
        - Adds all six bidirectional pairwise connections between all three members (a full-mesh
          connection topology).
        - Configures all memberships to use C:\RF01 as the folder for the root of each member's
          local copy of "RF01".
        - Sets SRV01 to be the primary member computer.
    .EXAMPLE
        .\New-DfsrConfiguration.ps1 -GroupName RG02 -FolderName RF02 -HubComputerName SRV01 -ComputerName SRV02,SRV03 -PrimaryComputerName SRV03 -ContentPath C:\RF02 -Verbose

        - Creates a new replication group named "RG02" and a replicated folder named "RF02".
        - Adds the member computers named SRV01, SRV02, and SRV03 to "RG02".
        - Adds four connections: bidirectionally between SRV01 and each of SRV02 and SRV03.
        - Configures all memberships to use C:\RF02 as the folder for the root of each member's
          local copy of "RF02".
        - Sets SRV03 to be the primary member computer.
    .EXAMPLE
        .\New-DfsrConfiguration.ps1 -GroupName RG03 -FolderName RF03 -ComputerName SRV02,SRV03 -PrimaryComputerName SRV01 -ContentPath C:\RF03 -StagingPathQuotaInMB (1024 * 32) -Verbose

        - Creates a new replication group named "RG03" and a replicated folder named "RF03".
        - Adds the member computers named SRV01, SRV02, and SRV03 to "RG03".
        - Adds all six bidirectional pairwise connections between all three members (a full-mesh
          connection topology).
        - Configures all memberships to use C:\RF03 as the folder for the root of each member's
          local copy of "RF03".
        - Sets SRV01 to be the primary member computer and the staging quota to 32 GB.
    .PARAMETER GroupName
        The name of the replication group to create.
    .PARAMETER FolderName
        The name of the replicated folder to create.
    .PARAMETER HubComputerName
        The name of the member computer to serve as the hub for a hub-and-spoke connection
        topology.  Do not specify this parameter (or use $null) for a full-mesh connection
        topology.
    .PARAMETER ComputerName
        A list of computer names to add as members of the replication group.
    .PARAMETER PrimaryComputerName
        The name of the member computer to serve as the authoritative copy during initial
        replication.
    .PARAMETER ContentPath
        The path that member computers will use for their local copy of the new replicated folder.
    .PARAMETER StagingPathQuotaInMB
        The maximum size in megabytes that the staging folder grows before purging oldest files.
#>

param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true,
        HelpMessage='Please specify a unique replication group name.')]
    [ValidateNotNullOrEmpty()]
    [string]$GroupName,

    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true,
        HelpMessage='Please specify a replicated folder name.')]
    [ValidateNotNullOrEmpty()]
    [string]$FolderName,

    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true,
        HelpMessage='Please specify a member computer name to act as the hub server.')]
    [ValidateNotNullOrEmpty()]
    [string]$HubComputerName,

    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true,
        HelpMessage='Please specify a list of member computer names.')]
    [ValidateNotNullOrEmpty()]
    [string[]]$ComputerName,

    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true,
        HelpMessage='Please specify a member computer name to act as the primary member during initial replication.')]
    [ValidateNotNullOrEmpty()]
    [string]$PrimaryComputerName,

    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true,
        HelpMessage='Please specify a content folder path.')]
    [ValidateNotNullOrEmpty()]
    [string]$ContentPath,

    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true,
        HelpMessage='Please specify a maximum size in megabytes for the staging folder.')]
    [ValidateRange(10,[UInt32]::MaxValue)]
    [UInt32]$StagingPathQuotaInMB
)

# Save error preference (in case of dot sourcing) then stop this script on the first error.
$prevErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Stop"

# Save progress preference (in case of dot sourcing) then suppress progress messages from the
# Test-DfsrInstalled workflow below because they are not helpful.
$prevProgressPreference = $ProgressPreference
$ProgressPreference = "SilentlyContinue"

Try {
    if ($HubComputerName) {
        $allComputerNames = $ComputerName + $HubComputerName
    } else {
        $allComputerNames = $ComputerName
    }

    if (!$allComputerNames.Contains($PrimaryComputerName)) {
        $allComputerNames = $allComputerNames + $PrimaryComputerName
    }
    # $allComputerNames now contains all DFSR member computers.

    $spokeComputerNames = $ComputerName
    if (!$spokeComputerNames.Contains($PrimaryComputerName) -and ($PrimaryComputerName -ne $HubComputerName)) {
        $spokeComputerNames = $spokeComputerNames + $PrimaryComputerName
    }
    # $spokeComputerNames now contains all spoke member computers (only used if a hub-and-spoke
    # connection topology is desired).

    # Check that there are at least two member computers specified.
    if ($allComputerNames.Count -lt 2) {
        throw "At least two member computers must be specified for replication."
    }

    # Check that the DFSR PowerShell cmdlets are installed locally.  Note the '*' at the end
    # because otherwise it would return an error (and end the script due to the above changes to
    # $ErrorActionPreference).
    if (!(Get-Command "Get-DfsReplicationGroup*")) {
        throw "Please install the DFSR PowerShell module on the local computer.  For Windows Server 2012 R2 or later, use 'Install-WindowsFeature RSAT-DFS-Mgmt-Con'.  For Windows 8.1 or later, download the RSAT package from the Microsoft Download Center."
    }

    # Verify that the DFSR PowerShell role is installed on each member computer.  A PowerShell
    # workflow allows foreach -parallel which checks each member in parallel.
    workflow Test-DfsrInstalled {
        <#
            .SYNOPSIS
            .PARAMETER MemberComputerNames
                A list of computer names to verify that the DFSR role is installed.
        #>
        param (
            [string[]] $MemberComputerNames
        )

        Write-Verbose "Testing if the DFSR role is installed on all member computers: $MemberComputerNames"
        foreach -parallel ($memberComputer in $MemberComputerNames) {
            $installed = Get-WindowsFeature FS-DFS-Replication -ComputerName $memberComputer
            if ($installed.Installed) {
                Write-Verbose "Verified that the DFSR role is installed on $memberComputer"
            } else {
                throw "Please install the DFSR role on the member computer named $memberComputer using 'Install-WindowsFeature FS-DFS-Replication -ComputerName $memberComputer'."
            }
        }
    }
    Test-DfsrInstalled $allComputerNames


    # Create DFSR configuration Active Directory objects

    # Create a new replication group
    # ------------------------------
    # A replication group's name is unique across the domain.  It serves as the container for all
    # other DFSR configuration objects in AD.
    Write-Verbose "Creating a new replication group named '$GroupName'"
    $rg = New-DfsReplicationGroup -GroupName $GroupName
    Write-Output $rg

    # Create a new replicated folder in the replication group
    # -------------------------------------------------------
    # A replicated folder's name is unique across the replication group.  It serves as the
    # container for the data that will be replicated.
    Write-Verbose "Creating a new replicated folder named '$FolderName'"
    $rf = New-DfsReplicatedFolder -GroupName $GroupName -FolderName $FolderName
    Write-Output $rf

    # Add members to the replication group
    # ------------------------------------
    # A member is a computer that is involved in a particular replication group.  Note that this
    # definition differs from the AD sense; an Active Directory domain controller can be a member
    # of a replication group.
    Write-Verbose "Adding the following member computers to the replication group named '$GroupName': $allComputerNames"
    $members = Add-DfsrMember -GroupName $GroupName -ComputerName $allComputerNames
    Write-Output $members

    # Add connections to the replication group
    # ----------------------------------------
    # A connection allows replication between two members of a replication group.  It is
    # directional, meaning if an enabled connection from SRV01 to SRV02 exists, but not vice-versa,
    # then changes made on SRV01 will be replicated to SRV02, but not the other way around.  This
    # usually is not an issue since the Add-DfsrConnection cmdlet adds two connections (one in
    # each direction) by default.  Each of the topologies demonstrated here add bidirectional
    # connections, so it does not apply here, but it is an important consideration when creating
    # custom topologies.
    if ($HubComputerName) {
        # A hub-and-spoke topology is where a hub member replicates with every other member in the
        # replication group (the spoke members).  It is useful when data is created on the hub
        # member and is replicated out to spoke members.  Although not shown here, this concept can
        # be modified to use multiple hub members.
        Write-Verbose "Configuring a hub-and-spoke connection topology"
        foreach ($spokeComputerName in $spokeComputerNames) {
            Write-Verbose "Adding bidirectional connections between the hub member computer named $HubComputer and the member computer named $spokeComputerName"
            $connection = Add-DfsrConnection -GroupName $GroupName -SourceComputerName $HubComputerName -DestinationComputerName $spokeComputerName
            Write-Output $connection
        }
    } else {
        # A full-mesh topology is where all members replicate with every other member in the
        # replication group.  It is useful when there are ten or fewer members.
        Write-Verbose "Configuring a full-mesh connection topology"
        for ($i = 0 ; $i -lt $allComputerNames.Count ; $i++) {
            for ($j = $i + 1 ; $j -lt $allComputerNames.Count ; $j++) {
                Write-Verbose ("Adding bidirectional connections between the member computers named {0} and {1}" -f $allComputerNames[$i],$allComputerNames[$j])
                $connection = Add-DfsrConnection -GroupName $GroupName -SourceComputerName $allComputerNames[$i] -DestinationComputerName $allComputerNames[$j]
                Write-Output $connection
            }
        }
    }

    # Set the content path and staging quota on all memberships
    # ---------------------------------------------------------
    # A membership contains the member-specific settings for a replicated folder.  When a
    # replicated folder is created, or a member is added to a replication group, one membership is
    # created on each member for each replicated folder.  There is no need to add a membership
    # explictly, and it cannot be removed by itself (it exists as long as the replicated folder and
    # the member are a part of the replication group).
    #
    # The content path is the location of a member computer's local copy of a replicated folder.
    #
    # The staging quota is the maximum size that the staging folder grows before purging the oldest
    # files.  This purging is done according to the staging cleanup percentages in the service
    # configuration settings (Get-DfsrServiceConfiguration).  The recommended value for the staging
    # quota for Windows Server 2012 R2 is 4 GB or the size of the 32 largest files in the
    # replicated folder, whichever is larger.
    #
    # Some may prefer using PowerShell splatting to pass multiple arguments to Set-DfsrMembership.
    # Instead, the simpler approach is used here for clarity.  For those that wish to customize this
    # script, the additional optional parameters to the Set-DfsrMembership cmdlet offer good
    # opportunities for extending the functionality of this script, as well as the use of
    # splatting.
    if ($StagingPathQuotaInMB -gt 0) {
        Write-Verbose "Setting the content path to '$ContentPath' and the staging path quota to $StagingPathQuotaInMB MB for the following member computers: $allComputerNames"
        $memberships = Set-DfsrMembership -GroupName $GroupName -FolderName $FolderName -ComputerName $allComputerNames -ContentPath $ContentPath -StagingPathQuotaInMB $StagingPathQuotaInMB -Force
    } else {
        Write-Verbose "Setting the content path to '$ContentPath' for the following member computers: $allComputerNames"
        $memberships = Set-DfsrMembership -GroupName $GroupName -FolderName $FolderName -ComputerName $allComputerNames -ContentPath $ContentPath -Force
    }
    Write-Output $memberships

    # Set the primary member
    # ----------------------
    # The primary member has the authoritative copy of data in its content path.  This means the
    # primary computer's copy of the data in the replicated folder will win conflicts during
    # initial sync.
    Write-Verbose ("Setting the primary member to be the computer named {0}" -f $PrimaryComputerName)
    $primaryMember = Set-DfsrMembership -GroupName $GroupName -FolderName $FolderName -ComputerName $PrimaryComputerName -PrimaryMember $true -Force
    Write-Output $primaryMember

    # Update the local copy of DFSR configuration on all members
    # ----------------------------------------------------------
    # DFSR AD configuration is cached on each member.  The cmdlets invoked above only update the
    # DFSR AD objects.  To avoid waiting for an automatic refresh, this command forces one
    # immediately on the member computers.
    Write-Verbose "Updating AD configuration on member computers: $allComputerNames"
    Update-DfsrConfigurationFromAD -ComputerName $allComputerNames
    Write-Verbose "Configuration complete.  Windows event 4104 will be written on each non-primary member computer when it completes initial sync."
} Finally {
    $ErrorActionPreference = $prevErrorActionPreference
    $ProgressPreference = $prevProgressPreference
}
'@
#endregion region Content of 'New-DfsrConfiguration.ps1'

#region Configurations
$rootDc = Get-LabVM -Role RootDC

Invoke-LabCommand -ComputerName (Get-LabVM | Where-Object Name -like DFS-NS-?) -ActivityName SetDfsnServerConfiguration -ScriptBlock {
    Set-DfsnServerConfiguration -Computername localhost -UseFqdn $true
}

Invoke-LabCommand -ComputerName $rootDc -ActivityName CreateAdReplicationInfrastructur -ScriptBlock {
    New-ADReplicationSite -Name A
    New-ADReplicationSite -Name B
    New-ADReplicationSite -Name C

    Get-ADReplicationSubnet -Filter * | Remove-ADReplicationSubnet -Confirm:$false

    New-ADReplicationSubnet -Name 192.168.56.8/29 -Site A
    New-ADReplicationSubnet -Name 192.168.56.16/29 -Site B
    New-ADReplicationSubnet -Name 192.168.56.24/29 -Site C

    New-ADReplicationSiteLink -Name A-B -Cost 100 -ReplicationFrequencyInMinutes 15 `
        -SitesIncluded A, B -OtherAttributes @{ options = 1 }

    New-ADReplicationSiteLink -Name A-C -Cost 100 -ReplicationFrequencyInMinutes 15 `
        -SitesIncluded A, C -OtherAttributes @{ options = 1 }

    Move-ADDirectoryServer -Identity $using:rootDc.Name -Site A

    Remove-ADReplicationSiteLink -Identity DEFAULTIPSITELINK -Confirm:$false
    Remove-ADReplicationSite -Identity Default-First-Site-Name -Confirm:$false
}

Invoke-LabCommand -ComputerName (Get-LabVM -Role FileServer) -ActivityName CreateFolderStructure -AsJob -PassThru -ScriptBlock {
    Get-Disk -Number 1 | Set-Disk -IsOffline $false
    Get-Disk -Number 1 | Set-Disk -IsReadOnly $false

    $lastDriveLetter = (Get-PSDrive -PSProvider FileSystem | Select-Object -Last 1).Name
    $content = New-Item -ItemType Directory "$($lastDriveLetter):\Content"

    $autoFolderCount = $using:autoFolderCount

    #create the following folders in the content folder
    $folders = 'Software', 'HomeDirectory'
    foreach ($folder in $folders)
    {
        $share = New-Item -ItemType Directory -Path (Join-Path -Path $content -ChildPath $folder)
        New-SmbShare -Name $share.Name -Path $share.FullName -FullAccess Everyone | Out-Null
    }

    #create n test folders also in content folder
    1..$autoFolderCount | ForEach-Object {
        $folder = "V1-Folder-{0:D5}" -f $_

        $share = New-Item -ItemType Directory -Path (Join-Path -Path $content -ChildPath $folder)
        New-SmbShare -Name $share.Name -Path $share.FullName -FullAccess Everyone | Out-Null

        $folder = "V2-Folder-{0:D5}" -f $_

        $share = New-Item -ItemType Directory -Path (Join-Path -Path $content -ChildPath $folder)
        New-SmbShare -Name $share.Name -Path $share.FullName -FullAccess Everyone | Out-Null
    }
} |
Wait-Job | Out-Null

Invoke-LabCommand -ComputerName (Get-LabVM | Where-Object Name -like DFS-NS-?) -ActivityName CreateRootShares -ScriptBlock {
    $folders = @()
    $folders += New-Item -ItemType Directory -Path C:\DFSRoots\V1-Root, C:\DFSRoots\V2-Root, C:\DFSRoots\Software

    foreach ($folder in $folders)
    {
        New-SmbShare -Name $folder.Name -Path $folder.FullName
    }
} -PassThru

$namespaceServers = Get-LabVM | Where-Object Name -Like 'DFS-NS-?'
Invoke-LabCommand -ComputerName $namespaceServers[0] -ActivityName CreateDfsnNamespaces -ScriptBlock {
    $ns1 = New-DfsnRoot -Path \\contoso.com\V1-Root -TargetPath "\\$($using:namespaceServers[0].Name)\V1-Root" -Type DomainV1
    $ns2 = New-DfsnRoot -Path \\contoso.com\V2-Root -TargetPath "\\$($using:namespaceServers[0].Name)\V2-Root" -Type DomainV2
    $software = New-DfsnRoot -Path \\contoso.com\Software -TargetPath "\\$($using:namespaceServers[0].Name)\Software" -Type DomainV2

    $ns1 | New-DfsnRootTarget -TargetPath "\\$($using:namespaceServers[1].Name)\V1-Root" | Out-Null
    $ns2 | New-DfsnRootTarget -TargetPath "\\$($using:namespaceServers[1].Name)\V2-Root" | Out-Null
    $software | New-DfsnRootTarget -TargetPath "\\$($using:namespaceServers[1].Name)\Software" | Out-Null

    $fileServers = Get-ADComputer -Filter "Name -like 'DFS-FS-*'"
    $session = New-CimSession -ComputerName $fileServers[0].DNSHostName

    $shares = Get-SmbShare -CimSession $session | Where-Object Name -Like 'V1*'
    foreach ($share in $shares)
    {
        $path = Join-Path -Path $ns1.Path -ChildPath $share.Name
        $folder = $ns1 | New-DfsnFolder -Path $path -TargetPath "\\$($share.PSComputerName)\$($share.Name)" -Description AutoCreated

        foreach ($fileServer in ($fileServers | Select-Object -Skip 1))
        {
            $folder | New-DfsnFolderTarget -TargetPath "\\$($fileServer.Name)\$($share.Name)" | Out-Null
        }
    }

    $shares = Get-SmbShare -CimSession $session | Where-Object Name -Like 'V2*'
    foreach ($share in $shares)
    {
        $path = Join-Path -Path $ns2.Path -ChildPath $share.Name
        $folder = $ns2 | New-DfsnFolder -Path $path -TargetPath "\\$($share.PSComputerName)\$($share.Name)" -Description AutoCreated

        foreach ($fileServer in ($fileServers | Select-Object -Skip 1))
        {
            $folder | New-DfsnFolderTarget -TargetPath "\\$($fileServer.Name)\$($share.Name)" | Out-Null
        }
    }

    $share = Get-SmbShare -CimSession $session | Where-Object Name -Like 'Software'
    $path = Join-Path -Path $software.Path -ChildPath $share.Name
    $folder = $software | New-DfsnFolder -Path $path -TargetPath "\\$($share.PSComputerName)\$($share.Name)" -Description AutoCreated

    foreach ($fileServer in ($fileServers | Select-Object -Skip 1))
    {
        $folder | New-DfsnFolderTarget -TargetPath "\\$($fileServer.Name)\$($share.Name)" | Out-Null
    }
} -PassThru

$primaryfileServer = (Get-LabVM -Role FileServer)[0]
$fileServerNames = (Get-LabVM -Role FileServer).Name

$tempFile = [System.IO.Path]::GetTempFileName()
$contentNewDfsrConfiguration | Out-File -FilePath $tempFile
Send-File -SourceFilePath $tempFile -DestinationFolderPath C:\ -Session (New-LabPSSession -ComputerName $primaryfileServer)
Remove-Item -Path $tempFile

Invoke-LabCommand -ComputerName $primaryfileServer -ActivityName CreateDfsrReplication -ScriptBlock {
    $lastDriveLetter = (Get-PSDrive -PSProvider FileSystem | Select-Object -Last 1).Name

    $content = New-Item -ItemType Directory "$($lastDriveLetter):\Content"
    C:\New-DfsrConfiguration.ps1 -GroupName Software -FolderName Software `
        -ComputerName $using:fileServerNames -PrimaryComputerName $using:primaryfileServer -ContentPath "$($lastDriveLetter):\Content\Software\Tools"

    Copy-Item -Path C:\Tools\*.* -Destination "$($lastDriveLetter):\Content\Software\Tools" -Recurse
}
#endregion Configurations

#region Break scripts
#------------------------------------------------------------------
#------------ Break Scripts ---------------------------------------
#------------------------------------------------------------------
#lab installation completed. Run the BreakScripts when the variable $runBreakScripts is set to $true
if ($runBreakScripts)
{
    $fileServers = Get-LabVM -Role FileServer
    Invoke-LabCommand -ComputerName $fileServers[0] -ActivityName "LocalSettings and GlobalSettings on Server0" -ScriptBlock {
        # write some events
        Write-EventLog -LogName 'DFS Replication' -Source DFSR -EventId 5102 -EntryType Error -Message Bla
        Write-EventLog -LogName 'DFS Replication' -Source DFSR -EventId 5014 -EntryType Error -Message "Error: 9036 (Paused for backup or restore)"
        Write-EventLog -LogName 'DFS Replication' -Source DFSR -EventId 2104 -EntryType Warning -Message "Dirty Shutdown"
        Write-EventLog -LogName 'DFS Replication' -Source DFSR -EventId 4502 -EntryType Warning -Message "This disk full error may be caused by insufficient real disk space or by some disk quota software."

        # Set staging quota
        Get-DfsrMember -GroupName Software | Set-DfsrMembership -FolderName Software -StagingPathQuotaInMB 10 -Force

        # Set file exclusion
        Get-DfsReplicationGroup | Set-DfsReplicatedFolder -FileNameToExclude *.mpg

        # Set connection settings
        Get-DfsrMember -GroupName Software | Get-DfsrConnection | Get-Random | Remove-DfsrConnection -Force
        Get-DfsrMember -GroupName Software | Get-DfsrConnection | Get-Random | Set-DfsrConnection -DisableRDC $true
        Get-DfsrMember -GroupName Software | Get-DfsrConnection | Get-Random | Set-DfsrConnectionSchedule -ScheduleType Never

        # Disable debug log
        Set-DfsrServiceConfiguration -DisableDebugLog $true


        #Add all existing sites to one randomly chosen site link
        $names = Get-ADReplicationSite -Filter * | Select-Object -ExpandProperty Name
        $link = Get-ADReplicationSiteLink -Filter * | Get-Random

        foreach ($name in $names)
        {
            $link | Set-ADReplicationSiteLink -SitesIncluded @{ Add = $name }
        }

        #remove one subnet that does not belong to the DCs' site
        Get-ADReplicationSubnet -Filter * | Select-Object -Skip 1 | Get-Random | Remove-ADReplicationSubnet -Confirm:$false

        #Create an non-mapped subnet
        New-ADReplicationSubnet -Name 192.168.56.200/29

        #Create a site without subnet
        New-ADReplicationSite -Name D

        # restart service
        Restart-Service DFSR


        # get namespace
        $dfsnroot = Get-DfsnRoot

        # Disable root target
        $dfsnroottarget = Get-DfsnRootTarget -Path $dfsnroot.Path[0]
        Set-DfsnRootTarget -path $dfsnroot.Path[0] -TargetPath $dfsnroottarget[0].TargetPath -State Offline

        # Enable /insite
        # start-sleep -Seconds 5
        # Set-DfsnRoot -Path $dfsnroot.Path[0] -EnableInsiteReferrals $true

        # Set root target globallow
        $dfsnroottarget = Get-DfsnRootTarget -Path $dfsnroot.Path[2]
        set-DfsnRootTarget -path $dfsnroot.Path[2] -TargetPath $dfsnroottarget[1].TargetPath -ReferralPriorityClass globallow

        # Set root target priority
        $dfsnroottarget = Get-DfsnRootTarget -Path $dfsnroot.Path[2]
        set-DfsnRootTarget -path $dfsnroot.Path[2] -TargetPath $dfsnroottarget[0].TargetPath -ReferralPriorityRank 1

        # Enable /ABE
        Set-DfsnRoot -Path $dfsnroot.Path[2] -EnableAccessBasedEnumeration $true

        # Enable /rootscalability
        Set-DfsnRoot -Path $dfsnroot.Path[2] -EnableRootScalability $true

        # Set cache time to 1h
        Set-DfsnRoot -Path $dfsnroot.Path[1] -TimeToLiveSec 3600


        # set global-high on one folder target
        $dfsnfolder = Get-DfsnFolder -Path \\contoso\software\software
        $dfsnfoldertarget = Get-DfsnFolderTarget -Path $dfsnfolder.Path
        Set-DfsnFolderTarget -Path $dfsnfolder.Path -TargetPath $dfsnfoldertarget.TargetPath[2] -ReferralPriorityClass globalhigh
    }

    Invoke-LabCommand -ComputerName $fileServers[1] -ActivityName "LocalSettings on Server 1" -ScriptBlock {

        # Set service start up settings
        Set-Service DFSR -StartupType Disabled -PassThru
        Stop-Service DFSR -PassThru

        Set-Service dfs -StartupType Manual

        # Edit hosts file
        Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "192.168.56.70 $($using:fileServers[0].Name)"

        # Rename local folder target
        $drive = Get-PSDrive -PSProvider FileSystem | Select-Object -Last 1
        Rename-Item -Path "$($drive.Name):\Content\Software\Tools" -NewName "$($drive.Name):\Content\Software\Toools"

        # Write events
        1..15 | ForEach-Object {
            Write-EventLog -LogName 'DFS Replication' -Source DFSR -EventId 4202 -EntryType Error -Message Bla
            Write-EventLog -LogName 'DFS Replication' -Source DFSR -EventId 4204 -EntryType Error -Message Bla
            Write-EventLog -LogName 'DFS Replication' -Source DFSR -EventId 4206 -EntryType Error -Message Bla
            Write-EventLog -LogName 'DFS Replication' -Source DFSR -EventId 4208 -EntryType Error -Message Bla
        }
    }

    $fileServers = Get-LabVM -Role FileServer
    Invoke-LabCommand -ComputerName $fileServers[2] -ActivityName "LocalSettings on Server2" -ScriptBlock {

        # Write some events
        1..250 | ForEach-Object {
            Write-EventLog -LogName 'DFS Replication' -Source DFSR -EventId 4412 -EntryType Error -Message "Assume this server is not accessed by users and conflicting files should not occur here"
        }

        # Write some events
        1..10 | ForEach-Object {
            Write-EventLog -LogName 'DFS Replication' -Source DFSR -EventId 1006 -EntryType Error -Message "Service stopping"
            Write-EventLog -LogName 'DFS Replication' -Source DFSR -EventId 1008 -EntryType Error -Message "Service stopped"
            Write-EventLog -LogName 'DFS Replication' -Source DFSR -EventId 1004 -EntryType Error -Message "Service started"
        }

        Restart-Service DFSR
    }
}
#endregion Break Scripts

#stop all machines to save money
Stop-LabVM -All -Wait

Show-LabDeploymentSummary -Detailed
```
