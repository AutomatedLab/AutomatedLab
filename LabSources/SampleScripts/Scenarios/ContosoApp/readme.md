# ContosoApp Lab Deployment Guide

This guide walks you through setting up a complete three-tier ContosoApp lab environment using **AutomatedLab**. The environment consists of four virtual machines — a domain controller, a SQL Server, an application server, and a web server — all joined to a `contoso.local` domain.

## Prerequisites

Before you begin, make sure your host meets the following requirements:

- **Operating System**: Windows 10/11 or Windows Server 2019 or later
- **Hyper-V**: Enabled ([Microsoft Docs — Enable Hyper-V](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v))
- **RAM**: At least 16 GB (the lab allocates 10 GB across four VMs)
- **Disk Space**: At least 80 GB free
- **.NET SDK 6.0** installed on the host ([Download .NET 6.0](https://dotnet.microsoft.com/download/dotnet/6.0)) — make sure `dotnet` is available in your system PATH (restart your terminal or VS Code after installation). The file is downloaded when calling script 10_New-ContosoLab.ps1, installing the SDK on the host allows you to build the ContosoApp without errors.
- **PowerShell 5.1** or later (PowerShell 7+ recommended)
- **Administrator privileges** for all steps below

## Step 1 — Install AutomatedLab

Open an **elevated** PowerShell session and install the AutomatedLab module:

```powershell
Install-Module -Name AutomatedLab -Force -AllowClobber
```

## Step 2 — Create the LabSources Folder

AutomatedLab stores ISOs, software packages, and other resources in a central *LabSources* folder. Create it on an appropriate drive:

```powershell
New-LabSourcesFolder -DriveLetter C
```

> **Note:** Adjust the drive letter to match your environment. The command creates the folder structure `C:\LabSources` with subdirectories for ISOs, software packages, and more.

## Step 3 — Download the Required ISO Files

The lab needs two ISO images. Download them from the Microsoft Evaluation Center:

| ISO | Download Link |
| --- | --- |
| Windows Server 2025 | <https://www.microsoft.com/en-us/evalcenter/download-windows-server-2025> |
| SQL Server 2022 | <https://www.microsoft.com/en-us/evalcenter/download-sql-server-2022> |

After downloading, move both ISO files into the LabSources ISOs directory:

```powershell
$downloadFolder = Join-Path -Path $env:USERPROFILE -ChildPath Downloads
Move-Item -Path "$downloadFolder\*.iso" -Destination "$labSources\ISOs"
```

## Step 4 — Verify the ISO Files

Run the following command to confirm that AutomatedLab recognizes the operating systems from the ISOs:

```powershell
Get-LabAvailableOperatingSystem
```

You should see entries for **Windows Server 2025** in various editions (Standard, Datacenter, with and without Desktop Experience). If the list is empty, double-check that the ISO files are in the correct `ISOs` folder.

> **Important:** Note the exact name of the operating system you want to use (for example, `Windows Server 2025 Standard Evaluation (Desktop Experience)`). The deployment script references this name and it must match exactly.

## Step 5 — Enable Lab Host Remoting

AutomatedLab relies on PowerShell Remoting to configure VMs. Enable it with:

```powershell
Enable-LabHostRemoting -Force
```

> Note: If this command crashes in VSCode, try running it in a regular PowerShell terminal. This terminal needs to run with administrator privileges. If you encounter issues with remoting later, re-run this command to ensure remoting is properly configured. You can verify that with `Test-LabHostRemoting`.

## Step 6 — Create the Script Directory

Create a dedicated folder for the deployment scripts and download them from GitHub:

```powershell
$scriptFolder = 'C:\ContosoLabDeploy'
New-Item -Path $scriptFolder -ItemType Directory -Force

$baseUrl = 'https://raw.githubusercontent.com/AutomatedLab/AutomatedLab/refs/heads/master/LabSources/SampleScripts/Scenarios/ContosoApp'
foreach ($file in @('10_New-ContosoLab.ps1', '20_Install-ContosoApp.ps1', 'Build-ContosoApp.ps1')) {
    $content = (Invoke-WebRequest -Uri "$baseUrl/$file" -UseBasicParsing).Content
    Set-Content -Path "$scriptFolder\$file" -Value $content -Encoding UTF8 -NoNewline
}
```

> **Note:** Adjust the path to match your preferred location. The subsequent steps assume the scripts are in this folder.

## Step 7 — Deploy the Lab Infrastructure

Navigate to the script directory created in the previous step and run the infrastructure deployment script. This creates all four VMs, configures the domain, installs SQL Server 2022, sets up IIS on the web server, and installs base software (7-Zip, Notepad++, .NET Framework 4.8):

```powershell
Set-Location -Path $scriptFolder
.\10_New-ContosoLab.ps1
```

**What the script does:**

1. Downloads required software packages (7-Zip, Notepad++, .NET Framework 4.8, .NET 6.0 SDK)
2. Creates the lab definition with four VMs:
   - **DC01** — Domain Controller (`contoso.local`)
   - **SQL01** — SQL Server 2022 (4 GB RAM)
   - **APP01** — Application Server
   - **WEB01** — Web Server with IIS
3. Installs the lab (VM creation, OS installation, domain join, role configuration)
4. Installs base software on all servers except the domain controller
5. Creates a snapshot `AfterLabDeployment` on all VMs

> **Note:** By default, the lab VM disks are stored in `C:\AutomatedLab-VMs`. If you need to change this location (for example, to use a faster or larger drive), adjust the `New-LabDefinition` call in line 79 of `10_New-ContosoLab.ps1` by adding the `-VmPath` parameter.

> **Duration:** Expect 45–90 minutes depending on hardware performance.

## Step 8 — Restart Your Shell

After the lab infrastructure deployment completes, **close your current PowerShell or VS Code window** and open a new one with administrator privileges. This ensures that any environment changes (new modules, updated PATH variables, etc.) made during the deployment are properly loaded before continuing.

## Step 9 — Build and Deploy the ContosoApp

Once the infrastructure is ready, deploy the ContosoApp:

```powershell
.\20_Install-ContosoApp.ps1
```

**What the script does:**

1. Builds the ContosoApp (.NET 6 Business Logic library and ASP.NET Core MVC web application)
2. Installs the .NET 6.0 SDK on the web server (downloaded in Step 7)
3. Creates the `ContosoApp` database on SQL01 with tables and sample data
4. Deploys the business logic component to APP01
5. Configures IIS on WEB01 with Windows Authentication
6. Verifies the deployment (database connectivity and web application health check)

## Verifying the Deployment

After both scripts complete successfully, connect to **WEB01** via Hyper-V Manager or Remote Desktop and open a web browser:

1. Open **Hyper-V Manager** and double-click the **WEB01** VM to open a console session
2. Log in with the domain credentials configured in the lab script (domain `contoso.local`)
3. Open a web browser and navigate to `http://localhost`
4. You should see the ContosoApp start page with a **Products** link in the navigation bar

## Resetting the Lab

If you want to start over with a clean application deployment, restore the snapshot that was created after the infrastructure deployment:

```powershell
Import-Lab -Name WebAppLab -NoValidation
Restore-LabVMSnapshot -All -SnapshotName AfterLabDeployment
```

Then re-run `.\20_Install-ContosoApp.ps1` to deploy the application again.

## Removing the Lab

To completely remove the lab and free all resources:

```powershell
Remove-Lab -Name WebAppLab -Confirm:$false
```

## Troubleshooting

| Symptom | Resolution |
| --- | --- |
| `Get-LabAvailableOperatingSystem` returns no results | Verify ISO files are in the `$labSources\ISOs` folder and are not corrupted |
| VM creation fails with insufficient memory | Close other applications or reduce VM memory in the script |
| SQL Server installation fails | Ensure the SQL Server 2022 ISO filename matches `SQLServer2022-x64-ENU.iso` |
| Web application returns 500 error | Check that the .NET 6.0 SDK installed correctly on WEB01 |
| Script fails with remoting errors | Re-run `Enable-LabHostRemoting -Force` and verify WinRM is running |
| `Build-ContosoApp.ps1` fails with `.NET SDK not found` | Ensure .NET SDK **6.0** (not a newer major version) is installed, and `C:\Program Files\dotnet` is in your system PATH. Restart your terminal after installation. |
