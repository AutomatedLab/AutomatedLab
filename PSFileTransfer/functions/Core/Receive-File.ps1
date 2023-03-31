function Receive-File
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFilePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationFilePath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession] $Session
    )

    $firstChunk = $true

    Write-Verbose -Message "PSFileTransfer: Receiving file $SourceFilePath to $DestinationFilePath from $($Session.ComputerName) ($([Math]::Round($chunkSize / 1MB, 2)) MB chunks)"

    $sourceLength = Invoke-Command -Session $Session -ScriptBlock (Get-Command Get-FileLength).ScriptBlock `
        -ArgumentList $SourceFilePath -ErrorAction Stop

    $chunkSize = [Math]::Min($sourceLength, $chunkSize)

    for ($position = 0; $position -lt $sourceLength; $position += $chunkSize)
    {
        $remaining = $sourceLength - $position
        $remaining = [Math]::Min($remaining, $chunkSize)

        try
        {
            $chunk = Invoke-Command -Session $Session -ScriptBlock (Get-Command Read-File).ScriptBlock `
                -ArgumentList $SourceFilePath, $position, $remaining -ErrorAction Stop
        }
        catch
        {
            Write-Error -Message 'Could not read destination file' -Exception $_.Exception
            return
        }

        Write-File -DestinationFullName $DestinationFilePath -Bytes $chunk.Bytes -Erase $firstChunk

        $firstChunk = $false
    }

    Write-Verbose -Message "PSFileTransfer: Finished receiving file $SourceFilePath"
}
