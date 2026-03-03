<#
.SYNOPSIS
    Builds and deploys the ContosoApp to the lab VMs.

.DESCRIPTION
    This script performs all steps to deploy the ContosoApp in an existing
    lab environment:
    - Builds the ContosoApp (Business Logic and Web Application)
    - Sets up the SQL Server database
    - Deploys the Business Logic component to the Application Server
    - Installs the .NET Hosting Bundle and configures IIS on the Web Server
    - Deploys the Web Application to the Web Server
    - Verifies the deployment

    Can be run repeatedly to redeploy the application.
    Requires that the lab was created with 10_New-ContosoLab.ps1.

.EXAMPLE
    .\20_Install-ContosoApp.ps1

    Builds and deploys the ContosoApp to the existing lab.

.NOTES
    Prerequisites:
    - Lab "WebAppLab" must exist (see New-ContosoLab.ps1)
    - .NET SDK 6.0 or later installed (on the host)
    - AutomatedLab module installed

    Author: AutomatedLab Article Series
    Version: 1.0.0
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Ensure the lab is imported
if (-not (Get-Lab -ErrorAction SilentlyContinue)) {
    Import-Lab -Name 'WebAppLab' -NoValidation
}

#region 1. Create ContosoApp demo application
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "Step 1: Build ContosoApp" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

& "$PSScriptRoot\Build-ContosoApp.ps1" -ProjectPath "$PSScriptRoot\ContosoApp"
Write-Host "✓ ContosoApp successfully created" -ForegroundColor Green
#endregion

#region 3. Set up database
Write-Host ("`n" + ("=" * 80)) -ForegroundColor Cyan
Write-Host "Step 3: Configure SQL Server" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

Invoke-LabCommand -ActivityName 'Create database and schema' -ComputerName SQL01 -ScriptBlock {
    $dbScript = @"
    -- Create database only if it does not exist
    IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ContosoApp')
    BEGIN
        CREATE DATABASE ContosoApp;
    END
    GO
    
    USE ContosoApp;
    GO

    -- Categories table
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categories')
    BEGIN
        CREATE TABLE Categories (
            CategoryID INT PRIMARY KEY IDENTITY(1,1),
            CategoryName NVARCHAR(100) NOT NULL
        );
    END

    -- Products table (with all columns expected by the application)
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Products')
    BEGIN
        CREATE TABLE Products (
            ProductID INT PRIMARY KEY IDENTITY(1,1),
            ProductName NVARCHAR(100) NOT NULL,
            Description NVARCHAR(500) NULL,
            Price DECIMAL(10,2) NOT NULL,
            Stock INT DEFAULT 0,
            CategoryID INT NULL FOREIGN KEY REFERENCES Categories(CategoryID),
            CreatedDate DATETIME2 DEFAULT GETDATE(),
            ModifiedDate DATETIME2 DEFAULT GETDATE(),
            IsActive BIT DEFAULT 1
        );
    END
    
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Orders')
    BEGIN
        CREATE TABLE Orders (
            OrderID INT PRIMARY KEY IDENTITY(1,1),
            ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
            Quantity INT NOT NULL,
            OrderDate DATETIME2 DEFAULT GETDATE()
        );
    END

    -- Insert categories (only if empty)
    IF NOT EXISTS (SELECT 1 FROM Categories)
    BEGIN
        INSERT INTO Categories (CategoryName) VALUES
            ('Computer & Laptops'),
            ('Accessories'),
            ('Netzwerk');
    END
    
    -- Insert test data (only if empty)
    IF NOT EXISTS (SELECT 1 FROM Products)
    BEGIN
        INSERT INTO Products (ProductName, Description, Price, Stock, CategoryID) VALUES
            ('Laptop Pro', 'High-performance business laptop with 16GB RAM', 1299.99, 15, 1),
            ('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 50, 2),
            ('USB-C Hub', '7-in-1 USB-C docking station', 49.99, 30, 2);
    END
    
    -- Grant domain administrator access
    IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'CONTOSO\Administrator')
        CREATE LOGIN [CONTOSO\Administrator] FROM WINDOWS;

    -- Create user in database context or repair
    -- If the login is already mapped as dbo, no separate user is needed
    BEGIN TRY
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'CONTOSO\Administrator' AND type IN ('U','G'))
            CREATE USER [CONTOSO\Administrator] FOR LOGIN [CONTOSO\Administrator];

        ALTER ROLE db_datareader ADD MEMBER [CONTOSO\Administrator];
        ALTER ROLE db_datawriter ADD MEMBER [CONTOSO\Administrator];
    END TRY
    BEGIN CATCH
        PRINT 'Note: ' + ERROR_MESSAGE() + ' - Login is probably already mapped as dbo.';
    END CATCH

    GO
