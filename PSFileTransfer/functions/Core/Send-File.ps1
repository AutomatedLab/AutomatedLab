function Send-File
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFilePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationFolderPath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,

        [switch]$Force
    )

    $firstChunk = $true

    Write-Verbose -Message "PSFileTransfer: Sending file $SourceFilePath to $DestinationFolderPath on $($Session.ComputerName) ($([Math]::Round($chunkSize / 1MB, 2)) MB chunks)"

    $sourcePath = (Resolve-Path $SourceFilePath -ErrorAction SilentlyContinue).Path
    $sourcePath = Convert-Path $sourcePath
    if (-not $sourcePath)
    {
        Write-Error -Message 'Source file could not be found.'
        return
    }

    if (-not (Test-Path -Path $SourceFilePath -PathType Leaf))
    {
        Write-Error -Message 'Source path points to a directory and not a file.'
        return
    }

    $sourceFileStream = [System.IO.File]::OpenRead($sourcePath)

    for ($position = 0; $position -lt $sourceFileStream.Length; $position += $chunkSize)
    {
        $remaining = $sourceFileStream.Length - $position
        $remaining = [Math]::Min($remaining, $chunkSize)

        $chunk = New-Object -TypeName byte[] -ArgumentList $remaining
        [void]$sourceFileStream.Read($chunk, 0, $remaining)

        $destinationFullName = Join-Path -Path $DestinationFolderPath -ChildPath (Split-Path -Path $SourceFilePath -Leaf)

        try
        {
            Invoke-Command -Session $Session -ScriptBlock (Get-Command Write-File).ScriptBlock `
                -ArgumentList $destinationFullName, $chunk, $firstChunk, $Force -ErrorAction Stop
        }
        catch
        {
            Write-Error -Message "Could not write destination file. The error was '$($_.Exception.Message)'. Please use the Force switch if the destination folder does not exist" -Exception $_.Exception
            return
        }

        $firstChunk = $false
    }

    $sourceFileStream.Close()

    Write-Verbose -Message "PSFileTransfer: Finished sending file $SourceFilePath"
}
