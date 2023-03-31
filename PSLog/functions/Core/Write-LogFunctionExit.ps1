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