"@
    
    Invoke-Sqlcmd -Query $dbScript -ServerInstance $env:COMPUTERNAME
    Write-Host "✓ Database ContosoApp created and initialized"
}

Write-Host "✓ SQL Server configured" -ForegroundColor Green
#endregion

#region 4. Configure Application Tier
Write-Host ("`n" + ("=" * 80)) -ForegroundColor Cyan
Write-Host "Step 4: Configure Application Server" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$appServers = Get-LabVM | Where-Object { $_.Name -like "APP*" }

# Create application directory
Invoke-LabCommand -ActivityName 'Create application directory' -ComputerName $appServers -ScriptBlock {
    New-Item -Path "C:\ContosoApp" -ItemType Directory -Force | Out-Null
    Write-Host "Directory C:\ContosoApp created"
}

# Copy application files
Copy-LabFileItem -Path "$PSScriptRoot\ContosoApp\ContosoApp.BusinessLogic\ContosoApp.BusinessLogic\bin\Release\net6.0\*" -ComputerName $appServers -DestinationFolderPath "C:\ContosoApp" -Recurse

# Create configuration file
$connectionString = "Server=SQL01.contoso.local;Database=ContosoApp;User Id=ContosoAppUser;Password=Secure!Pass123;"

Invoke-LabCommand -ActivityName 'Create app configuration' -ComputerName $appServers -ScriptBlock {
    $configContent = @"
{
    "ConnectionStrings": {
        "DefaultConnection": "$connectionString"
    },
    "AppSettings": {
        "Environment": "Development",
        "LogLevel": "Debug"
    }
}
"@
    
    $configContent | Out-File "C:\ContosoApp\appsettings.json" -Encoding UTF8
    Write-Host "Configuration file created"
} -Variable (Get-Variable connectionString)

Write-Host "✓ Application Server configured" -ForegroundColor Green
#endregion

#region 5. Configure Web Tier
Write-Host ("`n" + ("=" * 80)) -ForegroundColor Cyan
Write-Host "Step 5: Configure web server" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$webServers = Get-LabVM | Where-Object { $_.Name -like "WEB*" }

# Install additional IIS features
Invoke-LabCommand -ActivityName 'Install IIS features' -ComputerName $webServers -ScriptBlock {
    $features = @('Web-Asp-Net45', 'Web-Net-Ext45', 'Web-ISAPI-Ext', 'Web-ISAPI-Filter', 'Web-Windows-Auth')
    Install-WindowsFeature -Name $features
}

