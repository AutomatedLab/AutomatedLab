function Write-LogFunctionEntry
{
    [CmdletBinding()]
    param()

    $Global:LogFunctionEntryTime = Get-Date

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $Message = 'Entering...'

    $caller = (Get-PSCallStack)[1]
    $callerFunctionName = $caller.Command
    if ((Get-LabConfigurationItem -Name SendFunctionTelemetry) -and $callerFunctionName)
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
