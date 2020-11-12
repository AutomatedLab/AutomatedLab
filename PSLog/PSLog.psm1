#region Write-LogFunctionEntry
function Write-LogFunctionEntry
{
    [CmdletBinding()]
    param()

    $Global:LogFunctionEntryTime = Get-Date

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $Message = 'Entering...'

    $caller = (Get-PSCallStack)[1]
    $callerFunctionName = $caller.Command
    if ($callerFunctionName)
    {
        try
        {
            [AutomatedLab.LabTelemetry]::Instance.FunctionCalled($callerFunctionName)
        }
        catch
        { }
    }

    if ($caller.ScriptName)
    {
        $callerScriptName = Split-Path -Path $caller.ScriptName -Leaf
    }

    try
    {
        $boundParameters = $caller.InvocationInfo.BoundParameters.GetEnumerator()
    }
    catch
    {

    }

    $Message += ' ('
    foreach ($parameter in $boundParameters)
    {
        if (-not $parameter.Value)
        {
            $Message += '{0}={1},' -f $parameter.Key, '<null>'
        }
        elseif ($parameter.Value -is [System.Array] -and $parameter.Value[0] -is [string] -and $parameter.count -eq 1)
        {
            $Message += "{0}={1}," -f $parameter.Key, $($parameter.value)
        }
        elseif ($parameter.Value -is [System.Array])
        {
            $Message += '{0}={1}({2}),' -f $parameter.Key, $parameter.Value, $parameter.Value.Count
        }
        else
        {
            if ($defaults.TruncateTypes -contains $parameter.Value.GetType().FullName)
            {
                if ($parameter.Value.ToString().Length -lt $defaults.TruncateLength)
                {
                    $truncateLength = $parameter.Value.ToString().Length
                }
                else
                {
                    $truncateLength = $defaults.TruncateLength
                }
                $Message += '{0}={1},' -f $parameter.Key, $parameter.Value.ToString().Substring(0, $truncateLength)
            }
            elseif ($parameter.Value -is [System.Management.Automation.PSCredential])
            {
                $Message += '{0}=UserName: {1} / Password: {2},' -f $parameter.Key, $parameter.Value.UserName, $parameter.Value.GetNetworkCredential().Password
            }
            else
            {
                $Message += '{0}={1},' -f $parameter.Key, $parameter.Value
            }
        }
    }
    $Message = $Message.Substring(0, $Message.Length - 1)
    $Message += ')'

    $Message = '{0};{1};{2};{3}' -f (Get-Date), $callerScriptName, $callerFunctionName, $Message
    $Message = ($Message -split ';')[2..3] -join ' '

    Write-PSFMessage -Message $Message
}
#endregion

#region Write-LogFunctionExit
function Write-LogFunctionExit
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0)]
        [string]$ReturnValue
    )

    if ($Global:LogFunctionEntryTime)
    {
        $ts = New-TimeSpan -Start $Global:LogFunctionEntryTime -End (Get-Date)
    }
    else
    {
        $ts = New-TimeSpan -Seconds 0
    }

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if ($ReturnValue)
    {
        $Message = "...leaving - return value is '{0}'..." -f $ReturnValue
    }
    else
    {
        $Message = '...leaving...'
    }

    $caller = (Get-PSCallStack)[1]
    $callerFunctionName = $caller.Command
    if ($caller.ScriptName)
    {
        $callerScriptName = Split-Path -Path $caller.ScriptName -Leaf
    }

    $Message = '{0};{1};{2};{3};{4}' -f (Get-Date), $callerScriptName, $callerFunctionName, $Message, ("(Time elapsed: {0:hh}:{0:mm}:{0:ss}:{0:fff})" -f $ts)
    $Message = -join ($Message -split ';')[2..4]

    Write-PSFMessage -Message $Message
}
#endregion

