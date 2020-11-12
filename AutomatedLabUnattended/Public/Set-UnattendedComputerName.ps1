function Set-UnattendedComputerName
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [switch]
        $IsKickstart,

        [switch]
        $IsAutoYast
    )

    if (-not $script:un)
    {
        Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
        return
    }

    if ($IsKickstart) { Set-UnattendedKickstartComputerName -ComputerName $ComputerName; return }

    if ($IsAutoYast) { Set-UnattendedYastComputerName -ComputerName $ComputerName; return }

    Set-UnattendedWindowsComputerName -ComputerName $ComputerName
}