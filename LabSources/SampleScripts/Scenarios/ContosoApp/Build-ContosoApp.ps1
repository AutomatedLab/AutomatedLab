<#
.SYNOPSIS
    Automatic build script for the ContosoApp demo application

.DESCRIPTION
    This script automatically creates the entire ContosoApp application:
    - Directory structure
    - Database scripts
    - Business Logic component (.NET Class Library)
    - Web application (ASP.NET Core MVC)
    - Deployment scripts
    
    After successful completion, the application is ready for AutomatedLab deployment.

.PARAMETER ProjectPath
    Base path for the project (default: .\ContosoApp in the current directory)

.PARAMETER SkipDotnetRestore
    Skips 'dotnet restore' (useful for offline environments)

.EXAMPLE
    .\Build-ContosoApp.ps1
    
.EXAMPLE
    .\Build-ContosoApp.ps1 -ProjectPath "C:\Dev\ContosoApp"

.NOTES
    Prerequisites:
    - .NET SDK 6.0 or later installed
    - PowerShell 5.1 or later
    - Running as Administrator not required
    
    Author: AutomatedLab Article Series
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ProjectPath = ".\ContosoApp",
    
    [Parameter()]
    [switch]$SkipDotnetRestore
)

#region Helper functions
function Write-Step {
    param([string]$Message)
    Write-Host "`n$("=" * 80)" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host $("=" * 80) -ForegroundColor Cyan
}

function Write-SubStep {
    param([string]$Message)
    Write-Host "`n  → $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "  ℹ $Message" -ForegroundColor Cyan
}

function Test-DotnetInstalled {
    try {
        $version = dotnet --version 2>$null
        if ($version) {
            Write-Success ".NET SDK version $version found"
            return $true
        }
    } catch {
        Write-Failure ".NET SDK not found"
        Write-Info "Please install the .NET SDK from: https://dotnet.microsoft.com/download"
        return $false
    }
    return $false
}
#endregion

#region Main script
$ErrorActionPreference = "Stop"
$originalLocation = Get-Location
$startTime = Get-Date

Write-Host @"

╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                     ContosoApp Automatic Build                            ║
║                                                                               ║
║  This script creates the complete ContosoApp demo application              ║
║  for AutomatedLab deployment.                                              ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Info "Project path: $ProjectPath"
Write-Info "Start time: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))"

#region Check prerequisites
Write-Step "Step 1: Check prerequisites"

if (-not (Test-DotnetInstalled)) {
    Write-Failure "Build aborted: .NET SDK required"
    exit 1
}

Write-Success "All prerequisites met"
#endregion

#region Create directory structure
Write-Step "Step 2: Create directory structure"

$directories = @(
    $ProjectPath,
    "$ProjectPath\ContosoApp.BusinessLogic",
    "$ProjectPath\ContosoApp.BusinessLogic\ContosoApp.BusinessLogic",
    "$ProjectPath\ContosoApp.BusinessLogic\ContosoApp.BusinessLogic\Models",
    "$ProjectPath\ContosoApp.BusinessLogic\ContosoApp.BusinessLogic\Data",
    "$ProjectPath\ContosoWebApp",
    "$ProjectPath\ContosoWebApp\ContosoWebApp",
    "$ProjectPath\ContosoWebApp\ContosoWebApp\Controllers",
    "$ProjectPath\ContosoWebApp\ContosoWebApp\Views",
    "$ProjectPath\ContosoWebApp\ContosoWebApp\Views\Products",
    "$ProjectPath\DatabaseScripts",
    "$ProjectPath\DeploymentScripts"
)

foreach ($dir in $directories) {
    try {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Success "Created: $($dir.Replace($ProjectPath, '.'))"
        } else {
            Write-Info "Already exists: $($dir.Replace($ProjectPath, '.'))"
        }
    } catch {
        Write-Failure "Error creating $dir : $_"
        throw
    }
}

Write-Success "Directory structure successfully created"
#endregion

