function Test-FileName
{
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $fi = $null
    try
    {
        $fi = New-Object System.IO.FileInfo($Path)
    }
    catch [ArgumentException] { }
    catch [System.IO.PathTooLongException] { }
    catch [NotSupportedException] { }
    if ([object]::ReferenceEquals($fi, $null) -or $fi.Name -eq '')
    {
        return $false
    }
    else
    {
        return $true
    }
}
