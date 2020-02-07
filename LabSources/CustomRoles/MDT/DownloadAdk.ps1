param(
    [Parameter(Mandatory)]
    [string]$AdkDownloadUrl,

    [Parameter(Mandatory)]
    [string]$AdkDownloadPath,

    [Parameter(Mandatory)]
    [string]$AdkWinPeDownloadUrl
)

$adkSetup = Get-LabInternetFile -Uri $AdkDownloadUrl -Path $labSources\SoftwarePackages -PassThru

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

$adkWinPeSetup = Get-LabInternetFile -Uri $AdkWinPeDownloadUrl -Path $labSources\SoftwarePackages -PassThru

if (-not (Test-Path -Path $AdkWinPEDownloadPath))
{
    $p = Start-Process -FilePath $adkWinPeSetup.FullName -ArgumentList "/quiet /layout $AdkWinPEDownloadPath" -PassThru
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
