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
