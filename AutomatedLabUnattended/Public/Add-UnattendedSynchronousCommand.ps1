function Add-UnattendedSynchronousCommand
{
    param (
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [string]$Description,

        [switch]$IsKickstart,

        [switch]$IsAutoYast
    )

    if (-not $script:un)
    {
        Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
        return
    }

    if ($IsKickstart) { Add-UnattendedKickstartSynchronousCommand -Command $Command -Description $Description; return }

    if ($IsAutoYast) { Add-UnattendedYastSynchronousCommand -Command $Command -Description $Description; return }

    Add-UnattendedWindowsSynchronousCommand -Command $Command -Description $Description
}
