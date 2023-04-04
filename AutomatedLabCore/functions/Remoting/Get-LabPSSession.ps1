function Get-LabPSSession
{
    [cmdletBinding()]
    [OutputType([System.Management.Automation.Runspaces.PSSession])]

    param (
        [string[]]$ComputerName,

        [switch]$DoNotUseCredSsp
    )

    $pattern = '\w+_[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}'

    if ($ComputerName)
    {
        $computers = Get-LabVM -ComputerName $ComputerName -IncludeLinux
    }
    else
    {
        $computers = Get-LabVM -IncludeLinux
    }

    if (-not $computers)
    {
        Write-Error 'The machines could not be found' -TargetObject $ComputerName
    }

    $sessions = foreach ($computer in $computers)
    {
        $session = Get-PSSession | Where-Object { $_.Name -match $pattern -and $_.Name -like "$($computer.Name)_*" }

        if (-not $session -and $ComputerName)
        {
            Write-Error "No session found for computer '$computer'" -TargetObject $computer
        }
        else
        {
            $session
        }
    }

    if ($DoNotUseCredSsp)
    {
        $sessions | Where-Object { $_.Runspace.ConnectionInfo.AuthenticationMechanism -ne 'CredSsp' }
    }
    else
    {
        $sessions
    }
}