#region Create database script
Write-Step "Step 3: Create database script"

$dbScriptPath = "$ProjectPath\DatabaseScripts\01-CreateDatabase.sql"
$dbScript = @'
-- =============================================
-- ContosoApp Database Creation
-- Version: 1.0
-- =============================================

USE master;
GO

-- Create database (if not exists)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ContosoApp')
BEGIN
    CREATE DATABASE ContosoApp;
    PRINT 'Database ContosoApp created.';
END
ELSE
BEGIN
    PRINT 'Database ContosoApp already exists.';
END
GO

USE ContosoApp;
GO

-- =============================================
-- Create tables
-- =============================================

-- Table: Products
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Products')
BEGIN
    CREATE TABLE Products (
        ProductID INT PRIMARY KEY IDENTITY(1,1),
        ProductName NVARCHAR(100) NOT NULL,
        Description NVARCHAR(500),
        Price DECIMAL(10,2) NOT NULL,
        Stock INT DEFAULT 0,
        CategoryID INT,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE(),
        IsActive BIT DEFAULT 1
    );
    PRINT 'Table Products created.';
END
GO

-- Table: Categories
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categories')
BEGIN
    CREATE TABLE Categories (
        CategoryID INT PRIMARY KEY IDENTITY(1,1),
        CategoryName NVARCHAR(50) NOT NULL,
        Description NVARCHAR(200)
    );
    PRINT 'Table Categories created.';
    
    ALTER TABLE Products 
    ADD CONSTRAINT FK_Products_Categories 
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID);
END
GO

-- Table: Orders
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Orders')
BEGIN
    CREATE TABLE Orders (
        OrderID INT PRIMARY KEY IDENTITY(1,1),
        CustomerName NVARCHAR(100) NOT NULL,
        CustomerEmail NVARCHAR(100),
        OrderDate DATETIME2 DEFAULT GETDATE(),
        TotalAmount DECIMAL(10,2) NOT NULL,
        Status NVARCHAR(20) DEFAULT 'Pending',
        ShippingAddress NVARCHAR(200)
    );
    PRINT 'Table Orders created.';
END
GO

-- Table: OrderItems
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'OrderItems')
BEGIN
    CREATE TABLE OrderItems (
        OrderItemID INT PRIMARY KEY IDENTITY(1,1),
        OrderID INT NOT NULL,
        ProductID INT NOT NULL,
        Quantity INT NOT NULL,
        UnitPrice DECIMAL(10,2) NOT NULL,
        CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
        CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
    );
    PRINT 'Table OrderItems created.';
END
GO

-- =============================================
-- Insert test data
-- =============================================

IF NOT EXISTS (SELECT * FROM Categories)
BEGIN
    INSERT INTO Categories (CategoryName, Description) VALUES
        ('Computer', 'Desktop and laptop computers'),
        ('Accessories', 'Computer accessories and peripherals'),
        ('Software', 'Software licenses and subscriptions'),
        ('Networking', 'Network hardware and components');
    PRINT 'Categories inserted.';
END
GO

