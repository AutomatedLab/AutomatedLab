function Get-LWProxmoxNode
{
    param (
        [Parameter()]
        [string[]]$Name
    )

    Write-LogFunctionEntry

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    $result = Get-PveNodes

    $result = Get-PveNodes
    if ($result.StatusCode -ne 200)
    {
        Write-Error "Could not retrieve Proxmox nodes: The error was '$($result.StatusCode)'" -ErrorAction Stop
    }

    $result = if ($Name)
    {
        $result.Response.data | Where-Object { $Name -contains $_.node }
    }
    else
    {
        $result.Response.data | Sort-Object -Property node
    }

    $result | Add-Member -Name ToString -MemberType ScriptMethod -Value { $this.node } -Force
    $result

    Write-LogFunctionExit
}
