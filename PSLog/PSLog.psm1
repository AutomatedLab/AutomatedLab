#region Start-Log
function Start-Log
{
    [CmdletBinding(ConfirmImpact = 'Low')]
    param
    (
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'UserDefined')]
        [ValidateScript({
                    if (-not $_.Exists)
                    {
                        throw 'LogPath does not exist'
                    }
                    return $true
                }
        )]
        [System.IO.DirectoryInfo]$LogPath,
        
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'UserDefined')]
        [ValidateNotNullOrEmpty()]
        [string]$LogName,
        
        [Parameter(Position = 2, Mandatory = $true, ParameterSetName = 'UserDefined')]
        [System.Diagnostics.SourceLevels]$Level,
        
        [Parameter()]
        [switch]$Silent,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'UseDefaults')]
        [switch]$UseDefaults
    )
    
    if ($UseDefaults)
    {
        $script:defaults = $MyInvocation.MyCommand.Module.PrivateData
        if (-not $defaults.DefaultFolder)
        {
            $LogPath = [Environment]::GetFolderPath('MyDocuments')
        }
        else
        {
            $LogPath = $defaults.DefaultFolder
        }
        
        if (-not $defaults.DefaultName)
        {
            $LogName = $Env:USERNAME
        }
        else
        {
            $LogName = $defaults.DefaultName
        }
        
        if (-not $defaults.Level)
        {
            $Level = 'All'
        }
        else
        {
            $Level = $defaults.Level
        }
        
        $Silent = $defaults.Silent
    }
    
    Add-Type -AssemblyName Microsoft.VisualBasic
    $script:LogFile = $LogName
    $script:Log = New-Object -TypeName Microsoft.VisualBasic.Logging.Log
    $script:Log.DefaultFileLogWriter.Append = $true
    $script:Log.DefaultFileLogWriter.AutoFlush = $true
    $script:Log.DefaultFileLogWriter.Delimiter = ';'
    $script:Log.DefaultFileLogWriter.MaxFileSize = 2GB
    $script:Log.DefaultFileLogWriter.ReserveDiskSpace = 1GB
    $script:Log.DefaultFileLogWriter.LogFileCreationSchedule = 'Daily'
    $script:Log.DefaultFileLogWriter.Location = 'Custom'
    $script:Log.DefaultFileLogWriter.CustomLocation = $LogPath
    $script:Log.DefaultFileLogWriter.BaseFileName = $LogName
    $script:Log.TraceSource.Switch.Level = $Level
    
    $script:PSLog_Silent = $Silent
    
    if (!$UseDefaults)
    {
        Write-LogEntry -Message 'Starting log' -EntryType Information
    }
}
#endregion

#region Stop-Log
function Stop-Log
{
    Write-LogEntry -Message 'Closing log' -EntryType Verbose
    $Log.DefaultFileLogWriter.Flush()
    $Log.DefaultFileLogWriter.Close()
}
#endregion

#region Write-LogEntry
function Write-LogEntry
{
    param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Message,
        
        [Parameter(Position = 1, Mandatory = $true)]
        [System.Diagnostics.TraceEventType] $EntryType,
        
        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $Details,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [switch] $SupressConsole
    )
    
    
    
    if (($EntryType -band $Log.TraceSource.Switch.Level) -ne $EntryType)
    {
        return
    }
    
    $caller = (Get-PSCallStack)[1]
    if ($caller.Command -eq 'Write-Host' -or
        $caller.Command -eq 'Write-Warning' -or
        $caller.Command -eq 'Write-Verbose' -or
        $caller.Command -eq 'Write-Debug' -or
        $caller.Command -eq 'Write-Error' -or
        $caller.Command -eq 'Start-Log' -or
    $caller.Command -eq 'Stop-Log')
    {
        $caller = (Get-PSCallStack)[2]
    }
    
    $callerFunctionName = $caller.Command
    if ($caller.ScriptName)
    {
        $callerScriptName = Split-Path -Path $caller.ScriptName -Leaf
    }
    $Message = '{0};{1};{2};{3};{4}' -f (Get-Date), $callerScriptName, $callerFunctionName, $Message, $Details
    $Log.WriteEntry($Message, $EntryType)
    
    if (-not $SupressConsole)
    {
        $Message = ($Message -split ';')[2..3]
        if ($Details)
        {
            $Message += ": $Details"
        }
        
        if ($EntryType -eq 'Verbose')
        {
            Microsoft.PowerShell.Utility\Write-Verbose $Message
        }
        elseif ($EntryType -eq 'Warning')
        {
            Microsoft.PowerShell.Utility\Write-Warning $Message
        }
        elseif ($EntryType -eq 'Information')
        {
            if ($script:PSLog_Silent)
            {
                Microsoft.PowerShell.Utility\Write-Verbose $Message
            }
            else
            {
                Microsoft.PowerShell.Utility\Write-Host $Message -ForegroundColor DarkGreen
            }
        }
        elseif ($EntryType -eq 'Error')
        {
            if ($script:PSLog_Silent)
            {
                Microsoft.PowerShell.Utility\Write-Verbose $Message
            }
            else
            {
                Microsoft.PowerShell.Utility\Write-Host $Message -ForegroundColor Red
            }
        }
        elseif ($EntryType -eq 'Critical')
        {
            if ($script:PSLog_Silent)
            {
                Microsoft.PowerShell.Utility\Write-Verbose $Message
            }
            else
            {
                Microsoft.PowerShell.Utility\Write-Host $Message -ForegroundColor Red
            }
        }
    }
}
#endregion

