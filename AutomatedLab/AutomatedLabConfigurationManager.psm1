[hashtable]$configurationContent = @{
    '[Identification]'           = @{
        Action = 'InstallPrimarySite'
    }          
    '[Options]'                  = @{
        ProductID                 = ''
        SiteCode                  = ''
        SiteName                  = ''
        SMSInstallDir             = 'C:\Program Files\Microsoft Configuration Manager'
        SDKServer                 = ''
        RoleCommunicationProtocol = 'HTTPorHTTPS'
        ClientsUsePKICertificate  = 0
        PrerequisiteComp          = 1
        PrerequisitePath          = ''
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
        "ProxyName"          = $null
        "ProxyPort"          = $null
    }
           
    '[SystemCenterOptions]'      = @{}
           
    '[HierarchyExpansionOption]' = @{}
}

function Install-LabConfigurationManager
{
    [CmdletBinding()]
    param ()

    $vms = Get-LabVm -Role ConfigurationManager

    #region Prereq: ADK, CM binaries, stuff
    Write-ScreenInfo -Message "Installing Prerequisites on $($vms.Count) machines"
    $adkUrl = Get-LabConfigurationItem -Name WindowsAdk
    $adkPeUrl = Get-LabConfigurationItem -Name WindowsAdkPe
    $adkFile = Get-LabInternetFile -Uri $adkUrl -Path $labsources\SoftwarePackages -FileName adk.exe -PassThru -NoDisplay
    $adkpeFile = Get-LabInternetFile -Uri $adkPeUrl -Path $labsources\SoftwarePackages -FileName adkpe.exe -PassThru -NoDisplay
    
    if ($(Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        Install-LabSoftwarePackage -Path $adkFile.FullName -ComputerName $vms -CommandLine '/quiet /layout c:\ADKoffline' -NoDisplay
        Install-LabSoftwarePackage -Path $adkpeFile.FullName -ComputerName $vms -CommandLine '/quiet /layout c:\ADKPEoffline' -NoDisplay
    }
    else
    {
        Start-Process -FilePath $adkFile.FullName -ArgumentList "/quiet /layout $(Join-Path (Get-LabSourcesLocation -Local) Tools/ADKoffline)" -Wait -NoNewWindow
        Start-Process -FilePath $adkpeFile.FullName -ArgumentList " /quiet /layout $(Join-Path (Get-LabSourcesLocation -Local) Tools/ADKPEoffline)" -Wait -NoNewWindow
        Copy-LabFileItem -Path (Join-Path (Get-LabSourcesLocation -Local) Tools/ADKoffline) -ComputerName $vms
        Copy-LabFileItem -Path (Join-Path (Get-LabSourcesLocation -Local) Tools/ADKPEoffline) -ComputerName $vms
    }
    
    Install-LabSoftwarePackage -LocalPath C:\ADKOffline\adksetup.exe -ComputerName $vms -CommandLine '/norestart /q /ceip off /features OptionId.DeploymentTools OptionId.UserStateMigrationTool OptionId.ImagingAndConfigurationDesigner' -NoDisplay
    Install-LabSoftwarePackage -LocalPath C:\ADKPEOffline\adkwinpesetup.exe -ComputerName $vms -CommandLine '/norestart /q /ceip off /features OptionId.WindowsPreinstallationEnvironment' -NoDisplay

    $SQLNCLIMSIPath = Join-Path -Path $labSources -ChildPath "SoftwarePackages\sqlncli.msi"

    $ncliUrl = Get-LabConfigurationItem -Name SqlServerNativeClient2012
    try
    {
        $ncli = Get-LabInternetFile -Uri $ncliUrl -Path "$labSources/SoftwarePackages/sqlncli.msi" -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr" -PassThru
    }
    catch
    {
        $Message = "Failed to download SQL Native Client from '{0}' ({1})" -f $ncliUrl, $GetLabInternetFileErr.ErrorRecord.Exception.Message
        Write-LogFunctionExitWithError -Message $Message
    }

    Install-LabSoftwarePackage -Path $ncli.FullName -ComputerName $vms -CommandLine "/qn /norestart IAcceptSqlncliLicenseTerms=Yes" -ExpectedReturnCodes 0

    $WMIv2Zip = "{0}\WmiExplorer.zip" -f (Get-LabSourcesLocation -Local)
    $WMIv2Exe = "{0}\WmiExplorer.exe" -f (Get-LabSourcesLocation -Local)
    $wmiExpUrl = Get-LabConfigurationItem -Name ConfigurationManagerWmiExplorer

    try
    {
        Get-LabInternetFile -Uri $wmiExpUrl -Path (Split-Path -Path $WMIv2Zip -Parent) -FileName (Split-Path -Path $WMIv2Zip -Leaf) -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Could not download from '{0}' ({1})" -f $wmiExpUrl, $GetLabInternetFileErr.ErrorRecord.Exception.Message) -Type "Warning"
    }

    Expand-Archive -Path $WMIv2Zip -DestinationPath "$(Get-LabSourcesLocation -Local)/Tools" -ErrorAction "Stop"
    try
    {
        Remove-Item -Path $WMIv2Zip -Force -ErrorAction "Stop" -ErrorVariable "RemoveItemErr"
    }
    catch
    {
        Write-ScreenInfo -Message ("Failed to delete '{0}' ({1})" -f $WMIZip, $RemoveItemErr.ErrorRecord.Exception.Message) -Type "Warning"
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure') { Sync-LabAzureLabSources -Filter WmiExplorer.exe }

    # ConfigurationManager
    foreach ($vm in $vms)
    {
        $role = $vm.Roles.Where($_.Name -eq 'ConfigurationManager')
        $cmVersion = $role.Properties.Version
        $cmBranch = if ($role.Properties.ContainsKey('Branch')) { $role.Properties.Branch } else { 'CB' }

        $VMInstallDirectory = 'C:\Install'
        $CMBinariesDirectory = "$labSources\SoftwarePackages\CM-$($cmVersion)-$cmBranch"
        $CMPreReqsDirectory = "$labSources\SoftwarePackages\CM-Prereqs-$($cmVersion)-$cmBranch"
        $VMCMBinariesDirectory = "{0}\CM-{1}" -f $VMInstallDirectory, $cmBranch
        $VMCMPreReqsDirectory = "{0}\CM-PreReqs-{1}" -f $VMInstallDirectory, $cmBranch

        $cmDownloadUrl = Get-LabConfigurationItem -Name "ConfigurationManagerUrl$($cmVersion)$($cmBranch)"

        if (-not $cmDownloadUrl)
        {
            Write-LogFunctionExitWithError -Message "No URI configuration for CM version $cmVersion, branch $cmBranch."
        }

        #region CM binaries
        $CMZipPath = "{0}\SoftwarePackages\{1}" -f $labsources, ((Split-Path $CMDownloadURL -Leaf) -replace "\.exe$", ".zip")

        try
        {
            $CMZipObj = Get-LabInternetFile -Uri $CMDownloadURL -Path (Split-Path -Path $CMZipPath -Parent) -FileName (Split-Path -Path $CMZipPath -Leaf) -PassThru -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr"
        }
        catch
        {
            $Message = "Failed to download from '{0}' ({1})" -f $CMDownloadURL, $GetLabInternetFileErr.ErrorRecord.Exception.Message
            Write-LogFunctionExitWithError -Message $Message
        }
        #endregion

        #region Extract CM binaries
        try
        {
            if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
            {
                Invoke-LabCommand -Computer $vm -ScriptBlock {    
                    $null = mkdir -Force $VMCMBinariesDirectory        
                    Expand-Archive -Path $CMZipObj.FullName -DestinationPath $VMCMBinariesDirectory -Force
                } -Variable (Get-Variable VMCMBinariesDirectory, CMZipObj)
            }
            else
            {
                Expand-Archive -Path $CMZipObj.FullName -DestinationPath $CMBinariesDirectory -Force -ErrorAction "Stop" -ErrorVariable "ExpandArchiveErr"
                Copy-LabFileItem -Path $CMBinariesDirectory/* -Destination $VMCMBinariesDirectory -ComputerName $vm -Recurse
            }
        
        }
        catch
        {
            $Message = "Failed to initiate extraction to '{0}' ({1})" -f $CMBinariesDirectory, $ExpandArchiveErr.ErrorRecord.Exception.Message
            Write-LogFunctionExitWithError -Message $Message
        }
        #endregion

        #region Download CM prerequisites
        switch ($Branch)
        {
            "CB"
            {
                if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
                {
                    Install-LabSoftwarePackage -ComputerName $vm -LocalPath $VMCMBinariesDirectory\SMSSETUP\BIN\X64\setupdl.exe -CommandLine "/NOUI $VMCMPreReqsDirectory" -UseShellExecute -AsScheduledJob
                    break       
                }
                try
                {
                    $p = Start-Process -FilePath $CMBinariesDirectory\SMSSETUP\BIN\X64\setupdl.exe -ArgumentList "/NOUI", $CMPreReqsDirectory -PassThru -ErrorAction "Stop" -ErrorVariable "StartProcessErr" -Wait
                }
                catch
                {
                    $Message = "Failed to initiate download of CM pre-req files to '{0}' ({1})" -f $CMPreReqsDirectory, $StartProcessErr.ErrorRecord.Exception.Message
                    Write-LogFunctionExitWithError -Message $Message
                }

                Copy-LabFileItem -Path $CMPreReqsDirectory/* -Destination $VMCMPreReqsDirectory -Recurse -ComputerName $vm
                Write-ScreenInfo -Message '.'
            }
            "TP"
            {
                $Messages = @(
                    "Directory '{0}' is intentionally empty." -f $CMPreReqsDirectory
                    "The prerequisites will be downloaded by the installer within the VM."
                    "This is a workaround due to a known issue with TP 2002 baseline: https://twitter.com/codaamok/status/1268588138437509120"
                )

                try
                {
                    $CMPreReqsDirectory = "$(Get-LabSourcesLocation -Local)\SoftwarePackages\CM-Prereqs-$($cmVersion)-$cmBranch"
                    $PreReqDirObj = New-Item -Path $CMPreReqsDirectory -ItemType "Directory" -Force -ErrorAction "Stop" -ErrorVariable "CreateCMPreReqDir"
                    Set-Content -Path ("{0}\readme.txt" -f $PreReqDirObj.FullName) -Value $Messages -ErrorAction "SilentlyContinue"
                }
                catch
                {
                    $Message = "Failed to create CM prerequisite directory '{0}' ({1})" -f $CMPreReqsDirectory, $CreateCMPreReqDir.ErrorRecord.Exception.Message
                    Write-LogFunctionExitWithError -Message $Message
                }
            }
        }
    }
    #endregion
}
