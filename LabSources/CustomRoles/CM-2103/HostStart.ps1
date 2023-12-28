Param (
    
    [Parameter(Mandatory)]
    [String]$ComputerName,
    
    [Parameter(Mandatory)]
    [String]$CMSiteCode,

    [Parameter(Mandatory)]
    [String]$CMSiteName,

    [Parameter(Mandatory)]
    [ValidatePattern('^EVAL$|^\w{5}-\w{5}-\w{5}-\w{5}-\w{5}$', Options = 'IgnoreCase')]
    [String]$CMProductId,

    [Parameter(Mandatory)]
    [String]$CMBinariesDirectory,

    [Parameter(Mandatory)]
    [String]$CMPreReqsDirectory,

    [Parameter(Mandatory)]
    [String]$CMDownloadURL,

    [Parameter()]
    [String[]]$CMRoles,

    [Parameter(Mandatory)]
    [String]$ADKDownloadURL,

    [Parameter(Mandatory)]
    [String]$ADKDownloadPath,

    [Parameter(Mandatory)]
    [String]$WinPEDownloadURL,

    [Parameter(Mandatory)]
    [String]$WinPEDownloadPath,

    [Parameter(Mandatory)]
    [String]$LogViewer,

    [Parameter()]
    [String]$DoNotDownloadWMIEv2,

    [Parameter(Mandatory)]
    [String]$Version,

    [Parameter(Mandatory)]
    [String]$Branch,

    [Parameter(Mandatory)]
    [String]$AdminUser,

    [Parameter(Mandatory)]
    [String]$AdminPass,

    [Parameter(Mandatory)]
    [String]$ALLabName

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
    #>
    param
    (
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [int32]$LoopTimeout,
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [ValidateSet('Seconds', 'Minutes', 'Hours', 'Days')]
        [string]$LoopTimeoutType,
        [parameter(Mandatory = $true)]
        [int32]$LoopDelay,
        [parameter(Mandatory = $false, ParameterSetName = 'DoUntil')]
        [ValidateSet('Milliseconds', 'Seconds', 'Minutes')]
        [string]$LoopDelayType = 'Seconds',
        [parameter(Mandatory = $true, ParameterSetName = 'ForLoop')]
        [int32]$Iterations,
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
                    $ExitConditionResult = . $ExitCondition
                }
                until ($ExitConditionResult -eq $true -or $StopWatch.Elapsed -ge $TimeSpan)
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
                            $ExitConditionResult = $true
                            break
                        }
                        else {
                            $ExitConditionResult = $false
                        }
                    }
                }
            }
        }
    }
    end {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                if ((-not ($ExitConditionResult)) -and $StopWatch.Elapsed -ge $TimeSpan -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                    . $IfTimeoutScript
                }
                if (($ExitConditionResult) -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                    . $IfSucceedScript
                }
                $StopWatch.Reset()
            }
            'ForLoop' {
                if ($PSBoundParameters.ContainsKey('ExitCondition')) {
                    if ((-not ($ExitConditionResult)) -and $i -ge $Iterations -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                        . $IfTimeoutScript
                    }
                    elseif (($ExitConditionResult) -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
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

function Import-CMModule {
    Param(
        [String]$ComputerName,
        [String]$SiteCode
    )
    if(-not(Get-Module ConfigurationManager)) {
        try {
            Import-Module ("{0}\..\ConfigurationManager.psd1" -f $ENV:SMS_ADMIN_UI_PATH) -ErrorAction "Stop" -ErrorVariable "ImportModuleError"
        }
        catch {
            throw ("Failed to import ConfigMgr module: {0}" -f $ImportModuleError.ErrorRecord.Exception.Message)
        }
    }
    try {
        if(-not(Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $ComputerName -Scope "Script" -ErrorAction "Stop" | Out-Null
        }
        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"    
    } 
    catch {
        if(Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue") {
            Remove-PSDrive -Name $SiteCode -Force
        }
        throw ("Failed to create New-PSDrive with site code `"{0}`" and server `"{1}`"" -f $SiteCode, $ComputerName)
    }
}

function ConvertTo-Ini {
    param (
        [Object[]]$Content,
        [String]$SectionTitleKeyName
    )
    begin {
        $StringBuilder = [System.Text.StringBuilder]::new()
        $SectionCounter = 0
    }
    process {
        foreach ($ht in $Content) {
            $SectionCounter++

            if ($ht -is [System.Collections.Specialized.OrderedDictionary] -Or $ht -is [hashtable]) {
                if ($ht.Keys -contains $SectionTitleKeyName) {
                    $null = $StringBuilder.AppendFormat("[{0}]", $ht[$SectionTitleKeyName])
                }
                else {
                    $null = $StringBuilder.AppendFormat("[Section {0}]", $SectionCounter)
                }

                $null = $StringBuilder.AppendLine()

                foreach ($key in $ht.Keys) {
                    if ($key -ne $SectionTitleKeyName) {
                        $null = $StringBuilder.AppendFormat("{0}={1}", $key, $ht[$key])
                        $null = $StringBuilder.AppendLine()
                    }
                }

                $null = $StringBuilder.AppendLine()
            }
        }
    }
    end {
        $StringBuilder.ToString(0, $StringBuilder.Length-4)
    }
}
#endregion

Import-Lab -Name $data.Name -NoValidation -NoDisplay

$script = Get-Command -Name $PSScriptRoot\Invoke-DownloadMisc.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-DownloadMisc.ps1 @param

$script = Get-Command -Name $PSScriptRoot\Invoke-DownloadADK.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-DownloadADK.ps1 @param

$script = Get-Command -Name $PSScriptRoot\Invoke-DownloadCM.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-DownloadCM.ps1 @param

$script = Get-Command -Name $PSScriptRoot\Invoke-InstallCM.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-InstallCM.ps1 @param

$script = Get-Command -Name $PSScriptRoot\Invoke-UpdateCM.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-UpdateCM.ps1 @param

$script = Get-Command -Name $PSScriptRoot\Invoke-CustomiseCM.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-CustomiseCM.ps1 @param

Get-LabVM | ForEach-Object {
    Dismount-LabIsoImage -ComputerName $_.Name -SupressOutput
}