#region Write-LogFunctionEntry
function Write-LogFunctionEntry
{
    [CmdletBinding()]
    param()

    $Global:LogFunctionEntryTime = Get-Date
    
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if (!$Log)
    {
        if ($MyInvocation.MyCommand.Module.PrivateData.AutoStart)
        {
            Write-Verbose 'starting log'
            Start-Log -UseDefaults
        }
        else
        {
            Microsoft.PowerShell.Utility\Write-Verbose 'Cannot write to the log file until Start-Log has been called'
            return
        }
    }
    
    $Message = 'Entering...'
    
    $caller = (Get-PSCallStack)[1]
    $callerFunctionName = $caller.Command
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
    $Log.WriteEntry($Message, [System.Diagnostics.TraceEventType]::Verbose)
    $Message = ($Message -split ';')[2..3] -join ' '
    
    Microsoft.PowerShell.Utility\Write-Verbose $Message
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
    
    if (!$Log)
    {
        if ($MyInvocation.MyCommand.Module.PrivateData.AutoStart)
        {
            Start-Log -UseDefaults
        }
        else
        {
            Microsoft.PowerShell.Utility\Write-Verbose 'Cannot write to the log file until Start-Log has been called'
            return
        }
    }
    
    if (([System.Diagnostics.TraceEventType]::Verbose -band $Log.TraceSource.Switch.Level) -ne [System.Diagnostics.TraceEventType]::Verbose)
    {
        return
    }
    
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
    $Log.WriteEntry($Message, [System.Diagnostics.TraceEventType]::Verbose)
    $Message = -join ($Message -split ';')[2..4]
    
    Microsoft.PowerShell.Utility\Write-Verbose $Message
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
    
    if (!$Log)
    {
        if ($MyInvocation.MyCommand.Module.PrivateData.AutoStart)
        {
            Start-Log -UseDefaults
        }
        else
        {
            Microsoft.PowerShell.Utility\Write-Verbose 'Cannot write to the log file until Start-Log has been called'
            return
        }
    }
    
    if (([System.Diagnostics.TraceEventType]::Error -band $Log.TraceSource.Switch.Level) -ne [System.Diagnostics.TraceEventType]::Error)
    {
        return
    }
    
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
    $Log.WriteEntry($Message, [System.Diagnostics.TraceEventType]::Error)
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
    
    if (!$Log)
    {
        if ($MyInvocation.MyCommand.Module.PrivateData.AutoStart)
        {
            Start-Log -UseDefaults
        }
        else
        {
            Microsoft.PowerShell.Utility\Write-Verbose 'Cannot write to the log file until Start-Log has been called'
            return
        }
    }
    
    if ($EntryType -band $Log.TraceSource.Switch.Level -ne $EntryType)
    {
        return
    }
    
    $EntryType = 'Error'
    
    $caller = (Get-PSCallStack)[1]
    $callerFunctionName = $caller.Command
    if ($caller.ScriptName)
    {
        $callerScriptName = Split-Path -Path $caller.ScriptName -Leaf
    }
    
    if ($Excpetion)
    {
        $Message = '{0};{1};{2};{3}' -f (Get-Date), $callerScriptName, $callerFunctionName, ('{0}: {1}' -f $Message, $Excpetion.Message)
    }
    else
    {
        $Message = '{0};{1};{2};{3}' -f (Get-Date), $callerScriptName, $callerFunctionName, $Message
    }
    
    if ($Details)
    {
        $Message += ';' + $Details
    }
    $Log.WriteEntry($Message, $EntryType)
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

#region Write-Host
function Write-Host
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
        [System.Object]
        ${Object},
        
        [Switch]
        ${NoNewline},
        
        [System.Object]
        ${Separator},
        
        [System.ConsoleColor]
        ${ForegroundColor},
        
        [System.ConsoleColor]
    ${BackgroundColor})
    
    begin
    {
        try
        {
            Write-LogEntry -EntryType Information -Message $Object -SupressConsole
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Host', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {
                & $wrappedCmd @PSBoundParameters
            }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($MyInvocation.CommandOrigin)
            $steppablePipeline.Begin($pscmdlet)
        }
        catch
        {
            throw
        }
    }
    
    process
    {
        try
        {
            $steppablePipeline.Process($_)
        }
        catch
        {
            throw
        }
    }
    
    end
    {
        try
        {
            $steppablePipeline.End()
        }
        catch
        {
            throw
        }
    }
    <#

            .ForwardHelpTargetName Write-Host
            .ForwardHelpCategory Cmdlet

    #>
}
#endregion

