function Stop-ShellHWDetectionService
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [CmdletBinding()]
    param ( )

    Write-LogFunctionEntry

    $service = Get-Service -Name ShellHWDetection -ErrorAction SilentlyContinue
    if (-not $service)
    {
        Write-PSFMessage -Message "The service 'ShellHWDetection' is not installed, exiting."
        Write-LogFunctionExit
        return
    }

    Write-PSFMessage -Message 'Stopping the ShellHWDetection service (Shell Hardware Detection) to prevent the OS from responding to the new disks.'

    $retries = 5
    while ($retries -gt 0 -and ((Get-Service -Name ShellHWDetection).Status -ne 'Stopped'))
    {
        Write-Debug -Message 'Trying to stop ShellHWDetection'

        Stop-Service -Name ShellHWDetection | Out-Null
        Start-Sleep -Seconds 1
        if ((Get-Service -Name ShellHWDetection).Status -eq 'Running')
        {
            Write-Debug -Message "Could not stop service ShellHWDetection. Retrying."
            Start-Sleep -Seconds 5
        }
        $retries--
    }

    Write-LogFunctionExit
}
