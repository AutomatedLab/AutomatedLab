param(
    [Parameter(Mandatory)]
    [string]$SolutionDir,

    [Parameter()]
    [string[]]
    $ExternalDependency = @('PSFramework', 'newtonsoft.json', 'SHiPS')
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
$commonDllCorePath = Join-Path -Path $SolutionDir -ChildPath 'AutomatedLab.Common\AutomatedLab.Common\lib\core'
$commonDllPath = Join-Path -Path $SolutionDir -ChildPath 'AutomatedLab.Common\AutomatedLab.Common\lib\full'
$dllCorePath = Join-Path -Path (Resolve-Path -Path $dllPath\..).Path -ChildPath 'netcoreapp2.2'

Microsoft.PowerShell.Utility\Write-Host "Locating libraries in $dllPath and $dllCorePath"
$newContentFull = Get-ChildItem -File -Filter *.dll -Path $dllPath | ForEach-Object { '<File Source="$(var.SolutionDir)LabXml\bin\debug\net462\{0}" Id="{1}" />' -f $_.Name,"full$((New-Guid).Guid -replace '-')" }
$newContentCore = Get-ChildItem -File -Filter *.dll -Path $dllCorePath | ForEach-Object { '<File Source="$(var.SolutionDir)LabXml\bin\debug\netcoreapp2.2\{0}" Id="{1}" />' -f $_.Name,"core$((New-Guid).Guid -replace '-')" }

Microsoft.PowerShell.Utility\Write-Host "Locating libraries in $commonDllPath and $commonDllCorePath"
$newContentCommonFull = Get-ChildItem -File -Filter *.dll -Path $commonDllPath | ForEach-Object { '<File Source="$(var.SolutionDir)AutomatedLab.Common\AutomatedLab.Common\lib\full\{0}" Id="{1}" />' -f $_.Name,"full$((New-Guid).Guid -replace '-')" }
$newContentCommonCore = Get-ChildItem -File -Filter *.dll -Path $commonDllCorePath | ForEach-Object { '<File Source="$(var.SolutionDir)AutomatedLab.Common\AutomatedLab.Common\lib\core\{0}" Id="{1}" />' -f $_.Name,"core$((New-Guid).Guid -replace '-')" }

Microsoft.PowerShell.Utility\Write-Host "Creating backup of file product.wxs"
Copy-Item -Path $SolutionDir\Installer\product.wxs -Destination $SolutionDir\Installer\product.wxs.original
(Get-Content $SolutionDir\Installer\product.wxs) -replace '<!-- %%%FILEPLACEHOLDERCOMMONCORE%%% -->', ($newContentCommonCore -join "`r`n") -replace '<!-- %%%FILEPLACEHOLDERCOMMONFULL%%% -->', ($newContentCommonFull -join "`r`n") -replace '<!-- %%%FILEPLACEHOLDERCORE%%% -->', ($newContentCore -join "`r`n") -replace '<!-- %%%FILEPLACEHOLDERFULL%%% -->', ($newContentFull -join "`r`n") | Set-Content $SolutionDir\Installer\Product.wxs -Encoding UTF8

$xmlContent = [xml](Get-Content $SolutionDir\Installer\product.wxs)
$programFilesNode = ($xmlContent.Wix.Product.Directory.Directory | Where-Object Name -eq ProgramFilesFolder).Directory.Directory | Where-Object Name -eq 'Modules'
$componentRefNode = $xmlContent.wix.product.Feature.Feature | Where-Object Id -eq 'Modules'

# Copy internal modules to tmp
$internalModules = @('AutomatedLab','AutomatedLab.Common\AutomatedLab.Common','AutomatedLab.Recipe', 'AutomatedLab.Ships','AutomatedLabDefinition','AutomatedLabNotifications','AutomatedLabTest','AutomatedLabUnattended','AutomatedLabWorker','HostsFile','PSFileTransfer','PSLog')
foreach ($mod in $internalModules)
{
    $modP = Join-Path $SolutionDir $mod
    $destination = Join-Path ([IO.Path]::GetTempPath()) ($mod -split '\\')[-1]
    $null = robocopy $modP $destination /MIR
}

# Save external modules to tmp
Save-Module -Name $ExternalDependency -Path ([IO.Path]::GetTempPath()) -Force -Repository PSGallery

# Dependent modules insertion
foreach ($depp in ($ExternalDependency + $internalModules))
{
    $depp = ($depp -split '\\')[-1]
    $modPath = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath $depp
    $folders, $files = (Get-ChildItem -Path $modPath -Recurse -Force).Where({$_.PSIsContainer},'Split')
    $nodeHash = @{}

    $rootNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'Directory', 'http://schemas.microsoft.com/wix/2006/wi')
    $idAttrib =$xmlContent.CreateAttribute('Id')
    $idAttrib.Value = "$($depp -replace '\.|\\')Root"
    $nameAttrib = $xmlContent.CreateAttribute('Name')
    $nameAttrib.Value = "$($depp -replace '\.|\\')Root"
    $null = $rootNode.Attributes.Append($idAttrib)
    $null = $rootNode.Attributes.Append($nameAttrib)
    $nodeHash.Add("$($depp -replace '\.|\\')Root", @{Node = $rootNode; Component = $false})

    foreach ($folder in $folders)
    {
        $parentNodeName = ($folder.Parent.FullName).Replace(([IO.Path]::GetTempPath()), '').Replace('\','').Replace('.','').Replace('-','')
        $dirNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'Directory', 'http://schemas.microsoft.com/wix/2006/wi')
        $idAttrib =$xmlContent.CreateAttribute('Id')
        $idAttrib.Value = $folder.FullName.Replace(([IO.Path]::GetTempPath()), '').Replace('\','').Replace('.','').Replace('-','')
        $nameAttrib = $xmlContent.CreateAttribute('Name')
        $nameAttrib.Value = $folder.FullName.Replace(([IO.Path]::GetTempPath()), '').Replace('\','').Replace('.','').Replace('-','')
        $null = $dirNode.Attributes.Append($idAttrib)
        $null = $dirNode.Attributes.Append($nameAttrib)
        
        # Parent node lokalisieren, wenn nicht vorhanden, programFilesNode
        $parentNode = $nodeHash[$parentNodeName].Node
        $nodeHash.Add($nameAttrib.Value, @{Node = $dirNode; Component = $false})

        if ($null -eq $parentNode)
        {
            $null = $rootNode.AppendChild($dirNode)
            continue
        }

        $null = $parentNode.AppendChild($dirNode)
    }

    $appendComponents = @{}
    
    foreach ($file in $files)
    {
        $parentNodeName = ($file.DirectoryName).Replace(([IO.Path]::GetTempPath()), '').Replace('\','').Replace('.','').Replace('-','')
        $parentNode = $nodeHash[$parentNodeName].Node
        if ($null -eq $parentNode)
        {
            $parentNodeName = "$($depp -replace '\.|\\')Root"
            $parentNode = $rootNode
        }

        if (-not $appendComponents.ContainsKey($parentNodeName))
        {
            $appendComponents.Add($parentNodeName, @())
        }
        
        $componentCreated = $nodeHash[$parentNodeName].Component

        if (-not $componentCreated)
        {
            $compNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'Component', 'http://schemas.microsoft.com/wix/2006/wi')
            $idAttrib =$xmlContent.CreateAttribute('Id')
            $idAttrib.Value = "$($parentNodeName)Component"
            $guidAttrib = $xmlContent.CreateAttribute('Guid')
            $guidAttrib.Value = (New-Guid).Guid
            $null = $compNode.Attributes.Append($idAttrib)
            $null = $compNode.Attributes.Append($guidAttrib)
            $appendComponents.$parentNodeName += $compNode

            # add ref
            $refNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'ComponentRef', 'http://schemas.microsoft.com/wix/2006/wi')
            $refIdAttrib =$xmlContent.CreateAttribute('Id')
            $refIdAttrib.Value = $idAttrib.Value
            $null = $refNode.Attributes.Append($refIdAttrib)
            $null = $componentRefNode.AppendChild($refNode)
            $nodeHash[$parentNodeName].Component = $compNode
        }

        $fileNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'File', 'http://schemas.microsoft.com/wix/2006/wi')
        $fileSource = $xmlContent.CreateAttribute('Source')
        $fileSource.Value = $file.FullName
        $null = $fileNode.Attributes.Append($fileSource)
        $null = $nodeHash[$parentNodeName].Component.AppendChild($fileNode)
    }

    foreach ($nodeToAppend in $appendComponents.GetEnumerator())
    {
        $parentNode = $nodeHash[$nodeToAppend.Key].Node
        foreach ($no in $nodeToAppend.Value)
        {
            $null = $parentNode.AppendChild($no)
        }
    }
    
    $null = $programFilesNode.AppendChild($rootNode)
}

$xmlContent.Save("$SolutionDir\Installer\product.wxs")