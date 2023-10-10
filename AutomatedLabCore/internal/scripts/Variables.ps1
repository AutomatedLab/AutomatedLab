$adInstallRootDcScriptPre2012 = {
    param (
        [string]$DomainName,
        [string]$Password,
        [string]$ForestFunctionalLevel,
        [string]$DomainFunctionalLevel,
        [string]$NetBiosDomainName,
        [string]$DatabasePath,
        [string]$LogPath,
        [string]$SysvolPath,
        [string]$DsrmPassword
    )

    Start-Transcript -Path C:\DeployDebug\ALDCPromo.log

    $dcpromoAnswerFile = @"
      [DCInstall]
      ; New forest promotion
      ReplicaOrNewDomain=Domain
      NewDomain=Forest
      NewDomainDNSName=$DomainName
      ForestLevel=$($ForestFunctionalLevel)
      DomainNetbiosName=$($NetBiosDomainName)
      DomainLevel=$($DomainFunctionalLevel)
      InstallDNS=Yes
      ConfirmGc=Yes
      CreateDNSDelegation=No
      DatabasePath=$DatabasePath
      LogPath=$LogPath
      SYSVOLPath=$SysvolPath
      ; Set SafeModeAdminPassword to the correct value prior to using the unattend file
      SafeModeAdminPassword=$DsrmPassword
      ; Run-time flags (optional)
      ;RebootOnCompletion=No
"@

    $VerbosePreference = $using:VerbosePreference

    Write-Verbose -Message 'Installing AD-Domain-Services windows feature'
    Import-Module -Name ServerManager
    Add-WindowsFeature -Name DNS
    $result = Add-WindowsFeature -Name AD-Domain-Services
    if (-not $result.Success)
    {
        throw 'Could not install AD-Domain-Services windows feature'
    }
    else
    {
        Write-Verbose -Message 'AD-Domain-Services windows feature installed successfully'
    }

    ([WMIClass]'Win32_NetworkAdapterConfiguration').SetDNSSuffixSearchOrder($DomainName) | Out-Null

    $dcpromoAnswerFile | Out-File -FilePath C:\DcpromoAnswerFile.txt -Force

    dcpromo /unattend:'C:\DcpromoAnswerFile.txt'

    if ($LASTEXITCODE -ge 11)
    {
        throw 'Could not install new domain'
    }
    else
    {
        Write-Verbose -Message 'AD-Domain-Services windows feature installed successfully'
    }

    Set-ItemProperty -Path Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters -Name 'Repl Perform Initial Synchronizations' -Value 0 -Type DWord

    Write-Verbose -Message 'finished installing the Root Domain Controller'
}