IF NOT EXISTS (SELECT * FROM Products)
BEGIN
    INSERT INTO Products (ProductName, Description, Price, Stock, CategoryID) VALUES
        ('Laptop Pro 15"', 'High-performance laptop with 15" display', 1299.99, 15, 1),
        ('Desktop Workstation', 'Professional workstation for CAD/design', 2499.99, 8, 1),
        ('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 50, 2),
        ('USB-C Hub', 'Multi-function hub with 7 ports', 49.99, 30, 2),
        ('Mechanical Keyboard', 'RGB keyboard with mechanical switches', 129.99, 25, 2),
        ('27" 4K Monitor', 'UHD monitor with HDR support', 599.99, 12, 2),
        ('Office Suite License', 'Annual license for office suite', 149.99, 100, 3),
        ('Antivirus Pro', '3-year license for 5 devices', 89.99, 200, 3),
        ('Gigabit Switch 24-Port', 'Managed switch for enterprises', 349.99, 10, 4),
        ('WiFi 6 Router', 'High-speed WiFi router', 179.99, 20, 4);
    PRINT 'Products inserted.';
END
GO

IF NOT EXISTS (SELECT * FROM Orders)
BEGIN
    INSERT INTO Orders (CustomerName, CustomerEmail, OrderDate, TotalAmount, Status, ShippingAddress) VALUES
        ('Max Mustermann', 'max@example.com', GETDATE()-7, 1379.98, 'Completed', 'Sample St. 1, 12345 Sample City'),
        ('Erika Musterfrau', 'erika@example.com', GETDATE()-3, 179.99, 'Shipped', 'Example Way 5, 54321 Example City'),
        ('Hans Schmidt', 'hans@example.com', GETDATE()-1, 949.97, 'Processing', 'Test Square 10, 99999 Test Town');
    PRINT 'Orders inserted.';
    
    INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice) VALUES
        (1, 1, 1, 1299.99), (1, 3, 1, 29.99), (1, 4, 1, 49.99),
        (2, 10, 1, 179.99),
        (3, 5, 2, 129.99), (3, 6, 1, 599.99), (3, 3, 3, 29.99);
    PRINT 'Order items inserted.';
END
GO

-- =============================================
-- Stored Procedures
-- =============================================

IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'GetProductsByCategory')
    DROP PROCEDURE GetProductsByCategory;
GO

CREATE PROCEDURE GetProductsByCategory
    @CategoryID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.ProductID, p.ProductName, p.Description, p.Price, p.Stock,
           c.CategoryName, p.IsActive
    FROM Products p
    INNER JOIN Categories c ON p.CategoryID = c.CategoryID
    WHERE p.CategoryID = @CategoryID AND p.IsActive = 1
    ORDER BY p.ProductName;
END
GO

IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'CreateOrder')
    DROP PROCEDURE CreateOrder;
GO

CREATE PROCEDURE CreateOrder
    @CustomerName NVARCHAR(100),
    @CustomerEmail NVARCHAR(100),
    @ShippingAddress NVARCHAR(200),
    @OrderID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Orders (CustomerName, CustomerEmail, ShippingAddress, TotalAmount, Status)
    VALUES (@CustomerName, @CustomerEmail, @ShippingAddress, 0.00, 'Pending');
    SET @OrderID = SCOPE_IDENTITY();
END
GO

PRINT '=============================================';
PRINT 'ContosoApp database successfully set up!';
PRINT '=============================================';
GO
'@

try {
    $dbScript | Out-File -FilePath $dbScriptPath -Encoding UTF8 -Force
    Write-Success "Database script created: .\DatabaseScripts\01-CreateDatabase.sql"
    Write-Info "Size: $([math]::Round((Get-Item $dbScriptPath).Length / 1KB, 2)) KB"
} catch {
    Write-Failure "Error creating database script: $_"
    throw
}
#endregion

#region Create Business Logic project
Write-Step "Step 4: Create Business Logic component"

Set-Location "$ProjectPath\ContosoApp.BusinessLogic"

Write-SubStep "Create .NET Class Library project"
try {
    $output = dotnet new classlib -n ContosoApp.BusinessLogic -f net6.0 --force 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Class Library project created"
    } else {
        Write-Failure "Error creating the project"
        Write-Host $output
        throw "dotnet new failed"
    }
} catch {
    Write-Failure "Error: $_"
    throw
}

Set-Location "ContosoApp.BusinessLogic"

Write-SubStep "Add NuGet packages"
try {
    dotnet add package System.Data.SqlClient --version 4.8.5 --no-restore | Out-Null
    Write-Success "System.Data.SqlClient added"
    
    dotnet add package Newtonsoft.Json --version 13.0.3 --no-restore | Out-Null
    Write-Success "Newtonsoft.Json added"
} catch {
    Write-Failure "Error adding NuGet packages: $_"
    throw
}

