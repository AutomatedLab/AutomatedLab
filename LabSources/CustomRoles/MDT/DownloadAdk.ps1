param(
    [Parameter(Mandatory)]
    [string]$AdkDownloadPath
)

$windowsAdkUrl = 'https://download.microsoft.com/download/0/1/C/01CC78AA-B53B-4884-B7EA-74F2878AA79F/adk/adksetup.exe'
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
    Write-ScreenInfo "ADK folder already exists, skipping the download. Delete the folder '$AdkDownloadPath' if you want to download again."
}

$windowsAdkWinPEUrl = 'https://download.microsoft.com/download/D/7/E/D7E22261-D0B3-4ED6-8151-5E002C7F823D/adkwinpeaddons/adkwinpesetup.exe'
$adkWinPESetup = Get-LabInternetFile -Uri $windowsAdkWinPEUrl -Path $labSources\SoftwarePackages -PassThru

if (-not (Test-Path -Path $AdkWinPEDownloadPath))
{
    $p = Start-Process -FilePath $adkWinPESetup.FullName -ArgumentList "/quiet /layout $AdkWinPEDownloadPath" -PassThru
    Write-ScreenInfo "Waiting for ADK Windows PE Addons to download files" -NoNewLine
    while (-not $p.HasExited) {
        Write-ScreenInfo '.' -NoNewLine
        Start-Sleep -Seconds 10
    }
    Write-ScreenInfo 'finished'
}
else
{
    Write-ScreenInfo "ADK Windows PE Addons folder already exists, skipping the download. Delete the folder '$AdkWinPEDownloadPath' if you want to download again."
}