#region Write-LogFunctionExitWithError
function Write-LogFunctionExitWithError
{
    [CmdletBinding(
        ConfirmImpact = 'Low',
        DefaultParameterSetName = 'Message'
    )]

    param
    (
        [Parameter(Position = 0, ParameterSetName = 'Message')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Position = 0, ParameterSetName = 'ErrorRecord')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Position = 0, ParameterSetName = 'Exception')]
        [ValidateNotNullOrEmpty()]
        [System.Exception]$Exception,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Details
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    switch ($pscmdlet.ParameterSetName)
    {
        'Message'
        {
            $Message = '...leaving: ' + $Message
        }
        'ErrorRecord'
        {
            $Message = '...leaving: ' + $ErrorRecord.Exception.Message
        }
        'Exception'
        {
            $Message = '...leaving: ' + $Exception.Message
        }
    }

    $EntryType = 'Error'

    $caller = (Get-PSCallStack)[1]
    $callerFunctionName = $caller.Command
    if ($caller.ScriptName)
    {
        $callerScriptName = Split-Path -Path $caller.ScriptName -Leaf
    }

    $Message = '{0};{1};{2};{3}' -f (Get-Date), $callerScriptName, $callerFunctionName, $Message
    if ($Details)
    {
        $Message += ';' + $Details
    }

    $Message = -join ($Message -split ';')[2..3]

    if ($script:PSLog_Silent)
    {
        Microsoft.PowerShell.Utility\Write-Verbose -Message $Message
    }
    else
    {
        Microsoft.PowerShell.Utility\Write-Error -Message $Message
    }
}
#endregion

