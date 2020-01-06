param(
    [Parameter(Mandatory)]
    [string]$AdkDownloadPath,

    [Parameter(Mandatory)]
    [string]$WinPEDownloadPath
)

Write-ScreenInfo -Message "Starting ADK / WinPE download process" -TaskStart

#region ADK installer
Write-ScreenInfo -Message "Downloading ADK installer" -TaskStart

$ADKExePath = Join-Path -Path $labSources -ChildPath "SoftwarePackages\adksetup.exe"
if (Test-Path -Path $ADKExePath) {
    Write-ScreenInfo -Message ("ADK installer exists, delete '{0}' if you want to download again" -f $ADKExePath)
}

$ADKURL = 'https://go.microsoft.com/fwlink/?linkid=2086042'
try {
    $ADKExeObj = Get-LabInternetFile -Uri $ADKURL -Path (Split-Path -Path $ADKExePath -Parent) -FileName (Split-Path -Path $ADKExePath -Leaf) -PassThru -ErrorAction Stop -ErrorVariable GetLabInternetFileErr
}
catch {
    $Message = "Failed to download ADK installer from '{0}' ({1})" -f $ADKURL, $GetLabInternetFileErr.Message
    Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
    throw $Message
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

#region ADK files
Write-ScreenInfo -Message "Downloading ADK files" -TaskStart

if (-not (Test-Path -Path $AdkDownloadPath))
{
    $pArgs = "/quiet /layout {0}" -f $AdkDownloadPath
    try {
        $p = Start-Process -FilePath $ADKExeObj.FullName -ArgumentList $pArgs -PassThru -ErrorAction "Stop" -ErrorVariable StartProcessErr
    }
    catch {
        $Message = "Failed to initiate download of ADK files to '{0}' ({1})" -f $AdkDownloadPath, $StartProcessErr.Message
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
    Write-ScreenInfo -Message "ADK folder does already exist, skipping the download. Delete the folder '$AdkDownloadPath' if you want to download again."
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

#region ADK installer
Write-ScreenInfo -Message "Downloading WinPE installer" -TaskStart

$WinPEExePath = Join-Path -Path $labSources -ChildPath "SoftwarePackages\adkwinpesetup.exe"
if (Test-Path -Path $WinPEExePath) {
    Write-ScreenInfo -Message ("WinPE installer exists, delete '{0}' if you want to download again" -f $WinPEExePath)
}

$WinPEUrl = 'https://go.microsoft.com/fwlink/?linkid=2087112'
try {
    $WinPESetup = Get-LabInternetFile -Uri $WinPEUrl -Path (Split-Path -Path $WinPEExePath -Parent) -FileName (Split-Path -Path $WinPEExePath -Leaf) -PassThru -ErrorAction Stop -ErrorVariable GetLabInternetFileErr
}
catch {
    $Message = "Failed to download WinPE installer from '{0}' ({1})" -f $WinPEUrl, $GetLabInternetFileErr.Message
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
        $p = Start-Process -FilePath $WinPESetup.FullName -ArgumentList "/quiet /layout $WinPEDownloadPath" -PassThru -ErrorAction "Stop" -ErrorVariable StartProcessErr
    }
    catch {
        $Message = "Failed to initiate download of WinPE files to '{0}' ({1})" -f $WinPEDownloadPath, $StartProcessErr.Message
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
    Write-ScreenInfo -Message "WinPE folder does already exist, skipping the download. Delete the folder '$WinPEDownloadPath' if you want to download again."
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

# Workaround because Write-Progress doesn't yet seem to clear up from Get-LabInternetFile
Write-Progress -Activity * -Completed

Write-ScreenInfo -Message "Finished ADK / WinPE download process" -TaskEnd
