function Update-CMSite
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String]$CMSiteCode,

        [Parameter(Mandatory)]
        [String]$CMServerName
    )

    #region Initialise
    $CMServer = Get-LabVM -ComputerName $CMServerName
    $CMServerFqdn = $CMServer.FQDN

    Write-ScreenInfo -Message "Validating install" -TaskStart
    $cim = New-LabCimSession -ComputerName $CMServer
    $Query = "SELECT * FROM SMS_Site WHERE SiteCode='{0}'" -f $CMSiteCode
    $Namespace = "ROOT/SMS/site_{0}" -f $CMSiteCode

    try
    {
        $result = Get-CimInstance -Namespace $Namespace -Query $Query -ErrorAction "Stop" -CimSession $cim -ErrorVariable ReceiveJobErr
    }
    catch
    {
        $Message = "Failed to validate install, could not find site code '{0}' in SMS_Site class ({1})" -f $CMSiteCode, $ReceiveJobErr.ErrorRecord.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        return
    }
    #endregion

    #region Define enums
    enum SMS_CM_UpdatePackages_State
    {
        AvailableToDownload = 327682
        ReadyToInstall = 262146
        Downloading = 262145
        Installed = 196612
        Failed = 262143
    }
    #endregion

    #region Ensuring CONFIGURATION_MANAGER_UPDATE service is running
    Write-ScreenInfo -Message "Ensuring CONFIGURATION_MANAGER_UPDATE service is running" -TaskStart
    Invoke-LabCommand -ComputerName $CMServerName -ActivityName "Ensuring CONFIGURATION_MANAGER_UPDATE service is running" -ScriptBlock {
        $service = "CONFIGURATION_MANAGER_UPDATE"
        if ((Get-Service $service | Select-Object -ExpandProperty Status) -ne "Running")
        {
            Start-Service "CONFIGURATION_MANAGER_UPDATE" -ErrorAction "Stop"
        }
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Finding update for target version
    Write-ScreenInfo -Message "Waiting for updates to appear in console" -TaskStart
    $cim = New-LabCimSession -ComputerName $CMServerName
    $Query = "SELECT * FROM SMS_CM_UpdatePackages WHERE Impact = '31'"
    $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction SilentlyContinue -CimSession $cim | Sort-object -Property FullVersion -Descending
    $start = Get-Date
    while (-not $Update -and ((Get-Date) - $start) -lt '00:30:00')
    {
        $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction SilentlyContinue -CimSession $cim | Sort-object -Property FullVersion -Descending
    }

    # https://github.com/PowerShell/PowerShell/issues/9185
    $Update = $Update[0]
    
    # On some occasions, the update was already "ready to install"
    if ($Update.State -eq [SMS_CM_UpdatePackages_State]::ReadyToInstall)
    {
        $null = Invoke-CimMethod -InputObject $Update -MethodName "InitiateUpgrade" -Arguments @{PrereqFlag = 2 }
    }

    if ($Update.State -eq [SMS_CM_UpdatePackages_State]::AvailableToDownload)
    {
        $null = Invoke-CimMethod -InputObject $Update -MethodName "SetPackageToBeDownloaded"

        $Query = "SELECT * FROM SMS_CM_UpdatePackages WHERE PACKAGEGUID = '{0}'" -f $Update.PackageGuid
        $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction SilentlyContinue -CimSession $cim

        while ($Update.State -eq [SMS_CM_UpdatePackages_State]::Downloading)
        {
            Start-Sleep -Seconds 5
            $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction SilentlyContinue -CimSession $cim
        }

        $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction SilentlyContinue -CimSession $cim

        while (-not ($Update.State -eq [SMS_CM_UpdatePackages_State]::ReadyToInstall))
        {
            Start-Sleep -Seconds 5
            $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction SilentlyContinue -CimSession $cim
        }

        $null = Invoke-CimMethod -InputObject $Update -MethodName "InitiateUpgrade" -Arguments @{PrereqFlag = 2 }
    }

    # Wait for installation to finish
    $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction SilentlyContinue -CimSession $cim
    $start = Get-Date
    while ($Update.State -ne [SMS_CM_UpdatePackages_State]::Installed -and ((Get-Date) - $start) -lt '00:30:00')
    {
        Start-Sleep -Seconds 10
        $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction SilentlyContinue -CimSession $cim
    }

    #region Validate update
    Write-ScreenInfo -Message "Validating update" -TaskStart
    $cim = New-LabCimSession -ComputerName $CMServerName
    $Query = "SELECT * FROM SMS_CM_UpdatePackages WHERE PACKAGEGUID = '{0}'" -f $Update.PackageGuid
    $Update = Get-CimInstance -Namespace "ROOT/SMS/site_$CMSiteCode" -Query $Query -ErrorAction SilentlyContinue -CimSession $cim

    try
    {
        $InstalledSite = Get-CimInstance -Namespace "ROOT/SMS/site_$($CMSiteCode)" -ClassName "SMS_Site" -ErrorAction "Stop" -CimSession $cim
    }
    catch
    {
        Write-ScreenInfo -Message ("Could not query SMS_Site to validate update install ({0})" -f $_.ErrorRecord.Exception.Message) -TaskEnd -Type "Error"
        throw $_
    }
    if ($InstalledSite.Version -ne $Update.FullVersion)
    {
        $Message = "Update validation failed, installed version is '{0}' and the expected version is '{1}'. Try running Install-LabConfigurationManager a second time" -f $InstalledSite.Version, $Update.FullVersion
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Update console
    Write-ScreenInfo -Message "Updating console" -TaskStart
    $cmd = "/q TargetDir=`"C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole`" DefaultSiteServerName={0}" -f $CMServerFqdn
    $job = Install-LabSoftwarePackage -ComputerName $CMServerName -LocalPath "C:\Program Files\Microsoft Configuration Manager\tools\ConsoleSetup\ConsoleSetup.exe" -CommandLine $cmd
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
}