Write-SubStep "Create model classes"

# Product.cs
$productCs = @'
using System;

namespace ContosoApp.BusinessLogic.Models
{
    public class Product
    {
        public int ProductID { get; set; }
        public string ProductName { get; set; }
        public string Description { get; set; }
        public decimal Price { get; set; }
        public int Stock { get; set; }
        public int? CategoryID { get; set; }
        public string CategoryName { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime ModifiedDate { get; set; }
        public bool IsActive { get; set; }
    }
}
'@

$productCs | Out-File -FilePath "Models\Product.cs" -Encoding UTF8 -Force
Write-Success "Models\Product.cs created"

# Order.cs
$orderCs = @'
using System;
using System.Collections.Generic;

namespace ContosoApp.BusinessLogic.Models
{
    public class Order
    {
        public int OrderID { get; set; }
        public string CustomerName { get; set; }
        public string CustomerEmail { get; set; }
        public DateTime OrderDate { get; set; }
        public decimal TotalAmount { get; set; }
        public string Status { get; set; }
        public string ShippingAddress { get; set; }
        public List<OrderItem> Items { get; set; } = new List<OrderItem>();
    }

    public class OrderItem
    {
        public int OrderItemID { get; set; }
        public int OrderID { get; set; }
        public int ProductID { get; set; }
        public string ProductName { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal TotalPrice => Quantity * UnitPrice;
    }
}
'@

$orderCs | Out-File -FilePath "Models\Order.cs" -Encoding UTF8 -Force
Write-Success "Models\Order.cs created"

Write-SubStep "Create Data Access Layer"

# DatabaseConnection.cs
$dbConnectionCs = @'
using System.Data.SqlClient;
using Newtonsoft.Json.Linq;
using System;
using System.IO;

namespace ContosoApp.BusinessLogic.Data
{
    public class DatabaseConnection
    {
        private static string _connectionString;

        public static string ConnectionString
        {
            get
            {
                if (string.IsNullOrEmpty(_connectionString))
                {
                    LoadConnectionString();
                }
                return _connectionString;
            }
            set { _connectionString = value; }
        }

        private static void LoadConnectionString()
        {
            try
            {
                string configPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "appsettings.json");
                
                if (File.Exists(configPath))
                {
                    string json = File.ReadAllText(configPath);
                    JObject config = JObject.Parse(json);
                    _connectionString = config["ConnectionStrings"]["DefaultConnection"].ToString();
                }
                else
                {
                    _connectionString = "Server=localhost;Database=ContosoApp;Integrated Security=true;";
                }
            }
            catch (Exception ex)
            {
                throw new Exception("Error loading connection string: " + ex.Message);
            }
        }

        public static SqlConnection GetConnection()
        {
            return new SqlConnection(ConnectionString);
        }
    }
}
'@

$dbConnectionCs | Out-File -FilePath "Data\DatabaseConnection.cs" -Encoding UTF8 -Force
Write-Success "Data\DatabaseConnection.cs created"

# ProductRepository.cs
$productRepoCs = @'
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using ContosoApp.BusinessLogic.Models;

namespace ContosoApp.BusinessLogic.Data
{
    public class ProductRepository
    {
        public List<Product> GetAllProducts()
        {
            var products = new List<Product>();

            using (var conn = DatabaseConnection.GetConnection())
            {
                conn.Open();
                string query = @"
                    SELECT p.ProductID, p.ProductName, p.Description, p.Price, p.Stock, 
                           p.CategoryID, c.CategoryName, p.CreatedDate, p.ModifiedDate, p.IsActive
                    FROM Products p
                    LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
                    WHERE p.IsActive = 1
                    ORDER BY p.ProductName";

                using (var cmd = new SqlCommand(query, conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        products.Add(new Product
                        {
                            ProductID = reader.GetInt32(0),
                            ProductName = reader.GetString(1),
                            Description = reader.IsDBNull(2) ? "" : reader.GetString(2),
                            Price = reader.GetDecimal(3),
                            Stock = reader.GetInt32(4),
                            CategoryID = reader.IsDBNull(5) ? (int?)null : reader.GetInt32(5),
                            CategoryName = reader.IsDBNull(6) ? "" : reader.GetString(6),
                            CreatedDate = reader.GetDateTime(7),
                            ModifiedDate = reader.GetDateTime(8),
                            IsActive = reader.GetBoolean(9)
                        });
                    }
                }
            }

            return products;
        }

