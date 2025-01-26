# Scenarios - ContosoApp

This sample scenario deploys a complete three-tier ContosoApp environment consisting of four virtual machines joined to a `contoso.local` domain:

| VM | Role |
| --- | --- |
| **DC01** | Domain Controller |
| **SQL01** | SQL Server 2022 |
| **APP01** | Application Server |
| **WEB01** | Web Server with IIS |

## Scripts

The scenario is split into three scripts inside the `ContosoApp` folder:

| Script | Purpose |
| --- | --- |
| `10_New-ContosoLab.ps1` | Creates the lab infrastructure, downloads software packages, installs base software and creates a snapshot. |
| `20_Install-ContosoApp.ps1` | Builds the ContosoApp, sets up the database, deploys the business logic and web application, and verifies the deployment. |
| `Build-ContosoApp.ps1` | Helper script that scaffolds and compiles the .NET 6 ContosoApp (Business Logic class library and ASP.NET Core MVC web application). Called by `20_Install-ContosoApp.ps1`. |

A `readme.md` with detailed step-by-step instructions is included in the folder.

## Prerequisites

- **Hyper-V** enabled
- Windows Server 2025 ISO in `$labSources\ISOs`
- SQL Server 2022 ISO in `$labSources\ISOs` (filename `SQLServer2022-x64-ENU.iso`)
- At least 16 GB RAM and 80 GB free disk space
- Must be run as Administrator

## Usage

```powershell
# Step 1 - Create the lab infrastructure
& "$labSources\SampleScripts\Scenarios\ContosoApp\10_New-ContosoLab.ps1"

# Step 2 - Build and deploy the ContosoApp
& "$labSources\SampleScripts\Scenarios\ContosoApp\20_Install-ContosoApp.ps1"
```

After deployment, connect to **WEB01** and open `http://localhost` to access the ContosoApp web interface.
