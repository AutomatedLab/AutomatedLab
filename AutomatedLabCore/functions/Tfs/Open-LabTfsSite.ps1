function Open-LabTfsSite
{
    param
    (
        [string]
        $ComputerName
    )

    Start-Process -FilePath (Get-LabTfsUri @PSBoundParameters)
}