        public Product GetProductById(int productId)
        {
            Product product = null;

            using (var conn = DatabaseConnection.GetConnection())
            {
                conn.Open();
                string query = @"
                    SELECT p.ProductID, p.ProductName, p.Description, p.Price, p.Stock, 
                           p.CategoryID, c.CategoryName, p.CreatedDate, p.ModifiedDate, p.IsActive
                    FROM Products p
                    LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
                    WHERE p.ProductID = @ProductID";

                using (var cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@ProductID", productId);

                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            product = new Product
                            {
                                ProductID = reader.GetInt32(0),
                                ProductName = reader.GetString(1),
                                Description = reader.IsDBNull(2) ? "" : reader.GetString(2),
                                Price = reader.GetDecimal(3),
                                Stock = reader.GetInt32(4),
                                CategoryID = reader.IsDBNull(5) ? (int?)null : reader.GetInt32(5),
                                CategoryName = reader.IsDBNull(6) ? "" : reader.GetString(6),
                                CreatedDate = reader.GetDateTime(7),
                                ModifiedDate = reader.GetDateTime(8),
                                IsActive = reader.GetBoolean(9)
                            };
                        }
                    }
                }
            }

            return product;
        }
    }
}
'@

$productRepoCs | Out-File -FilePath "Data\ProductRepository.cs" -Encoding UTF8 -Force
Write-Success "Data\ProductRepository.cs created"

# Delete Class1.cs (default file)
if (Test-Path "Class1.cs") {
    Remove-Item "Class1.cs" -Force
    Write-Info "Default file Class1.cs removed"
}

Write-SubStep "Compile Business Logic component"
try {
    if (-not $SkipDotnetRestore) {
        Write-Info "Running 'dotnet restore'..."
        dotnet restore | Out-Null
    }
    
    $buildOutput = dotnet build -c Release --no-restore 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Business Logic component compiled successfully"
        $dllPath = "bin\Release\net6.0\ContosoApp.BusinessLogic.dll"
        if (Test-Path $dllPath) {
            Write-Info "DLL created: $dllPath"
            Write-Info "Size: $([math]::Round((Get-Item $dllPath).Length / 1KB, 2)) KB"
        }
    } else {
        Write-Failure "Build failed"
        Write-Host $buildOutput
        throw "Build failed"
    }
} catch {
    Write-Failure "Error compiling: $_"
    throw
}

# Return to project base path
Set-Location $PSScriptRoot
#endregion

#region Create web application
Write-Step "Step 5: Create web application"

# Make sure we use the absolute path
$absoluteProjectPath = (Resolve-Path $ProjectPath).Path
Set-Location "$absoluteProjectPath\ContosoWebApp"

Write-SubStep "Create ASP.NET Core MVC project"
try {
    $output = dotnet new mvc -n ContosoWebApp -f net6.0 --force 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "MVC project created"
    } else {
        Write-Failure "Error creating MVC project"
        Write-Host $output
        throw "dotnet new mvc failed"
    }
} catch {
    Write-Failure "Error: $_"
    throw
}

Set-Location "ContosoWebApp"

Write-SubStep "Add Business Logic reference"
try {
    $businessLogicProjectPath = Resolve-Path "$absoluteProjectPath\ContosoApp.BusinessLogic\ContosoApp.BusinessLogic\ContosoApp.BusinessLogic.csproj"
    dotnet add reference $businessLogicProjectPath | Out-Null
    Write-Success "Business Logic reference added"
} catch {
    Write-Failure "Error adding reference: $_"
    throw
}