#region Write-Warning
function Write-Warning
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('Msg')]
        [AllowEmptyString()]
        [System.String]
    ${Message})
    
    begin
    {
        try
        {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            Write-LogEntry -EntryType Warning -Message $Message -SupressConsole
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Warning', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {
                & $wrappedCmd @PSBoundParameters
            }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($MyInvocation.CommandOrigin)
            $steppablePipeline.Begin($pscmdlet)
        }
        catch
        {
            throw
        }
    }
    
    process
    {
        try
        {
            $steppablePipeline.Process($_)
        }
        catch
        {
            throw
        }
    }
    
    end
    {
        try
        {
            $steppablePipeline.End()
        }
        catch
        {
            throw
        }
    }
    <#

            .ForwardHelpTargetName Write-Warning
            .ForwardHelpCategory Cmdlet

    #>
}
#endregion

#region Write-Verbose
function Write-Verbose
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('Msg')]
        [AllowEmptyString()]
        [System.String]
    ${Message})
    
    begin
    {
        try
        {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            Write-LogEntry -EntryType Verbose -Message $Message -SupressConsole
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Verbose', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {
                & $wrappedCmd @PSBoundParameters
            }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($MyInvocation.CommandOrigin)
            $steppablePipeline.Begin($pscmdlet)
        }
        catch
        {
            throw
        }
    }
    
    process
    {
        try
        {
            if ($PSBoundParameters.ContainsKey('Verbose'))
            {			
                $steppablePipeline.Process($_)
            }
        }
        catch
        {
            throw
        }
    }
    
    end
    {
        try
        {
            $steppablePipeline.End()
        }
        catch
        {
            throw
        }
    }
    <#

            .ForwardHelpTargetName Write-Verbose
            .ForwardHelpCategory Cmdlet

    #>
}
#endregion

#region Write-Error
function Write-Error
{
    [CmdletBinding(DefaultParameterSetName = 'NoException')]
    param (
        [Parameter(ParameterSetName = 'WithException', Mandatory = $true)]
        [System.Exception]
        ${Exception},
        
        [Parameter(ParameterSetName = 'NoException', Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'WithException')]
        [Alias('Msg')]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        ${Message},
        
        [Parameter(ParameterSetName = 'ErrorRecord', Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]
        ${ErrorRecord},
        
        [Parameter(ParameterSetName = 'NoException')]
        [Parameter(ParameterSetName = 'WithException')]
        [System.Management.Automation.ErrorCategory]
        ${Category},
        
        [Parameter(ParameterSetName = 'NoException')]
        [Parameter(ParameterSetName = 'WithException')]
        [System.String]
        ${ErrorId},
        
        [Parameter(ParameterSetName = 'NoException')]
        [Parameter(ParameterSetName = 'WithException')]
        [System.Object]
        ${TargetObject},
        
        [System.String]
        ${RecommendedAction},
        
        [Alias('Activity')]
        [System.String]
        ${CategoryActivity},
        
        [Alias('Reason')]
        [System.String]
        ${CategoryReason},
        
        [Alias('TargetName')]
        [System.String]
        ${CategoryTargetName},
        
        [Alias('TargetType')]
        [System.String]
    ${CategoryTargetType})
    
    begin
    {
        try
        {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            Write-LogEntry -EntryType Error -Message $Message -SupressConsole
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Error', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {
                & $wrappedCmd @PSBoundParameters
            }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($MyInvocation.CommandOrigin)
            $steppablePipeline.Begin($pscmdlet)
        }
        catch
        {
            throw
        }
    }
    
    process
    {
        try
        {
            $steppablePipeline.Process($_)
        }
        catch
        {
            throw
        }
    }
    
    end
    {
        try
        {
            $steppablePipeline.End()
        }
        catch
        {
            throw
        }
    }
    <#

            .ForwardHelpTargetName Write-Error
            .ForwardHelpCategory Cmdlet

    #>
}
#endregion