# .NET 6.0 Hosting Bundle (installs ASP.NET Core runtime + IIS ANCM module)
# The Hosting Bundle is downloaded in 10_New-ContosoLab.ps1
# OPT_NO_SHARED_CONFIG_CHECK=1 prevents errors with Shared Config
Install-LabSoftwarePackage -Path "$labSources\SoftwarePackages\dotnet-hosting-6.0-win.exe" `
    -CommandLine '/quiet /norestart OPT_NO_SHARED_CONFIG_CHECK=1' -ComputerName $webServers

# Register ANCM module and restart IIS
Invoke-LabCommand -ActivityName 'Register ASP.NET Core module and restart IIS' -ComputerName $webServers -ScriptBlock {
    # Check if AspNetCoreModuleV2 is registered
    $ancmPath = "$env:ProgramFiles\IIS\Asp.Net Core Module\V2\aspnetcorev2.dll"
    if (Test-Path $ancmPath) {
        # Register module in IIS if not present
        $modules = & "$env:windir\system32\inetsrv\appcmd.exe" list module /name:AspNetCoreModuleV2
        if (-not $modules) {
            & "$env:windir\system32\inetsrv\appcmd.exe" install module /name:AspNetCoreModuleV2 /image:$ancmPath
            Write-Host "✓ AspNetCoreModuleV2 manually registered"
        } else {
            Write-Host "✓ AspNetCoreModuleV2 already registered"
        }
    } else {
        Write-Warning "AspNetCoreModuleV2 DLL not found at $ancmPath"
    }
    & iisreset /restart | Out-Null
    Write-Host "✓ IIS restarted"
}

# Deploy web application
Copy-LabFileItem -Path "$PSScriptRoot\ContosoApp\ContosoWebApp\published\*" -ComputerName $webServers -DestinationFolderPath "C:\inetpub\ContosoWebApp" -Recurse

# Configure IIS site
$appServerUrl = "http://APP01.contoso.local:8080"

Invoke-LabCommand -ActivityName 'Set up IIS site' -ComputerName $webServers -ScriptBlock {
    Import-Module WebAdministration
    
    # Stop default site
    Stop-Website -Name "Default Web Site"
    
    # Create Application Pool (only if not present)
    if (-not (Test-Path "IIS:\AppPools\ContosoWebApp")) {
        New-WebAppPool -Name 'ContosoWebApp'
    }
    Set-ItemProperty "IIS:\AppPools\ContosoWebApp" -Name managedRuntimeVersion -Value ''
    
    # Create or update site
    $existingSite = Get-Website -Name 'ContosoWebApp' -ErrorAction SilentlyContinue
    if ($existingSite) {
        # On redeployment: stop site, update, start
        Stop-Website -Name 'ContosoWebApp' -ErrorAction SilentlyContinue
        Set-ItemProperty "IIS:\Sites\ContosoWebApp" -Name physicalPath -Value 'C:\inetpub\ContosoWebApp'
        Start-Website -Name 'ContosoWebApp'
    } else {
        New-Website -Name 'ContosoWebApp' -PhysicalPath 'C:\inetpub\ContosoWebApp' -Port 80 -ApplicationPool 'ContosoWebApp' -Force
    }

    # Unlock authentication sections at server level to allow site-level override
    & "$env:windir\system32\inetsrv\appcmd.exe" unlock config -section:system.webServer/security/authentication/windowsAuthentication | Out-Null
    & "$env:windir\system32\inetsrv\appcmd.exe" unlock config -section:system.webServer/security/authentication/anonymousAuthentication | Out-Null

    # Enable Windows Authentication, disable Anonymous
    Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/windowsAuthentication' `
        -Name 'enabled' -Value $true -PSPath 'IIS:\' -Location 'ContosoWebApp'
    Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication' `
        -Name 'enabled' -Value $false -PSPath 'IIS:\' -Location 'ContosoWebApp'
    
    Write-Host "✓ IIS site ContosoWebApp configured (Windows Authentication)"
} -Variable (Get-Variable appServerUrl)

Write-Host "✓ Web server configured" -ForegroundColor Green

# Create desktop shortcut
Invoke-LabCommand -ActivityName 'Create desktop shortcut' -ComputerName WEB01 -ScriptBlock {
    $desktopPath = [Environment]::GetFolderPath('CommonDesktopDirectory')
    $shortcutPath = Join-Path -Path $desktopPath -ChildPath 'ContosoApp.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = 'http://localhost'
    $shortcut.IconLocation = 'shell32.dll,14'
    $shortcut.Description = 'ContosoApp Web Application'
    $shortcut.Save()
    Write-Host "✓ Desktop shortcut created: $shortcutPath"
}
Write-Host "✓ Desktop shortcut on WEB01 created" -ForegroundColor Green
#endregion

#region 6. Verify deployment
Write-Host ("`n" + ("=" * 80)) -ForegroundColor Cyan
Write-Host "Step 6: Verify deployment" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# Test database connection
Invoke-LabCommand -ActivityName 'Test database connection' -ComputerName SQL01 -ScriptBlock {
    $result = Invoke-Sqlcmd -Query "SELECT COUNT(*) AS ProductCount FROM ContosoApp.dbo.Products" -ServerInstance $env:COMPUTERNAME
    Write-Host "Number of products in database: $($result.ProductCount)"
}

# Test web application
Invoke-LabCommand -ActivityName 'Test web application' -ComputerName $webServers -ScriptBlock {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing -UseDefaultCredentials
        Write-Host "✓ Web application responds with status: $($response.StatusCode)"
    } catch {
        Write-Warning "✗ Web application not reachable: $_"
    }
}

Write-Host ("`n" + ("=" * 80)) -ForegroundColor Green
Write-Host "✓ DEPLOYMENT SUCCESSFULLY COMPLETED" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Green
Write-Host ""
#endregion

#region 7. Create snapshot
Write-Host ("`n" + ("=" * 80)) -ForegroundColor Cyan
Write-Host "Step 7: Create snapshot" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

Checkpoint-LabVM -All -SnapshotName 'AfterAppDeployment'
Write-Host "✓ Snapshot 'AfterAppDeployment' created on all VMs" -ForegroundColor Green
#endregion