Write-SubStep "Create appsettings.json"
$appSettings = @'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=SQL01.contoso.local;Database=ContosoApp;Integrated Security=True;TrustServerCertificate=True;"
  },
  "AppSettings": {
    "ApplicationName": "Contoso Product Management",
    "Version": "1.0.0",
    "Environment": "Development"
  }
}
'@

$appSettings | Out-File -FilePath "appsettings.json" -Encoding UTF8 -Force
Write-Success "appsettings.json updated"

Write-SubStep "Configure Windows Authentication in Program.cs"
$programCs = Get-Content -Path "Program.cs" -Raw
# Add Windows Authentication and Negotiate after AddControllersWithViews
$programCs = $programCs.Replace(
    'builder.Services.AddControllersWithViews();',
    @"
builder.Services.AddControllersWithViews();
builder.Services.AddAuthentication("Windows");
"@
)
# Add UseAuthentication before UseAuthorization
$programCs = $programCs.Replace(
    'app.UseAuthorization();',
    @"
app.UseAuthentication();
app.UseAuthorization();
"@
)
$programCs | Out-File -FilePath "Program.cs" -Encoding UTF8 -Force
Write-Success "Program.cs updated: Windows Authentication enabled"

Write-SubStep "Create ProductsController"
$productsController = @'
using Microsoft.AspNetCore.Mvc;
using ContosoApp.BusinessLogic.Data;
using ContosoApp.BusinessLogic.Models;
using System.Collections.Generic;
using System.Security.Principal;

namespace ContosoWebApp.Controllers
{
    public class ProductsController : Controller
    {
        private readonly ProductRepository _productRepository;

        public ProductsController()
        {
            _productRepository = new ProductRepository();
        }

        public IActionResult Index()
        {
            try
            {
                // Database access using the logged-in user's identity
                var identity = (WindowsIdentity)HttpContext.User.Identity;
                List<Product> products = WindowsIdentity.RunImpersonated(
                    identity.AccessToken,
                    () => _productRepository.GetAllProducts());
                return View(products);
            }
            catch (System.Exception ex)
            {
                ViewBag.ErrorMessage = $"Error loading products: {ex.Message}";
                return View(new List<Product>());
            }
        }

        public IActionResult Details(int id)
        {
            try
            {
                // Database access using the logged-in user's identity
                var identity = (WindowsIdentity)HttpContext.User.Identity;
                Product product = WindowsIdentity.RunImpersonated(
                    identity.AccessToken,
                    () => _productRepository.GetProductById(id));
                
                if (product == null)
                {
                    return NotFound();
                }

                return View(product);
            }
            catch (System.Exception ex)
            {
                ViewBag.ErrorMessage = $"Error loading product: {ex.Message}";
                return RedirectToAction("Index");
            }
        }
    }
}
'@

$productsController | Out-File -FilePath "Controllers\ProductsController.cs" -Encoding UTF8 -Force
Write-Success "Controllers\ProductsController.cs created"

Write-SubStep "Create views"

# Index.cshtml
$indexView = @'
@model List<ContosoApp.BusinessLogic.Models.Product>

@{
    ViewData["Title"] = "Product Overview";
}

