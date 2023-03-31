function Get-LabVMUptime
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    $cmdGetUptime = {
        if ($IsLinux -or $IsMacOs)
        {
            (Get-Date) - [datetime](uptime -s)
        }
        else
        {
            $lastboottime = (Get-WmiObject -Class Win32_OperatingSystem).LastBootUpTime
            (Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime($lastboottime)
        }
    }

    $uptime = Invoke-LabCommand -ComputerName $ComputerName -ActivityName GetUptime -ScriptBlock $cmdGetUptime -UseLocalCredential -PassThru

    if ($uptime)
    {
        Write-LogFunctionExit -ReturnValue $uptime
        $uptime
    }
    else
    {
        Write-LogFunctionExitWithError -Message 'Uptime could not be retrieved'
    }
}
