#region DC Install Scripts
$adInstallRootDcScriptPre2012 = {
    param (
        [string]$DomainName,
        [string]$Password,
        [string]$ForestFunctionalLevel,
        [string]$DomainFunctionalLevel
    )

    Start-Transcript -Path C:\DeployDebug\ALDCPromo.log
    
    $dcpromoAnswerFile = @"
      [DCInstall]
      ; New forest promotion
      ReplicaOrNewDomain=Domain
      NewDomain=Forest
      NewDomainDNSName=$DomainName
      ForestLevel=$($ForestFunctionalLevel)
      ; DomainNetbiosName=
      DomainLevel=$($DomainFunctionalLevel)
      InstallDNS=Yes
      ConfirmGc=Yes
      CreateDNSDelegation=No
      DatabasePath="C:\Windows\NTDS"
      LogPath="C:\Windows\NTDS"
      SYSVOLPath="C:\Windows\SYSVOL"
      ; Set SafeModeAdminPassword to the correct value prior to using the unattend file
      SafeModeAdminPassword=$Password
      ; Run-time flags (optional)
      ;RebootOnCompletion=No
"@
    
    $VerbosePreference = $using:VerbosePreference
    
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
        [string]$DomainFunctionalLevel
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
    
    Write-Verbose -Message "Creating a new forest named '$DomainName' on the machine '$(HOSTNAME.EXE)'"
    $safeModePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $result = Install-ADDSForest -DomainName $DomainName `
    -SafeModeAdministratorPassword $safeModePassword `
    -InstallDNS `
    -DomainMode $DomainFunctionalLevel `
    -Force `
    -ForestMode $ForestFunctionalLevel

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
        [string]$SiteName = 'Default-First-Site-Name'
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
            Write-Warning "Domain $ParentDomainName was not reachable ($count)"
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
        Write-Warning "The first try to promote '$(HOSTNAME.EXE)' did not work. The error was '$($result.Message)'. Retrying after $SecondsBetweenRetries seconds. Retry count $retriesDone of $Retries."
        ipconfig.exe /flushdns | Out-Null
        
        try
        {
            #if there is a '.' inside the domain name, it is a new domain tree, otherwise a child domain
            if ($NewDomainName.Contains('.'))
            {
                $newDomainNetBiosName = $NewDomainName.Substring(0, $NewDomainName.IndexOf('.'))
                $domainType = 'TreeDomain'
                $createDNSDelegation = $false
            }
            else
            {
                $newDomainNetBiosName = $NewDomainName.ToUpper()
                $domainType = 'ChildDomain'
                $createDNSDelegation = $true
            }

            Start-Sleep -Seconds $SecondsBetweenRetries
            
            $result = Install-ADDSDomain -NewDomainName $NewDomainName `
            -NewDomainNetbiosName $newDomainNetbiosName `
            -ParentDomainName $ParentDomainName `
            -SiteName $SiteName `
            -InstallDNS `
            -CreateDnsDelegation:$createDNSDelegation `
            -SafeModeAdministratorPassword $RootDomainCredential.Password `
            -Force `
            -Credential $RootDomainCredential `
            -DomainType $domainType `
            -DomainMode $DomainMode
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
        [string]$SiteName = 'Default-First-Site-Name'
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
            Write-Warning "Domain $ParentDomainName was not reachable ($count)"
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
    }
    else
    {
        $domainType = 'Child'
    }
    
    $dcpromoAnswerFile = @"
      [DCInstall]
      ; New child domain promotion
      ReplicaOrNewDomain=Domain
      NewDomain=$domainType
      ParentDomainDNSName=$($ParentDomainName)
      NewDomainDNSName=$($NewDomainName)
      ChildName=$($NewDomainName)
      ; DomainNetbiosName=<name>
      DomainLevel=$($DomainMode)
      SiteName=$($SiteName)
      InstallDNS=Yes
      ConfirmGc=Yes
      UserDomain=$($RootDomainCredential.UserName.Split('\')[0])
      UserName=$($RootDomainCredential.UserName.Split('\')[1])
      Password=$($RootDomainCredential.GetNetworkCredential().Password)
      DatabasePath="C:\Windows\NTDS"
      LogPath="C:\Windows\NTDS"
      SYSVOLPath="C:\Windows\SYSVOL"
      ; Set SafeModeAdminPassword to the correct value prior to using the unattend file
      SafeModeAdminPassword=$($RootDomainCredential.GetNetworkCredential().Password)
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
        Write-Warning "Promoting the Domain Controller '$(HOSTNAME.EXE)' did not work. The error code was '$LASTEXITCODE'. Retrying after $SecondsBetweenRetries seconds. Retry count $retriesDone of $Retries."
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
        [string]$SiteName = 'Default-First-Site-Name'
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
            Write-Warning "Domain $DomainName was not reachable ($count)"
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
    Install-Windowsfeature AD-Domain-Services, DNS -IncludeManagementTools
    
    Write-Verbose -Message "Promoting machine '$(HOSTNAME.EXE)' to domain '$DomainName'"
    
    #this is required for RODCs
    $expectedNetbionDomainName = ($DomainName -split '\.')[0]
    
    $param = @{
        DomainName = $DomainName
        SiteName = $SiteName
        SafeModeAdministratorPassword = $RootDomainCredential.Password
        Force = $true
        Credential = $RootDomainCredential
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
        Write-Warning "The first try to promote '$(HOSTNAME.EXE)' did not work. The error was '$($result.Message)'. Retrying after $SecondsBetweenRetries seconds. Retry count $retriesDone of $Retries."
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
        [string]$SiteName = 'Default-First-Site-Name'
    )

    $VerbosePreference = $using:VerbosePreference

    Start-Transcript -Path C:\DeployDebug\ALDCPromo.log
    
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
      DatabasePath="C:\Windows\NTDS"
      LogPath="C:\Windows\NTDS"
      SYSVOLPath="C:\Windows\SYSVOL"
      ; Set SafeModeAdminPassword to the correct value prior to using the unattend file
      SafeModeAdminPassword=$($RootDomainCredential.GetNetworkCredential().Password)
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
            Write-Warning "Domain $DomainName was not reachable ($count)"
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
        Write-Warning "The first try to promote '$(HOSTNAME.EXE)' did not work. The error code was '$LASTEXITCODE'. Retrying after $SecondsBetweenRetries seconds. Retry count $retriesDone of $Retries."
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
#endregion DC Install Scripts

#region Install-LabRootDcs
function Install-LabRootDcs
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [int]$DcPromotionRestartTimeout = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_DcPromotionRestartAfterDcpromo,
        
        [int]$AdwsReadyTimeout = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_DcPromotionAdwsReady,
        
        [switch]$CreateCheckPoints
    )
    
    Write-LogFunctionEntry
    
    $lab = Get-Lab
    if (-not $lab.Machines)
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    $machines = Get-LabMachine -Role RootDC
    
    if (-not $machines)
    {
        Write-Warning -Message "There is no machine with the role 'RootDC'"
        Write-LogFunctionExit
        return
    }
    
    
    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline
    Start-LabVM -RoleName RootDC -Wait -DoNotUseCredSsp -ProgressIndicator 10 -PostDelaySeconds 5
    
    #Determine if any machines are already installed as Domain Controllers and exclude these
    $machinesAlreadyInstalled = foreach ($machine in $machines)
    {
        if (Test-LabADReady -ComputerName $machine)
        {
            $machine.Name
        }
    }
    
    $machines = $machines | Where-Object Name -notin $machinesAlreadyInstalled
    foreach ($m in $machinesAlreadyInstalled)
    {
        Write-ScreenInfo -Message "Machine '$m' is already a Domain Controller. Skipping this machine." -Type Warning
    }
    
    $jobs = @()
    if ($machines)
    {
        Invoke-LabCommand -ComputerName $machines -ActivityName "Create folder 'C:\DeployDebug' for debug info" -NoDisplay -ScriptBlock {
            New-Item -ItemType Directory -Path 'c:\DeployDebug' -ErrorAction SilentlyContinue | Out-Null

            $acl = Get-Acl -Path C:\DeployDebug
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule('Everyone', 'Read', 'ObjectInherit', 'None', 'Allow')
            $acl.AddAccessRule($rule)
            Set-Acl -Path C:\DeployDebug -AclObject $acl
        } -DoNotUseCredSsp
        
        foreach ($machine in $machines)
        {
            $rootDcRole = $machine.Roles | Where-Object Name -eq 'RootDC'
        
            $version = (New-Object -TypeName AutomatedLab.OperatingSystem -ArgumentList ($machine.OperatingSystem)).Version
            if ($version -le 6.1)
            {
                #Pre 2012
                $scriptblock = $adInstallRootDcScriptPre2012
                $forestFunctionalLevel = [int][AutomatedLab.ActiveDirectoryFunctionalLevel]$rootDcRole.Properties.ForestFunctionalLevel
                $domainFunctionalLevel = [int][AutomatedLab.ActiveDirectoryFunctionalLevel]$rootDcRole.Properties.DomainFunctionalLevel
            }
            else
            {
                $scriptblock = $adInstallRootDcScript2012
                $forestFunctionalLevel = $rootDcRole.Properties.ForestFunctionalLevel
                $domainFunctionalLevel = $rootDcRole.Properties.DomainFunctionalLevel
            }

            #only print out warnings if verbose logging is enabled
            $WarningPreference = $VerbosePreference
            
            $jobs += Invoke-LabCommand -ComputerName $machine.Name `
            -ActivityName "Install Root DC ($($machine.name))" `
            -AsJob `
            -UseLocalCredential `
            -DoNotUseCredSsp `
            -PassThru `
            -NoDisplay `
            -ScriptBlock $scriptblock `
            -ArgumentList $machine.DomainName, 
            $machine.InstallationUser.Password, 
            $forestFunctionalLevel, 
            $domainFunctionalLevel
        }
        
        
        Write-ScreenInfo -Message 'Waiting for Root Domain Controllers to complete installation of Active Directory and restart' -NoNewLine
        
        $machinesToStart = @()
        $machinesToStart += Get-LabMachine -Role FirstChildDC, DC
        #starting machines in a multi net environment may not work
        if (-not (Get-LabMachine -Role Routing))
        {
            $machinesToStart += Get-LabMachine | Where-Object { -not $_.IsDomainJoined }
        }

        Wait-LabVMRestart -ComputerName $machines.Name -StartMachinesWhileWaiting $machinesToStart -DoNotUseCredSsp -ProgressIndicator 30 -TimeoutInMinutes $DcPromotionRestartTimeout -ErrorAction Stop -MonitorJob $jobs
        
        Write-ScreenInfo -Message 'Root Domain Controllers have now restarted. Waiting for Active Directory to start up' -NoNewLine
        
        Wait-LabVM -ComputerName $machines -DoNotUseCredSsp -TimeoutInMinutes 30 -ProgressIndicator 30 -NoNewLine
        Wait-LabADReady -ComputerName $machines -TimeoutInMinutes $AdwsReadyTimeout -ErrorAction Stop -ProgressIndicator 30 -NoNewLine
        
        Invoke-LabCommand -ActivityName 'Configuring DNS Forwarders on Azure Root DCs' -ComputerName $machines -ScriptBlock {
            dnscmd /ResetForwarders 168.63.129.16
        } -DoNotUseCredSsp -NoDisplay
        
        #Create reverse lookup zone (forest scope)
        foreach ($network in ((Get-LabVirtualNetworkDefinition).AddressSpace.IpAddress.AddressAsString))
        {
            Invoke-LabCommand -ComputerName $machines[0] -ActivityName 'Create reverse lookup zone' -NoDisplay -ScriptBlock `
            {
                param
                (
                    [string]$ip
                )
                
                $zoneName = "$($ip.split('.')[2]).$($ip.split('.')[1]).$($ip.split('.')[0]).in-addr.arpa"
                dnscmd . /ZoneAdd "$zoneName" /DsPrimary /DP /forest
                dnscmd . /Config "$zoneName" /AllowUpdate 2
                ipconfig.exe -registerdns
            } -ArgumentList $network
        }
        

        #Make sure the specified installation user will be forest admin
        $cmd = {
            $PSDefaultParameterValues = @{
                '*-AD*:Server' = $env:COMPUTERNAME
            }
            
            $user = Get-ADUser -Identity ([System.Security.Principal.WindowsIdentity]::GetCurrent().User) -Server localhost
        
            Add-ADGroupMember -Identity 'Domain Admins' -Members $user -Server localhost
            Add-ADGroupMember -Identity 'Enterprise Admins' -Members $user -Server localhost
            Add-ADGroupMember -Identity 'Schema Admins' -Members $user -Server localhost
        }
        Invoke-LabCommand -ComputerName $machines -ActivityName 'Make installation user Domain Admin' -NoDisplay -ScriptBlock $cmd -ErrorAction SilentlyContinue
    
        #Non-domain-joined machine are not registered in DNS hence cannot be found from inside the lab.
        #creating an A record for each non-domain-joined machine in the first forst solves that.
        #Every non-domain-joined machine get the first forest's name as the primary DNS domain.
        $dnsCmd = Get-LabMachine -All | Where-Object { -not $_.IsDomainJoined -and $_.IpV4Address } | ForEach-Object {
            "dnscmd /recordadd $(@($rootDomains)[0]) $_ A $($_.IpV4Address)`n"
        }
        $dnsCmd += "Restart-Service -Name DNS -WarningAction SilentlyContinue`n"	
        Invoke-LabCommand -ComputerName $machines[0] -ActivityName 'Register non domain joined machines in DNS' -NoDisplay -ScriptBlock ([scriptblock]::Create($dnsCmd))

        Invoke-LabCommand -ComputerName $machines -ActivityName 'Add flat domain name DNS record to speed up start of gpsvc in 2016' -NoDisplay -ScriptBlock {
            $machine = $args[0] | Where-Object { $_.Name -eq $env:COMPUTERNAME }
            dnscmd localhost /recordadd $env:USERDNSDOMAIN $env:USERDOMAIN A $machine.IpV4Address
        } -ArgumentList $machines

        Restart-LabVM -ComputerName $machines -Wait
        Wait-LabADReady -ComputerName $machines
        
        Enable-LabVMRemoting -ComputerName $machines
        
        #Restart the Network Location Awareness service to ensure that Windows Firewall Profile is 'Domain'
        Restart-ServiceResilient -ComputerName $machines -ServiceName nlasvc -NoNewLine
        
        #DNS client configuration is change by DCpromo process. Change this back
        Reset-DNSConfiguration -ComputerName (Get-LabMachine -Role RootDC) -ProgressIndicator 30 -NoNewLine
        
        #Need to make sure that A records for domain is registered
        Write-Verbose -Message 'Restarting DNS and Netlogon service on Root Domain Controllers'
        $jobs = @()
        foreach ($dc in (@(Get-LabMachine -Role RootDC)))
        {
            $jobs += Sync-LabActiveDirectory -ComputerName $dc -ProgressIndicator 5 -AsJob -Passthru
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 5 -NoDisplay -NoNewLine
        Write-ProgressIndicatorEnd
        
        foreach ($machine in $machines)
        {
            $dcRole = $machine.Roles | Where-Object Name -like '*DC'
            
            if ($dcRole.Properties.SiteName)
            {
                New-LabADSite -ComputerName $machine -SiteName $dcRole.Properties.SiteName -SiteSubnet $dcRole.Properties.SiteSubnet
                Move-LabDomainController -ComputerName $machine -SiteName $dcRole.Properties.SiteName
            }
        }        
        
        
        if ($CreateCheckPoints)
        {
            foreach ($machine in ($machines | Where-Object HostType -eq 'HyperV'))
            {
                Checkpoint-LWVM -ComputerName $machine -SnapshotName 'Post DC Promotion'
            }
        }
    }
    else
    {
        Write-ScreenInfo -Message 'All Root Domain Controllers are already installed' -Type Warning -TaskEnd
        return
    }
    Get-PSSession | Where-Object State -ne Disconnected | Remove-PSSession
    
    Write-LogFunctionExit
}
#endregion Install-LabRootDcs

