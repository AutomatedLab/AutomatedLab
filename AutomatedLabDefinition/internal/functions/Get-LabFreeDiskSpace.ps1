function Get-LabFreeDiskSpace
{
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    [uint64]$freeBytesAvailable = 0
    [uint64]$totalNumberOfBytes = 0
    [uint64]$totalNumberOfFreeBytes = 0

    $success = [AutomatedLab.DiskSpaceWin32]::GetDiskFreeSpaceEx($Path, [ref]$freeBytesAvailable, [ref]$totalNumberOfBytes, [ref]$totalNumberOfFreeBytes)
    if (-not $success)
    {
        Write-Error "Could not determine free disk space of path '$Path'"
    }

    New-Object -TypeName PSObject -Property @{
        TotalNumberOfBytes     = $totalNumberOfBytes
        FreeBytesAvailable     = $freeBytesAvailable
        TotalNumberOfFreeBytes = $totalNumberOfFreeBytes
    }
}
