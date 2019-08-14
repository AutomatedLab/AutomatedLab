﻿param(
    [Parameter(Mandatory)]
    [string]$SolutionDir
)

Push-Location

Set-Location -Path $SolutionDir\AutomatedLab.Common
git reset --hard
git submodule -q update --init --recursive
git pull origin master

# Compile Common libary
dotnet build $SolutionDir\AutomatedLab.Common

Write-Host "Init task - compiling help for Installer"
if (-not (Get-Module -List PlatyPs))
{
    Write-Host 'Installing Package Provider'
    Install-PackageProvider nuget -Force
    Write-Host 'Installing Module PlatyPS'
    Install-Module PlatyPS -Force -AllowClobber -SkipPublisherCheck
}

$null = New-ExternalHelp -Path $SolutionDir\AutomatedLab.Common\Help\en-us -OutputPath $SolutionDir\AutomatedLab.Common\AutomatedLab.Common\en-us

foreach ($moduleName in (Get-ChildItem -Path $SolutionDir\Help -Directory))
{
    Write-Host "Building help for module '$moduleName'"
    foreach ($language in ($moduleName | Get-ChildItem -Directory))
    {
        $ci = try { [cultureinfo]$language.BaseName} catch { }
        if (-not $ci) { continue }

        $opPath = Join-Path -Path $SolutionDir -ChildPath "$($moduleName.BaseName)\$($language.BaseName)"
        Write-Host "Generating help XML in $opPath"
        $null = New-ExternalHelp -Path $language.FullName -OutputPath $opPath
    }
}

Microsoft.PowerShell.Utility\Write-Host 'Creating backup of file AutomatedLab.Common.psd1'
Copy-Item -Path $SolutionDir\AutomatedLab.Common\AutomatedLab.Common\AutomatedLab.Common.psd1 -Destination $SolutionDir\AutomatedLab.Common\AutomatedLab.Common\AutomatedLab.Common.psd1.original
Microsoft.PowerShell.Utility\Write-Host 'Creating backup of file Includes.wxi'
Copy-Item -Path $SolutionDir\Installer\Includes.wxi -Destination $SolutionDir\Installer\Includes.wxi.original

$dllPath = Join-Path -Path $SolutionDir -ChildPath LabXml\bin\debug\net462
$automatedLabdll = Get-Item -Path "$dllPath\AutomatedLab.dll"
Microsoft.PowerShell.Utility\Write-Host "AutomatedLab Dll path is '$($automatedLabdll.FullName)'"
$alDllVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($automatedLabdll)
Microsoft.PowerShell.Utility\Write-Host "Product Version of AutomatedLab is '$($alDllVersion.FileVersion)'"

$alCommonVersion = (Find-Module -Name AutomatedLab.Common -ErrorAction SilentlyContinue).Version

Microsoft.PowerShell.Utility\Write-Host "Version of AutomatedLab.Common is '$alCommonVersion'"
Microsoft.PowerShell.Utility\Write-Host "Writing new 'Includes.wxi' file"
('<?xml version="1.0" encoding="utf-8"?><Include Id="VersionNumberInclude"><?define AutomatedLabCommonVersion="{0}" ?><?define AutomatedLabProductVersion="{1}" ?></Include>' -f $alCommonVersion, $alDllVersion.FileVersion) | Out-File -FilePath ..\Installer\Includes.wxi -Encoding UTF8
Microsoft.PowerShell.Utility\Write-Host "Replacing version in 'AutomatedLab.Common.psd1' file"
(Get-Content -Path .\AutomatedLab.Common\AutomatedLab.Common.psd1 -Raw) -replace "(ModuleVersion([ =]+))(')(?<Version>\d{1,2}\.\d{1,2}\.\d{1,2})", "`$1'$alCommonVersion" | Out-File -FilePath .\AutomatedLab.Common\AutomatedLab.Common.psd1

Pop-Location

# Update installer
$dllCorePath = Join-Path -Path (Resolve-Path -Path $dllPath\..).Path -ChildPath 'netcoreapp2.2'

Microsoft.PowerShell.Utility\Write-Host "Locating libraries in $dllPath and $dllCorePath"
$newContentFull = Get-ChildItem -File -Filter *.dll -Path $dllPath | ForEach-Object { '<File Source="$(var.SolutionDir)LabXml\bin\debug\net462\{0}" Id="{1}" />' -f $_.Name,"full$((New-Guid).Guid -replace '-')" }
$newContentCore = Get-ChildItem -File -Filter *.dll -Path $dllCorePath | ForEach-Object { '<File Source="$(var.SolutionDir)LabXml\bin\debug\netcoreapp2.2\{0}" Id="{1}" />' -f $_.Name,"core$((New-Guid).Guid -replace '-')" }

Microsoft.PowerShell.Utility\Write-Host "Creating backup of file product.wxs"
Copy-Item -Path $SolutionDir\Installer\product.wxs -Destination $SolutionDir\Installer\product.wxs.original
(Get-Content $SolutionDir\Installer\product.wxs) -replace '<!-- %%%FILEPLACEHOLDERCOMMONCORE%%% -->', ($newContentCommonCore -join "`r`n") -replace '<!-- %%%FILEPLACEHOLDERCOMMONFULL%%% -->', ($newContentCommonFull -join "`r`n") -replace '<!-- %%%FILEPLACEHOLDERCORE%%% -->', ($newContentCore -join "`r`n") -replace '<!-- %%%FILEPLACEHOLDERFULL%%% -->', ($newContentFull -join "`r`n") | Set-Content $SolutionDir\Installer\Product.wxs -Encoding UTF8
