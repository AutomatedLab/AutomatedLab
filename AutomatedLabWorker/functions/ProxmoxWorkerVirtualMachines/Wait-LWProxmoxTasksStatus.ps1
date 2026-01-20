function Wait-LWProxmoxTasksStatus
{
    [Cmdletbinding()]
    [OutputType([string], [pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [string[]]$Upid,

        [Parameter(Mandatory)]
        [string]$Node,

        [Parameter(Mandatory)]
        [hashtable]$DesiredValues,

        [int]$TimeoutInSeconds = 300
    )

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    $startTime = Get-Date

    $result = foreach ($id in $Upid)
    {
        while ($true)
        {
            $status = (Get-PveNodesTasksStatus -Node $Node -Upid $id).Response.data

            $taskSuccessful = $true
            foreach ($key in $DesiredValues.Keys)
            {
                $desiredStatus = $DesiredValues[$key]
                $currentStatus = $status.$key

                if ($currentStatus -ne $desiredStatus)
                {
                    $taskSuccessful = $false
                }
            }

            if ($taskSuccessful)
            {
                [pscustomobject]@{
                    Upid       = $id
                    ExitStatus = $status.exitstatus
                    Status     = $status.status
                }
                break
            }

            if ((Get-Date) - $startTime -gt (New-TimeSpan -Seconds $TimeoutInSeconds))
            {
                Write-Error "Timeout waiting for task '$id' to reach status '$DesiredStatus'. Current status: '$exitStatus'."
                break
            }

            Start-Sleep -Seconds 1
        }
    }

    if ($result.Count -eq 1)
    {
        return $result.exitStatus
    }
    else
    {
        return $result
    }
}
