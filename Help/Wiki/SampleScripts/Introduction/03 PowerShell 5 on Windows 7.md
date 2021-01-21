# Introduction - 03 PowerShell 5 on Windows 7

INSERT TEXT HERE

```powershell
$labSources = Get-LabSourcesLocation

New-LabDefinition -Name PowerShell7 -DefaultVirtualizationEngine HyperV
Add-LabMachineDefinition -Name Client7 -Memory 1GB -OperatingSystem 'Windows 7 PROFESSIONAL' -ToolsPath $labSources\Tools
Install-Lab

Install-LabSoftwarePackage -Path $labSources\SoftwarePackages\NDP452-KB2901907-x86-x64-AllOS-ENU.exe -CommandLine '/q /log c:\dotnet452.txt' -ComputerName Client7 -AsScheduledJob -UseShellExecute
Restart-LabVM -ComputerName Client7 -Wait

Install-LabSoftwarePackage -Path $labSources\OSUpdates\2008R2\Win7AndW2K8R2-KB3191566-x64.msu -ComputerName Client7 -ExpectedReturnCodes 0, -2146498530
Restart-LabVM -ComputerName Client7 -Wait

Install-LabSoftwarePackage -Path $labSources\SoftwarePackages\Notepad++.exe -ComputerName Client7 -CommandLine /S

Checkpoint-LabVM -All -SnapshotName 1

Show-LabDeploymentSummary -Detailed

```
