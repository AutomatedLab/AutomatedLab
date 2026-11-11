function ConvertTo-LWProxmoxTaskResultText
{
    <#
    .SYNOPSIS
        Turns the result of Wait-LWProxmoxTasksStatus into the text of the Proxmox task.

    .DESCRIPTION
        Wait-LWProxmoxTasksStatus returns the exit status of one task as a string in PowerShell 7 and as an
        object with an ExitStatus property in Windows PowerShell, where a single object has no Count. For
        several tasks it returns one object per task, and nothing when the wait timed out. This function
        returns the exit status as text in each case, so that an error message can show it.

    .PARAMETER TaskResult
        The result of Wait-LWProxmoxTasksStatus.

    .PARAMETER TimeoutInSeconds
        The timeout of the wait, named in the text when the wait returned no exit status.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [object]
        $TaskResult,

        [Parameter()]
        [int]
        $TimeoutInSeconds
    )

    $texts = foreach ($item in @($TaskResult))
    {
        if (-not $item)
        {
            continue
        }

        if ($item -is [string])
        {
            $item
        }
        elseif ($item.PSObject.Properties['ExitStatus'])
        {
            [string]$item.ExitStatus
        }
        else
        {
            [string]$item
        }
    }

    $text = @($texts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join '; '
    if ($text)
    {
        return $text
    }

    if ($TimeoutInSeconds -gt 0)
    {
        return "no exit status within $TimeoutInSeconds seconds"
    }

    'no exit status'
}
