<#
.SYNOPSIS
    Creates the lab infrastructure for the ContosoApp environment.

.DESCRIPTION
    This script uses AutomatedLab to create a complete three-tier infrastructure:
    - Domain Controller (DC01)
    - SQL Server (SQL01)
    - Application Server (APP01)
    - Web Server (WEB01) with IIS

    Additionally, base software (7-Zip, Notepad++, .NET Framework 4.8) is installed
    on all servers (except the DC).

    This script only creates the infrastructure. To deploy the application,
    use 20_Install-ContosoApp.ps1.

.EXAMPLE
    .\10_New-ContosoLab.ps1

    Creates the complete lab with all VMs, roles, and base software.

.NOTES
    Prerequisites:
    - AutomatedLab module installed
    - Hyper-V enabled
    - Windows Server 2025 ISO in $labSources\ISOs
    - SQL Server 2022 ISO in $labSources\ISOs
    - Must be run as Administrator

    Author: AutomatedLab Article Series
    Version: 1.0.0
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

#region 1. Download software packages
Write-Host ('=' * 80) -ForegroundColor Cyan
Write-Host 'Step 1: Download software packages' -ForegroundColor Cyan
Write-Host ('=' * 80) -ForegroundColor Cyan

$downloadFolder = "$labSources\SoftwarePackages"

$7ZipFile = Get-LabInternetFile -Uri 'https://www.7-zip.org/a/7z2408-x64.msi' `
    -Path $downloadFolder -FileName '7z-x64.msi' -PassThru
Write-Host '  ✓ 7-Zip downloaded' -ForegroundColor Green

$NotepadPlusPlusFile = Get-LabInternetFile -Uri 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.7.6/npp.8.7.6.Installer.x64.exe' `
    -Path $downloadFolder -FileName 'Notepad++.exe' -PassThru
Write-Host '  ✓ Notepad++ downloaded' -ForegroundColor Green

$DotNet48File = Get-LabInternetFile -Uri 'https://download.visualstudio.microsoft.com/download/pr/2d6bb6b2-226a-4baa-bdec-798822606ff1/8494001c276a4b96804cde7829c04d7f/ndp48-x86-x64-allos-enu.exe' `
    -Path $downloadFolder -FileName 'ndp48-x86-x64-allos-enu.exe' -PassThru
Write-Host '  ✓ .NET Framework 4.8 downloaded' -ForegroundColor Green

$DotNetSdkFile = Get-LabInternetFile -Uri 'https://builds.dotnet.microsoft.com/dotnet/Sdk/6.0.428/dotnet-sdk-6.0.428-win-x64.exe' `
    -Path $downloadFolder -FileName 'dotnet-sdk-6.0.428-win-x64.exe' -PassThru
Write-Host "  ✓ .NET 6.0 SDK downloaded" -ForegroundColor Green
Write-Host "    Installing .NET 6.0 SDK on host machine..." -ForegroundColor Yellow -NoNewline
Start-Process -FilePath $DotNetSdkFile.FullName -ArgumentList '/q', '/norestart' -Wait
Write-Host "done." -ForegroundColor Yellow

$DotNetHostingFile = Get-LabInternetFile -Uri 'https://aka.ms/dotnet/6.0/dotnet-hosting-win.exe' `
    -Path $downloadFolder -FileName 'dotnet-hosting-6.0-win.exe' -PassThru
Write-Host '  ✓ .NET 6.0 Hosting Bundle downloaded' -ForegroundColor Green
#endregion

Write-Host '✓ All software packages downloaded' -ForegroundColor Green
#endregion

#region 2. Define and create lab
Write-Host ("`n" + ('=' * 80)) -ForegroundColor Cyan
Write-Host 'Step 2: Create lab' -ForegroundColor Cyan
Write-Host ('=' * 80) -ForegroundColor Cyan

New-LabDefinition -Name 'WebAppLab' -DefaultVirtualizationEngine HyperV

