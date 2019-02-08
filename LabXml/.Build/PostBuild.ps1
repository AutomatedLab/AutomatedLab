param(
    [Parameter(Mandatory)]
    [string]$SolutionDir,

    [Parameter(Mandatory)]
    [string]$TargetPath,

    [Parameter(Mandatory)]
    [string]$TargetDir
)

Microsoft.PowerShell.Utility\Write-Host "Copy-Item -Path $TargetPath -Destination $SolutionDir\AutomatedLab\AutomatedLab.dll"
Copy-Item -Path $TargetPath -Destination $SolutionDir\AutomatedLab\AutomatedLab.dll

Microsoft.PowerShell.Utility\Write-Host "Copy-Item -Path $TargetPath -Destination $SolutionDir\AutomatedLab\AutomatedLab.dll"
Copy-Item -Path $TargetDir\Microsoft.ApplicationInsights.dll -Destination $SolutionDir\AutomatedLab\Microsoft.ApplicationInsights.dll

Microsoft.PowerShell.Utility\Write-Host "Copy-Item -Path $TargetPath -Destination $SolutionDir\AutomatedLab\AutomatedLab.dll"
Copy-Item -Path $TargetDir\System.Diagnostics.DiagnosticSource.dll -Destination $SolutionDir\AutomatedLab\System.Diagnostics.DiagnosticSource.dll
