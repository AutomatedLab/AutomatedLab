Param (
    [Parameter(Mandatory)]
    [String]$ADKDownloadPath,

    [Parameter(Mandatory)]
    [String]$WinPEDownloadPath
)

Write-ScreenInfo -Message "Starting ADK / WinPE download process" -TaskStart

#region ADK installer
Write-ScreenInfo -Message "Downloading ADK installer" -TaskStart

$ADKExePath = "{0}\SoftwarePackages\adksetup.exe" -f $labSources
if (Test-Path -Path $ADKExePath) {
    Write-ScreenInfo -Message ("ADK installer already exists, delete '{0}' if you want to download again" -f $ADKExePath)
}

# Windows 10 2004 ADK
$URL = 'https://go.microsoft.com/fwlink/?linkid=2120254'
try {
    $ADKExeObj = Get-LabInternetFile -Uri $URL -Path (Split-Path -Path $ADKExePath -Parent) -FileName (Split-Path -Path $ADKExePath -Leaf) -PassThru -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr"
}
catch {
    $Message = "Failed to download ADK installer from '{0}' ({1})" -f $URL, $GetLabInternetFileErr.ErrorRecord.Exception.Message
    Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
    throw $Message
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

#region ADK files
Write-ScreenInfo -Message "Downloading ADK files" -TaskStart

if (-not (Test-Path -Path $ADKDownloadPath))
{
    $pArgs = "/quiet /layout {0}" -f $ADKDownloadPath
    try {
        $p = Start-Process -FilePath $ADKExeObj.FullName -ArgumentList $pArgs -PassThru -ErrorAction "Stop" -ErrorVariable "StartProcessErr"
    }
    catch {
        $Message = "Failed to initiate download of ADK files to '{0}' ({1})" -f $ADKDownloadPath, $StartProcessErr.ErrorRecord.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    Write-ScreenInfo -Message "Waiting for ADK files to finish downloading"
    while (-not $p.HasExited) {
        Write-ScreenInfo -Message '.' -NoNewLine
        Start-Sleep -Seconds 10
    }
    Write-ScreenInfo -Message '.'
}
else
{
    Write-ScreenInfo -Message ("ADK directory does already exist, skipping the download. Delete the directory '{0}' if you want to download again." -f $ADKDownloadPath)
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

#region ADK installer
Write-ScreenInfo -Message "Downloading WinPE installer" -TaskStart

$WinPEExePath = "{0}\SoftwarePackages\adkwinpesetup.exe" -f $labSources
if (Test-Path -Path $WinPEExePath) {
    Write-ScreenInfo -Message ("WinPE installer already exists, delete '{0}' if you want to download again" -f $WinPEExePath)
}

# Windows 10 2004 WinPE
$WinPEUrl = 'https://go.microsoft.com/fwlink/?linkid=2120253'
try {
    $WinPESetup = Get-LabInternetFile -Uri $WinPEUrl -Path (Split-Path -Path $WinPEExePath -Parent) -FileName (Split-Path -Path $WinPEExePath -Leaf) -PassThru -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr"
}
catch {
    $Message = "Failed to download WinPE installer from '{0}' ({1})" -f $WinPEUrl, $GetLabInternetFileErr.ErrorRecord.Exception.Message
    Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
    throw $Message
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

#region WinPE files
Write-ScreenInfo -Message "Downloading WinPE files" -TaskStart

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
    Write-ScreenInfo -Message "Waiting for WinPE files to finish downloading"
    while (-not $p.HasExited) {
        Write-ScreenInfo -Message '.' -NoNewLine
        Start-Sleep -Seconds 10
    }
    Write-ScreenInfo -Message '.'
}
else
{
    Write-ScreenInfo -Message ("WinPE directory does already exist, skipping the download. Delete the directory '{0}' if you want to download again." -f $WinPEDownloadPath)
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

# Workaround because Write-Progress doesn't yet seem to clear up from Get-LabInternetFile
Write-Progress -Activity * -Completed

Write-ScreenInfo -Message "Finished ADK / WinPE download process" -TaskEnd