#region Install-LabFirstChildDcs
function Install-LabFirstChildDcs
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [int]$DcPromotionRestartTimeout = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_DcPromotionRestartAfterDcpromo,
        
        [int]$AdwsReadyTimeout = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_DcPromotionAdwsReady,
        
        [switch]$CreateCheckPoints
    )
    
    Write-LogFunctionEntry
    
    $lab = Get-Lab
    if (-not $lab.Machines)
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    $machines = $lab.Machines | Where-Object { $_.Roles.Name -contains 'FirstChildDC' }
    if (-not $machines)
    {
        Write-Warning -Message "There is no machine with the role 'FirstChildDC'"
        Write-LogFunctionExit
        return
    }
    
    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline
    Start-LabVM -RoleName FirstChildDC -Wait -DoNotUseCredSsp -ProgressIndicator 15 -PostDelaySeconds 5
    
    #Determine if any machines are already installed as Domain Controllers and exclude these
    $machinesAlreadyInstalled = foreach ($machine in $machines)
    {
        if (Test-LabADReady -ComputerName $machine)
        {
            $machine.Name
        }
    }
    
    $machines = $machines | Where-Object Name -notin $machinesAlreadyInstalled
    foreach ($m in $machinesAlreadyInstalled)
    {
        Write-ScreenInfo -Message "Machine '$m' is already a Domain Controller. Skipping this machine." -Type Warning
    }
    
    if ($machines)
    {
        Invoke-LabCommand -ComputerName $machines -ActivityName "Create folder 'C:\DeployDebug' for debug info" -NoDisplay -ScriptBlock {
            New-Item -ItemType Directory -Path 'c:\DeployDebug' -ErrorAction SilentlyContinue | Out-Null

            $acl = Get-Acl -Path C:\DeployDebug
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule('Everyone', 'Read', 'ObjectInherit', 'None', 'Allow')
            $acl.AddAccessRule($rule)
            Set-Acl -Path C:\DeployDebug -AclObject $acl
        } -DoNotUseCredSsp
        
        $jobs = @()
        foreach ($machine in $machines)
        {
            $dcRole = $machine.Roles | Where-Object Name -eq 'FirstChildDc'
            
            $parentDomainName = $dcRole.Properties['ParentDomain']
            $newDomainName = $dcRole.Properties['NewDomain']
            $domainFunctionalLevel = $dcRole.Properties['DomainFunctionalLevel']
            $parentDomain = $lab.Domains | Where-Object Name -eq $parentDomainName
            
            #get the root domain to build the root domain credentials
            if (-not $parentDomain)
            {
                throw "New domain '$newDomainName' could not be installed. The root domain ($parentDomainName) could not be found in the lab"
            }
            $rootCredential = $parentDomain.GetCredential()
            
            #if there is a '.' inside the domain name, it is a new domain tree, otherwise a child domain hence we need to
            #create a DNS zone for the child domain in the parent domain
            if ($NewDomainName.Contains('.'))
            {
                $parentDc = Get-LabMachine -Role RootDC, FirstChildDC | Where-Object DomainName -eq $ParentDomainName
                Write-Verbose -Message "Setting up a new domain tree hence creating a stub zone on Domain Controller '$($parentDc.Name)'"
                
                $cmd = "dnscmd . /zoneadd $NewDomainName /dsstub $((Get-LabMachine -Role RootDC,FirstChildDC,DC | Where-Object DomainName -eq $NewDomainName).IpV4Address -join ', ') /dp /forest"
                
                Invoke-LabCommand -ScriptBlock ([scriptblock]::Create($cmd)) -ComputerName $parentDc -NoDisplay -ActivityName 'Add DNS zones'
                Invoke-LabCommand -ScriptBlock {Restart-Service Dns} -ComputerName $parentDc -NoDisplay -ActivityName 'Restart DNS'
            }
            
            Write-Verbose -Message 'Invoking script block for DC installation and promotion'
            $version = (New-Object -TypeName AutomatedLab.OperatingSystem -ArgumentList ($machine.OperatingSystem)).Version
            if ($version -le 6.1)
            {
                $scriptBlock = $adInstallFirstChildDcPre2012
                $domainFunctionalLevel = [int][AutomatedLab.ActiveDirectoryFunctionalLevel]$domainFunctionalLevel
            }
            else
            {
                $scriptBlock = $adInstallFirstChildDc2012
            }			
            
            
            $siteName = 'Default-First-Site-Name'

            if ($dcRole.Properties.SiteName)
            {
                $siteName = $dcRole.Properties.SiteName
                New-LabADSite -ComputerName $machine -SiteName $siteName -SiteSubnet $dcRole.Properties.SiteSubnet
            }

            #only print out warnings if verbose logging is enabled
            $WarningPreference = $VerbosePreference

            $jobs += Invoke-LabCommand -ComputerName $machine.Name `
            -ActivityName "Install FirstChildDC ($($machine.Name))" `
            -AsJob `
            -PassThru `
            -UseLocalCredential `
            -NoDisplay `
            -ScriptBlock $scriptBlock `
            -ArgumentList $newDomainName,
            $parentDomainName,
            $rootCredential,
            $domainFunctionalLevel,
            7,
            120,
            $siteName
        }
        
        
        Write-ScreenInfo -Message 'Waiting for First Child Domain Controllers to complete installation of Active Directory and restart' -NoNewline
        
        $domains = @((Get-LabMachine -Role RootDC).DomainName)
        foreach ($domain in $domains)
        {
            if (Get-LabMachine -Role DC | Where-Object DomainName -eq $domain)
            {
                $domains = $domain | Where-Object { $_ -ne $domain }
            }
        }

        $machinesToStart = @()
        $machinesToStart += Get-LabMachine -Role DC
        #starting machines in a multi net environment may not work
        if (-not (Get-LabMachine -Role Routing))
        {
            $machinesToStart += Get-LabMachine | Where-Object { -not $_.IsDomainJoined }
            $machinesToStart += Get-LabMachine | Where-Object DomainName -in $domains
        }
        
        Wait-LabVMRestart -ComputerName $machines.name -StartMachinesWhileWaiting $machinesToStart -ProgressIndicator 45 -TimeoutInMinutes $DcPromotionRestartTimeout -ErrorAction Stop -MonitorJob $jobs
        
        Write-ScreenInfo -Message 'First Child Domain Controllers have now restarted. Waiting for Active Directory to start up' -NoNewLine
        
        #Wait a little to be able to connect in first attempt
        Wait-LWLabJob -Job (Start-Job -Name 'Delay waiting for machines to be reachable' -ScriptBlock {Start-Sleep -Seconds 60}) -ProgressIndicator 20 -NoDisplay -NoNewLine
        
        Wait-LabVM -ComputerName $machines -TimeoutInMinutes 30 -ProgressIndicator 20 -NoNewLine
        
        Wait-LabADReady -ComputerName $machines -TimeoutInMinutes $AdwsReadyTimeout -ErrorAction Stop -ProgressIndicator 20 -NoNewLine
        
        
        #Make sure the specified installation user will be domain admin
        $cmd = {
            $PSDefaultParameterValues = @{
                '*-AD*:Server' = $env:COMPUTERNAME
            }
            
            $user = Get-ADUser -Identity ([System.Security.Principal.WindowsIdentity]::GetCurrent().User)
            
            Add-ADGroupMember -Identity 'Domain Admins' -Members $user
        }
        Invoke-LabCommand -ComputerName $machines -ActivityName 'Make installation user Domain Admin' -NoDisplay -ScriptBlock $cmd -ErrorAction SilentlyContinue

        Invoke-LabCommand -ComputerName $machines -ActivityName 'Add flat domain name DNS record to speed up start of gpsvc in 2016' -NoDisplay -ScriptBlock {
            $machine = $args[0] | Where-Object { $_.Name -eq $env:COMPUTERNAME }
            dnscmd localhost /recordadd $env:USERDNSDOMAIN $env:USERDOMAIN A $machine.IpV4Address
        } -ArgumentList $machines

        Restart-LabVM -ComputerName $machines -Wait
        Wait-LabADReady -ComputerName $machines
        
        Enable-LabVMRemoting -ComputerName $machines
        
        #Restart the Network Location Awareness service to ensure that Windows Firewall Profile is 'Domain'
        Restart-ServiceResilient -ComputerName $machines -ServiceName nlasvc -NoNewLine
        
        #DNS client configuration is change by DCpromo process. Change this back
        Reset-DNSConfiguration -ComputerName (Get-LabMachine -Role FirstChildDC) -ProgressIndicator 20 -NoNewLine
        
        
        Write-Verbose -Message 'Restarting DNS and Netlogon services on Root and Child Domain Controllers and triggering replication'
        $jobs = @()
        foreach ($dc in (@(Get-LabMachine -Role RootDC)))
        {
            $jobs += Sync-LabActiveDirectory -ComputerName $dc -ProgressIndicator 20 -AsJob -Passthru
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -NoDisplay -NoNewLine
        $jobs = @()
        foreach ($dc in (@(Get-LabMachine -Role FirstChildDC)))
        {
            $jobs += Sync-LabActiveDirectory -ComputerName $dc -ProgressIndicator 20 -AsJob -Passthru
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -NoDisplay -NoNewLine
        Write-ProgressIndicatorEnd
        
        if ($CreateCheckPoints)
        {
            foreach ($machine in ($machines | Where-Object HostType -eq 'HyperV'))
            {
                Checkpoint-LWVM -ComputerName $machine -SnapshotName 'Post DC Promotion'
            }
        }
    }
    else
    {
        Write-ScreenInfo -Message 'All First Child Domain Controllers are already installed' -Type Warning -TaskEnd
        return
    }
    
    Get-PSSession | Where-Object State -ne Disconnected | Remove-PSSession
    
    Write-LogFunctionExit
}
#endregion Install-LabFirstChildDcs

#region Install-LabDcs
function Install-LabDcs
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [int]$DcPromotionRestartTimeout = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_DcPromotionRestartAfterDcpromo,
        
        [int]$AdwsReadyTimeout = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_DcPromotionAdwsReady,
        
        [switch]$CreateCheckPoints
    )
    
    Write-LogFunctionEntry
    
    $lab = Get-Lab
    if (-not $lab.Machines)
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    $machines = Get-LabMachine -Role DC
    
    if (-not $machines)
    {
        Write-Warning -Message "There is no machine with the role 'DC'"
        Write-LogFunctionExit
        return
    }
    
    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline
    Start-LabVM -RoleName DC -Wait -DoNotUseCredSsp -ProgressIndicator 15 -PostDelaySeconds 5

    #Determine if any machines are already installed as Domain Controllers and exclude these
    $machinesAlreadyInstalled = foreach ($machine in $machines)
    {
        if (Test-LabADReady -ComputerName $machine)
        {
            $machine.Name
        }
    }
    
    $machines = $machines | Where-Object Name -notin $machinesAlreadyInstalled
    foreach ($m in $machinesAlreadyInstalled)
    {
        Write-ScreenInfo -Message "Machine '$m' is already a Domain Controller. Skipping this machine." -Type Warning
    }
    
    if ($machines)
    {
        Invoke-LabCommand -ComputerName $machines -ActivityName "Create folder 'C:\DeployDebug' for debug info" -NoDisplay -ScriptBlock {
            New-Item -ItemType Directory -Path 'c:\DeployDebug' -ErrorAction SilentlyContinue | Out-Null

            $acl = Get-Acl -Path C:\DeployDebug
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule('Everyone', 'Read', 'ObjectInherit', 'None', 'Allow')
            $acl.AddAccessRule($rule)
            Set-Acl -Path C:\DeployDebug -AclObject $acl
        } -DoNotUseCredSsp
        
        $rootDcs = Get-LabMachine -Role RootDC
        $childDcs = Get-LabMachine -Role FirstChildDC
        
        $jobs = @()
        
        foreach ($machine in $machines)
        {
            $dcRole = $machine.Roles | Where-Object Name -like '*DC'
            
            $isReadOnly = $dcRole.Properties['IsReadOnly']
            if ($isReadOnly -eq 'true')
            {
                $isReadOnly = $true
            }
            else
            {
                $isReadOnly = $false
            }
            
            #get the root domain to build the root domain credentials
            $parentDc = Get-LabMachine -Role RootDC | Where-Object DomainName -eq $lab.GetParentDomain($machine.DomainName).Name
            $parentCredential = $parentDc.GetCredential((Get-Lab))
            
            Write-Verbose -Message 'Invoking script block for DC installation and promotion'
            $version = (New-Object -TypeName AutomatedLab.OperatingSystem -ArgumentList ($machine.OperatingSystem)).Version
            if ($version -le 6.1)
            {
                $scriptblock = $adInstallDcPre2012
            }
            else
            {
                $scriptblock = $adInstallDc2012
            }            
            
            
            $siteName = 'Default-First-Site-Name'

            if ($dcRole.Properties.SiteName)
            {
                $siteName = $dcRole.Properties.SiteName
                New-LabADSite -ComputerName $machine -SiteName $siteName -SiteSubnet $dcRole.Properties.SiteSubnet
            }
            
            #only print out warnings if verbose logging is enabled
            $WarningPreference = $VerbosePreference

            $jobs += Invoke-LabCommand -ComputerName $machine `
            -ActivityName "Install DC ($($machine.name))" `
            -AsJob `
            -PassThru `
            -UseLocalCredential `
            -NoDisplay `
            -ScriptBlock $scriptblock `
            -ArgumentList $machine.DomainName,
            $parentCredential,
            $isReadOnly,
            7,
            120,
            $siteName
        }
        
        Write-ScreenInfo -Message 'Waiting for additional Domain Controllers to complete installation of Active Directory and restart' -NoNewLine
        
        $domains = (Get-LabMachine -Role DC).DomainName

        $machinesToStart = @()
        #starting machines in a multi net environment may not work
        if (-not (Get-LabMachine -Role Routing))
        {
            $machinesToStart += Get-LabMachine | Where-Object { -not $_.IsDomainJoined }
            $machinesToStart += Get-LabMachine | Where-Object DomainName -notin $domains
        }

        Wait-LabVMRestart -ComputerName $machines -StartMachinesWhileWaiting $machinesToStart -TimeoutInMinutes $DcPromotionRestartTimeout -ErrorAction Stop -ProgressIndicator 60 -MonitorJob $jobs
        
        Write-ScreenInfo -Message 'Additional Domain Controllers have now restarted. Waiting for Active Directory to start up' -NoNewLine
        
        #Wait a little to be able to connect in first attempt
        Wait-LWLabJob -Job (Start-Job -Name 'Delay waiting for machines to be reachable' -ScriptBlock {Start-Sleep -Seconds 60}) -ProgressIndicator 20 -NoDisplay -NoNewLine
        
        Wait-LabVM -ComputerName $machines -TimeoutInMinutes 30 -ProgressIndicator 20 -NoNewLine
        
        Wait-LabADReady -ComputerName $machines -TimeoutInMinutes $AdwsReadyTimeout -ErrorAction Stop -ProgressIndicator 20 -NoNewLine
        
        #Restart the Network Location Awareness service to ensure that Windows Firewall Profile is 'Domain'
        Restart-ServiceResilient -ComputerName $machines -ServiceName nlasvc -NoNewLine
        
        Enable-LabVMRemoting -ComputerName $machines
        
        #DNS client configuration is change by DCpromo process. Change this back
        Reset-DNSConfiguration -ComputerName (Get-LabMachine -Role DC) -ProgressIndicator 20 -NoNewLine
        
        
        Write-Verbose -Message 'Restarting DNS and Netlogon services on all Domain Controllers and triggering replication'
        $jobs = @()
        foreach ($dc in (Get-LabMachine -Role RootDC))
        {
            $jobs += Sync-LabActiveDirectory -ComputerName $dc -ProgressIndicator 20 -AsJob -Passthru
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -NoDisplay -NoNewLine
        $jobs = @()
        foreach ($dc in (Get-LabMachine -Role FirstChildDC))
        {
            $jobs += Sync-LabActiveDirectory -ComputerName $dc -ProgressIndicator 20 -AsJob -Passthru
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -NoDisplay -NoNewLine
        $jobs = @()
        foreach ($dc in (Get-LabMachine -Role DC))
        {
            $jobs += Sync-LabActiveDirectory -ComputerName $dc -ProgressIndicator 20 -AsJob -Passthru
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -NoDisplay -NoNewLine
        Write-ProgressIndicatorEnd
        
        if ($CreateCheckPoints)
        {
            foreach ($machine in ($machines | Where-Object HostType -eq 'HyperV'))
            {
                Checkpoint-LWVM -ComputerName $machine -SnapshotName 'Post DC Promotion'
            }
        }
    }
    else
    {
        Write-ScreenInfo -Message 'All additional Domain Controllers are already installed' -Type Warning -TaskEnd
        return
    }
    
    Get-PSSession | Where-Object State -ne Disconnected | Remove-PSSession
    
    Write-LogFunctionExit
}
#endregion Install-LabDcs

#region Wait-LabADReady
function Wait-LabADReady
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        
        [int]$TimeoutInMinutes = 15,

        [int]$ProgressIndicator,

        [switch]$NoNewLine
    )
    
    Write-LogFunctionEntry
    
    $start = Get-Date
    
    $machines = Get-LabMachine -ComputerName $ComputerName
    $machines | Add-Member -Name AdRetries -MemberType NoteProperty -Value 2 -Force
    
    $ProgressIndicatorTimer = (Get-Date)
    do
    {
        foreach ($machine in $machines)
        {
            if ($machine.AdRetries)
            {
                $adReady = Test-LabADReady -ComputerName $machine
                
                if ($DebugPreference)
                {
                    Write-Debug -Message "Return '$adReady' from '$($machine)'"
                }
                
                if ($adReady)
                {
                    $machine.AdRetries--
                }
            }
            
            if (-not $machine.AdRetries)
            {
                Write-Verbose -Message "Active Directory is now ready on Domain Controller '$machine'"
            }
            else
            {
                Write-Debug "Active Directory is NOT ready yet on Domain Controller: '$machine'"
            }
        }
        
        if (((Get-Date) - $ProgressIndicatorTimer).TotalSeconds -ge $ProgressIndicator)
        {
            if ($ProgressIndicator)
            {
                Write-ProgressIndicator
            }
            $ProgressIndicatorTimer = (Get-Date)
        }
        
        if ($DebugPreference)
        {
            $machines | ForEach-Object {
                Write-Debug -Message "$($_.Name.PadRight(18)) $($_.AdRetries)"
            }
        }
        
        if ($machines | Where-Object { $_.AdRetries })
        {
            Start-Sleep -Seconds 3
        }
    }
    until (($machines.AdRetries | Measure-Object -Maximum).Maximum -le 0 -or (Get-Date).AddMinutes(-$TimeoutInMinutes) -gt $start)
    
    if ($ProgressIndicator -and -not $NoNewLine)
    {
        Write-ProgressIndicatorEnd
    }
    
    if (($machines.AdRetries | Measure-Object -Maximum).Maximum -le 0)
    {
        Write-Verbose -Message 'Domain Controllers specified are now ready:'
        Write-Verbose -Message ($machines.Name -join ', ')
    }
    else
    {
        $machines | Where-Object { $_.AdRetries -gt 0 } | ForEach-Object {
            Write-Error -Message "Timeout occured waiting for Active Directory to be ready on Domain Controller: $_. Retry count is $($_.AdRetries)" -TargetObject $_
        }
    }
    
    Write-LogFunctionExit
}
#endregion Wait-LabADReady

