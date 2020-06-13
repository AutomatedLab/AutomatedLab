Param (
    [Parameter()]
    [String]$DoNotDownloadWMIEv2
)

$DoNotDownloadWMIEv2 = [Convert]::ToBoolean($DoNotDownloadWMIEv2)

Write-ScreenInfo -Message "Starting miscellaneous items download process" -TaskStart

#region Download Microsoft SQL Server 2012 Native Client QFE
# https://support.microsoft.com/en-us/help/3135244/tls-1-2-support-for-microsoft-sql-server
Write-ScreenInfo -Message "Downloading SQL Native Client" -TaskStart

$SQLNCLIMSIPath = Join-Path -Path $labSources -ChildPath "SoftwarePackages\sqlncli.msi"
if (Test-Path -Path $SQLNCLIMSIPath) {
    Write-ScreenInfo -Message ("SQL Native Client MSI already exists, delete '{0}' if you want to download again" -f $SQLNCLIMSIPath)
}

$URL = "https://download.microsoft.com/download/B/E/D/BED73AAC-3C8A-43F5-AF4F-EB4FEA6C8F3A/ENU/x64/sqlncli.msi"
try {
    Get-LabInternetFile -Uri $URL -Path (Split-Path -Path $SQLNCLIMSIPath) -FileName (Split-Path $SQLNCLIMSIPath -Leaf) -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr"
}
catch {
    $Message = "Failed to download SQL Native Client from '{0}' ({1})" -f $URL, $GetLabInternetFileErr.ErrorRecord.Exception.Message
    Write-ScreenInfo -Message $Message -Type "Error" -TaskEnd
    throw $Message
}
Write-ScreenInfo -Message "Activity Done" -TaskEnd
#endregion

#region Download WMIExplorer v2
if ([bool]$DoNotDownloadWMIEv2 -eq $false) {
    $WMIv2Zip = "{0}\WmiExplorer_2.0.0.2.zip" -f $labSources
    $WMIv2Exe = "{0}\WmiExplorer.exe" -f $labSources
    $URL = "https://github.com/vinaypamnani/wmie2/releases/download/v2.0.0.2/WmiExplorer_2.0.0.2.zip"
    if (-not (Test-Path $WMIv2Zip) -And (-not (Test-Path $WMIv2Exe))) {
        Write-ScreenInfo -Message ("Downloading '{0}' to '{1}'" -f (Split-Path $WMIv2Zip -Leaf), (Split-Path $WMIv2Zip -Parent)) -TaskStart
        try {
            Get-LabInternetFile -Uri $URL -Path (Split-Path -Path $WMIv2Zip -Parent) -FileName (Split-Path -Path $WMIv2Zip -Leaf) -ErrorAction "Stop" -ErrorVariable "GetLabInternetFileErr"
        }
        catch {
            Write-ScreenInfo -Message ("Could not download from '{0}' ({1})" -f $URL, $GetLabInternetFileErr.ErrorRecord.Exception.Message) -Type "Warning"
        }
        if (Test-Path -Path $WMIv2Zip) {
            Expand-Archive -Path $WMIv2Zip -DestinationPath $labSources\Tools -ErrorAction "Stop"
            try {
                Remove-Item -Path $WMIv2Zip -Force -ErrorAction "Stop" -ErrorVariable "RemoveItemErr"
            }
            catch {
                Write-ScreenInfo -Message ("Failed to delete '{0}' ({1})" -f $WMIZip, $RemoveItemErr.ErrorRecord.Exception.Message) -Type "Warning"
            }
        } 
        Write-ScreenInfo -Message "Activity done" -TaskEnd
    }
    else {
        Write-ScreenInfo -Message ("File '{0}' already exists, skipping the download. Delete the file '{0}' if you want to download again." -f $WMIv2Exe)
    }
}
#endregion

Write-ScreenInfo -Message "Finished miscellaneous items download process" -TaskEnd
