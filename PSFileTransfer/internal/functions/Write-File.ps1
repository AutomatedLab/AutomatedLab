function Write-File
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$DestinationFullName,

        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes,

        [bool]$Erase,

        [bool]$Force
    )

    Write-Debug -Message "Send-File $($env:COMPUTERNAME): writing $DestinationFullName length $($Bytes.Length)"

    #Convert the destination path to a full filesytem path (to support relative paths)
    try
    {
        $DestinationFullName = $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationFullName)
    }
    catch
    {
        throw New-Object -TypeName System.IO.FileNotFoundException -ArgumentList ('Could not set destination path', $_)
    }

    if ((Test-Path -Path $DestinationFullName -PathType Container))
    {
        Write-Error "Please define the target file's full name. '$DestinationFullName' points to a folder."
        return
    }

    if ($Erase)
    {
        Remove-Item $DestinationFullName -Force -ErrorAction SilentlyContinue
    }

    if ($Force)
    {
        $parentPath = Split-Path -Path $DestinationFullName -Parent
        if (-not (Test-Path -Path $parentPath))
        {
            Write-Verbose -Message "Force is set and destination folder '$parentPath' does not exist, creating it."
            New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
        }
    }

    $destFileStream = [System.IO.File]::OpenWrite($DestinationFullName)
    $destBinaryWriter = New-Object -TypeName System.IO.BinaryWriter -ArgumentList ($destFileStream)

    [void]$destBinaryWriter.Seek(0, 'End')

    $destBinaryWriter.Write($Bytes)

    $destBinaryWriter.Close()
    $destFileStream.Close()

    $Bytes = $null
    [GC]::Collect()
}
