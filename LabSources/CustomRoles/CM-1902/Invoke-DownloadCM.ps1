Param (
    [Parameter(Mandatory)]
    [string]$CMBinariesDirectory,

    [Parameter(Mandatory)]
    [string]$CMPreReqsDirectory
)

Write-ScreenInfo -Message "Starting CM binaries and prerequisites download process" -TaskStart

#region CM binaries
Write-ScreenInfo -Message "Downloading CM binaries archive" -TaskStart

$CMZipPath = Join-Path -Path $labSources -ChildPath "SoftwarePackages\SC_Configmgr_SCEP_1902.zip"
if (Test-Path -Path $CMZipPath) {
    Write-ScreenInfo -Message ("CM binaries archive already exists, delete '{0}' if you want to download again" -f $CMZipPath)
}

$URL = 'http://download.microsoft.com/download/1/B/C/1BCADBD7-47F6-40BB-8B1F-0B2D9B51B289/SC_Configmgr_SCEP_1902.exe'
try {
    $CMZipObj = Get-LabInternetFile -Uri $URL -Path (Split-Path -Path $CMZipPath -Parent) -FileName (Split-Path -Path $CMZipPath -Leaf) -PassThru -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr"
}
catch {
    $Message = "Failed to download CM binaries archive from '{0}' ({1})" -f $URL, $GetLabInternetFileErr.ErrorRecord.Exception.Message
    Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
    throw $Message
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

#region Extract CM binaries
Write-ScreenInfo -Message "Extracting CM binaries from archive" -TaskStart

if (-not (Test-Path -Path $CMBinariesDirectory))
{
    try {
        Expand-Archive -Path $CMZipObj.FullName -DestinationPath $CMBinariesDirectory -Force -ErrorAction "Stop" -ErrorVariable "ExpandArchiveErr"
    }
    catch {
        $Message = "Failed to initiate extraction to '{0}' ({1})" -f $CMBinariesDirectory, $ExpandArchiveErr.ErrorRecord.Exception.Message
        Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
        throw $Message
    }
}
else
{
    Write-ScreenInfo -Message ("CM folder already exists, skipping the download. Delete the folder '{0}' if you want to download again." -f $CMBinariesDirectory)
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

#region
Write-ScreenInfo -Message "Downloading CM prerequisites" -TaskStart
if (-not (Test-Path -Path $CMPreReqsDirectory))
{
    try {
        $p = Start-Process -FilePath $CMBinariesDirectory\SMSSETUP\BIN\X64\setupdl.exe -ArgumentList "/NOUI", $CMPreReqsDirectory -PassThru -ErrorAction "Stop" -ErrorVariable "StartProcessErr"
    }
    catch {
        $Message = "Failed to initiate download of CM pre-req files to '{0}' ({1})" -f $CMPreReqsDirectory, $StartProcessErr.ErrorRecord.Exception.Message
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
    Write-ScreenInfo -Message ("CM prerequisites folder already exists, skipping the download. Delete the folder '{0}' if you want to download again." -f $CMPreReqsDirectory)
}

Write-ScreenInfo -Message "Activity done" -TaskEnd
#endregion

# Workaround because Write-Progress doesn't yet seem to clear up from Get-LabInternetFile
Write-Progress -Activity * -Completed

Write-ScreenInfo -Message "Finished CM binaries and prerequisites download process" -TaskEnd
