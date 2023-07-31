function Initialize-LWAzureVM
{
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine[]]$Machine
    )

    Test-LabHostConnected -Throw -Quiet
    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount
    $lab = Get-Lab

    $initScript = {
        param(
            [string]
            $UserLocale,

            [string]
            $TimeZoneId,

            [string]
            $Disks,

            [string]
            $LabSourcesPath,

            [string]
            $StorageAccountName,

            [string]
            $StorageAccountKey,

            [string[]]
            $DnsServers,

            [int]
            $WinRmMaxEnvelopeSizeKb,

            [int]
            $WinRmMaxConcurrentOperationsPerUser,

            [int]
            $WinRmMaxConnections,

            [string]
            $PublicKey
        )

        $defaultSettings = @{
            WinRmMaxEnvelopeSizeKb              = 500
            WinRmMaxConcurrentOperationsPerUser = 1500
            WinRmMaxConnections                 = 300
        }

        $null = mkdir C:\DeployDebug -ErrorAction SilentlyContinue
        $null = Start-Transcript -OutputDirectory C:\DeployDebug
    
        Start-Service WinRm
        foreach ($setting in $defaultSettings.GetEnumerator())
        {
            if ($PSBoundParameters[$setting.Key].Value -ne $setting.Value)
            {
                $subdir = if ($setting.Key -match 'MaxEnvelope') { $null } else { 'Service\' }
                Set-Item "WSMAN:\localhost\$subdir$($setting.Key.Replace('WinRm',''))" $($PSBoundParameters[$setting.Key]) -Force
            }
        }

        Enable-PSRemoting -Force -SkipNetworkProfileCheck
        Enable-WSManCredSSP -Role Server -Force

        #region Region Settings Xml
        $regionSettings = @'
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">

 <!-- user list -->
 <gs:UserList>
    <gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/>
 </gs:UserList>

 <!-- GeoID -->
 <gs:LocationPreferences>
    <gs:GeoID Value="{1}"/>
 </gs:LocationPreferences>

 <!-- system locale -->
 <gs:SystemLocale Name="{0}"/>

<!-- user locale -->
 <gs:UserLocale>
    <gs:Locale Name="{0}" SetAsCurrent="true" ResetAllSettings="true"/>
 </gs:UserLocale>

</gs:GlobalizationServices>
'@
        #endregion

        try
        {
            $geoId = [System.Globalization.RegionInfo]::new($UserLocale).GeoId
        }
        catch
        {
            $geoId = 244 #default is US
        }

        if (-not (Test-Path 'C:\AL'))
        {
            $alDir = New-Item -ItemType Directory -Path C:\AL -Force
        }

        $alDir = 'C:\AL'

        $tempFile = Join-Path -Path $alDir -ChildPath RegionalSettings
        $regionSettings -f $UserLocale, $geoId | Out-File -FilePath $tempFile
        $argument = 'intl.cpl,,/f:"{0}"' -f $tempFile
        control.exe $argument
        Start-Sleep -Seconds 1

        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force

        $idx = (Get-NetIPInterface | Where-object { $_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -like "*Ethernet*" }).ifIndex
        $dnsServer = Get-DnsClientServerAddress -InterfaceIndex $idx -AddressFamily IPv4
        Set-DnsClientServerAddress -InterfaceIndex $idx -ServerAddresses 168.63.129.16
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/powershell/powershell/releases/latest' -UseBasicParsing -ErrorAction SilentlyContinue
        $uri = ($release.assets | Where-Object name -like '*-win-x64.msi').browser_download_url
        if (-not $uri)
        {
            $uri = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.5/PowerShell-7.2.5-win-x64.msi'
        }
    
        Invoke-WebRequest -Uri $uri -UseBasicParsing -OutFile C:\PS7.msi -ErrorAction SilentlyContinue    
        Start-Process -Wait -FilePath msiexec '/package C:\PS7.msi /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=0 ENABLE_PSREMOTING=0 REGISTER_MANIFEST=0 USE_MU=0 ENABLE_MU=0' -NoNewWindow -PassThru -ErrorAction SilentlyContinue
        Remove-Item -Path C:\PS7.msi -ErrorAction SilentlyContinue

        # Configure SSHD for PowerShell Remoting alternative that also works on Linux
        if (Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*')
        {
            Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction SilentlyContinue
            Start-Service sshd -ErrorAction SilentlyContinue
            Set-Service -Name sshd -StartupType 'Automatic' -ErrorAction SilentlyContinue

            if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) 
            {
                New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any
            }

            New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\powershell\7\pwsh.exe" -PropertyType String -Force -ErrorAction SilentlyContinue
            $null = New-Item -Force -Path C:\AL\SSH -ItemType Directory
            if ($PublicKey) { $PublicKey | Set-Content -Path (Join-Path -Path C:\AL\SSH -ChildPath 'keys') }
            Start-Process -Wait -FilePath icacls.exe -ArgumentList "$(Join-Path -Path C:\AL\SSH -ChildPath 'keys') /inheritance:r /grant ""Administrators:F"" /grant ""SYSTEM:F""" -ErrorAction SilentlyContinue
            $sshdConfig = @"
Port 22
PasswordAuthentication no
PubkeyAuthentication yes
GSSAPIAuthentication yes
AllowGroups Users Administrators
AuthorizedKeysFile c:/al/ssh/keys
Subsystem powershell c:/progra~1/powershell/7/pwsh.exe -sshs -NoLogo
"@
            $sshdConfig | Set-Content -Path (Join-Path -Path $env:ProgramData -ChildPath 'ssh/sshd_config') -ErrorAction SilentlyContinue    
            Restart-Service -Name sshd -ErrorAction SilentlyContinue    
        }

        Set-DnsClientServerAddress -InterfaceIndex $idx -ServerAddresses $dnsServer.ServerAddresses

        #Set Power Scheme to High Performance
        powercfg.exe -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

        #Create a scheduled tasks that maps the Azure lab sources drive during each logon
        if (-not [string]::IsNullOrWhiteSpace($LabSourcesPath))
        {
            $script = @'
$output = ''
$labSourcesPath = '{0}'

$pattern = '^(OK|Unavailable) +(?<DriveLetter>\w): +\\\\automatedlab'

#remove all drive connected to an Azure LabSources share that are no longer available
$drives = net.exe use
foreach ($line in $drives)
{{
    if ($line -match $pattern)
    {{
        $output += net.exe use "$($Matches.DriveLetter):" /d
    }}
}}

$output += cmdkey.exe /add:{1} /user:{2} /pass:{3}

Start-Sleep -Seconds 1

net.exe use * {0} /u:{2} {3}

$initialErrorCode = $LASTEXITCODE
    
if ($LASTEXITCODE -eq 2) {{
    $hostName = ([uri]$labSourcesPath).Host
	$dnsRecord = Resolve-DnsName -Name $hostname | Where-Object {{ $_ -is [Microsoft.DnsClient.Commands.DnsRecord_A] }}
    $ipAddress = $dnsRecord.IPAddress
    $alternativeLabSourcesPath = $labSourcesPath.Replace($hostName, $ipAddress)
    $output += net.exe use * $alternativeLabSourcesPath /u:{2} {3}
}}

$finalErrorCode = $LASTEXITCODE

[pscustomobject]@{{
    Output = $output
    InitialErrorCode = $initialErrorCode
    FinalErrorCode = $finalErrorCode
    LabSourcesPath = $labSourcesPath
    AlternativeLabSourcesPath  = $alternativeLabSourcesPath 
}}
'@

            $cmdkeyTarget = ($LabSourcesPath -split '\\')[2]
            $script = $script -f $LabSourcesPath, $cmdkeyTarget, $StorageAccountName, $StorageAccountKey

            [pscustomobject]@{
                Path               = $LabSourcesPath
                StorageAccountName = $StorageAccountName
                StorageAccountKey  = $StorageAccountKey
            } | Export-Clixml -Path C:\AL\LabSourcesStorageAccount.xml
            $script | Out-File C:\AL\AzureLabSources.ps1 -Force
        }

        #set the time zone
        Set-TimeZone -Name $TimeZoneId

        reg.exe add 'HKLM\SOFTWARE\Microsoft\ServerManager\oobe' /v DoNotOpenInitialConfigurationTasksAtLogon /d 1 /t REG_DWORD /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\ServerManager' /v DoNotOpenServerManagerAtLogon /d 1 /t REG_DWORD /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' /v EnableFirstLogonAnimation /d 0 /t REG_DWORD /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v FilterAdministratorToken /t REG_DWORD /d 0 /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v EnableLUA /t REG_DWORD /d 0 /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' /v IsInstalled /t REG_DWORD /d 0 /f #disable admin IE Enhanced Security Configuration
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' /v IsInstalled /t REG_DWORD /d 0 /f #disable user IE Enhanced Security Configuration
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' /v BgInfo /t REG_SZ /d "C:\AL\BgInfo.exe C:\AL\BgInfo.bgi /Timer:0 /nolicprompt" /f

        #turn off the Windows firewall
        Set-NetFirewallProfile -All -Enabled False -PolicyStore PersistentStore

        if ($DnsServers.Count -gt 0)
        {
            Write-Verbose "Configuring $($DnsServers.Count) DNS Servers"
            $idx = (Get-NetIPInterface | Where-object { $_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -like "*Ethernet*" }).ifIndex
            Set-DnsClientServerAddress -InterfaceIndex $idx -ServerAddresses $DnsServers
        }

        #Add *.windows.net to Local Intranet Zone
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\windows.net'
        New-Item -Path $path -Force

        New-ItemProperty $path -Name http -Value 1 -Type DWORD
        New-ItemProperty $path -Name file -Value 1 -Type DWORD

        if (-not $Disks) { $null = try { Stop-Transcript -ErrorAction Stop } catch { }; return }
        
        # Azure InvokeRunAsCommand is not very clever, so we sent the stuff as JSON
        $Disks | Set-Content -Path C:\AL\disks.json
        [object[]] $diskObjects = $Disks | ConvertFrom-Json
        Write-Verbose -Message "Disk count for $env:COMPUTERNAME`: $($diskObjects.Count)"
        foreach ($diskObject in $diskObjects.Where({ -not $_.SkipInitialization }))
        {
            $disk = Get-Disk | Where-Object Location -like "*LUN $($diskObject.LUN)"
            $disk | Set-Disk -IsReadOnly $false
            $disk | Set-Disk -IsOffline $false
            $disk | Initialize-Disk -PartitionStyle GPT
            $party = if ($diskObject.DriveLetter)
            {
                $disk | New-Partition -UseMaximumSize -DriveLetter $diskObject.DriveLetter
            }
            else
            {
                $disk | New-Partition -UseMaximumSize -AssignDriveLetter
            }
            $party | Format-Volume -Force -UseLargeFRS:$diskObject.UseLargeFRS -AllocationUnitSize $diskObject.AllocationUnitSize -NewFileSystemLabel $diskObject.Label
        }

        $null = try { Stop-Transcript -ErrorAction Stop } catch { }
    }

    $initScriptFile = New-Item -ItemType File -Path (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "$($Lab.Name)vminit.ps1") -Force
    $initScript.ToString() | Set-Content -Path $initScriptFile -Force

    # Configure AutoShutdown
    if ($lab.AzureSettings.AutoShutdownTime)
    {
        $time = $lab.AzureSettings.AutoShutdownTime
        $tz = if (-not $lab.AzureSettings.AutoShutdownTimeZone) { Get-TimeZone } else { Get-TimeZone -Id $lab.AzureSettings.AutoShutdownTimeZone }
        Write-ScreenInfo -Message "Configuring auto-shutdown of all VMs daily at $($time) in timezone $($tz.Id)"
        Enable-LWAzureAutoShutdown -ComputerName (Get-LabVm -IncludeLinux | Where-Object Name -notin $machineSpecific.Name) -Time $time -TimeZone $tz.Id -Wait
    }

    $machineSpecific = Get-LabVm -SkipConnectionInfo -IncludeLinux | Where-Object {
        $_.AzureProperties.ContainsKey('AutoShutdownTime')
    }

    foreach ($machine in $machineSpecific)
    {
        $time = $machine.AzureProperties.AutoShutdownTime
        $tz = if (-not $machine.AzureProperties.AutoShutdownTimezoneId) { Get-TimeZone } else { Get-TimeZone -Id $machine.AzureProperties.AutoShutdownTimezoneId }
        Write-ScreenInfo -Message "Configure shutdown of $machine daily at $($time) in timezone $($tz.Id)"
        Enable-LWAzureAutoShutdown -ComputerName $machine -Time $time -TimeZone $tz.Id -Wait
    }

    Write-ScreenInfo -Message 'Configuring localization and additional disks' -TaskStart -NoNewLine
    if (-not $lab.AzureSettings.IsAzureStack) { $labsourcesStorage = Get-LabAzureLabSourcesStorage }
    $jobs = [System.Collections.ArrayList]::new()
    foreach ($m in ($Machine | Where-Object OperatingSystemType -eq 'Windows'))
    {
        [string[]]$DnsServers = ($m.NetworkAdapters | Where-Object { $_.VirtualSwitch.Name -eq $Lab.Name }).Ipv4DnsServers.AddressAsString
        $azVmDisks = (Get-AzVm -Name $m.ResourceName -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName).StorageProfile.DataDisks
        foreach ($machDisk in $m.Disks)
        {
            $machDisk.Lun = $azVmDisks.Where({ $_.Name -eq $machDisk.Name }).Lun
        }
        
        $diskJson = $m.disks | ConvertTo-Json -Compress

        $scriptParam = @{
            UserLocale                          = $m.UserLocale
            TimeZoneId                          = $m.TimeZone
            WinRmMaxEnvelopeSizeKb              = Get-LabConfigurationItem -Name WinRmMaxEnvelopeSizeKb
            WinRmMaxConcurrentOperationsPerUser = Get-LabConfigurationItem -Name WinRmMaxConcurrentOperationsPerUser
            WinRmMaxConnections                 = Get-LabConfigurationItem -Name WinRmMaxConnections
        }
        $azsArgumentLine = '-UserLocale "{0}" -TimeZoneId "{1}" -WinRmMaxEnvelopeSizeKb {2} -WinRmMaxConcurrentOperationsPerUser {3} -WinRmMaxConnections {4}' -f $m.UserLocale, $m.TimeZone, (Get-LabConfigurationItem -Name WinRmMaxEnvelopeSizeKb), (Get-LabConfigurationItem -Name WinRmMaxConcurrentOperationsPerUser), (Get-LabConfigurationItem -Name WinRmMaxConnections)

        if ($DnsServers.Count -gt 0)
        {
            $scriptParam.DnsServers = $DnsServers
            $azsArgumentLine += ' -DnsServers "{0}"' -f ($DnsServers -join '","')
        }

        if ($m.SshPublicKey)
        {
            $scriptParam.PublicKey = $m.SshPublicKey
            $azsArgumentLine += ' -PublicKey "{0}"' -f $m.SshPublicKey
        }

        if ($diskJson)
        {
            $scriptParam.Disks = $diskJson
            $azsArgumentLine += " -Disks '{0}'" -f $diskJson
        }

        if ($labsourcesStorage)
        {            
            $scriptParam.LabSourcesPath = $labsourcesStorage.Path
            $scriptParam.StorageAccountName = $labsourcesStorage.StorageAccountName
            $scriptParam.StorageAccountKey = $labsourcesStorage.StorageAccountKey
            $azsArgumentLine += '-LabSourcesPath {0} -StorageAccountName {1} -StorageAccountKey {2}' -f $labsourcesStorage.Path, $labsourcesStorage.StorageAccountName, $labsourcesStorage.StorageAccountKey
        }

        if ($m.IsDomainJoined)
        {
            $domain = $lab.Domains | Where-Object Name -eq $m.DomainName
        }

        # Azure Stack - Create temporary storage account to upload script and use extension - sad, but true.
        if ($Lab.AzureSettings.IsAzureStack)
        {
            $sa = Get-AzStorageAccount -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue
            if (-not $sa)
            {
                $sa = New-AzStorageAccount -Name "cse$(-join (1..10 | % {[char](Get-Random -Min 97 -Max 122)}))" -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -SkuName Standard_LRS -Kind Storage -Location (Get-LabAzureDefaultLocation).Location
            }

            $co = $sa | Get-AzStorageContainer -Name customscriptextension -ErrorAction SilentlyContinue
            if (-not $co)
            {
                $co = $sa | New-AzStorageContainer -Name customscriptextension
            }

            $content = Set-AzStorageBlobContent -File $initScriptFile -CloudBlobContainer $co.CloudBlobContainer -Blob $(Split-Path -Path $initScriptFile -Leaf) -Context $sa.Context -Force -ErrorAction Stop
            $token = New-AzStorageBlobSASToken -CloudBlob $content.ICloudBlob -StartTime (Get-Date) -ExpiryTime $(Get-Date).AddHours(1) -Protocol HttpsOnly -Context $sa.Context -Permission r -ErrorAction Stop
            $uri = '{0}{1}/{2}{3}' -f $co.Context.BlobEndpoint, 'customscriptextension', $(Split-Path -Path $initScriptFile -Leaf), $token
            [version] $typehandler = (Get-AzVMExtensionImage -PublisherName Microsoft.Compute -Type CustomScriptExtension -Location (Get-LabAzureDefaultLocation).Location | Sort-Object { [version]$_.Version } | Select-Object -Last 1).Version
            
            $extArg = @{
                ResourceGroupName  = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
                VMName             = $m.ResourceName
                FileUri            = $uri
                TypeHandlerVersion = '{0}.{1}' -f $typehandler.Major, $typehandler.Minor
                Name               = 'initcustomizations'
                Location           = (Get-LabAzureDefaultLocation).Location
                Run                = Split-Path -Path $initScriptFile -Leaf
                Argument           = $azsArgumentLine
                NoWait             = $true
            }
            $Null = Set-AzVMCustomScriptExtension @extArg
        }
        else
        {
            $null = $jobs.Add((Invoke-AzVMRunCommand -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -VMName $m.ResourceName -ScriptPath $initScriptFile -Parameter $scriptParam -CommandId 'RunPowerShellScript' -ErrorAction Stop -AsJob))
        }
    }


    $initScriptLinux = @'
sudo sed -i 's|[#]*GSSAPIAuthentication yes|GSSAPIAuthentication yes|g' /etc/ssh/sshd_config
sudo sed -i 's|[#]*PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config
sudo sed -i 's|[#]*PubkeyAuthentication yes|PubkeyAuthentication yes|g' /etc/ssh/sshd_config
if [ -n "$(sudo cat /etc/ssh/sshd_config | grep 'Subsystem powershell')" ]; then
    echo "PowerShell subsystem configured"
else
    echo "Subsystem powershell /usr/bin/pwsh -sshs -NoLogo -NoProfile" | sudo tee --append /etc/ssh/sshd_config
fi
sudo mkdir -p /usr/local/share/powershell 2>/dev/null
sudo chmod 777 -R /usr/local/share/powershell

if [ -n "$(which apt 2>/dev/null)" ]; then
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
    sudo apt update
    sudo apt install -y wget apt-transport-https software-properties-common
    wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt update
    sudo apt install -y powershell
    sudo apt install -y openssl omi omi-psrp-server
    sudo apt install -y oddjob oddjob-mkhomedir sssd adcli krb5-workstation realmd samba-common samba-common-tools authselect-compat openssh-server
elif [ -n "$(which yum 2>/dev/null)" ]; then
    sudo rpm -Uvh "https://packages.microsoft.com/config/rhel/$(sudo cat /etc/redhat-release | grep -oP "(\d)" | head -1)/packages-microsoft-prod.rpm"
    sudo yum install -y powershell
    sudo yum install -y openssl omi omi-psrp-server
    sudo yum install -y oddjob oddjob-mkhomedir sssd adcli krb5-workstation realmd samba-common samba-common-tools authselect-compat openssh-server
elif [ -n "$(which dnf 2>/dev/null)" ]; then
    sudo rpm -Uvh https://packages.microsoft.com/config/rhel/$(sudo cat /etc/redhat-release | grep -oP "(\d)" | head -1)/packages-microsoft-prod.rpm
    sudo dnf install -y powershell
    sudo dnf install -y openssl omi omi-psrp-server
    sudo dnf install -y oddjob oddjob-mkhomedir sssd adcli krb5-workstation realmd samba-common samba-common-tools authselect-compat openssh-server
fi
sudo systemctl restart sshd
'@
    $linuxInitFiles = foreach ($m in ($Machine | Where-Object OperatingSystemType -eq 'Linux'))
    {
        if ($Lab.AzureSettings.IsAzureStack)
        {
            Write-ScreenInfo -Type Warning -Message 'Linux VMs not yet implemented on Azure Stack, sorry.'
            continue
        }

        $initScriptFileLinux = New-Item -ItemType File -Path (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "$($Lab.Name)$($m.Name)vminitlinux.bash") -Force
        $initScriptLinux | Set-Content -Path $initScriptFileLinux -Force
        $initScriptFileLinux

        $null = $jobs.Add((Invoke-AzVMRunCommand -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -VMName $m.ResourceName -ScriptPath $initScriptFileLinux.FullName -CommandId 'RunShellScript' -ErrorAction Stop -AsJob))
    }

    if ($jobs)
    {
        Wait-LWLabJob -Job $jobs -ProgressIndicator 5 -Timeout 30 -NoDisplay
    }

    $initScriptFile | Remove-Item -ErrorAction SilentlyContinue
    $linuxInitFiles | Copy-Item -Destination $Lab.LabPath
    $linuxInitFiles | Remove-Item -ErrorAction SilentlyContinue

    # And once again for all the VMs that for some unknown reason did not *really* execute the RunCommand
    if (Get-Command ssh -ErrorAction SilentlyContinue)
    {
        Install-LabSshKnownHost
        foreach ($m in ($Machine | Where-Object {$_.OperatingSystemType -eq 'Linux' -and $_.SshPrivateKeyPath}))
        {
            $ci = $m.AzureConnectionInfo
            $null = ssh -p $ci.SshPort "automatedlab@$($ci.DnsName)" -i $m.SshPrivateKeyPath $initScriptLinux 2>$null
        }
    }

    # Wait for VM extensions to be "done"
    if ($lab.AzureSettings.IsAzureStack)
    {
        $extensionStatuus = Get-LabVm -IncludeLinux | Foreach-Object { Get-AzVMCustomScriptExtension -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -VMName $_.ResourceName -Name initcustomizations -ErrorAction SilentlyContinue }
        $start = Get-Date
        $timeout = New-TimeSpan -Minutes 5
        while (($extensionStatuus.ProvisioningState -contains 'Updating' -or $extensionStatuus.ProvisioningState -contains 'Creating') -and ((Get-Date) - $start) -lt $timeout)
        {
            Start-Sleep -Seconds 5
            $extensionStatuus = Get-LabVm -IncludeLinux | Foreach-Object { Get-AzVMCustomScriptExtension -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -VMName $_.ResourceName -Name initcustomizations -ErrorAction SilentlyContinue }
        }

        foreach ($network in $Lab.VirtualNetworks)
        {
            if ($network.DnsServers.Count -eq 0) { continue }
            $vnet = Get-AzVirtualNetwork -Name $network.ResourceName -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
            $vnet.dhcpOptions.dnsServers = [string[]]($network.DnsServers.AddressAsString)
            $null = $vnet | Set-AzVirtualNetwork
        }
    }

    Copy-LabFileItem -Path (Get-ChildItem -Path "$((Get-Module -Name AutomatedLabCore)[0].ModuleBase)\Tools\HyperV\*") -DestinationFolderPath /AL -ComputerName ($Machine | Where OperatingSystemType -eq 'Windows') -UseAzureLabSourcesOnAzureVm $false
    $sessions = if ($PSVersionTable.PSVersion -ge [System.Version]'7.0')
    {
        New-LabPSSession $Machine
    }
    else
    {
        Write-ScreenInfo -Type Warning -Message "Skipping copy of AutomatedLab.Common to Linux VMs as Windows PowerShell is used on the host and not PowerShell 7+."
        New-LabPSSession ($Machine | Where OperatingSystemType -eq 'Windows')
    }

    Send-ModuleToPSSession -Module (Get-Module -ListAvailable -Name AutomatedLab.Common | Select-Object -First 1) -Session $sessions -IncludeDependencies -Force
    Write-ScreenInfo -Message 'Finished' -TaskEnd

    Write-ScreenInfo -Message 'Stopping all new machines except domain controllers'
    $machinesToStop = $Machine | Where-Object { $_.Roles.Name -notcontains 'RootDC' -and $_.Roles.Name -notcontains 'FirstChildDC' -and $_.Roles.Name -notcontains 'DC' -and $_.IsDomainJoined }
    if ($machinesToStop)
    {
        Stop-LWAzureVM -ComputerName $machinesToStop -StayProvisioned $true
        Wait-LabVMShutdown -ComputerName $machinesToStop
    }

    if ($machinesToStop)
    {
        Write-ScreenInfo -Message "$($Machine.Count) new Azure machines were configured. Some machines were stopped as they are not to be domain controllers '$($machinesToStop -join ', ')'"
    }
    else
    {
        Write-ScreenInfo -Message "($($Machine.Count)) new Azure machines were configured"
    }

    Write-PSFMessage "Removing all sessions after VmInit"
    Remove-LabPSSession

    Write-LogFunctionExit
}