<div class="container mt-4">
    <h1 class="mb-4">
        <i class="fas fa-box"></i> Product Overview
    </h1>

    @if (!string.IsNullOrEmpty(ViewBag.ErrorMessage))
    {
        <div class="alert alert-danger">
            <i class="fas fa-exclamation-triangle"></i> @ViewBag.ErrorMessage
        </div>
    }

    @if (Model.Count == 0)
    {
        <div class="alert alert-info">
            <i class="fas fa-info-circle"></i> No products available.
        </div>
    }
    else
    {
        <div class="row">
            @foreach (var product in Model)
            {
                <div class="col-md-4 mb-4">
                    <div class="card h-100">
                        <div class="card-body">
                            <h5 class="card-title">@product.ProductName</h5>
                            <h6 class="card-subtitle mb-2 text-muted">@product.CategoryName</h6>
                            <p class="card-text">@product.Description</p>
                            <p class="card-text">
                                <strong>Price:</strong> @product.Price.ToString("C2")<br/>
                                <strong>Stock:</strong> @product.Stock units
                            </p>
                        </div>
                        <div class="card-footer">
                            <a asp-action="Details" asp-route-id="@product.ProductID" class="btn btn-primary btn-sm">
                                <i class="fas fa-info-circle"></i> Details
                            </a>
                        </div>
                    </div>
                </div>
            }
        </div>
    }
</div>

<style>
    .card {
        transition: transform 0.2s;
    }
    .card:hover {
        transform: translateY(-5px);
        box-shadow: 0 4px 8px rgba(0,0,0,0.2);
    }
</style>
'@

$indexView | Out-File -FilePath "Views\Products\Index.cshtml" -Encoding UTF8 -Force
Write-Success "Views\Products\Index.cshtml created"

# Details.cshtml
$detailsView = @'
@model ContosoApp.BusinessLogic.Models.Product

@{
    ViewData["Title"] = "Product Details";
}

<div class="container mt-4">
    <nav aria-label="breadcrumb">
        <ol class="breadcrumb">
            <li class="breadcrumb-item"><a asp-controller="Home" asp-action="Index">Home</a></li>
            <li class="breadcrumb-item"><a asp-controller="Products" asp-action="Index">Products</a></li>
            <li class="breadcrumb-item active">@Model.ProductName</li>
        </ol>
    </nav>

    <div class="row">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header bg-primary text-white">
                    <h2><i class="fas fa-box"></i> @Model.ProductName</h2>
                </div>
                <div class="card-body">
                    <div class="row mb-3">
                        <div class="col-md-4"><strong>Product ID:</strong></div>
                        <div class="col-md-8">@Model.ProductID</div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-4"><strong>Category:</strong></div>
                        <div class="col-md-8"><span class="badge bg-secondary">@Model.CategoryName</span></div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-4"><strong>Description:</strong></div>
                        <div class="col-md-8">@Model.Description</div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-4"><strong>Price:</strong></div>
                        <div class="col-md-8"><h4 class="text-success">@Model.Price.ToString("C2")</h4></div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-4"><strong>Stock:</strong></div>
                        <div class="col-md-8">
                            @if (Model.Stock > 10)
                            {
                                <span class="badge bg-success">@Model.Stock units available</span>
                            }
                            else if (Model.Stock > 0)
                            {
                                <span class="badge bg-warning">Only @Model.Stock units left</span>
                            }
                            else
                            {
                                <span class="badge bg-danger">Not available</span>
                            }
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-4"><strong>Created on:</strong></div>
                        <div class="col-md-8">@Model.CreatedDate.ToString("dd.MM.yyyy HH:mm")</div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-4"><strong>Last modified:</strong></div>
                        <div class="col-md-8">@Model.ModifiedDate.ToString("dd.MM.yyyy HH:mm")</div>
                    </div>
                </div>
                <div class="card-footer">
                    <a asp-action="Index" class="btn btn-secondary">
                        <i class="fas fa-arrow-left"></i> Back to overview
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>
'@

$detailsView | Out-File -FilePath "Views\Products\Details.cshtml" -Encoding UTF8 -Force
Write-Success "Views\Products\Details.cshtml created"