#region Write-Debug
function Write-Debug
{
    [CmdletBinding(HelpUri = 'http://go.microsoft.com/fwlink/?LinkID=113424', RemotingCapability = 'None')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('Msg')]
        [AllowEmptyString()]
        [string]
    ${Message})
    
    begin
    {
        try
        {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            Write-LogEntry -EntryType Verbose -Message $Message -SupressConsole
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Debug', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {
                & $wrappedCmd @PSBoundParameters
            }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($MyInvocation.CommandOrigin)
            $steppablePipeline.Begin($pscmdlet)
        }
        catch
        {
            throw
        }
    }
    
    process
    {
        try
        {
            $steppablePipeline.Process($_)
        }
        catch
        {
            throw
        }
    }
    
    end
    {
        try
        {
            $steppablePipeline.End()
        }
        catch
        {
            throw
        }
    }
    <#

            .ForwardHelpTargetName Write-Debug
            .ForwardHelpCategory Cmdlet

    #>
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
        [ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
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
        $filterHash = @{}
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
            'ErrorView' = $null
            'FormatEnumerationLimit' = $null
            'LogCommandHealthEvent' = $null
            'LogCommandLifecycleEvent' = $null
            'LogEngineHealthEvent' = $null
            'LogEngineLifecycleEvent' = $null
            'LogProviderHealthEvent' = $null
            'LogProviderLifecycleEvent' = $null
            'MaximumAliasCount' = $null
            'MaximumDriveCount' = $null
            'MaximumErrorCount' = $null
            'MaximumFunctionCount' = $null
            'MaximumHistoryCount' = $null
            'MaximumVariableCount' = $null
            'OFS' = $null
            'OutputEncoding' = $null
            'ProgressPreference' = $null
            'PSDefaultParameterValues' = $null
            'PSEmailServer' = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName' = $null
            'PSSessionConfigurationName' = $null
            'PSSessionOption' = $null

            'ErrorActionPreference' = 'ErrorAction'
            'DebugPreference' = 'Debug'
            'ConfirmPreference' = 'Confirm'
            'WhatIfPreference' = 'WhatIf'
            'VerbosePreference' = 'Verbose'
            'WarningPreference' = 'WarningAction'
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
    # .ExternalHelp AutomatedLab.Help.xml
    Write-ScreenInfo -Message '.' -NoNewline
}
#endregion Write-ProgressIndicator

#region Write-ProgressIndicatorEnd
function Write-ProgressIndicatorEnd
{
    # .ExternalHelp AutomatedLab.Help.xml
    Write-ScreenInfo -Message '.'
}
#endregion Write-ProgressIndicatorEnd