#region Test-LabADReady
function Test-LabADReady
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName
    )
    
    Write-LogFunctionEntry
    
    $machine = Get-LabMachine -ComputerName $ComputerName
    if (-not $machine)
    {
        Write-Error "The machine '$ComputerName' could not be found in the lab"
        return
    }
    
    $adReady = Invoke-LabCommand -ComputerName $machine -ActivityName GetAdwsServiceStatus -ScriptBlock {
     
        if ((Get-Service -Name ADWS).Status -eq 'Running')
        {
            try
            {
                $env:ADPS_LoadDefaultDrive = 0
                $WarningPreference = 'SilentlyContinue'
                Import-Module -Name ActiveDirectory -ErrorAction Stop
                [bool](Get-ADDomainController -Server $env:COMPUTERNAME -ErrorAction SilentlyContinue)
            }
            catch
            {
                $false
            }
        }
        
    } -DoNotUseCredSsp -PassThru -NoDisplay  -ErrorAction SilentlyContinue
    
    [bool]$adReady
    
    Write-LogFunctionExit
}
#endregion Test-LabADReady

#region Reset-DNSConfiguration
function Reset-DNSConfiguration
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param
    (
        [string[]]$ComputerName,

        [int]$ProgressIndicator,

        [switch]$NoNewLine
    )

    Write-LogFunctionEntry
    
    $machines = Get-LabMachine -ComputerName $ComputerName

    $jobs = @()
    foreach ($machine in $machines)
    {
        $jobs += Invoke-LabCommand -ComputerName $machine -ActivityName 'Reset DNS client configuration to match specified DNS configuration' -ScriptBlock `
        {
            param
            (
                $DnsServers
            )
            $AdapterNames = (Get-WmiObject -Namespace Root\CIMv2 -Class Win32_NetworkAdapter | Where-Object {$_.PhysicalAdapter}).NetConnectionID
            foreach ($AdapterName in $AdapterNames)
            {
                netsh.exe interface ipv4 set dnsservers "$AdapterName" static $DnsServers primary
                
                "netsh interface ipv6 delete dnsservers '$AdapterName' all"
                netsh.exe interface ipv6 delete dnsservers "$AdapterName" all
            } 
        } -AsJob -PassThru -NoDisplay -ArgumentList $machine.DNSServers
    }
    
    Wait-LWLabJob -Job $jobs -NoDisplay -Timeout 30 -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine

    Write-LogFunctionExit
}
#endregion Reset-DNSConfiguration

#region Sync-LabActiveDirectory
function Sync-LabActiveDirectory
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        
        [int]$ProgressIndicator,

        [switch]$AsJob,
        
        [switch]$Passthru
    )
    
    Write-LogFunctionEntry

    $machines = Get-LabMachine -ComputerName $ComputerName
    $lab = Get-Lab

    if (-not $machines)
    {
        Write-Error "The machine '$ComputerName' could not be found in the current lab"
        return
    }
    
    foreach ($machine in $machines)
    {
        if (-not $machine.DomainName)
        {
            Write-Verbose -Message 'The machine is not domain joined hence AD replication cannot be triggered'
            return
        }

        #region Force Replication Scriptblock
        $adForceReplication = {
            $VerbosePreference = $using:VerbosePreference
        
            ipconfig.exe -flushdns
        
            Write-Verbose -Message 'Getting list of DCs'
            $dcs = repadmin.exe /viewlist *
            Write-Verbose -Message "List: '$($dcs -join ', ')'"
            (Get-Date -Format 'yyyy-MM-dd hh:mm:ss') | Add-Content -Path c:\DeployDebug\DCList.log -Force
            $dcs | Add-Content -Path c:\DeployDebug\DCList.log

            foreach ($dc in $dcs)
            {
                if ($dc)
                {
                    $dcName = $dc.Split()[2]
                    Write-Verbose -Message "Executing 'repadmin.exe /SyncAll /Ae $dcname'"
                    $result = repadmin.exe /SyncAll /Ae $dcName
                    (Get-Date -Format 'yyyy-MM-dd hh:mm:ss') | Add-Content -Path "c:\DeployDebug\Syncs-$($dcName).log" -Force
                    $result | Add-Content -Path "c:\DeployDebug\Syncs-$($dcName).log"
                }
            }
            Write-Verbose -Message "Executing 'repadmin.exe /ReplSum'"
            $result = repadmin.exe /ReplSum
            $result | Add-Content -Path c:\DeployDebug\repadmin.exeResult.log
        
            Restart-Service -Name DNS -WarningAction SilentlyContinue
        
            ipconfig.exe /registerdns
        
            Write-Verbose -Message 'Getting list of DCs'
            $dcs = repadmin.exe /viewlist *
            Write-Verbose -Message "List: '$($dcs -join ', ')'"
            (Get-Date -Format 'yyyy-MM-dd hh:mm:ss') | Add-Content -Path c:\DeployDebug\DCList.log -Force
            $dcs | Add-Content -Path c:\DeployDebug\DCList.log
            foreach ($dc in $dcs)
            {
                if ($dc)
                {
                    $dcName = $dc.Split()[2]
                    Write-Verbose -Message "Executing 'repadmin.exe /SyncAll /Ae $dcname'"
                    $result = repadmin.exe /SyncAll /Ae $dcName
                    (Get-Date -Format 'yyyy-MM-dd hh:mm:ss') | Add-Content -Path "c:\DeployDebug\Syncs-$($dcName).log" -Force
                    $result | Add-Content -Path "c:\DeployDebug\Syncs-$($dcName).log"
                }
            }
            Write-Verbose -Message "Executing 'repadmin.exe /ReplSum'"
            $result = repadmin.exe /ReplSum
            $result | Add-Content -Path c:\DeployDebug\repadmin.exeResult.log
        
            ipconfig.exe /registerdns
        
            Restart-Service -Name DNS -WarningAction SilentlyContinue
        
            #for debugging
            #dnscmd /zoneexport $env:USERDNSDOMAIN "c:\DeployDebug\$($env:USERDNSDOMAIN).txt"
        }
        #endregion Force Replication Scriptblock
    
        Invoke-LabCommand -ActivityName "Performing ipconfig /registerdns on '$ComputerName'" `
        -ComputerName $ComputerName -ScriptBlock { ipconfig.exe /registerdns } -NoDisplay
    
        if ($AsJob)
        {
            $job = Invoke-LabCommand -ActivityName "Triggering replication on '$ComputerName'" -ComputerName $ComputerName -ScriptBlock $adForceReplication -AsJob -Passthru -NoDisplay 

            if ($PassThru)
            {
                $job
            }
        }
        else
        {
            $result = Invoke-LabCommand -ActivityName "Triggering replication on '$ComputerName'" -ComputerName $ComputerName -ScriptBlock $adForceReplication -Passthru -NoDisplay

            if ($PassThru)
            {
                $result
            }
        }
    }
    
    Write-LogFunctionExit
}
#endregion Sync-LabActiveDirectory

