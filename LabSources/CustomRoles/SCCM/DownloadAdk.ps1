param(
    [Parameter(Mandatory)]
    [string]$AdkDownloadPath
)

$windowsAdkUrl = 'http://download.microsoft.com/download/3/1/E/31EC1AAF-3501-4BB4-B61C-8BD8A07B4E8A/adk/adksetup.exe'
$adkSetup = Get-LabInternetFile -Uri $windowsAdkUrl -Path $labSources\SoftwarePackages -PassThru

if (-not (Test-Path -Path $AdkDownloadPath))
{
    $p = Start-Process -FilePath $adkSetup.FullName -ArgumentList "/quiet /layout $AdkDownloadPath" -PassThru
    Write-ScreenInfo "Waiting for ADK to download files" -NoNewLine
    while (-not $p.HasExited) {
        Write-ScreenInfo '.' -NoNewLine
        Start-Sleep -Seconds 10
    }
    Write-ScreenInfo 'finished'
}
else
{
    Write-ScreenInfo "ADK folder does already exist, skipping the download. Delete the folder '$AdkDownloadPath' if you want to download again."
}