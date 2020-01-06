param(
    [Parameter(Mandatory)]
    [string]$SccmBinariesDirectory,

    [Parameter(Mandatory)]
    [string]$SccmPreReqsDirectory
)

Write-ScreenInfo -Message "Starting CM binaries and prerequisites download process" -TaskStart

#region CM binaries
Write-ScreenInfo -Message "Downloading CM binaries archive" -TaskStart

$CMExePath = Join-Path -Path $labSources -ChildPath "SoftwarePackages\SC_Configmgr_SCEP_1902.exe"
if (Test-Path -Path $CMExePath) {
    Write-ScreenInfo -Message ("CM binaries archive exists, delete '{0}' if you want to download again" -f $CMExePath)
}

$CMURL = 'http://download.microsoft.com/download/1/B/C/1BCADBD7-47F6-40BB-8B1F-0B2D9B51B289/SC_Configmgr_SCEP_1902.exe'
try {
    $CMExeObj = Get-LabInternetFile -Uri $CMURL -Path (Split-Path -Path $CMExePath -Parent) -FileName (Split-Path -Path $CMExePath -Leaf) -PassThru -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr"
}
catch {
    $Message = "Failed to download CM binaries archive from '{0}' ({1})" -f $CMURL, $GetLabInternetFileErr.Message
    Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
    throw $Message
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

#region Extract CM binaries
Write-ScreenInfo -Message "Extracting CM binaries from archive" -TaskStart

if (-not (Test-Path -Path $SccmBinariesDirectory))
{
    $pArgs = '/AUTO "{0}"' -f $SccmBinariesDirectory
    try {
        $p = Start-Process -FilePath $CMExeObj.FullName -ArgumentList $pArgs -PassThru -ErrorAction "Stop" -ErrorVariable "StartProcessErr"
    }
    catch {
        $Message = "Failed to initiate extraction to '{0}' ({1})" -f $SccmBinariesDirectory, $StartProcessErr.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    Write-ScreenInfo -Message "Waiting for extraction to complete"
    while (-not $p.HasExited) {
        Write-ScreenInfo -Message '.' -NoNewLine
        Start-Sleep -Seconds 10
    }
    Write-ScreenInfo -Message '.'
}
else
{
    Write-ScreenInfo -Message ("CM folder does already exist, skipping the download. Delete the folder '{0}' if you want to download again." -f $SccmBinariesDirectory)
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

#region
Write-ScreenInfo -Message "Downloading CM prerequisites" -TaskStart
if (-not (Test-Path -Path $SccmPreReqsDirectory))
{
    try {
        $p = Start-Process -FilePath $SccmBinariesDirectory\SMSSETUP\BIN\X64\setupdl.exe -ArgumentList $SccmPreReqsDirectory -PassThru -ErrorAction "Stop" -ErrorVariable "StartProcessErr"
    }
    catch {
        $Message = "Failed to initiate download of CM pre-req files to '{0}' ({1})" -f $SccmPreReqsDirectory, $StartProcessErr.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
    Write-ScreenInfo -Message "Waiting for CM prerequisites to finish downloading"
    while (-not $p.HasExited) {
        Write-ScreenInfo '.' -NoNewLine
        Start-Sleep -Seconds 10
    }
    Write-ScreenInfo -Message '.'
}
else
{
    Write-ScreenInfo -Message ("CM prerequisites folder does already exist, skipping the download. Delete the folder '{0}' if you want to download again." -f $SccmPreReqsDirectory)
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

# Workaround because Write-Progress doesn't yet seem to clear up from Get-LabInternetFile
Write-Progress -Activity * -Completed

Write-ScreenInfo -Message "Finished CM binaries and prerequisites download process" -TaskEnd