function Read-File
{
    [OutputType([Byte[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,

        [Parameter(Mandatory = $true)]
        [int]$Offset,

        [int]$Length
    )

    #Convert the destination path to a full filesytem path (to support relative paths)
    try
    {
        $sourcePath = $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SourceFile)
    }
    catch
    {
        throw New-Object -TypeName System.IO.FileNotFoundException
    }

    if (-not (Test-Path -Path $SourceFile))
    {
        throw 'Source file could not be found'
    }

    $sourceFileStream = [System.IO.File]::OpenRead($sourcePath)

    $chunk = New-Object -TypeName byte[] -ArgumentList $Length
    [void]$sourceFileStream.Seek($Offset, 'Begin')
    [void]$sourceFileStream.Read($chunk, 0, $Length)

    $sourceFileStream.Close()

    return @{ Bytes = $chunk }
}