#region Add-LabDomainAdmin
function Add-LabDomainAdmin
{
    # .ExternalHelp AutomatedLab.Help.xml
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [System.Security.SecureString]$Password,

        [string]$ComputerName
    )

    $cmd = {
        param(
            [Parameter(Mandatory)]
            [string]$Name,

            [Parameter(Mandatory)]
            [System.Security.SecureString]$Password
        )

        $server = 'localhost'

        $user = New-ADUser -Name $Name -AccountPassword $Password -Enabled $true -PassThru

        Add-ADGroupMember -Identity 'Domain Admins' -Members $user -Server $server

        try
        {
            Add-ADGroupMember -Identity 'Enterprise Admins' -Members $user -Server $server
            Add-ADGroupMember -Identity 'Schema Admins' -Members $user -Server $server
        }
        catch
        {
            #if adding the groups failed, this is executed propably in a child domain
        }
    }

    Invoke-LabCommand -ComputerName $ComputerName -ActivityName AddDomainAdmin -ScriptBlock $cmd -ArgumentList $Name, $Password
}
#endregion Add-LabDomainAdmin

#region New-LabADSubnet
function New-LabADSubnet
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param(
        [switch]$PassThru
    )
  
    Write-LogFunctionEntry
  
    $createSubnetScript = {
        param(
            $NetworkInfo
        )
        
        $PSDefaultParameterValues = @{
            '*-AD*:Server' = $env:COMPUTERNAME
        }
    
        #$defaultSite = Get-ADReplicationSite -Identity Default-First-Site-Name -Server localhost
        $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext([System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Forest)
        $defaultSite = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::FindByName($ctx, 'Default-First-Site-Name') 
        $subnetName = "$($NetworkInfo.Network)/$($NetworkInfo.MaskLength)"
    
        try
        {
            $subnet = Get-ADReplicationSubnet -Identity $subnetName -Server localhost
        }
        catch { }
    
        if (-not $subnet)
        {
            #New-ADReplicationSubnet seems to have a bug and reports Access Denied.
            #New-ADReplicationSubnet -Name $subnetName -Site $defaultSite -PassThru -Server localhost
            $subnet = New-Object System.DirectoryServices.ActiveDirectory.ActiveDirectorySubnet($ctx, $subnetName)
            $subnet.Site = $defaultSite
            $subnet.Save()
        }
    }
  
    $machines = Get-LabMachine -Role RootDC, FirstChildDC
    $lab = Get-Lab
  
    foreach ($machine in $machines)
    {
        $ipAddress = ($machine.IpAddress -split '/')[0]
        $subnetMask = ($machine.IpAddress -split '/')[1] | ConvertTo-Mask
    
        $networkInfo = Get-NetworkSummary -IPAddress $ipAddress -SubnetMask $subnetMask
        Write-Verbose -Message "Creating subnet '$($networkInfo.Network)' with mask '$($networkInfo.MaskLength)' on machine '$($machine.Name)'"
    
        #if the machine is not a Root Domain Controller
        if (-not ($machine.Roles | Where-Object { $_.Name -eq 'RootDC'}))
        {
            $rootDc = $machines | Where-Object { $_.Roles.Name -eq 'RootDC' -and $_.DomainName -eq $lab.GetParentDomain($machine.DomainName) }
        }
        else
        {
            $rootDc = $machine
        }
    
        Invoke-LabCommand -ComputerName $rootDc -ActivityName 'Create AD SubNet' -NoDisplay `
        -ScriptBlock $createSubnetScript -AsJob -ArgumentList $networkInfo
    }
  
    Write-LogFunctionExit
}
#endregion New-LabADSubnet

#region function New-LabADSite
function New-LabADSite
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$ComputerName,
        
        [Parameter(Mandatory)]
        [string]$SiteName,
        
        [Parameter(Mandatory)]
        [string]$SiteSubnet
    )
    
    Write-LogFunctionEntry
    
    $machine = Get-LabMachine -ComputerName $ComputerName
    $dcRole = $machine.Roles | Where-Object Name -like '*DC'
    
    if (-not $dcRole)
    {
        Write-Verbose "No Domain Controller roles found on computer '$Computer'"
        return
    }
    
    $forest = $dcRole.Properties.ParentDomain
            
    Write-Verbose -Message "Try to find domain root machine for '$ComputerName'"
    $domainRootMachine = Get-LabMachine -Role RootDC | Where-Object DomainName -eq $machine.DomainName
    if (-not $domainRootMachine)
    {
        Write-Verbose -Message "No RootDC found in same domain as '$ComputerName'. Looking for FirstChildDC instead"

        $domainRootMachine = Get-LabMachine -role FirstChildDC | Where-Object DomainName -eq $machine.DomainName
    }

    #if no domain tree
    if (-not ($forest))
    {
        Write-Verbose -Message "Forest of Domain root machine '$domainRootMachine' not found"

        $domain = $machine.DomainName
        if ($domain.Split('.').Count -le 2)
        {
            $forest = $domain
            Write-Verbose -Message "Forest set to '$forest' based on domain name of '$ComputerName' only has 2 names"
        }
        else
        {
            $forest = $domain.Split('.', 2)[-1]
            Write-Verbose -Message "Forest set to '$forest' based on two last names of domain name '$domain' of '$ComputerName'"
        }
    }
    
    $rootDcForMachine = Get-LabMachine -Role RootDC | Where-Object DomainName -eq $forest
    if (-not $rootDcForMachine)
    {
        $rootDcForMachine = Get-LabMachine -Role FirstChildDC | Where-Object DomainName -eq $forest
        $dcRole = $rootDcForMachine.Roles | Where-Object Name -eq 'FirstChild'
        $forest = $dcRole.Properties.ParentDomain
    }
    
    
    $result = Invoke-LabCommand -ComputerName $rootDcForMachine -NoDisplay -PassThru -ScriptBlock `
    {
        param
        (
            $ComputerName, $SiteName, $SiteSubnet
        )
        
        $PSDefaultParameterValues = @{
            '*-AD*:Server' = $env:COMPUTERNAME
        }
        
        Write-Verbose -Message "For computer '$ComputerName', create AD site '$SiteName' in subnet '$SiteSubnet'"
        
        if (-not (Get-ADReplicationSite -Filter "Name -eq '$SiteName'"))
        {
            Write-Verbose -Message "SiteName '$SiteName' does not exist. Attempting to create it now"
            New-ADReplicationSite -Name $SiteName
        }
        else
        {
            Write-Verbose -Message "SiteName '$SiteName' already exists"
        }
        
        
        if (-not (Get-ADReplicationSubNet -Filter "Name -eq '$SiteSubnet'"))
        {
            Write-Verbose -Message "SiteSubnet does not exist. Attempting to create it now and associate it with site '$SiteName'"
            New-ADReplicationSubnet -Name $SiteSubnet -Site $SiteName -Location $SiteName
        }
        else
        {
            Write-Verbose -Message "SiteSubnet '$SiteSubnet' already exists"
        }

        
        $sites = (Get-AdReplicationSite -Filter 'Name -ne "Default-First-Name-Site"').Name
        foreach ($site in $sites)
        {
            $otherSites = $sites | Where-Object { $_ -ne $site }
            foreach ($otherSite in $otherSites)
            {
                if (-not (Get-ADReplicationSiteLink -Filter "(name -eq '[$site]-[$otherSite]')") -and -not 
                (Get-ADReplicationSiteLink -Filter "(name -eq '[$otherSite]-[$Site]')"))
                {
                    Write-Verbose -Message "Site link '[$site]-[$otherSite]' does not exist. Creating it now"
                    New-ADReplicationSiteLink -Name "[$site]-[$otherSite]" `
                    -SitesIncluded $site, $otherSite `
                    -Cost 100 `
                    -ReplicationFrequencyInMinutes 15 `
                    -InterSiteTransportProtocol IP `
                    -OtherAttributes @{ 'options' = 5 }
                }
            }
        }
    } -ArgumentList $ComputerName, $SiteName, $SiteSubnet
    
    
    Write-LogFunctionExit
}
#endregion function New-LabADSite

#region function Move-LabDomainController
function Move-LabDomainController
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$ComputerName,
        
        [Parameter(Mandatory)]
        [string]$SiteName
    )
    
    Write-LogFunctionEntry
    
    
    $dcRole = (Get-LabMachine -ComputerName $ComputerName).Roles | Where-Object Name -like '*DC'
    
    if (-not $dcRole)
    {
        Write-Verbose "No Domain Controller roles found on computer '$ComputerName'"
        return
    }
    
    $forest = $dcRole.Properties.ParentDomain
    $machine = Get-LabMachine -ComputerName $ComputerName
            
    Write-Verbose -Message "Try to find domain root machine for '$ComputerName'"
    $domainRootMachine = Get-LabMachine -Role RootDC | Where-Object DomainName -eq $machine.DomainName
    if (-not $domainRootMachine)
    {
        Write-Verbose -Message "No RootDC found in same domain as '$ComputerName'. Looking for FirstChildDC instead"

        $domainRootMachine = Get-LabMachine -Role FirstChildDC | Where-Object DomainName -eq $machine.DomainName
    }

    #if no domain tree
    if (-not $forest)
    {
        Write-Verbose -Message "Forest of Domain root machine '$domainRootMachine' not found"

        $domain = $machine.DomainName
        if ($domain.Split('.').Count -le 2)
        {
            $forest = $domain
            Write-Verbose -Message "Forest set to '$forest' based on domain name of '$ComputerName' only has 2 names"
        }
        else
        {
            $forest = $domain.Split('.', 2)[-1]
            Write-Verbose -Message "Forest set to '$forest' based on two last names of domain name '$domain' of '$ComputerName'"
        }
    }
    
    $rootDcForMachine = Get-LabMachine -Role RootDC | Where-Object DomainName -eq $forest
    if (-not $rootDcForMachine)
    {
        $rootDcForMachine = Get-LabMachine -Role FirstChildDC | Where-Object DomainName -eq $forest
        $dcRole = $rootDcForMachine.Roles | Where-Object Name -eq 'FirstChild'
        $forest = $dcRole.Properties.ParentDomain
    }
    
    
    $result = Invoke-LabCommand -ComputerName $rootDcForMachine -NoDisplay -PassThru -ScriptBlock `
    {
        param
        (
            $ComputerName, $SiteName
        )
        
        $searchBase = (Get-ADRootDSE).ConfigurationNamingContext
        
        Write-Verbose -Message "Moving computer '$ComputerName' to AD site '$SiteName'"
        $targetSite = Get-ADObject -Filter 'ObjectClass -eq "site" -and CN -eq $SiteName' -SearchBase $searchBase
        Write-Verbose -Message "Target site: '$targetSite'"
        $dc =  Get-ADObject -Filter "ObjectClass -eq 'server' -and Name -eq '$ComputerName'" -SearchBase $searchBase
        Write-Verbose -Message "DC distinguished name: '$dc'"
        Move-ADObject -Identity $dc -TargetPath "CN=Servers,$($TargetSite.DistinguishedName)"

    } -ArgumentList $ComputerName, $SiteName
    
    Write-LogFunctionExit
}
#endregion function Move-LabDomainController

#region Install-LabDnsForwarder
function Install-LabDnsForwarder
{
    # .ExternalHelp AutomatedLab.Help.xml
    $forestNames = (Get-LabMachine -Role RootDC).DomainName
    if (-not $forestNames)
    {
        Write-Error 'Could not get forest names from the lab'
        return
    }

    $forwarders = Get-FullMesh -List $forestNames

    foreach ($forwarder in $forwarders)
    {
        $targetMachine = Get-LabMachine -Role RootDC | Where-Object { $_.DomainName -eq $forwarder.Source }
        $masterServers = Get-LabMachine -Role DC,RootDC,FirstChildDC | Where-Object { $_.DomainName -eq $forwarder.Destination }
    
        $cmd = @"
            `$hostname = hostname.exe
            Write-Verbose "Creating a DNS forwarder on server '$hostname'. Forwarder name is '$($forwarder.Destination)' and target DNS server is '$($masterServers.IpV4Address)'..."
            #Add-DnsServerConditionalForwarderZone -ReplicationScope Forest -Name $($forwarder.Destination) -MasterServers $($masterServers.IpV4Address)
            dnscmd . /zoneadd $($forwarder.Destination) /forwarder $($masterServers.IpV4Address)
            Write-Verbose '...done'
"@

        Invoke-LabCommand -ComputerName $targetMachine -ScriptBlock ([scriptblock]::Create($cmd)) -NoDisplay
    }
    
    $azureRootDCs = Get-LabMachine -Role RootDC | Where-Object HostType -eq Azure
    if ($azureRootDCs)
    {
        Invoke-LabCommand -ActivityName 'Configuring DNS Forwarders on Azure Root DCs' -ComputerName $azureRootDCs -ScriptBlock {
            dnscmd /ResetForwarders 168.63.129.16
        }
    }
}
#region Install-LabDnsForwarder

#region Install-LabADDSTrust
function Install-LabADDSTrust
{
    # .ExternalHelp AutomatedLab.Help.xml
    $forestNames = (Get-LabMachine -Role RootDC).DomainName
    if (-not $forestNames)
    {
        Write-Error 'Could not get forest names from the lab'
        return
    }

    $forwarders = Get-FullMesh -List $forestNames

    foreach ($forwarder in $forwarders)
    {
        $targetMachine = Get-LabMachine -Role RootDC | Where-Object { $_.DomainName -eq $forwarder.Source }
        $masterServers = Get-LabMachine -Role DC,RootDC,FirstChildDC | Where-Object { $_.DomainName -eq $forwarder.Destination }
    
        $cmd = @"
            `$hostname = hostname.exe
            Write-Verbose "Creating a DNS forwarder on server '$hostname'. Forwarder name is '$($forwarder.Destination)' and target DNS server is '$($masterServers.IpV4Address)'..."
            #Add-DnsServerConditionalForwarderZone -ReplicationScope Forest -Name $($forwarder.Destination) -MasterServers $($masterServers.IpV4Address)
            dnscmd . /zoneadd $($forwarder.Destination) /forwarder $($masterServers.IpV4Address)
            Write-Verbose '...done'
"@

        Invoke-LabCommand -ComputerName $targetMachine -ScriptBlock ([scriptblock]::Create($cmd)) -NoDisplay
    }

    Get-LabMachine -Role RootDC | ForEach-Object {
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
                    $result = repadmin.exe /SyncAll /AeP $dcName
                }
            }        
            Write-Verbose '...done'
        }
    }

    $rootDcs = Get-LabMachine -Role RootDC
    $trustMesh = Get-FullMesh -List $forestNames -OneWay

    foreach ($rootDc in $rootDcs)
    {
        $trusts = $trustMesh | Where-Object { $_.Source -eq $rootDc.DomainName }

        Write-Verbose "Creating trusts on machine $($rootDc.Name)"
        foreach ($trust in $trusts)
        {
            $domainAdministrator = ((Get-Lab).Domains | Where-Object { $_.Name -eq ($rootDcs | Where-Object { $_.DomainName -eq $trust.Destination }).DomainName }).Administrator

            $cmd = @"
                `$thisForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

                `$otherForestCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext(
                    [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Forest,
                    '$($trust.Destination)',
                    '$($domainAdministrator.UserName)',
                    '$($domainAdministrator.Password)')
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
#region Install-LabADDSTrust