Write-SubStep "Update _Layout.cshtml (navigation)"
$layoutPath = "Views\Shared\_Layout.cshtml"
if (Test-Path $layoutPath) {
    $layoutContent = Get-Content $layoutPath -Raw
    # Add a Products link between Home and Privacy
    $oldNav = '<a class="nav-link text-dark" asp-area="" asp-controller="Home" asp-action="Privacy">Privacy</a>'
    $newNav = @'
<a class="nav-link text-dark" asp-area="" asp-controller="Products" asp-action="Index">Products</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link text-dark" asp-area="" asp-controller="Home" asp-action="Privacy">Privacy</a>
'@
    $layoutContent = $layoutContent.Replace($oldNav, $newNav)
    $layoutContent | Out-File -FilePath $layoutPath -Encoding UTF8 -Force
    Write-Success "_Layout.cshtml updated: Products link added"
} else {
    Write-Failure "_Layout.cshtml not found"
}

Write-SubStep "Compile web application"
try {
    if (-not $SkipDotnetRestore) {
        Write-Info "Running 'dotnet restore'..."
        dotnet restore | Out-Null
    }
    
    $buildOutput = dotnet build -c Release --no-restore 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Web application compiled successfully"
    } else {
        Write-Failure "Build failed"
        Write-Host $buildOutput
        throw "Build failed"
    }
} catch {
    Write-Failure "Error compiling: $_"
    throw
}

Write-SubStep "Create publish output"
try {
    $publishPath = "$ProjectPath\ContosoWebApp\published"
    $publishOutput = dotnet publish -c Release -o $publishPath --no-build 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Publish output created: .\ContosoWebApp\published\"
        $fileCount = (Get-ChildItem $publishPath -Recurse -File).Count
        $totalSize = [math]::Round((Get-ChildItem $publishPath -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
        Write-Info "Files: $fileCount | Total size: $totalSize MB"
    } else {
        Write-Failure "Publish failed"
        Write-Host $publishOutput
        throw "Publish failed"
    }
} catch {
    Write-Failure "Error during publish: $_"
    throw
}
#endregion

#region Copy deployment script
Write-Step "Step 6: Create deployment script"

$deployScriptPath = "$ProjectPath\DeploymentScripts\Deploy-ContosoApp.ps1"
$deployScriptSource = "$PSScriptRoot\Deploy-ContosoApp.ps1"

if (Test-Path $deployScriptSource) {
    Copy-Item $deployScriptSource -Destination $deployScriptPath -Force
    Write-Success "Deploy-ContosoApp.ps1 copied"
} else {
    Write-Info "Deploy-ContosoApp.ps1 not found in the current directory"
    Write-Info "Please copy manually to .\DeploymentScripts\"
}
#endregion

#region Summary
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n"
Write-Host @"

╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                     ✓ BUILD SUCCESSFULLY COMPLETED                         ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Project path:        $ProjectPath" -ForegroundColor White
Write-Host "  Start time:          $($startTime.ToString('HH:mm:ss'))" -ForegroundColor White
Write-Host "  End time:            $($endTime.ToString('HH:mm:ss'))" -ForegroundColor White
Write-Host "  Duration:            $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor White
Write-Host ""

Write-Host "Created components:" -ForegroundColor Cyan
Write-Host "  ✓ Database script:    .\DatabaseScripts\01-CreateDatabase.sql" -ForegroundColor Green
Write-Host "  ✓ Business Logic:    .\ContosoApp.BusinessLogic\" -ForegroundColor Green
Write-Host "  ✓ Web application:   .\ContosoWebApp\" -ForegroundColor Green
Write-Host "  ✓ Publish output:    .\ContosoWebApp\published\" -ForegroundColor Green
Write-Host "  ✓ Deployment script: .\DeploymentScripts\" -ForegroundColor Green
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the created files in: $ProjectPath"
Write-Host "  2. Optional: Test the application locally with 'dotnet run'"
Write-Host "  3. Run the deployment script:"
Write-Host "     .\DeploymentScripts\Deploy-ContosoApp.ps1"
Write-Host ""

Write-Host "The ContosoApp is ready for AutomatedLab deployment!" -ForegroundColor Green
Write-Host ""

Set-Location $originalLocation
#endregion
