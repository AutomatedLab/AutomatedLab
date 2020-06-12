Param (

    [Parameter(Mandatory)]
    [String]$ComputerName,

    [Parameter(Mandatory)]
    [String]$CMSiteCode,

    [Parameter(Mandatory)]
    [String]$Version

)

#region Define functions
function New-LoopAction {
    <#
    .SYNOPSIS
        Function to loop a specified scriptblock until certain conditions are met
    .DESCRIPTION
        This function is a wrapper for a ForLoop or a DoUntil loop. This allows you to specify if you want to exit based on a timeout, or a number of iterations.
            Additionally, you can specify an optional delay between loops, and the type of dealy (Minutes, Seconds). If needed, you can also perform an action based on
            whether the 'Exit Condition' was met or not. This is the IfTimeoutScript and IfSucceedScript. 
    .PARAMETER LoopTimeout
        A time interval integer which the loop should timeout after. This is for a DoUntil loop.
    .PARAMETER LoopTimeoutType
         Provides the time increment type for the LoopTimeout, defaulting to Seconds. ('Seconds', 'Minutes', 'Hours', 'Days')
    .PARAMETER LoopDelay
        An optional delay that will occur between each loop.
    .PARAMETER LoopDelayType
        Provides the time increment type for the LoopDelay between loops, defaulting to Seconds. ('Milliseconds', 'Seconds', 'Minutes')
    .PARAMETER Iterations
        Implies that a ForLoop is wanted. This will provide the maximum number of Iterations for the loop. [i.e. "for ($i = 0; $i -lt $Iterations; $i++)..."]
    .PARAMETER ScriptBlock
        A script block that will run inside the loop. Recommend encapsulating inside { } or providing a [scriptblock]
    .PARAMETER ExitCondition
        A script block that will act as the exit condition for the do-until loop. Will be evaluated each loop. Recommend encapsulating inside { } or providing a [scriptblock]
    .PARAMETER IfTimeoutScript
        A script block that will act as the script to run if the timeout occurs. Recommend encapsulating inside { } or providing a [scriptblock]
    .PARAMETER IfSucceedScript
        A script block that will act as the script to run if the exit condition is met. Recommend encapsulating inside { } or providing a [scriptblock]
    .EXAMPLE
        C:\PS> $newLoopActionSplat = @{
                    LoopTimeoutType = 'Seconds'
                    ScriptBlock = { 'Bacon' }
                    ExitCondition = { 'Bacon' -Eq 'eggs' }
                    IfTimeoutScript = { 'Breakfast'}
                    LoopDelayType = 'Seconds'
                    LoopDelay = 1
                    LoopTimeout = 10
                }
                New-LoopAction @newLoopActionSplat
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Breakfast
    .EXAMPLE
        C:\PS> $newLoopActionSplat = @{
                    ScriptBlock = { if($Test -eq $null){$Test = 0};$TEST++ }
                    ExitCondition = { $Test -eq 4 }
                    IfTimeoutScript = { 'Breakfast' }
                    IfSucceedScript = { 'Dinner'}
                    Iterations  = 5
                    LoopDelay = 1
                }
                New-LoopAction @newLoopActionSplat
                Dinner
        C:\PS> $newLoopActionSplat = @{
                    ScriptBlock = { if($Test -eq $null){$Test = 0};$TEST++ }
                    ExitCondition = { $Test -eq 6 }
                    IfTimeoutScript = { 'Breakfast' }
                    IfSucceedScript = { 'Dinner'}
                    Iterations  = 5
                    LoopDelay = 1
                }
                New-LoopAction @newLoopActionSplat
                Breakfast
    .NOTES
            Play with the conditions a bit. I've tried to provide some examples that demonstrate how the loops, timeouts, and scripts work!
            Author: @CodyMathis123
            Link: https://github.com/CodyMathis123/CM-Ramblings
    #>
    param
    (
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [Int32]$LoopTimeout,
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [ValidateSet('Seconds', 'Minutes', 'Hours', 'Days')]
        [String]$LoopTimeoutType,
        [parameter(Mandatory = $true)]
        [Int32]$LoopDelay,
        [parameter(Mandatory = $false, ParameterSetName = 'DoUntil')]
        [ValidateSet('Milliseconds', 'Seconds', 'Minutes')]
        [String]$LoopDelayType = 'Seconds',
        [parameter(Mandatory = $true, ParameterSetName = 'ForLoop')]
        [Int32]$Iterations,
        [parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [parameter(Mandatory = $false, ParameterSetName = 'ForLoop')]
        [scriptblock]$ExitCondition,
        [parameter(Mandatory = $false)]
        [scriptblock]$IfTimeoutScript,
        [parameter(Mandatory = $false)]
        [scriptblock]$IfSucceedScript
    )
    begin {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                $paramNewTimeSpan = @{
                    $LoopTimeoutType = $LoopTimeout
                }    
                $TimeSpan = New-TimeSpan @paramNewTimeSpan
                $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
                $FirstRunDone = $false        
            }
        }
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                do {
                    switch ($FirstRunDone) {
                        $false {
                            $FirstRunDone = $true
                        }
                        Default {
                            $paramStartSleep = @{
                                $LoopDelayType = $LoopDelay
                            }
                            Start-Sleep @paramStartSleep
                        }
                    }
                    . $ScriptBlock
                }
                until ((. $ExitCondition) -or $StopWatch.Elapsed -ge $TimeSpan)
            }
            'ForLoop' {
                for ($i = 0; $i -lt $Iterations; $i++) {
                    switch ($FirstRunDone) {
                        $false {
                            $FirstRunDone = $true
                        }
                        Default {
                            $paramStartSleep = @{
                                $LoopDelayType = $LoopDelay
                            }
                            Start-Sleep @paramStartSleep
                        }
                    }
                    . $ScriptBlock
                    if ($PSBoundParameters.ContainsKey('ExitCondition')) {
                        if (. $ExitCondition) {
                            break
                        }
                    }
                }
            }
        }
    }
    end {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                if ((-not (. $ExitCondition)) -and $StopWatch.Elapsed -ge $TimeSpan -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                    . $IfTimeoutScript
                }
                if ((. $ExitCondition) -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                    . $IfSucceedScript
                }
                $StopWatch.Reset()
            }
            'ForLoop' {
                if ($PSBoundParameters.ContainsKey('ExitCondition')) {
                    if ((-not (. $ExitCondition)) -and $i -ge $Iterations -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                        . $IfTimeoutScript
                    }
                    elseif ((. $ExitCondition) -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                        . $IfSucceedScript
                    }
                }
                else {
                    if ($i -ge $Iterations -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                        . $IfTimeoutScript
                    }
                    elseif ($i -lt $Iterations -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                        . $IfSucceedScript
                    }
                }
            }
        }
    }
}

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
    }
    #endregion

    #region Check $Version
    if ($Version -eq "2002") {
        Write-ScreenInfo -Message "Target verison is 2002, skipping updates"
        return
    }
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
            $Update.State -eq [SMS_CM_UpdatePackages_State]::Downloading
        } -IfTimeoutScript {
            $Message = "Could not initiate download (timed out)"
            Write-ScreenInfo -Message $Message -TaskEnd -Type "Error"
            throw $Message
        } -IfSucceedScript {
            return $Update
        } -ScriptBlock {
            $Update = New-LoopAction -LoopTimeout 15 -LoopTimeoutType "Minutes" -LoopDelay 5 -LoopDelayType "Seconds" -ExitCondition {
                $Update.State -eq [SMS_CM_UpdatePackages_State]::Downloading
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
                $job = Invoke-LabCommand -ActivityName "Verifying update download initiated OK" -Variable (Get-Variable -Name "Update", "CMSiteCode") -ScriptBlock {
                    $Query = "SELECT * FROM SMS_CM_UPDATEPACKAGES WHERE PACKAGEGUID = '{0}'" -f $Update.PackageGuid
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

        Write-ScreenInfo -Message "Initiating update" -TaskStart
        $job = Invoke-LabCommand -ActivityName "Initiating update" -Variable (Get-Variable -Name "Update") -ScriptBlock {
            Invoke-CimMethod -InputObject $Update -MethodName "InitiateUpgrade" -Arguments @{PrereqFlag = $Update.PrereqFlag}
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
