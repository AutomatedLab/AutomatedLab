param(
    [Parameter(Mandatory)]
    [string]$SolutionDir,

    [Parameter()]
    [string[]]
    $ExternalDependency = @('PSFramework', 'newtonsoft.json', 'SHiPS'),

    [Parameter()]
    [string[]]
    $InternalModules = @('AutomatedLab','AutomatedLab.Common\AutomatedLab.Common','AutomatedLab.Recipe', 'AutomatedLab.Ships','AutomatedLabDefinition','AutomatedLabNotifications','AutomatedLabTest','AutomatedLabUnattended','AutomatedLabWorker','HostsFile','PSFileTransfer','PSLog')
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

$null = New-ExternalHelp -Path $SolutionDir\AutomatedLab.Common\Help\en-us -OutputPath $SolutionDir\AutomatedLab.Common\AutomatedLab.Common\en-us -Force

foreach ($moduleName in (Get-ChildItem -Path $SolutionDir\Help -Directory))
{
    Write-Host "Building help for module '$moduleName'"
    foreach ($language in ($moduleName | Get-ChildItem -Directory))
    {
        $ci = try { [cultureinfo]$language.BaseName} catch { }
        if (-not $ci) { continue }

        $opPath = Join-Path -Path $SolutionDir -ChildPath "$($moduleName.BaseName)\$($language.BaseName)"
        Write-Host "Generating help XML in $opPath"
        $null = New-ExternalHelp -Path $language.FullName -OutputPath $opPath -Force
    }
}

Microsoft.PowerShell.Utility\Write-Host 'Creating backup of file AutomatedLab.Common.psd1'
Copy-Item -Path $SolutionDir\AutomatedLab.Common\AutomatedLab.Common\AutomatedLab.Common.psd1 -Destination $SolutionDir\AutomatedLab.Common\AutomatedLab.Common\AutomatedLab.Common.psd1.original
Microsoft.PowerShell.Utility\Write-Host 'Creating backup of file Includes.wxi'
Copy-Item -Path $SolutionDir\Installer\Includes.wxi -Destination $SolutionDir\Installer\Includes.wxi.original
Copy-Item -Path $SolutionDir\Installer\Product.wxs -Destination $SolutionDir\Installer\Product.wxs.original

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

Microsoft.PowerShell.Utility\Write-Host "Dynamically adding modules to product.wxs"
$xmlContent = [xml](Get-Content $SolutionDir\Installer\product.wxs)
$programFilesNode = ($xmlContent.Wix.Product.Directory.Directory | Where-Object Name -eq ProgramFilesFolder).Directory.Directory | Where-Object Name -eq 'Modules'
$componentRefNode = $xmlContent.wix.product.Feature.Feature | Where-Object Id -eq 'Modules'

# Copy internal modules to tmp

foreach ($mod in $internalModules)
{
    $modP = Join-Path $SolutionDir $mod
    $destination = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "$(($mod -split '\\')[-1])$alDllVersion"
    $null = robocopy $modP $destination /MIR
}

# Save external modules to tmp
Save-Module -Name $ExternalDependency -Path ([IO.Path]::GetTempPath()) -Force -Repository PSGallery

# Dependent modules insertion
foreach ($depp in ($ExternalDependency + $internalModules))
{
    $depp = ($depp -split '\\')[-1]
    Microsoft.PowerShell.Utility\Write-Host "Dynamically adding $depp to product.wxs"
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
        $parentNodeName = ($folder.Parent.FullName).Replace(([IO.Path]::GetTempPath()), '') -replace '\W'
        $dirNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'Directory', 'http://schemas.microsoft.com/wix/2006/wi')
        $idAttrib =$xmlContent.CreateAttribute('Id')
        $idAttrib.Value = $folder.FullName.Replace(([IO.Path]::GetTempPath()), '') -replace '\W'
        $nameAttrib = $xmlContent.CreateAttribute('Name')
        $nameAttrib.Value = $folder.FullName.Replace(([IO.Path]::GetTempPath()), '') -replace '\W'
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
        $parentNodeName = ($file.DirectoryName).Replace(([IO.Path]::GetTempPath()), '') -replace '\W'
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
        $fileId = $xmlContent.CreateAttribute('Id')
        $rnd = 71
        $fileId.Value = -join [char[]]$(1..$rnd | %{Get-Random -Minimum 97 -Maximum 122})
        $null = $fileNode.Attributes.Append($fileSource)
        $null = $fileNode.Attributes.Append($fileId)
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