#region Write-LogError
function Write-LogError
{
    [CmdletBinding(
        ConfirmImpact = 'Low',
        DefaultParameterSetName = 'Name'
    )]
    param
    (
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Message')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Details,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Exception]$Exception
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $EntryType = 'Error'

    $caller = (Get-PSCallStack)[1]
    $callerFunctionName = $caller.Command
    if ($caller.ScriptName)
    {
        $callerScriptName = Split-Path -Path $caller.ScriptName -Leaf
    }

    if ($Exception)
    {
        $Message = '{0};{1};{2};{3}' -f (Get-Date), $callerScriptName, $callerFunctionName, ('{0}: {1}' -f $Message, $Exception.Message)
    }
    else
    {
        $Message = '{0};{1};{2};{3}' -f (Get-Date), $callerScriptName, $callerFunctionName, $Message
    }

    if ($Details)
    {
        $Message += ';' + $Details
    }

    $Message = -join ($Message -split ';')[2..3]

    if ($script:PSLog_Silent)
    {
        Microsoft.PowerShell.Utility\Write-Verbose $Message
    }
    else
    {
        Microsoft.PowerShell.Utility\Write-Host $Message -ForegroundColor Red
    }
}
#endregion

#region Get-CallerPreference
function Get-CallerPreference
{
    <#
            .Synopsis
            Fetches "Preference" variable values from the caller's scope.
            .DESCRIPTION
            Script module functions do not automatically inherit their caller's variables, but they can be
            obtained through the $PSCmdlet variable in Advanced Functions.  This function is a helper function
            for any script module Advanced Function; by passing in the values of $ExecutionContext.SessionState
            and $PSCmdlet, Get-CallerPreference will set the caller's preference variables locally.
            .PARAMETER Cmdlet
            The $PSCmdlet object from a script module Advanced Function.
            .PARAMETER SessionState
            The $ExecutionContext.SessionState object from a script module Advanced Function.  This is how the
            Get-CallerPreference function sets variables in its callers' scope, even if that caller is in a different
            script module.
            .PARAMETER Name
            Optional array of parameter names to retrieve from the caller's scope.  Default is to retrieve all
            Preference variables as defined in the about_Preference_Variables help file (as of PowerShell 4.0)
            This parameter may also specify names of variables that are not in the about_Preference_Variables
            help file, and the function will retrieve and set those as well.
            .EXAMPLE
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

            Imports the default PowerShell preference variables from the caller into the local scope.
            .EXAMPLE
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'ErrorActionPreference','SomeOtherVariable'

            Imports only the ErrorActionPreference and SomeOtherVariable variables into the local scope.
            .EXAMPLE
            'ErrorActionPreference','SomeOtherVariable' | Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

            Same as Example 2, but sends variable names to the Name parameter via pipeline input.
            .INPUTS
            String
            .OUTPUTS
            None.  This function does not produce pipeline output.
            .LINK
            about_Preference_Variables
    #>

    [CmdletBinding(DefaultParameterSetName = 'AllVariables')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]
        $SessionState,

        [Parameter(ParameterSetName = 'Filtered', ValueFromPipeline = $true)]
        [string[]]
        $Name
    )

    begin
    {
        $filterHash = @{ }
    }

    process
    {
        if ($null -ne $Name)
        {
            foreach ($string in $Name)
            {
                $filterHash[$string] = $true
            }
        }
    }

    end
    {
        # List of preference variables taken from the about_Preference_Variables help file in PowerShell version 4.0

        $vars = @{
            'ErrorView'                     = $null
            'FormatEnumerationLimit'        = $null
            'LogCommandHealthEvent'         = $null
            'LogCommandLifecycleEvent'      = $null
            'LogEngineHealthEvent'          = $null
            'LogEngineLifecycleEvent'       = $null
            'LogProviderHealthEvent'        = $null
            'LogProviderLifecycleEvent'     = $null
            'MaximumAliasCount'             = $null
            'MaximumDriveCount'             = $null
            'MaximumErrorCount'             = $null
            'MaximumFunctionCount'          = $null
            'MaximumHistoryCount'           = $null
            'MaximumVariableCount'          = $null
            'OFS'                           = $null
            'OutputEncoding'                = $null
            'ProgressPreference'            = $null
            'PSDefaultParameterValues'      = $null
            'PSEmailServer'                 = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName'      = $null
            'PSSessionConfigurationName'    = $null
            'PSSessionOption'               = $null

            'ErrorActionPreference'         = 'ErrorAction'
            'DebugPreference'               = 'Debug'
            'ConfirmPreference'             = 'Confirm'
            'WhatIfPreference'              = 'WhatIf'
            'VerbosePreference'             = 'Verbose'
            'WarningPreference'             = 'WarningAction'
        }


        foreach ($entry in $vars.GetEnumerator())
        {
            if (([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) -and
                ($PSCmdlet.ParameterSetName -eq 'AllVariables' -or $filterHash.ContainsKey($entry.Name)))
            {
                $variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)

                if ($null -ne $variable)
                {
                    if ($SessionState -eq $ExecutionContext.SessionState)
                    {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                    }
                    else
                    {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Filtered')
        {
            foreach ($varName in $filterHash.Keys)
            {
                if (-not $vars.ContainsKey($varName))
                {
                    $variable = $Cmdlet.SessionState.PSVariable.Get($varName)

                    if ($null -ne $variable)
                    {
                        if ($SessionState -eq $ExecutionContext.SessionState)
                        {
                            Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                        }
                        else
                        {
                            $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                        }
                    }
                }
            }
        }

    }
}
#endregion Get-CallerPreference

#region Write-ProgressIndicator
function Write-ProgressIndicator
{


    if (-not (Get-PSCallStack)[1].InvocationInfo.BoundParameters['ProgressIndicator'])
    {
        return
    }
    Write-ScreenInfo -Message '.' -NoNewline
}
#endregion Write-ProgressIndicator

#region Write-ProgressIndicatorEnd
function Write-ProgressIndicatorEnd
{

    if (-not (Get-PSCallStack)[1].InvocationInfo.BoundParameters['ProgressIndicator'])
    {
        return
    }
    if ((Get-PSCallStack)[1].InvocationInfo.BoundParameters['NoNewLine'].IsPresent)
    {
        return
    }

    Write-ScreenInfo -Message '.'
}
#endregion Write-ProgressIndicatorEnd

#region Write-ScreenInfo
function Write-ScreenInfo
{

    param
    (
        [Parameter(Position = 1)]
        [string[]]$Message,

        [Parameter(Position = 2)]
        [timespan]$TimeDelta,

        [Parameter(Position = 3)]
        [timespan]$TimeDelta2,

        [ValidateSet('Error', 'Warning', 'Info', 'Verbose', 'Debug')]
        [string]$Type = 'Info',

        [switch]$NoNewLine,

        [switch]$TaskStart,

        [switch]$TaskEnd,

        [switch]$OverrideNoDisplay
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if ((Get-PSCallStack)[1].InvocationInfo.BoundParameters['NoDisplay'].IsPresent -and -not $OverrideNoDisplay)
    {
        return
    }

    if (-not $Global:AL_DeploymentStart)
    {
        $Global:AL_DeploymentStart = (Get-Date)
    }
    if (-not $Global:taskStart)
    {
        [datetime[]]$Global:taskStart = @()
        $Global:taskStart += (Get-Date)
    }
    elseif ($TaskStart)
    {
        $Global:taskStart += (Get-Date)
    }
    elseif ($TaskEnd)
    {
        $TimeDelta2 = ((Get-Date) - $Global:taskStart[-1])

        $newSize = ($Global:taskStart).Length - 1
        if ($newSize -lt 0) { $newSize = 0 }
        #Replaced Select-Object with array indexing because of https://github.com/PowerShell/PowerShell/issues/9185
        $Global:taskStart = $Global:taskStart[0..(($Global:taskStart).Length - 1)] #$Global:taskStart | Select-Object -First (($Global:taskStart).Length - 1)
    }


    if (-not $TimeDelta -and $Global:AL_DeploymentStart)
    {
        $TimeDelta = (Get-Date) - $Global:AL_DeploymentStart
    }
    if (-not $TimeDelta2 -and $Global:taskStart[-1])
    {
        $TimeDelta2 = (Get-Date) - $Global:taskStart[-1]
    }

    $timeDeltaString = '{0:d2}:{1:d2}:{2:d2}' -f $TimeDelta.Hours, $TimeDelta.Minutes, $TimeDelta.Seconds
    $timeDeltaString2 = '{0:d2}:{1:d2}:{2:d2}.{3:d3}' -f $TimeDelta2.Hours, $TimeDelta2.Minutes, $TimeDelta2.Seconds, $TimeDelta2.Milliseconds

    $date = Get-Date
    $timeCurrent = '{0:d2}:{1:d2}:{2:d2}' -f $date.Hour, $date.Minute, $date.Second

    $Message | Foreach-Object {
        Write-PSFMessage -Level Verbose $_
    }

    if ($NoNewLine)
    {
        if ($Global:PSLog_NoNewLine)
        {
            switch ($Type)
            {
                Error { Microsoft.PowerShell.Utility\Write-Host $Message -NoNewline -ForegroundColor Red }
                Warning { Microsoft.PowerShell.Utility\Write-Host $Message -NoNewline -ForegroundColor DarkYellow }
                Info { Microsoft.PowerShell.Utility\Write-Host $Message -NoNewline }
                Debug { if ($DebugPreference -eq 'Continue') { Microsoft.PowerShell.Utility\Write-Host $Message -NoNewline -ForegroundColor Cyan } }
                Verbose { if ($VerbosePreference -eq 'Continue') { Microsoft.PowerShell.Utility\Write-Host $Message -NoNewline -ForegroundColor Cyan } }
            }
        }
        else
        {
            if ($Global:PSLog_Indent -gt 0) { $Message = ('  ' * ($Global:PSLog_Indent - 1)) + '- ' + $Message }

            switch ($Type)
            {
                Error { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $Message" -NoNewline -ForegroundColor Red }
                Warning { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $Message" -NoNewline -ForegroundColor Yellow }
                Info { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $Message" -NoNewline }
                Debug { if ($DebugPreference -eq 'Continue') { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $Message" -NoNewline -ForegroundColor Cyan } }
                Verbose { if ($VerbosePreference -eq 'Continue') { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $Message" -NoNewline -ForegroundColor Cyan } }
            }

            $Message | ForEach-Object { Write-PSFMessage -Level Verbose -Message "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" }
        }
        $Global:PSLog_NoNewLine = $true
    }
    else
    {
        if ($Global:PSLog_NoNewLine)
        {
            switch ($Type)
            {
                Error
                {
                    $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host $_ -ForegroundColor Red }
                    $Global:PSLog_NoNewLine = $false
                }
                Warning
                {
                    $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host $_ -ForegroundColor Yellow }
                    $Global:PSLog_NoNewLine = $false
                }
                Info
                {
                    $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host $_ }
                    $Global:PSLog_NoNewLine = $false
                }
                Verbose
                {
                    if ($VerbosePreference -eq 'Continue')
                    {
                        $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host $_ -ForegroundColor Cyan }
                        $Global:PSLog_NoNewLine = $false
                    }
                }
                Debug
                {
                    if ($DebugPreference -eq 'Continue')
                    {
                        $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host $_ -ForegroundColor Cyan }
                        $Global:PSLog_NoNewLine = $false
                    }
                }
            }
        }
        else
        {
            if ($Global:PSLog_Indent -gt 0) { $Message = ('  ' * ($Global:PSLog_Indent - 1)) + '- ' + $Message }
            $Message | ForEach-Object { Write-PSFMessage -Level Verbose -Message "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" }
            switch ($Type)
            {
                Error
                {
                    $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" -ForegroundColor Red }
                }
                Warning
                {
                    $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" -ForegroundColor Yellow }
                }
                Info
                {
                    $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" }
                }
                Debug
                {
                    if ($DebugPreference -eq 'Continue')
                    {
                        $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" -ForegroundColor Cyan }
                    }
                }
                Verbose
                {
                    if ($VerbosePreference -eq 'Continue')
                    {
                        $Message | ForEach-Object { Microsoft.PowerShell.Utility\Write-Host "$timeCurrent|$timeDeltaString|$timeDeltaString2| $_" -ForegroundColor Cyan }
                    }
                }
            }
        }
    }

    if ($TaskStart)
    {
        $Global:PSLog_Indent++
    }

    if ($TaskEnd)
    {
        $Global:PSLog_Indent--
        if ($Global:PSLog_Indent -lt 0) { $Global:PSLog_Indent = 0 }
    }

}
#endregion Write-ScreenInfo
