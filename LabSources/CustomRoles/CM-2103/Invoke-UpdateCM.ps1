Param (

    [Parameter(Mandatory)]
    [String]$ComputerName,

    [Parameter(Mandatory)]
    [String]$CMSiteCode,

    [Parameter(Mandatory)]
    [String]$Version

)

#region Define functions
function Update-CMSite {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String]$CMSiteCode,

        [Parameter(Mandatory)]
        [String]$CMServerName,

        [Parameter(Mandatory)]
        [String]$Version
    )

    #region Initialise
    Import-Lab -Name $LabName -NoValidation -NoDisplay
    $CMServer = Get-LabVM -ComputerName $CMServerName
    $CMServerFqdn = $CMServer.FQDN

    $PSDefaultParameterValues = @{
        "Invoke-LabCommand:ComputerName"            = $CMServerName
        "Invoke-LabCommand:AsJob"                   = $true
        "Invoke-LabCommand:PassThru"                = $true
        "Invoke-LabCommand:NoDisplay"               = $true
        "Invoke-LabCommand:Retries"                 = 1
        "Install-LabSoftwarePackage:ComputerName"   = $CMServerName
        "Install-LabSoftwarePackage:AsJob"          = $true
        "Install-LabSoftwarePackage:PassThru"       = $true
        "Install-LabSoftwarePackage:NoDisplay"      = $true
        "Wait-LWLabJob:NoDisplay"                   = $true
    }
    #endregion

    #region Define enums
    enum SMS_CM_UpdatePackages_State {
        AvailableToDownload = 327682
        ReadyToInstall = 262146
        Downloading = 262145
        Installed = 196612
        Failed = 262143
    }
    #endregion

    #region Check $Version
    if ($Version -eq "2002") {
        Write-ScreenInfo -Message "Target verison is 2002, skipping updates"
        return
    }
    #endregion

    #region Restart computer
    Write-ScreenInfo -Message "Restarting server" -TaskStart
    Restart-LabVM -ComputerName $CMServerName -Wait -ErrorAction "Stop"
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Ensuring CONFIGURATION_MANAGER_UPDATE service is running
    Write-ScreenInfo -Message "Ensuring CONFIGURATION_MANAGER_UPDATE service is running" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Ensuring CONFIGURATION_MANAGER_UPDATE service is running" -ScriptBlock {
        $service = "CONFIGURATION_MANAGER_UPDATE"
        if ((Get-Service $service | Select-Object -ExpandProperty Status) -ne "Running") {
            Start-Service "CONFIGURATION_MANAGER_UPDATE" -ErrorAction "Stop"
        }
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Could not start CONFIGURATION_MANAGER_UPDATE service ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error" -TaskEnd
        throw $ReceiveJobErr
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Finding update for target version
    Write-ScreenInfo -Message "Waiting for updates to appear in console" -TaskStart
    $Update = New-LoopAction -LoopTimeout 30 -LoopTimeoutType "Minutes" -LoopDelay 60 -LoopDelayType "Seconds" -ExitCondition {
        $null -ne $Update
    } -IfTimeoutScript {
        # Writing dot because of -NoNewLine in Wait-LWLabJob
        Write-ScreenInfo -Message "."
        Write-ScreenInfo -Message "No updates available" -TaskEnd
        # Exit rather than throw, so we can resume with whatever else is in HostStart.ps1
        exit
    } -IfSucceedScript {
        return $Update
    } -ScriptBlock {
        $job = Invoke-LabCommand -ActivityName "Waiting for updates to appear in console" -Variable (Get-Variable -Name "CMSiteCode") -ScriptBlock {
            $Query = "SELECT * FROM SMS_CM_UpdatePackages WHERE Impact = '31'"
            Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction "Stop" | Sort-object -Property FullVersion -Descending
        }
        Wait-LWLabJob -Job $job -NoNewLine
        try {
            $Update = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch {
            Write-ScreenInfo -Message ("Could not query SMS_CM_UpdatePackages to find latest update ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
            throw $ReceiveJobErr
        }
    }
    
    if ($Version -eq "Latest") {
        # https://github.com/PowerShell/PowerShell/issues/9185
        $Update = $Update[0]
    }
    else {
        $Update = $Update | Where-Object { $_.Name -like "*$Version*" }
    }

    # Writing dot because of -NoNewLine in Wait-LWLabJob
    Write-ScreenInfo -Message "."
    Write-ScreenInfo -Message ("Found update: '{0}' {1} ({2})" -f $Update.Name, $Update.FullVersion, $Update.PackageGuid)
    $UpdatePackageGuid = $Update.PackageGuid
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Initiate download and wait for state to change to Downloading
    if ($Update.State -eq [SMS_CM_UpdatePackages_State]::AvailableToDownload) {

        Write-ScreenInfo -Message "Initiating download" -TaskStart
        if ($Update.State -eq [SMS_CM_UpdatePackages_State]::AvailableToDownload) {
            $job = Invoke-LabCommand -ActivityName "Initiating download" -Variable (Get-Variable -Name "Update") -ScriptBlock {
                Invoke-CimMethod -InputObject $Update -MethodName "SetPackageToBeDownloaded" -ErrorAction "Stop"
            }
            Wait-LWLabJob -Job $job
            try {
                $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
            }
            catch {
                Write-ScreenInfo -Message ("Failed to initiate download ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
                throw $ReceiveJobErr
            }
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd

        # If State doesn't change after 15 minutes, restart SMS_EXECUTIVE service and repeat this 3 times, otherwise quit.
        Write-ScreenInfo -Message "Verifying update download initiated OK" -TaskStart
        $Update = New-LoopAction -Iterations 3 -LoopDelay 1 -ExitCondition {
            [SMS_CM_UpdatePackages_State]::Downloading, [SMS_CM_UpdatePackages_State]::ReadyToInstall -contains $Update.State
        } -IfTimeoutScript {
            $Message = "Could not initiate download (timed out)"
            Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
            throw $Message
        } -IfSucceedScript {
            return $Update
        } -ScriptBlock {
            $Update = New-LoopAction -LoopTimeout 15 -LoopTimeoutType "Minutes" -LoopDelay 5 -LoopDelayType "Seconds" -ExitCondition {
                [SMS_CM_UpdatePackages_State]::Downloading, [SMS_CM_UpdatePackages_State]::ReadyToInstall -contains $Update.State
            } -IfSucceedScript {
                return $Update
            } -IfTimeoutScript {
                # Writing dot because of -NoNewLine in Wait-LWLabJob
                Write-ScreenInfo -Message "."
                Write-ScreenInfo -Message "Download did not start, restarting SMS_EXECUTIVE" -TaskStart -Type "Warning"
                try {
                    Restart-ServiceResilient -ComputerName $CMServerName -ServiceName "SMS_EXECUTIVE" -ErrorAction "Stop" -ErrorVariable "RestartServiceResilientErr"
                }
                catch {
                    $Message = "Could not restart SMS_EXECUTIVE ({0})" -f $RestartServiceResilientErr.ErrorRecord.Exception.Message
                    Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
                    throw $Message
                }
                Write-ScreenInfo -Message "Activity done" -TaskEnd
            } -ScriptBlock {
                $job = Invoke-LabCommand -ActivityName "Verifying update download initiated OK" -Variable (Get-Variable -Name "UpdatePackageGuid", "CMSiteCode") -ScriptBlock {
                    $Query = "SELECT * FROM SMS_CM_UPDATEPACKAGES WHERE PACKAGEGUID = '{0}'" -f $UpdatePackageGuid
                    Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction "Stop"
                }
                Wait-LWLabJob -Job $job -NoNewLine
                try {
                    $Update = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
                }
                catch {
                    Write-ScreenInfo -Message ("Failed to query SMS_CM_UpdatePackages after initiating download (2) ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
                    throw $ReceiveJobErr
                }
            }
        }
        # Writing dot because of -NoNewLine in Wait-LWLabJob
        Write-ScreenInfo -Message "."
        Write-ScreenInfo -Message "Activity done" -TaskEnd

    }
    #endregion
    
    #region Wait for update to finish download
    if ($Update.State -eq [SMS_CM_UpdatePackages_State]::Downloading) {

        Write-ScreenInfo -Message "Waiting for update to finish downloading" -TaskStart
        $Update = New-LoopAction -LoopTimeout 604800 -LoopTimeoutType "Seconds" -LoopDelay 15 -LoopDelayType "Seconds" -ExitCondition {
            $Update.State -eq [SMS_CM_UpdatePackages_State]::ReadyToInstall
        } -IfTimeoutScript {
            # Writing dot because of -NoNewLine in Wait-LWLabJob
            Write-ScreenInfo -Message "."
            $Message = "Download timed out"
            Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
            throw $Message
        } -IfSucceedScript {
            # Writing dot because of -NoNewLine in Wait-LWLabJob
            Write-ScreenInfo -Message "."
            return $Update
        } -ScriptBlock {
            $job = Invoke-LabCommand -ActivityName "Querying update download status" -Variable (Get-Variable -Name "Update", "CMSiteCode") -ScriptBlock {
                $Query = "SELECT * FROM SMS_CM_UPDATEPACKAGES WHERE PACKAGEGUID = '{0}'" -f $Update.PackageGuid
                Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction "Stop"
            }
            Wait-LWLabJob -Job $job -NoNewLine
            try {
                $Update = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
            }
            catch {
                Write-ScreenInfo -Message ("Failed to query SMS_CM_UpdatePackages waiting for download to complete ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
                throw $ReceiveJobErr
            }
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd

    }
    #endregion
    
    #region Initiate update install and wait for state to change to Installed
    if ($Update.State -eq [SMS_CM_UpdatePackages_State]::ReadyToInstall) {

        Write-ScreenInfo -Message "Waiting for SMS_SITE_COMPONENT_MANAGER to enter an idle state" -TaskStart
        $ServiceState = New-LoopAction -LoopTimeout 30 -LoopTimeoutType "Minutes" -LoopDelay 1 -LoopDelayType "Minutes" -ExitCondition {
            $sitecomplog -match '^Waiting for changes' -as [bool] -eq $true
        } -IfTimeoutScript {
            # Writing dot because of -NoNewLine in Wait-LWLabJob
            Write-ScreenInfo -Message "."
            $Message = "Timed out waiting for SMS_SITE_COMPONENT_MANAGER"
            Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
            throw $Message
        } -IfSucceedScript {
            # Writing dot because of -NoNewLine in Wait-LWLabJob
            Write-ScreenInfo -Message "."
            return $Update
        } -ScriptBlock {
            $job = Invoke-LabCommand -ActivityName "Reading sitecomp.log to determine SMS_SITE_COMPONENT_MANAGER state" -ScriptBlock {
                Get-Content -Path "C:\Program Files\Microsoft Configuration Manager\Logs\sitecomp.log" -Tail 2 -ErrorAction "Stop"
            }
            Wait-LWLabJob -Job $job -NoNewLine
            try {
                $sitecomplog = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
            }
            catch {
                Write-ScreenInfo -Message ("Failed to read sitecomp.log to ({0})" -f $ReceiveJobErr.ErrorRecord.ExceptionMessage) -TaskEnd -Type "Error"
                throw $ReceiveJobErr
            }
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd

        Write-ScreenInfo -Message "Initiating update" -TaskStart
        $job = Invoke-LabCommand -ActivityName "Initiating update" -Variable (Get-Variable -Name "Update") -ScriptBlock {
            Invoke-CimMethod -InputObject $Update -MethodName "InitiateUpgrade" -Arguments @{PrereqFlag = 2}
        }
        Wait-LWLabJob -Job $job
        try {
            $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
        }
        catch {
            Write-ScreenInfo -Message ("Could not initiate update ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
            throw $ReceiveJobErr
        }
        Write-ScreenInfo -Message "Activity done" -TaskEnd

        Write-ScreenInfo -Message "Waiting for update to finish installing" -TaskStart
        $Update = New-LoopAction -LoopTimeout 43200 -LoopTimeoutType "Seconds" -LoopDelay 5 -LoopDelayType "Seconds" -ExitCondition {
            $Update.State -eq [SMS_CM_UpdatePackages_State]::Installed
        } -IfTimeoutScript {
            # Writing dot because of -NoNewLine in Wait-LWLabJob
            Write-ScreenInfo -Message "."
            $Message = "Install timed out"
            Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
            throw $Message
        } -IfSucceedScript {
            return $Update
        } -ScriptBlock {
            # No error handling since WMI can become unavailabile with "generic error" exception multiple times throughout the update. Not ideal
            $job = Invoke-LabCommand -ComputerName $CMServerName -ActivityName "Querying update install state" -Variable (Get-Variable -Name "UpdatePackageGuid", "CMSiteCode") -ScriptBlock {
                $Query = "SELECT * FROM SMS_CM_UPDATEPACKAGES WHERE PACKAGEGUID = '{0}'" -f $UpdatePackageGuid
                Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction SilentlyContinue
            }
            Wait-LWLabJob -Job $job -NoNewLine
            $Update = $job | Receive-Job -ErrorAction SilentlyContinue
            if ($Update.State -eq [SMS_CM_UpdatePackages_State]::Failed) {
                Write-ScreenInfo -Message "."
                $Message = "Update failed, check CMUpdate.log"
                Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
                throw $Message
            }
        }
        # Writing dot because of -NoNewLine in Wait-LWLabJob
        Write-ScreenInfo -Message "."
        Write-ScreenInfo -Message "Activity done" -TaskEnd
        
    }
    #endregion

    #region Validate update
    Write-ScreenInfo -Message "Validating update" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Validating update" -Variable (Get-Variable -Name "CMSiteCode") -ScriptBlock {
        Get-CimInstance -Namespace "ROOT/SMS/site_$($CMSiteCode)" -ClassName "SMS_Site" -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try {
        $InstalledSite = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Could not query SMS_Site to validate update install ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
        throw $ReceiveJobErr
    }
    if ($InstalledSite.Version -ne $Update.FullVersion) {
        $Message = "Update validation failed, installed version is '{0}' and the expected version is '{1}'" -f $InstalledSite.Version, $Update.FullVersion
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Update console
    Write-ScreenInfo -Message "Updating console" -TaskStart
    $cmd = "/q TargetDir=`"C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole`" DefaultSiteServerName={0}" -f $CMServerFqdn
    $job = Install-LabSoftwarePackage -LocalPath "C:\Program Files\Microsoft Configuration Manager\tools\ConsoleSetup\ConsoleSetup.exe" -CommandLine $cmd -ExpectedReturnCodes 0 -ErrorAction "Stop" -ErrorVariable "InstallLabSoftwarePackageErr"
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Console update failed ({0}) " -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Warning"
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
}
#endregion

Write-ScreenInfo -Message "Starting site update process" -TaskStart
Update-CMSite -CMServerName $ComputerName -CMSiteCode $CMSiteCode -Version $Version
Write-ScreenInfo -Message "Finished site update process" -TaskEnd
