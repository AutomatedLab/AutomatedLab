<#
.SYNOPSIS
    Deploy NuGet Server to Web Server
.DESCRIPTION
    Deploy NuGet Server binaries to a web server
#>
[CmdletBinding()]
param
(
    [string]
    $Path = 'C:\inetpub\nuget',

    [string]
    $SourcePath,

    [string]
    $SiteName = 'NuGet',

    [pscredential]
    $ApiKey = (Get-Credential -UserName NuGetApiKey -Message 'Key to publish modules to the gallery.'),

    [uint16]
    $Port = 80,

    [switch]
    $UseSsl,

    [string]
    $CertificateThumbprint,

    [switch]
    $UpdateOnly
)

#Requires -Module WebAdministration

if ([string]::IsNullOrWhiteSpace($SourcePath))
{
    $SourcePath = Join-Path -Path $PSScriptRoot -ChildPath deploy.zip -Resolve -ErrorAction Stop
}

# Extract archive
$tempDir = Join-Path $env:TEMP 'NugetContent'
$null = New-Item $tempDir -Force -ItemType Directory
Expand-Archive $SourcePath $tempDir -Force

# Copy necessary files
if (-not (Test-Path -Path $Path))
{
    $null = New-Item -ItemType Directory -Path $Path
}

$null = Robocopy.exe $tempDir\Modules 'C:\Program Files\WindowsPowerShell\Modules' /S /E
if (-not (Test-Path (Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet')))
{
    $null = New-Item -ItemType Directory -Path (Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\')
}

Copy-Item $tempDir\nuget.exe (Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\nuget.exe') -Force

$null = Robocopy.exe /S /E $tempDir $Path /XD Modules /XF test.ps1
$ACL = Get-Acl -Path $Path
$rule = [System.Security.AccessControl.FileSystemAccessRule]::new(
    'IIS_IUSRS',
    'Modify',
    'ContainerInherit,ObjectInherit',
    'None',
    'Allow'
)
$ACL.AddAccessRule($rule)
Set-Acl -AclObject $ACL -Path $Path

# Modify web.config
[xml]$webConfig = Get-Content -Path (Join-Path -Path $Path -ChildPath 'web.config')
$apiNode = $webConfig.SelectSingleNode('configuration/appSettings/add[@key = "apiKey"]')
$apiNode.value = $ApiKey.GetNetworkCredential().Password
$webConfig.Save((Join-Path -Path $Path -ChildPath 'web.config'))

# Create or update web site
$site = Get-WebSite -Name NuGet

if ($site)
{
    $site | Remove-Website
}

$site = New-WebSite -Name $SiteName -Port $Port -PhysicalPath $Path -Ssl:$($UseSSl.IsPresent)

if ($UseSsl.IsPresent)
{
    $binding = Get-WebBinding -Name $SiteName -Protocol "https"
    $cert = Get-Item -Path Cert:\LocalMachine\my\$($CertificateThumbprint)
    if (-not $cert)
    {
        Write-Error -Message 'No SSL Certificate found. Web site will not work.'
        return 666
    }

    $binding.AddSslCertificate($cert.GetCertHashString(), "my")
}

# Register repo
$ci = Get-CimInstance -ClassName Win32_ComputerSystem
$hostname = '{0}.{1}' -f $ci.Name, $ci.Domain

$params = @{
    Name               = 'Internal'
    SourceLocation     = if ($UseSsl.IsPresent)
    {
        'https://{0}:{1}/nuget' -f $hostname, $Port 
    }
    else
    {
        'http://{0}:{1}/nuget' -f $hostname, $Port 
    }
    PublishLocation    = if ($UseSsl.IsPresent)
    {
        'https://{0}:{1}/nuget' -f $hostname, $Port 
    }
    else
    {
        'http://{0}:{1}/nuget' -f $hostname, $Port 
    }
    InstallationPolicy = 'Trusted'
}

Register-PSRepository @params

# Test repo
if (-not (Get-Module pester -ListAvailable))
{
    return 
}

Invoke-Pester -Script @{
    Path       = (Join-Path $tempDir test.ps1)
    Parameters = @{
        ApiKey = $ApiKey.GetNetworkCredential().Password
    }
} -PassThru