$adInstallRootDcScript2012 = {
    param (
        [string]$DomainName,
        [string]$Password,
        [string]$ForestFunctionalLevel,
        [string]$DomainFunctionalLevel,
        [string]$NetBiosDomainName,
        [string]$DatabasePath,
        [string]$LogPath,
        [string]$SysvolPath,
        [string]$DsrmPassword
    )

    $VerbosePreference = $using:VerbosePreference

    Start-Transcript -Path C:\DeployDebug\ALDCPromo.log

    ([WMIClass]'Win32_NetworkAdapterConfiguration').SetDNSSuffixSearchOrder($DomainName) | Out-Null

    Write-Verbose -Message "Starting installation of Root Domain Controller on '$(HOSTNAME.EXE)'"

    Write-Verbose -Message 'Installing AD-Domain-Services windows feature'
    $result = Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
    if (-not $result.Success)
    {
        throw 'Could not install AD-Domain-Services windows feature'
    }
    else
    {
        Write-Verbose -Message 'AD-Domain-Services windows feature installed successfully'
    }

    $safeDsrmPassword = ConvertTo-SecureString -String $DsrmPassword -AsPlainText -Force

    Write-Verbose -Message "Creating a new forest named '$DomainName' on the machine '$(HOSTNAME.EXE)'"
    $result = Install-ADDSForest -DomainName $DomainName `
    -SafeModeAdministratorPassword $safeDsrmPassword `
    -InstallDNS `
    -DomainMode $DomainFunctionalLevel `
    -Force `
    -ForestMode $ForestFunctionalLevel `
    -DomainNetbiosName $NetBiosDomainName `
    -SysvolPath $SysvolPath `
    -DatabasePath $DatabasePath `
    -LogPath $LogPath

    if ($result.Status -eq 'Error')
    {
        throw 'Could not install new domain'
    }
    else
    {
        Write-Verbose -Message 'AD-Domain-Services windows feature installed successfully'
    }

    Set-ItemProperty -Path Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters -Name 'Repl Perform Initial Synchronizations' -Value 0 -Type DWord

    Write-Verbose -Message 'finished installing the Root Domain Controller'
}

$adInstallFirstChildDc2012 = {
    param (
        [string]$NewDomainName,
        [string]$ParentDomainName,
        [System.Management.Automation.PSCredential]$RootDomainCredential,
        [string]$DomainMode,
        [int]$Retries,
        [int]$SecondsBetweenRetries,
        [string]$SiteName = 'Default-First-Site-Name',
        [string]$NetBiosDomainName,
        [string]$DatabasePath,
        [string]$LogPath,
        [string]$SysvolPath,
        [string]$DsrmPassword
    )

    $VerbosePreference = $using:VerbosePreference

    Start-Transcript -Path C:\DeployDebug\ALDCPromo.log

    ([WMIClass]'Win32_NetworkAdapterConfiguration').SetDNSSuffixSearchOrder($DomainName) | Out-Null

    Write-Verbose -Message "Starting installation of First Child Domain Controller of domain '$NewDomainName' on '$(HOSTNAME.EXE)'"
    Write-Verbose -Message "NewDomainName is '$NewDomainName'"
    Write-Verbose -Message "ParentDomainName is '$ParentDomainName'"
    Write-Verbose -Message "RootCredential UserName is '$($RootDomainCredential.UserName)'"
    Write-Verbose -Message "RootCredential Password is '$($RootDomainCredential.GetNetworkCredential().Password)'"
    Write-Verbose -Message "DomainMode is '$DomainMode'"

    Write-Verbose -Message "Trying to reach domain $ParentDomainName"
    while (-not $result -and $count -lt 15)
    {
        $result = Test-Connection -ComputerName $ParentDomainName -Count 1 -Quiet

        if ($result)
        {
            Write-Verbose -Message "Domain $ParentDomainName was reachable ($count)"
        }
        else
        {
            Write-ScreenInfo "Domain $ParentDomainName was not reachable ($count)" -Type Warning
        }

        Start-Sleep -Seconds 1

        Clear-DnsClientCache

        $count++
    }
    if (-not $result)
    {
        Write-Error "The domain '$ParentDomainName' could not be contacted. Trying DC promotion anyway"
    }
    else
    {
        Write-Verbose -Message "The domain '$ParentDomainName' could be reached"
    }

    Write-Verbose -Message 'Installing AD-Domain-Services windows feature'
    $result = Install-Windowsfeature AD-Domain-Services, DNS -IncludeManagementTools
    if (-not $result.Success)
    {
        throw 'Could not install AD-Domain-Services windows feature'
    }
    else
    {
        Write-Verbose -Message 'AD-Domain-Services windows feature installed successfully'
    }

    $retriesDone = 0
    do
    {
        Write-Verbose "The first try to promote '$(HOSTNAME.EXE)' did not work. The error was '$($result.Message)'. Retrying after $SecondsBetweenRetries seconds. Retry count $retriesDone of $Retries." -Type Warning
        ipconfig.exe /flushdns | Out-Null

        try
        {
            #if there is a '.' inside the domain name, it is a new domain tree, otherwise a child domain
            if ($NewDomainName.Contains('.'))
            {
                if (-not $NetBiosDomainName)
                {
                    $NetBiosDomainName = $NewDomainName.Substring(0, $NewDomainName.IndexOf('.'))
                }
                $domainType = 'TreeDomain'
                $createDNSDelegation = $false
            }
            else
            {
                if (-not $NetBiosDomainName)
                {
                    $newDomainNetBiosName = $NewDomainName.ToUpper()
                }
                $domainType = 'ChildDomain'
                $createDNSDelegation = $true
            }

            Start-Sleep -Seconds $SecondsBetweenRetries

            $safeDsrmPassword = ConvertTo-SecureString -String $DsrmPassword -AsPlainText -Force

            $result = Install-ADDSDomain -NewDomainName $NewDomainName `
            -NewDomainNetbiosName $NetBiosDomainName `
            -ParentDomainName $ParentDomainName `
            -SiteName $SiteName `
            -InstallDNS `
            -CreateDnsDelegation:$createDNSDelegation `
            -SafeModeAdministratorPassword $safeDsrmPassword `
            -Force `
            -Credential $RootDomainCredential `
            -DomainType $domainType `
            -DomainMode $DomainMode `
            -SysvolPath $SysvolPath `
            -DatabasePath $DatabasePath `
            -LogPath $LogPath
        }
        catch
        {
            Start-Sleep -Seconds $SecondsBetweenRetries
        }

        $retriesDone++
    }
    until ($result.Status -ne 'Error' -or $retriesDone -ge $Retries)

    if ($result.Status -eq 'Error')
    {
        Write-Error "Could not install new domain '$NewDomainName' on computer '$(HOSTNAME.EXE)' in $Retries retries. Aborting the promotion of '$(HOSTNAME.EXE)'"
        return
    }
    else
    {
        Write-Verbose -Message "Active Directory installed successfully on computer '$(HOSTNAME.EXE)'"
    }

    Set-ItemProperty -Path Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters -Name 'Repl Perform Initial Synchronizations' -Value 0 -Type DWord

    Write-Verbose -Message 'Finished installing the first child Domain Controller'
}

