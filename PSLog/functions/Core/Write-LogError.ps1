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
