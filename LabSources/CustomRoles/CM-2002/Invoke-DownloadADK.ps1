Param (
    [Parameter(Mandatory)]
    [String]$AdkDownloadURL,

    [Parameter(Mandatory)]
    [String]$AdkDownloadPath,

    [Parameter(Mandatory)]
    [String]$WinPEDownloadURL,

    [Parameter(Mandatory)]
    [String]$WinPEDownloadPath
)

Write-ScreenInfo -Message "Starting ADK and WinPE download process" -TaskStart

#region ADK installer
$ADKExePath = Join-Path -Path $labSources -ChildPath "SoftwarePackages\adksetup.exe"

Write-ScreenInfo -Message ("Downloading '{0}' to '{1}'" -f (Split-Path $ADKExePath -Leaf), (Split-Path $AdkExePath -Parent)) -TaskStart

if (Test-Path -Path $ADKExePath) {
    Write-ScreenInfo -Message ("File already exists, skipping the download. Delete if you want to download again." -f $ADKExePath)
}

try {
    $ADKExeObj = Get-LabInternetFile -Uri $AdkDownloadURL -Path (Split-Path -Path $ADKExePath -Parent) -FileName (Split-Path -Path $ADKExePath -Leaf) -PassThru -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr"
}
catch {
    $Message = "Failed to download from '{0}' ({1})" -f $AdkDownloadURL, $GetLabInternetFileErr.ErrorRecord.Exception.Message
    Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
    throw $Message
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

#region ADK files
Write-ScreenInfo -Message ("Downloading ADK files to '{0}'" -f $AdkDownloadPath) -TaskStart

if (-not (Test-Path -Path $AdkDownloadPath))
{
    $pArgs = "/quiet /layout {0}" -f $AdkDownloadPath
    try {
        $p = Start-Process -FilePath $ADKExeObj.FullName -ArgumentList $pArgs -PassThru -ErrorAction "Stop" -ErrorVariable "StartProcessErr"
    }
    catch {
        $Message = "Failed to initiate download of ADK files to '{0}' ({1})" -f $AdkDownloadPath, $StartProcessErr.ErrorRecord.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    Write-ScreenInfo -Message "Downloading"
    while (-not $p.HasExited) {
        Write-ScreenInfo -Message '.' -NoNewLine
        Start-Sleep -Seconds 10
    }
    Write-ScreenInfo -Message '.'
}
else
{
    Write-ScreenInfo -Message ("Directory already exist, skipping the download. Delete the directory if you want to download again." -f $AdkDownloadPath)
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

#region ADK installer
$WinPEExePath = Join-Path -Path $labSources -ChildPath "SoftwarePackages\adkwinpesetup.exe"

Write-ScreenInfo -Message ("Downloading '{0}' to '{1}'" -f (Split-Path $WinPEExePath -Leaf), (Split-Path $WinPEExePath -Parent)) -TaskStart

if (Test-Path -Path $WinPEExePath) {
    Write-ScreenInfo -Message ("File already exists, skipping the download. Delete if you want to download again." -f $WinPEExePath)
}

try {
    $WinPESetup = Get-LabInternetFile -Uri $WinPEDownloadURL -Path (Split-Path -Path $WinPEExePath -Parent) -FileName (Split-Path -Path $WinPEExePath -Leaf) -PassThru -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr"
}
catch {
    $Message = "Failed to download from '{0}' ({1})" -f $WinPEDownloadURL, $GetLabInternetFileErr.ErrorRecord.Exception.Message
    Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
    throw $Message
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

#region WinPE files
Write-ScreenInfo -Message ("Downloading WinPE files to '{0}'" -f $WinPEDownloadPath) -TaskStart

if (-not (Test-Path -Path $WinPEDownloadPath))
{
    try {
        $p = Start-Process -FilePath $WinPESetup.FullName -ArgumentList "/quiet /layout $WinPEDownloadPath" -PassThru -ErrorAction "Stop" -ErrorVariable "StartProcessErr"
    }
    catch {
        $Message = "Failed to initiate download of WinPE files to '{0}' ({1})" -f $WinPEDownloadPath, $StartProcessErr.ErrorRecord.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    Write-ScreenInfo -Message "Downloading"
    while (-not $p.HasExited) {
        Write-ScreenInfo -Message '.' -NoNewLine
        Start-Sleep -Seconds 10
    }
    Write-ScreenInfo -Message '.'
}
else
{
    Write-ScreenInfo -Message ("Directory already exists, skipping the download. Delete the directory if you want to download again." -f $WinPEDownloadPath)
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

# Workaround because Write-Progress doesn't yet seem to clear up from Get-LabInternetFile
Write-Progress -Activity * -Completed

Write-ScreenInfo -Message "Finished ADK / WinPE download process" -TaskEnd