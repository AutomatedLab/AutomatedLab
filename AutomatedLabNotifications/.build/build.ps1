# Prepare and write new content to module instead of dot-sourcing
# Get public and private function definition files.
$importFolders = Get-ChildItem "$PSScriptRoot\.." -Include Types, Public, Private -Recurse -Directory -ErrorAction SilentlyContinue

$sb = [System.Text.StringBuilder]::new()
$publicList = [System.Collections.ArrayList]::new()

foreach ($file in (Get-ChildItem -Recurse -Path $importFolders -Filter *.ps1))
{
    if ($file.Directory.Name -eq 'Public')
    {
        $null = $publicList.Add($file.Basename)
    }

    $null = $sb.AppendLine()
    $null = $sb.Append((Get-Content -Raw -Path $file.FullName))
}

$null = $sb.AppendLine()
$null = $sb.AppendLine("Export-ModuleMember -Function $($publicList -join ',')")
$sb.ToString() | Set-Content "$PSScriptRoot\..\AutomatedLabNotifications.psm1"

Update-ModuleManifest -Path "$PSScriptRoot\..\AutomatedLabNotifications.psd1" -FunctionsToExport $publicList
