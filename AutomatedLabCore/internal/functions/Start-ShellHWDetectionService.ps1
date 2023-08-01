function Start-ShellHWDetectionService
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

    if ((Get-Service -Name ShellHWDetection).Status -eq 'Running')
    {
        Write-PSFMessage -Message "'ShellHWDetection' Service is already running."
        Write-LogFunctionExit
        return
    }

    Write-PSFMessage -Message 'Starting the ShellHWDetection service (Shell Hardware Detection) again.'

    $retries = 5
    while ($retries -gt 0 -and ((Get-Service -Name ShellHWDetection).Status -ne 'Running'))
    {
        Write-Debug -Message 'Trying to start ShellHWDetection'
        Start-Service -Name ShellHWDetection -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        if ((Get-Service -Name ShellHWDetection).Status -ne 'Running')
        {
            Write-Debug -Message 'Could not start service ShellHWDetection. Retrying.'
            Start-Sleep -Seconds 5
        }
        $retries--
    }

    Write-LogFunctionExit
}