$adInstallFirstChildDcPre2012 = {
    param (
        [string]$NewDomainName,
        [string]$ParentDomainName,
        [System.Management.Automation.PSCredential]$RootDomainCredential,
        [string]$DomainMode,
        [int]$Retries,
        [int]$SecondsBetweenRetries,
        [string]$SiteName = 'Default-First-Site-Name',
        [string]$NetBiosDomainName,
        [string]$DatabasePath,
        [string]$LogPath,
        [string]$SysvolPath,
        [string]$DsrmPassword
    )

    Start-Transcript -Path C:\DeployDebug\ALDCPromo.log

    Write-Verbose -Message 'Installing AD-Domain-Services windows feature'
    Import-Module -Name ServerManager
    Add-WindowsFeature -Name DNS
    $result = Add-WindowsFeature -Name AD-Domain-Services
    if (-not $result.Success)
    {
        throw 'Could not install AD-Domain-Services windows feature'
    }
    else
    {
        Write-Verbose -Message 'AD-Domain-Services windows feature installed successfully'
    }

    ([WMIClass]'Win32_NetworkAdapterConfiguration').SetDNSSuffixSearchOrder($ParentDomainName) | Out-Null

    Write-Verbose -Message "Starting installation of First Child Domain Controller of domain '$NewDomainName' on '$(HOSTNAME.EXE)'"
    Write-Verbose -Message "NewDomainName is '$NewDomainName'"
    Write-Verbose -Message "ParentDomainName is '$ParentDomainName'"
    Write-Verbose -Message "RootCredential UserName is '$($RootDomainCredential.UserName)'"
    Write-Verbose -Message "RootCredential Password is '$($RootDomainCredential.GetNetworkCredential().Password)'"
    Write-Verbose -Message "DomainMode is '$DomainMode'"

    Write-Verbose -Message "Starting installation of First Child Domain Controller of domain '$NewDomainName' on '$(HOSTNAME.EXE)'"

    Write-Verbose -Message "Trying to reach domain $ParentDomainName"
    while (-not $result -and $count -lt 15)
    {
        $result = Test-Connection -ComputerName $ParentDomainName -Count 1 -Quiet

        if ($result)
        {
            Write-Verbose -Message "Domain $ParentDomainName was reachable ($count)"
        }
        else
        {
            Write-ScreenInfo "Domain $ParentDomainName was not reachable ($count)" -Type Warning
        }

        Start-Sleep -Seconds 1

        ipconfig.exe /flushdns | Out-Null

        $count++
    }
    if (-not $result)
    {
        Write-Error "The domain $ParentDomainName could not be contacted. Trying the DCPromo anyway"
    }
    else
    {
        Write-Verbose -Message "The domain $ParentDomainName could be reached"
    }

    Write-Verbose -Message "Credentials prepared for user $logonName"

    $tempName = $NewDomainName #using seems not to work in a if statement
    if ($tempName.Contains('.'))
    {
        $domainType = 'Tree'
        if (-not $NetBiosDomainName)
        {
            $NetBiosDomainName = $NewDomainName.Substring(0, $NewDomainName.IndexOf('.')).ToUpper()
        }
    }
    else
    {
        $domainType = 'Child'
        if (-not $NetBiosDomainName)
        {
            $NetBiosDomainName = $NewDomainName.ToUpper()
        }
    }

    $dcpromoAnswerFile = @"
      [DCInstall]
      ; New child domain promotion
      ReplicaOrNewDomain=Domain
      NewDomain=$domainType
      ParentDomainDNSName=$($ParentDomainName)
      NewDomainDNSName=$($NetBiosDomainName)
      ChildName=$($NewDomainName)
      DomainNetbiosName=$($NetBiosDomainName)
      DomainLevel=$($DomainMode)
      SiteName=$($SiteName)
      InstallDNS=Yes
      ConfirmGc=Yes
      UserDomain=$($RootDomainCredential.UserName.Split('\')[0])
      UserName=$($RootDomainCredential.UserName.Split('\')[1])
      Password=$($RootDomainCredential.GetNetworkCredential().Password)
      DatabasePath=$DatabasePath
      LogPath=$LogPath
      SYSVOLPath=$SysvolPath
      ; Set SafeModeAdminPassword to the correct value prior to using the unattend file
      SafeModeAdminPassword=$DsrmPassword
      ; Run-time flags (optional)
      ; RebootOnCompletion=No
"@

    if ($domainType -eq 'Child')
    {
        $dcpromoAnswerFile += ("
                CreateDNSDelegation=Yes
                DNSDelegationUserName=$($RootDomainCredential.UserName)
        DNSDelegationPassword=$($RootDomainCredential.GetNetworkCredential().Password)")
    }
    else
    {
        $dcpromoAnswerFile += ('
        CreateDNSDelegation=No')
    }

    $dcpromoAnswerFile | Out-File -FilePath C:\DcpromoAnswerFile.txt -Force
    Copy-Item -Path C:\DcpromoAnswerFile.txt -Destination C:\DcpromoAnswerFileBackup.txt

    Write-Verbose -Message 'Installing AD-Domain-Services windows feature'
    Write-Verbose -Message "Promoting machine '$(HOSTNAME.EXE)' to domain $($NewDomainName)"
    dcpromo /unattend:'C:\DcpromoAnswerFile.txt'

    $retriesDone = 0
    while ($LASTEXITCODE -ge 11 -and $retriesDone -lt $Retries)
    {
        Write-ScreenInfo "Promoting the Domain Controller '$(HOSTNAME.EXE)' did not work. The error code was '$LASTEXITCODE'. Retrying after $SecondsBetweenRetries seconds. Retry count $retriesDone of $Retries." -Type Warning
        ipconfig.exe /flushdns | Out-Null

        Start-Sleep -Seconds $SecondsBetweenRetries

        Copy-Item -Path C:\DcpromoAnswerFileBackup.txt -Destination C:\DcpromoAnswerFile.txt
        dcpromo /unattend:'C:\DcpromoAnswerFile.txt'
        Write-Verbose -Message "Return code of DCPromo was '$LASTEXITCODE'"

        $retriesDone++
    }

    if ($LASTEXITCODE -ge 11)
    {
        Write-Error "Could not install new domain '$NewDomainName' on computer '$(HOSTNAME.EXE)' in $Retries retries. Aborting the promotion of '$(HOSTNAME.EXE)'"
        return
    }
    else
    {
        Write-Verbose -Message "AD-Domain-Services windows feature installed successfully on computer '$(HOSTNAME.EXE)'"
    }

    Set-ItemProperty -Path Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters `
    -Name 'Repl Perform Initial Synchronizations' -Value 0 -Type DWord -ErrorAction Stop

    Write-Verbose -Message 'finished installing the the first child Domain Controller'
}

$adInstallDc2012 = {
    param (
        [string]$DomainName,
        [System.Management.Automation.PSCredential]$RootDomainCredential,
        [bool]$IsReadOnly,
        [int]$Retries,
        [int]$SecondsBetweenRetries,
        [string]$SiteName = 'Default-First-Site-Name',
        [string]$DatabasePath,
        [string]$LogPath,
        [string]$SysvolPath,
        [string]$DsrmPassword
    )

    $VerbosePreference = $using:VerbosePreference

    Start-Transcript -Path C:\DeployDebug\ALDCPromo.log

    ([WMIClass]'Win32_NetworkAdapterConfiguration').SetDNSSuffixSearchOrder($DomainName) | Out-Null

    Write-Verbose -Message "Starting installation of an additional Domain Controller on '$(HOSTNAME.EXE)'"
    Write-Verbose -Message "DomainName is '$DomainName'"
    Write-Verbose -Message "RootCredential UserName is '$($RootDomainCredential.UserName)'"
    Write-Verbose -Message "RootCredential Password is '$($RootDomainCredential.GetNetworkCredential().Password)'"

    #The random delay is very important when promoting more than one Domain Controller.
    Start-Sleep -Seconds (Get-Random -Minimum 60 -Maximum 180)

    Write-Verbose -Message "Trying to reach domain $DomainName"
    $count = 0
    while (-not $result -and $count -lt 15)
    {
        Clear-DnsClientCache

        $result = Test-Connection -ComputerName $DomainName -Count 1 -Quiet

        if ($result)
        {
            Write-Verbose -Message "Domain $DomainName was reachable ($count)"
        }
        else
        {
            Write-ScreenInfo "Domain $DomainName was not reachable ($count)" -Type Warning
        }

        Start-Sleep -Seconds 1

        $count++
    }
    if (-not $result)
    {
        Write-Error "The domain '$DomainName' could not be contacted. Trying DC promotion anyway"
    }
    else
    {
        Write-Verbose -Message "The domain '$DomainName' could be reached"
    }

    Write-Verbose -Message 'Installing AD-Domain-Services windows feature'
    $result = Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
    if (-not $result.Success)
    {
        throw 'Could not install AD-Domain-Services windows feature'
    }
    else
    {
        Write-Verbose -Message 'AD-Domain-Services windows feature installed successfully'
    }

    $safeDsrmPassword = ConvertTo-SecureString -String $DsrmPassword -AsPlainText -Force

    Write-Verbose -Message "Promoting machine '$(HOSTNAME.EXE)' to domain '$DomainName'"

    #this is required for RODCs
    $expectedNetbionDomainName = ($DomainName -split '\.')[0]

    $param = @{
        DomainName = $DomainName
        SiteName = $SiteName
        SafeModeAdministratorPassword = $safeDsrmPassword
        Force = $true
        Credential = $RootDomainCredential
        SysvolPath = $SysvolPath
        DatabasePath = $DatabasePath
        LogPath = $LogPath
    }


    if ($IsReadOnly)
    {
        $param.Add('ReadOnlyReplica', $true)

        $param.Add('DenyPasswordReplicationAccountName',
            @('BUILTIN\Administrators',
                'BUILTIN\Server Operators',
                'BUILTIN\Backup Operators',
                'BUILTIN\Account Operators',
        "$expectedNetbionDomainName\Denied RODC Password Replication Group"))

        $param.Add('AllowPasswordReplicationAccountName', @("$expectedNetbionDomainName\Allowed RODC Password Replication Group"))
    }
    else
    {
        $param.Add('CreateDnsDelegation', $false)
    }

    try
    {
        $result = Install-ADDSDomainController @param
    }
    catch
    {
        Write-Error -Message 'Error occured in installation of Domain Controller. Error:'
        Write-Error -Message $_
    }

    Write-Verbose -Message 'First attempt of installation finished'
    $retriesDone = 0
    while ($result.Status -eq 'Error' -and $retriesDone -lt $Retries)
    {
        Write-ScreenInfo "The first try to promote '$(HOSTNAME.EXE)' did not work. The error was '$($result.Message)'. Retrying after $SecondsBetweenRetries seconds. Retry count $retriesDone of $Retries." -Type Warning
        ipconfig.exe /flushdns | Out-Null

        Start-Sleep -Seconds $SecondsBetweenRetries
        try
        {
            $result = Install-ADDSDomainController @param
        }
        catch { }

        $retriesDone++
    }

    if ($result.Status -eq 'Error')
    {
        Write-Error "The problem could not be solved in $Retries retries. Aborting the promotion of '$(HOSTNAME.EXE)'"
        return
    }

    Set-ItemProperty -Path Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters -Name 'Repl Perform Initial Synchronizations' -Value 0 -Type DWord

    Write-Verbose -Message 'finished installing the Root Domain Controller'
}

$adInstallDcPre2012 = {
    param (
        [string]$DomainName,
        [System.Management.Automation.PSCredential]$RootDomainCredential,
        [bool]$IsReadOnly,
        [int]$Retries,
        [int]$SecondsBetweenRetries,
        [string]$SiteName = 'Default-First-Site-Name',
        [string]$DatabasePath,
        [string]$LogPath,
        [string]$SysvolPath,
        [string]$DsrmPassword
    )

    $VerbosePreference = $using:VerbosePreference

    Start-Transcript -Path C:\DeployDebug\ALDCPromo.log

    Write-Verbose -Message 'Installing AD-Domain-Services windows feature'
    Import-Module -Name ServerManager
    Add-WindowsFeature -Name DNS
    $result = Add-WindowsFeature -Name AD-Domain-Services
    if (-not $result.Success)
    {
        throw 'Could not install AD-Domain-Services windows feature'
    }
    else
    {
        Write-Verbose -Message 'AD-Domain-Services windows feature installed successfully'
    }

    ([WMIClass]'Win32_NetworkAdapterConfiguration').SetDNSSuffixSearchOrder($DomainName) | Out-Null

    Write-Verbose -Message "Starting installation of an additional Domain Controller on '$(HOSTNAME.EXE)'"
    Write-Verbose -Message "DomainName is '$DomainName'"
    Write-Verbose -Message "RootCredential UserName is '$($RootDomainCredential.UserName)'"
    Write-Verbose -Message "RootCredential Password is '$($RootDomainCredential.GetNetworkCredential().Password)'"

    #$type is required for the pre-2012 installatioon
    if ($IsReadOnly)
    {
        $type = 'ReadOnlyReplica'
    }
    else
    {
        $type = 'Replica'
    }

    Start-Sleep -Seconds (Get-Random -Minimum 60 -Maximum 180)

    $dcpromoAnswerFile = @"
      [DCInstall]
      ; Read-Only Replica DC promotion
      ReplicaOrNewDomain=$type
      ReplicaDomainDNSName=$DomainName
      SiteName=$SiteName
      InstallDNS=Yes
      ConfirmGc=Yes
      UserDomain=$($RootDomainCredential.UserName.Split('\')[0])
      UserName=$($RootDomainCredential.UserName.Split('\')[1])
      Password=$($RootDomainCredential.GetNetworkCredential().Password)
      DatabasePath=$DatabasePath
      LogPath=$LogPath
      SYSVOLPath=$SysvolPath
      ; Set SafeModeAdminPassword to the correct value prior to using the unattend file
      SafeModeAdminPassword=$DsrmPassword
      ; RebootOnCompletion=No
"@

    if ($type -eq 'ReadOnlyReplica')
    {
        $dcpromoAnswerFile += ('
                PasswordReplicationDenied="BUILTIN\Administrators"
                PasswordReplicationDenied="BUILTIN\Server Operators"
                PasswordReplicationDenied="BUILTIN\Backup Operators"
                PasswordReplicationDenied="BUILTIN\Account Operators"
                PasswordReplicationDenied="{0}\Denied RODC Password Replication Group"
        PasswordReplicationAllowed="{0}\Allowed RODC Password Replication Group"' -f $DomainName)
    }
    else
    {
        $dcpromoAnswerFile += ('
        CreateDNSDelegation=No')
    }

    $dcpromoAnswerFile | Out-File -FilePath C:\DcpromoAnswerFile.txt -Force
    #The backup file is required to be able to start dcpromo a second time as the passwords are getting
    #removed by dcpromo
    Copy-Item -Path C:\DcpromoAnswerFile.txt -Destination C:\DcpromoAnswerFileBackup.txt

    #For debug
    Copy-Item -Path C:\DcpromoAnswerFile.txt -Destination C:\DeployDebug\DcpromoAnswerFile.txt

    Write-Verbose -Message "Starting installation of an additional Domain Controller on '$(HOSTNAME.EXE)'"

    Write-Verbose -Message "Trying to reach domain $DomainName"
    $count = 0
    while (-not $result -and $count -lt 15)
    {
        ipconfig.exe /flushdns | Out-Null

        $result = Test-Connection -ComputerName $DomainName -Count 1 -Quiet

        if ($result)
        {
            Write-Verbose -Message "Domain $DomainName was reachable ($count)"
        }
        else
        {
            Write-ScreenInfo "Domain $DomainName was not reachable ($count)" -Type Warning
        }

        Start-Sleep -Seconds 1

        $count++
    }
    if (-not $result)
    {
        Write-Error "The domain $DomainName could not be contacted. Trying the DCPromo anyway"
    }
    else
    {
        Write-Verbose -Message "The domain $DomainName could be reached"
    }

    Write-Verbose -Message 'Installing AD-Domain-Services windows feature'
    Write-Verbose -Message "Promoting machine '$(HOSTNAME.EXE)' to domain '$($DomainName)'"
    Copy-Item -Path C:\DcpromoAnswerFileBackup.txt -Destination C:\DcpromoAnswerFile.txt
    dcpromo /unattend:'C:\DcpromoAnswerFile.txt'
    Write-Verbose -Message "Return code of DCPromo was '$LASTEXITCODE'"

    $retriesDone = 0
    while ($LASTEXITCODE -ge 11 -and $retriesDone -lt $Retries)
    {
        Write-ScreenInfo "The first try to promote '$(HOSTNAME.EXE)' did not work. The error code was '$LASTEXITCODE'. Retrying after $SecondsBetweenRetries seconds. Retry count $retriesDone of $Retries." -Type Warning
        ipconfig.exe /flushdns | Out-Null

        Start-Sleep -Seconds $SecondsBetweenRetries

        Copy-Item -Path C:\DcpromoAnswerFileBackup.txt -Destination C:\DcpromoAnswerFile.txt
        dcpromo /unattend:'C:\DcpromoAnswerFile.txt'
        Write-Verbose -Message "Return code of DCPromo was '$LASTEXITCODE'"

        $retriesDone++
    }

    if ($LASTEXITCODE -ge 11)
    {
        Write-Error "The problem could not be solved in $Retries retries. Aborting the promotion of '$(HOSTNAME.EXE)'"
        return
    }
    else
    {
        Write-Verbose -Message 'finished installing the Domain Controller'

        Set-ItemProperty -Path Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters `
        -Name 'Repl Perform Initial Synchronizations' -Value 0 -Type DWord -ErrorAction Stop
    }
}

[hashtable]$configurationManagerContent = @{
    '[Identification]'           = @{
        Action = 'InstallPrimarySite'
    }          
    '[Options]'                  = @{
        ProductID                 = 'EVAL'
        SiteCode                  = 'AL1'
        SiteName                  = 'AutomatedLab-01'
        SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
        SDKServer                 = ''
        RoleCommunicationProtocol = 'HTTPorHTTPS'
        ClientsUsePKICertificate  = 0
        PrerequisiteComp          = 1
        PrerequisitePath          = 'C:\Install\CM-Prereqs'
        AdminConsole              = 1
        JoinCEIP                  = 0
    }
           
    '[SQLConfigOptions]'         = @{
        SQLServerName = ''
        DatabaseName  = ''
    }
           
    '[CloudConnectorOptions]'    = @{
        CloudConnector       = 1
        CloudConnectorServer = ''
        UseProxy             = 0
    }
           
    '[SystemCenterOptions]'      = @{}
           
    '[HierarchyExpansionOption]' = @{}
}

$configurationManagerAVExcludedPaths = @(
    'C:\Install'
    'C:\Install\ADK\adksetup.exe'
    'C:\Install\WinPE\adkwinpesetup.exe'
    'C:\InstallCM\SMSSETUP\BIN\X64\setup.exe'
    'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Binn\sqlservr.exe'
    'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer\bin\ReportingServicesService.exe'
    'C:\Program Files\Microsoft Configuration Manager'
    'C:\Program Files\Microsoft Configuration Manager\Inboxes'
    'C:\Program Files\Microsoft Configuration Manager\Logs'
    'C:\Program Files\Microsoft Configuration Manager\EasySetupPayload'
    'C:\Program Files\Microsoft Configuration Manager\MP\OUTBOXES'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Smsexec.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Sitecomp.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Smswriter.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Smssqlbkup.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Cmupdate.exe'
    'C:\Program Files\SMS_CCM'
    'C:\Program Files\SMS_CCM\Logs'
    'C:\Program Files\SMS_CCM\ServiceData'
    'C:\Program Files\SMS_CCM\PolReqStaging\POL00000.pol'
    'C:\Program Files\SMS_CCM\ccmexec.exe'
    'C:\Program Files\SMS_CCM\Ccmrepair.exe'
    'C:\Program Files\SMS_CCM\RemCtrl\CmRcService.exe'
    'C:\Windows\CCMSetup'
    'C:\Windows\CCMSetup\ccmsetup.exe'
    'C:\Windows\CCMCache'
)
$configurationManagerAVExcludedProcesses = @(
    'C:\Install\ADK\adksetup.exe'
    'C:\Install\WinPE\adkwinpesetup.exe'
    'C:\Install\CM\SMSSETUP\BIN\X64\setup.exe'
    'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Binn\sqlservr.exe'
    'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer\bin\ReportingServicesService.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Smsexec.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Sitecomp.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Smswriter.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Smssqlbkup.exe'
    'C:\Program Files\Microsoft Configuration Manager\bin\x64\Cmupdate.exe'
    'C:\Program Files\SMS_CCM\ccmexec.exe'
    'C:\Program Files\SMS_CCM\Ccmrepair.exe'
    'C:\Program Files\SMS_CCM\RemCtrl\CmRcService.exe'
    'C:\Windows\CCMSetup\ccmsetup.exe'
)

$iniContentServerScvmm = @{
    UserName                    = 'Administrator'
    CompanyName                 = 'AutomatedLab'
    ProgramFiles                = 'C:\Program Files\Microsoft System Center\Virtual Machine Manager {0}'
    CreateNewSqlDatabase        = '1'
    SqlInstanceName             = 'MSSQLSERVER'
    SqlDatabaseName             = 'VirtualManagerDB'
    RemoteDatabaseImpersonation = '0'
    SqlMachineName              = 'REPLACE'
    IndigoTcpPort               = '8100'
    IndigoHTTPSPort             = '8101'
    IndigoNETTCPPort            = '8102'
    IndigoHTTPPort              = '8103'
    WSManTcpPort                = '5985'
    BitsTcpPort                 = '443'
    CreateNewLibraryShare       = '1'
    LibraryShareName            = 'MSSCVMMLibrary'
    LibrarySharePath            = 'C:\ProgramData\Virtual Machine Manager Library Files'
    LibraryShareDescription     = 'Virtual Machine Manager Library Files'
    SQMOptIn                    = '0'
    MUOptIn                     = '0'
    VmmServiceLocalAccount      = '0'
    TopContainerName            = 'CN=VMMServer,DC=contoso,DC=com'
}
$iniContentConsoleScvmm = @{
    ProgramFiles  = 'C:\Program Files\Microsoft System Center\Virtual Machine Manager {0}'
    IndigoTcpPort = '8100'
    MUOptIn       = '0'
}

$setupCommandLineServerScvmm = '/server /i /f C:\Server.ini /VmmServiceDomain {0} /VmmServiceUserName {1} /VmmServiceUserPassword {2} /SqlDBAdminDomain {0} /SqlDBAdminName {1} /SqlDBAdminPassword {2} /IACCEPTSCEULA'
$spsetupConfigFileContent = '<Configuration>
    <Package Id="sts">
        <Setting Id="LAUNCHEDFROMSETUPSTS" Value="Yes"/>
    </Package>

    <Package Id="spswfe">
        <Setting Id="SETUPCALLED" Value="1"/>
    </Package>

    <Logging Type="verbose" Path="%temp%" Template="SharePoint Server Setup(*).log"/>
    <PIDKEY Value="{0}" />
    <Display Level="none" CompletionNotice="no" />
    <Setting Id="SERVERROLE" Value="APPLICATION"/>
    <Setting Id="USINGUIINSTALLMODE" Value="0"/>
    <Setting Id="SETUP_REBOOT" Value="Never" />
    <Setting Id="SETUPTYPE" Value="CLEAN_INSTALL"/>
</Configuration>'

$SharePoint2013InstallScript = {
    param
    (
        [string]
        $Mode = '/unattended'
    )
    $exitCode = (Start-Process -PassThru -Wait "C:\SPInstall\PrerequisiteInstaller.exe" -ArgumentList "$Mode /SQLNCli:C:\SPInstall\PrerequisiteInstallerFiles\sqlncli.msi `
               /IDFX:C:\SPInstall\PrerequisiteInstallerFiles\Windows6.1-KB974405-x64.msu  `
               /IDFX11:C:\SPInstall\PrerequisiteInstallerFiles\MicrosoftIdentityExtensions-64.msi `
               /Sync:C:\SPInstall\PrerequisiteInstallerFiles\Synchronization.msi  `
               /AppFabric:C:\SPInstall\PrerequisiteInstallerFiles\WindowsServerAppFabricSetup_x64.exe  `
               /KB2671763:C:\SPInstall\PrerequisiteInstallerFiles\AppFabric1.1-RTM-KB2671763-x64-ENU.exe  `
               /MSIPCClient:C:\SPInstall\PrerequisiteInstallerFiles\setup_msipc_x64.msi  `
               /WCFDataServices:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices.exe  `
               /WCFDataServices56:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices56.exe").ExitCode

    return @{
        ExitCode = $exitCode
        Hostname = $env:COMPUTERNAME
    }
}
$SharePoint2016InstallScript = {
    param
    (
        [string]
        $Mode = '/unattended'
    )
    $exitCode = (Start-Process -PassThru -Wait "C:\SPInstall\PrerequisiteInstaller.exe" -ArgumentList "$Mode /SQLNCli:C:\SPInstall\PrerequisiteInstallerFiles\sqlncli.msi `
    /IDFX11:C:\SPInstall\PrerequisiteInstallerFiles\MicrosoftIdentityExtensions-64.msi `
    /Sync:C:\SPInstall\PrerequisiteInstallerFiles\Synchronization.msi  `
    /AppFabric:C:\SPInstall\PrerequisiteInstallerFiles\WindowsServerAppFabricSetup_x64.exe  `
    /KB3092423:C:\SPInstall\PrerequisiteInstallerFiles\AppFabric-KB3092423-x64-ENU.exe  `
    /MSIPCClient:C:\SPInstall\PrerequisiteInstallerFiles\setup_msipc_x64.exe  `
    /WCFDataServices56:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices.exe  `
    /DotNetFx:C:\SPInstall\PrerequisiteInstallerFiles\NDP462-KB3151800-x86-x64-AllOS-ENU.exe  `
    /ODBC:C:\SPInstall\PrerequisiteInstallerFiles\msodbcsql.msi  `
    /MSVCRT11:C:\SPInstall\PrerequisiteInstallerFiles\vcredist_64_2012.exe  `
    /MSVCRT14:C:\SPInstall\PrerequisiteInstallerFiles\vcredist_64_2015.exe").ExitCode

    return @{
        ExitCode = $exitCode
        Hostname = $env:COMPUTERNAME
    }
}
$SharePoint2019InstallScript = {
    param
    (
        [string]
        $Mode = '/unattended'
    )
    $exitCode = (Start-Process -Wait -PassThru "C:\SPInstall\PrerequisiteInstaller.exe" -ArgumentList "$Mode /SQLNCli:C:\SPInstall\PrerequisiteInstallerFiles\sqlncli.msi `
    /IDFX11:C:\SPInstall\PrerequisiteInstallerFiles\MicrosoftIdentityExtensions-64.msi `
    /Sync:C:\SPInstall\PrerequisiteInstallerFiles\Synchronization.msi  `
    /AppFabric:C:\SPInstall\PrerequisiteInstallerFiles\WindowsServerAppFabricSetup_x64.exe  `
    /KB3092423:C:\SPInstall\PrerequisiteInstallerFiles\AppFabric-KB3092423-x64-ENU.exe  `
    /MSIPCClient:C:\SPInstall\PrerequisiteInstallerFiles\setup_msipc_x64.exe  `
    /WCFDataServices56:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices.exe  `
    /DotNet472:C:\SPInstall\PrerequisiteInstallerFiles\NDP472-KB4054530-x86-x64-AllOS-ENU.exe  `
    /MSVCRT11:C:\SPInstall\PrerequisiteInstallerFiles\vcredist_64_2012.exe  `
    /MSVCRT141:C:\SPInstall\PrerequisiteInstallerFiles\vcredist_64_2017.exe").ExitCode

    return @{
        ExitCode = $exitCode
        Hostname = $env:COMPUTERNAME
    }
}
$ExtendedKeyUsages = @{
    OldAuthorityKeyIdentifier = '.29.1'
    OldPrimaryKeyAttributes = '2.5.29.2'
    OldCertificatePolicies = '2.5.29.3'
    PrimaryKeyUsageRestriction = '2.5.29.4'
    SubjectDirectoryAttributes = '2.5.29.9'
    SubjectKeyIdentifier = '2.5.29.14'
    KeyUsage = '2.5.29.15'
    PrivateKeyUsagePeriod = '2.5.29.16'
    SubjectAlternativeName = '2.5.29.17'
    IssuerAlternativeName = '2.5.29.18'
    BasicConstraints = '2.5.29.19'
    CRLNumber = '2.5.29.20'
    Reasoncode = '2.5.29.21'
    HoldInstructionCode = '2.5.29.23'
    InvalidityDate = '2.5.29.24'
    DeltaCRLindicator = '2.5.29.27'
    IssuingDistributionPoint = '2.5.29.28'
    CertificateIssuer = '2.5.29.29'
    NameConstraints = '2.5.29.30'
    CRLDistributionPoints = '2.5.29.31'
    CertificatePolicies = '2.5.29.32'
    PolicyMappings = '2.5.29.33'
    AuthorityKeyIdentifier = '2.5.29.35'
    PolicyConstraints = '2.5.29.36'
    Extendedkeyusage = '2.5.29.37'
    FreshestCRL = '2.5.29.46'
    X509version3CertificateExtensionInhibitAny = '2.5.29.54'
}

$ApplicationPolicies = @{
    # Remote Desktop
    'Remote Desktop' = '1.3.6.1.4.1.311.54.1.2'
    # Windows Update
    'Windows Update' = '1.3.6.1.4.1.311.76.6.1'
    # Windows Third Party Applicaiton Component
    'Windows Third Party Application Component' = '1.3.6.1.4.1.311.10.3.25'
    # Windows TCB Component
    'Windows TCB Component' = '1.3.6.1.4.1.311.10.3.23'
    # Windows Store
    'Windows Store' = '1.3.6.1.4.1.311.76.3.1'
    # Windows Software Extension verification
    ' Windows Software Extension Verification' = '1.3.6.1.4.1.311.10.3.26'
    # Windows RT Verification
    'Windows RT Verification' = '1.3.6.1.4.1.311.10.3.21'
    # Windows Kits Component
    'Windows Kits Component' = '1.3.6.1.4.1.311.10.3.20'
    # ROOT_PROGRAM_NO_OCSP_FAILOVER_TO_CRL
    'No OCSP Failover to CRL' = '1.3.6.1.4.1.311.60.3.3'
    # ROOT_PROGRAM_AUTO_UPDATE_END_REVOCATION
    'Auto Update End Revocation' = '1.3.6.1.4.1.311.60.3.2'
    # ROOT_PROGRAM_AUTO_UPDATE_CA_REVOCATION
    'Auto Update CA Revocation' = '1.3.6.1.4.1.311.60.3.1'
    # Revoked List Signer
    'Revoked List Signer' = '1.3.6.1.4.1.311.10.3.19'
    # Protected Process Verification
    'Protected Process Verification' = '1.3.6.1.4.1.311.10.3.24'
    # Protected Process Light Verification
    'Protected Process Light Verification' = '1.3.6.1.4.1.311.10.3.22'
    # Platform Certificate
    'Platform Certificate' = '2.23.133.8.2'
    # Microsoft Publisher
    'Microsoft Publisher' = '1.3.6.1.4.1.311.76.8.1'
    # Kernel Mode Code Signing
    'Kernel Mode Code Signing' = '1.3.6.1.4.1.311.6.1.1'
    # HAL Extension
    'HAL Extension' = '1.3.6.1.4.1.311.61.5.1'
    # Endorsement Key Certificate
    'Endorsement Key Certificate' = '2.23.133.8.1'
    # Early Launch Antimalware Driver
    'Early Launch Antimalware Driver' = '1.3.6.1.4.1.311.61.4.1'
    # Dynamic Code Generator
    'Dynamic Code Generator' = '1.3.6.1.4.1.311.76.5.1'
    # Domain Name System (DNS) Server Trust
    'DNS Server Trust' = '1.3.6.1.4.1.311.64.1.1'
    # Document Encryption
    'Document Encryption' = '1.3.6.1.4.1.311.80.1'
    # Disallowed List
    'Disallowed List' = '1.3.6.1.4.1.10.3.30'
    # Attestation Identity Key Certificate
    # System Health Authentication
    'System Health Authentication' = '1.3.6.1.4.1.311.47.1.1'
    # Smartcard Logon
    'IdMsKpScLogon' = '1.3.6.1.4.1.311.20.2.2'
    # Certificate Request Agent
    'ENROLLMENT_AGENT' = '1.3.6.1.4.1.311.20.2.1'
    # CTL Usage
    'AUTO_ENROLL_CTL_USAGE' = '1.3.6.1.4.1.311.20.1'
    # Private Key Archival
    'KP_CA_EXCHANGE' = '1.3.6.1.4.1.311.21.5'
    # Key Recovery Agent
    'KP_KEY_RECOVERY_AGENT' = '1.3.6.1.4.1.311.21.6'
    # Secure Email
    'PKIX_KP_EMAIL_PROTECTION' = '1.3.6.1.5.5.7.3.4'
    # IP Security End System
    'PKIX_KP_IPSEC_END_SYSTEM' = '1.3.6.1.5.5.7.3.5'
    # IP Security Tunnel Termination
    'PKIX_KP_IPSEC_TUNNEL' = '1.3.6.1.5.5.7.3.6'
    # IP Security User
    'PKIX_KP_IPSEC_USER' = '1.3.6.1.5.5.7.3.7'
    # Time Stamping
    'PKIX_KP_TIMESTAMP_SIGNING' = '1.3.6.1.5.5.7.3.8'
    # OCSP Signing
    'KP_OCSP_SIGNING' = '1.3.6.1.5.5.7.3.9'
    # IP security IKE intermediate
    'IPSEC_KP_IKE_INTERMEDIATE' = '1.3.6.1.5.5.8.2.2'
    # Microsoft Trust List Signing
    'KP_CTL_USAGE_SIGNING' = '1.3.6.1.4.1.311.10.3.1'
    # Microsoft Time Stamping
    'KP_TIME_STAMP_SIGNING' = '1.3.6.1.4.1.311.10.3.2'
    # Windows Hardware Driver Verification
    'WHQL_CRYPTO' = '1.3.6.1.4.1.311.10.3.5'
    # Windows System Component Verification
    'NT5_CRYPTO' = '1.3.6.1.4.1.311.10.3.6'
    # OEM Windows System Component Verification
    'OEM_WHQL_CRYPTO' = '1.3.6.1.4.1.311.10.3.7'
    # Embedded Windows System Component Verification
    'EMBEDDED_NT_CRYPTO' = '1.3.6.1.4.1.311.10.3.8'
    # Root List Signer
    'ROOT_LIST_SIGNER' = '1.3.6.1.4.1.311.10.3.9'
    # Qualified Subordination
    'KP_QUALIFIED_SUBORDINATION' = '1.3.6.1.4.1.311.10.3.10'
    # Key Recovery
    'KP_KEY_RECOVERY' = '1.3.6.1.4.1.311.10.3.11'
    # Document Signing
    'KP_DOCUMENT_SIGNING' = '1.3.6.1.4.1.311.10.3.12'
    # Lifetime Signing
    'KP_LIFETIME_SIGNING' = '1.3.6.1.4.1.311.10.3.13'
    'DRM' = '1.3.6.1.4.1.311.10.5.1'
    'DRM_INDIVIDUALIZATION' = '1.3.6.1.4.1.311.10.5.2'
    # Key Pack Licenses
    'LICENSES' = '1.3.6.1.4.1.311.10.6.1'
    # License Server Verification
    'LICENSE_SERVER' = '1.3.6.1.4.1.311.10.6.2'
    'Server Authentication' = '1.3.6.1.5.5.7.3.1' #The certificate can be used for OCSP authentication.
    KP_IPSEC_USER = '1.3.6.1.5.5.7.3.7' #The certificate can be used for an IPSEC user.
    'Code Signing' = '1.3.6.1.5.5.7.3.3' #The certificate can be used for signing code.
    'Client Authentication' = '1.3.6.1.5.5.7.3.2' #The certificate can be used for authenticating a client.
    KP_EFS = '1.3.6.1.4.1.311.10.3.4' #The certificate can be used to encrypt files by using the Encrypting File System.
    EFS_RECOVERY = '1.3.6.1.4.1.311.10.3.4.1' #The certificate can be used for recovery of documents protected by using Encrypting File System (EFS).
    DS_EMAIL_REPLICATION = '1.3.6.1.4.1.311.21.19' #The certificate can be used for Directory Service email replication.
    ANY_APPLICATION_POLICY = '1.3.6.1.4.1.311.10.12.1' #The applications that can use the certificate are not restricted.
}