# Network
Add-LabVirtualNetworkDefinition -Name 'AppNetzwerk' -AddressSpace '10.0.10.0/24'

# Mount SQL Server ISO
Add-LabIsoImageDefinition -Name SQLServer2022 -Path "$labSources\ISOs\SQLServer2022-x64-ENU.iso"

# Domain Controller
$dcParams = @{
    Name            = 'DC01'
    Memory          = 2GB
    OperatingSystem = 'Windows Server 2025 Standard Evaluation (Desktop Experience)'
    Network         = 'AppNetzwerk'
    Roles           = 'RootDC'
    DomainName      = 'contoso.local'
}
Add-LabMachineDefinition @dcParams

# SQL Server
$sqlParams = @{
    Name            = 'SQL01'
    Memory          = 4GB
    OperatingSystem = 'Windows Server 2025 Standard Evaluation (Desktop Experience)'
    Network         = 'AppNetzwerk'
    Roles           = 'SQLServer2022'
    DomainName      = 'contoso.local'
}
Add-LabMachineDefinition @sqlParams

# Application Server
$appParams = @{
    Name            = 'APP01'
    Memory          = 2GB
    OperatingSystem = 'Windows Server 2025 Standard Evaluation (Desktop Experience)'
    Network         = 'AppNetzwerk'
    DomainName      = 'contoso.local'
}
Add-LabMachineDefinition @appParams

# Web Server
$webParams = @{
    Name            = 'WEB01'
    Memory          = 2GB
    OperatingSystem = 'Windows Server 2025 Standard Evaluation (Desktop Experience)'
    Network         = 'AppNetzwerk'
    Roles           = 'WebServer'
    DomainName      = 'contoso.local'
}
Add-LabMachineDefinition @webParams

# Install the lab
Install-Lab
Write-Host '✓ Lab successfully created' -ForegroundColor Green
#endregion

#region 3. Install base software
Write-Host ("`n" + ('=' * 80)) -ForegroundColor Cyan
Write-Host 'Step 3: Install base software' -ForegroundColor Cyan
Write-Host ('=' * 80) -ForegroundColor Cyan

# Install software on all servers
$allServers = Get-LabVM | Where-Object { $_.Name -ne 'DC01' }

$basicSoftware = @(
    @{Name = '7-Zip'; Path = $7ZipFile.FullName; Args = '/quiet' },
    @{Name = 'Notepad++'; Path = $NotepadPlusPlusFile.FullName; Args = '/S' },
    @{Name = '.NET 4.8'; Path = $DotNet48File.FullName; Args = '/q /norestart' }
)

foreach ($sw in $basicSoftware) {
    Write-Host "Installing $($sw.Name)..." -ForegroundColor Yellow
    Install-LabSoftwarePackage -Path $sw.Path -CommandLine $sw.Args -ComputerName $allServers -AsScheduledJob -UseShellExecute
    Write-Host "  ✓ $($sw.Name) installed" -ForegroundColor Green
}
#endregion

#region 4. Create snapshot
Write-Host ("`n" + ('=' * 80)) -ForegroundColor Cyan
Write-Host 'Step 4: Create snapshot of all VMs' -ForegroundColor Cyan
Write-Host ('=' * 80) -ForegroundColor Cyan

Checkpoint-LabVM -All -SnapshotName 'AfterLabDeployment'
Write-Host "✓ Snapshot 'AfterLabDeployment' created for all VMs" -ForegroundColor Green
#endregion

Write-Host ("`n" + ('=' * 80)) -ForegroundColor Green
Write-Host '✓ LAB INFRASTRUCTURE SUCCESSFULLY CREATED' -ForegroundColor Green
Write-Host ('=' * 80) -ForegroundColor Green
Write-Host ''
Write-Host 'Next step: Run .\20_Install-ContosoApp.ps1 to deploy the application.' -ForegroundColor Yellow