#region Write-ScreenInfo
function Write-ScreenInfo
{
    # .ExternalHelp AutomatedLab.Help.xml
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
        
        [int]$Indent,
        
        [switch]$TaskStart,
        
        [switch]$TaskEnd
    )
    
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
        
        $newSize = ($Global:taskStart).Length-1
        if ($newSize -lt 0) { $newSize = 0 }
        $Global:taskStart = $Global:taskStart | Select-Object -first (($Global:taskStart).Length-1)
    }
    
    
    if (-not $TimeDelta -and $Global:AL_DeploymentStart)
    {
        $TimeDelta  = (Get-Date) - $Global:AL_DeploymentStart
    }
    if (-not $TimeDelta2 -and $Global:taskStart[-1])
    {
        $TimeDelta2 = (Get-Date) - $Global:taskStart[-1]
    }
    
    $TimeDeltaString = '{0:d2}:{1:d2}:{2:d2}' -f ($TimeDelta.Hours), ($TimeDelta.Minutes), ($TimeDelta.Seconds)
    $TimeDeltaString2 = '{0:d2}:{1:d2}:{2:d2}.{3:d3}' -f ($TimeDelta2.Hours), ($TimeDelta2.Minutes), ($TimeDelta2.Seconds), ($TimeDelta2.Milliseconds)
    
    $TimeCurrent = '{0:d2}:{1:d2}:{2:d2}' -f ((Get-Date).Hour), ((Get-Date).Minute), ((Get-Date).Second)
    
    if ($NoNewLine)
    {
        if ($Global:labDeploymentNoNewLine)
        {
            switch ($Type)
            {
                Error   { Write-Host $message -NoNewline -ForegroundColor Red}
                Warning { Write-Host $message -NoNewline -ForegroundColor DarkYellow }
                Info    { Write-Host $message -NoNewline }
                Debug   { if ($DebugPreference -eq 'Continue') { Write-Host $message -NoNewline -ForegroundColor Cyan } }
                Verbose { if ($VerbosePreference -eq 'Continue') { Write-Host $message -NoNewline -ForegroundColor Cyan } }
            }
        }
        else
        {
            if ($Global:indent -gt 0) { $Message = ('  '*($Global:indent-1)) + '- ' + $message }

            switch ($Type)
            {
                Error   { Write-Host "$TimeCurrent|$TimeDeltaString|$TimeDeltaString2| $message" -NoNewline -ForegroundColor Red }
                Warning { Write-Host "$TimeCurrent|$TimeDeltaString|$TimeDeltaString2| $message" -NoNewline -ForegroundColor Yellow }
                Info    { Write-Host "$TimeCurrent|$TimeDeltaString|$TimeDeltaString2| $message" -NoNewline }
                Debug   { if ($DebugPreference -eq 'Continue') { Write-Host "$TimeCurrent|$TimeDeltaString|$TimeDeltaString2| $message" -NoNewline -ForegroundColor Cyan } }
                Verbose { if ($VerbosePreference -eq 'Continue') { Write-Host "$TimeCurrent|$TimeDeltaString|$TimeDeltaString2| $message" -NoNewline -ForegroundColor Cyan } }
            }

        }
        $Global:labDeploymentNoNewLine = $True
    }
    else
    {
        if ($Global:labDeploymentNoNewLine)
        {
            switch ($Type)
            {
                Error   { $Message | ForEach-Object { Write-Host $_ -ForegroundColor Red } }
                Warning { $Message | ForEach-Object { Write-Host $_ -ForegroundColor Yellow } }
                Info    { $Message | ForEach-Object { Write-Host $_ } }
                Verbose { if ($VerbosePreference -eq 'Continue') { $Message | ForEach-Object { Write-Host $_  -ForegroundColor Cyan } } }
                Debug   { if ($DebugPreference -eq 'Continue') { $Message | ForEach-Object { Write-Host $_  -ForegroundColor Cyan } } }
            }
        }
        else
        {
            if ($Global:indent -gt 0) { $Message = ('  '*($Global:indent-1)) + '- ' + $message }
            switch ($Type)
            {
                Error   { Write-Host "$TimeCurrent|$TimeDeltaString|$TimeDeltaString2| $message" -ForegroundColor Red }
                Warning { Write-Host "$TimeCurrent|$TimeDeltaString|$TimeDeltaString2| $message" -ForegroundColor Yellow }
                Info    { Write-Host "$TimeCurrent|$TimeDeltaString|$TimeDeltaString2| $message" }
                Debug   { if ($DebugPreference -eq 'Continue') { Write-Host "$TimeCurrent|$TimeDeltaString|$TimeDeltaString2| $message" -ForegroundColor Cyan } }
                Verbose { if ($VerbosePreference -eq 'Continue') { Write-Host "$TimeCurrent|$TimeDeltaString|$TimeDeltaString2| $message" -ForegroundColor Cyan } }
            }
        }
        $Global:labDeploymentNoNewLine = $False
    }

    if ($TaskStart)
    {
        $Global:indent++
    }
    
    if ($TaskEnd)
    {
        $Global:indent--
        if ($Global:indent -lt 0) { $Global:indent = 0 }
    }
    
}
#endregion function Write-ScreenInfo