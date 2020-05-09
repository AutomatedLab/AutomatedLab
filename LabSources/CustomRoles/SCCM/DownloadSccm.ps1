param(
    [Parameter(Mandatory)]
    [string]$SccmBinariesDirectory,

    [Parameter(Mandatory)]
    [string]$SccmPreReqsDirectory
)

$sccm1702Url = 'http://download.microsoft.com/download/C/A/0/CA0CAE64-358C-49EC-9F61-8FACFEDE7083/SC_Configmgr_SCEP_1702.exe'
$sccmSetup = Get-LabInternetFile -Uri $sccm1702Url -Path $labSources\SoftwarePackages -PassThru

if (-not (Test-Path -Path $SccmBinariesDirectory))
{
    $pArgs = '/AUTO "{0}"' -f $SccmBinariesDirectory
    $p = Start-Process -FilePath $sccmSetup.FullName -ArgumentList $pArgs -PassThru
    Write-ScreenInfo "Waiting for extracting the SCCM files to '$SccmBinariesDirectory'" -NoNewLine
    while (-not $p.HasExited) {
        Write-ScreenInfo '.' -NoNewLine
        Start-Sleep -Seconds 10
    }
    Write-ScreenInfo 'finished'
}
else
{
    Write-ScreenInfo "SCCM folder does already exist, skipping the download. Delete the folder '$SccmBinariesDirectory' if you want to download again."
}

if (-not (Test-Path -Path $SccmPreReqsDirectory))
{
    $p = Start-Process -FilePath $labSources\SoftwarePackages\SCCM1702\SMSSETUP\BIN\X64\setupdl.exe -ArgumentList $SccmPreReqsDirectory -PassThru
    Write-ScreenInfo "Waiting for downloading the SCCM Prerequisites to '$SccmPreReqsDirectory'" -NoNewLine
    while (-not $p.HasExited) {
        Write-ScreenInfo '.' -NoNewLine
        Start-Sleep -Seconds 10
    }
    Write-ScreenInfo 'finished'

}
else
{
    Write-ScreenInfo "SCCM Prerequisites folder does already exist, skipping the download. Delete the folder '$SccmPreReqsDirectory' if you want to download again."
}