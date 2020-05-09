function Set-UnattendedTimeZone
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$TimeZone,

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

    if ($IsKickstart) { Set-UnattendedKickstartTimeZone -TimeZone $TimeZone; return }

    if ($IsAutoYast) { Set-UnattendedYastTimeZone -TimeZone $TimeZone; return }

    Set-UnattendedWindowsTimeZone -TimeZone $TimeZone
}