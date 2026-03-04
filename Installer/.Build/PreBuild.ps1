param(
    [Parameter(Mandatory)]
    [string]$SolutionDir,

    [Parameter()]
    [string[]]
    $ExternalDependency = @('Pester', 'PSFramework', 'SHiPS', 'AutomatedLab.Common', 'xPSDesiredStateConfiguration', 'xDscDiagnostics', 'xWebAdministration', 'powershell-yaml'),

    [Parameter()]
    [string[]]
    $InternalModules = @('AutomatedLab', 'AutomatedLabCore', 'AutomatedLab.Recipe', 'AutomatedLab.Ships', 'AutomatedLabDefinition', 'AutomatedLabNotifications', 'AutomatedLabTest', 'AutomatedLabUnattended', 'AutomatedLabWorker', 'PSFileTransfer', 'PSLog')
)

Write-Host "Init task - compiling help for Installer"
if (-not (Get-Module -List PlatyPs))
{
    Write-Host 'Installing Package Provider'
    try
    {
        #https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netcore-2.0#System_Net_SecurityProtocolType_SystemDefault
        if ($PSVersionTable.PSVersion.Major -lt 6 -and [Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12')
        {
            Write-Verbose -Message 'Adding support for TLS 1.2'
            [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
        }
    }
    catch
    {
        Write-Warning -Message 'Adding TLS 1.2 to supported security protocols was unsuccessful.'
    }
    if (-not (Get-PackageProvider nuget)) { Install-PackageProvider nuget -Force }
    Write-Host 'Installing Module PlatyPS'
    Install-Module PlatyPS -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser
}

Write-Host 'Trying to build generic help content'
# Prepare about_help from wiki content (until a better solution presents itself)
@'
# AutomatedLab Roles Overview
## about_AutomatedLabRoles

# SHORT DESCRIPTION
Generic help about the role system of AutomatedLab

# LONG DESCRIPTION

'@ | Set-Content -Path (Join-Path $SolutionDir -ChildPath Help/AutomatedLabCore/en-us/about_AutomatedLabRoles.md)
$roleContent = Get-Content -Path (Join-Path $SolutionDir -ChildPath Help/Wiki/Roles/roles.md) | ForEach-Object { if ($_.StartsWith('#')) { $_.Insert(0, '#') } else { $_ } }
$roleContent | Add-Content -Path (Join-Path $SolutionDir -ChildPath Help/AutomatedLabCore/en-us/about_AutomatedLabRoles.md)

$helpFiles = Get-ChildItem -Path (Join-Path $SolutionDir -ChildPath Help/Wiki/Roles) -Exclude roles.md
$roleContent = @'
# AutomatedLab {0} Role
## about_AutomatedLab_{0}

# SHORT DESCRIPTION
Generic help about the Role '{0}' in AutomatedLab

# LONG DESCRIPTION

'@
foreach ($helpfile in $helpFiles)
{
    $rolename = $helpFile.BaseName

    $roleContent -f $rolename | Set-Content -Path (Join-Path $SolutionDir -ChildPath Help/AutomatedLabCore/en-us/about_AutomatedLab_$rolename.md)
    foreach ($line in ($helpFile | Get-Content))
    {
        if ($line.StartsWith('#'))
        {
            $line = $line.Insert(0, '#')
        }
        $line | Add-Content -Path (Join-Path $SolutionDir -ChildPath Help/AutomatedLabCore/en-us/about_AutomatedLab_$rolename.md)
    }
}

@'
# AutomatedLab Basics
## about_AutomatedLabBasics

# SHORT DESCRIPTION
Generic help about the basics of AutomatedLab

# LONG DESCRIPTION

'@ | Set-Content -Path (Join-Path $SolutionDir -ChildPath Help/AutomatedLabCore/en-us/about_AutomatedLabBasics.md)
[System.Collections.Generic.List[System.IO.FileInfo]]$helpFiles = Get-Item -Path (Join-Path $SolutionDir -ChildPath Help/Wiki/Basic/gettingstarted.md)
$helpFiles.AddRange([IO.FileInfo[]](Get-ChildItem -Path (Join-Path $SolutionDir -ChildPath Help/Wiki/Basic)))
foreach ($line in ($helpFiles | Get-Content))
{
    if ($line.StartsWith('#'))
    {
        $line = $line.Insert(0, '#')
    }
    $line | Add-Content -Path (Join-Path $SolutionDir -ChildPath Help/AutomatedLabCore/en-us/about_AutomatedLabBasics.md)
}

@'
# AutomatedLab Advanced
## about_AutomatedLabAdvanced

# SHORT DESCRIPTION
Generic help about the advanced mechanics of AutomatedLab

# LONG DESCRIPTION

'@ | Set-Content -Path (Join-Path $SolutionDir -ChildPath Help/AutomatedLabCore/en-us/about_AutomatedLabAdvanced.md)
$advHelp = Get-ChildItem -Path (Join-Path $SolutionDir -ChildPath Help/Wiki/Advanced)
foreach ($line in ($advHelp | Get-Content))
{
    if ($line.StartsWith('#'))
    {
        $line = $line.Insert(0, '#')
    }
    $line | Add-Content -Path (Join-Path $SolutionDir -ChildPath Help/AutomatedLabCore/en-us/about_AutomatedLabAdvanced.md)
}

foreach ($moduleName in (Get-ChildItem -Path $SolutionDir\Help -Directory))
{
    Write-Host "Building help for module '$moduleName'"
    foreach ($language in ($moduleName | Get-ChildItem -Directory))
    {
        $ci = try { [cultureinfo]$language.BaseName } catch { }
        if (-not $ci) { continue }

        $mPath = Join-Path -Path $SolutionDir -ChildPath "publish\$($moduleName.BaseName)\*" -Resolve
        $opPath = Join-Path -Path $mPath -ChildPath $language.BaseName
        Write-Host "Generating help XML in $opPath"
        $null = New-ExternalHelp -Path $language.FullName -OutputPath $opPath -Force
    }
}

Microsoft.PowerShell.Utility\Write-Host 'Creating backup of file Includes.wxi'
Copy-Item -Path $SolutionDir\Installer\Includes.wxi -Destination $SolutionDir\Installer\Includes.wxi.original
Copy-Item -Path $SolutionDir\Installer\Product.wxs -Destination $SolutionDir\Installer\Product.wxs.original

$dllPath = Join-Path -Path $SolutionDir -ChildPath LabXml\bin\debug\net462
$automatedLabdll = Get-Item -Path "$dllPath\AutomatedLab.dll"
Microsoft.PowerShell.Utility\Write-Host "AutomatedLab Dll path is '$($automatedLabdll.FullName)'"
$alDllVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($automatedLabdll)
Microsoft.PowerShell.Utility\Write-Host "Product Version of AutomatedLab is '$($alDllVersion.FileVersion)'"
$alCommonVersion = (Find-Module AutomatedLab.Common -Repository PSgallery).Version

Microsoft.PowerShell.Utility\Write-Host "Writing new 'Includes.wxi' file"
('<?xml version="1.0" encoding="utf-8"?><Include Id="VersionNumberInclude"><?define AutomatedLabCommonVersion="{0}" ?><?define AutomatedLabProductVersion="{1}" ?></Include>' -f $alCommonVersion, $alDllVersion.FileVersion) | Out-File -FilePath $SolutionDir\Installer\Includes.wxi -Encoding UTF8

Microsoft.PowerShell.Utility\Write-Host "Dynamically adding modules to product.wxs"
$xmlContent = [xml](Get-Content $SolutionDir\Installer\product.wxs)
$scratch = Join-Path -Path $SolutionDir -ChildPath publish
$scratchExt = Join-Path -Path $SolutionDir -ChildPath scratch
$null = mkdir -Force -Path $scratchExt
$null = mkdir -Force -Path $scratch
$programFilesNode = ($xmlContent.Wix.Product.Directory.Directory | Where-Object Name -eq ProgramFilesFolder).Directory.Directory | Where-Object Name -eq 'Modules'
$componentRefNode = $xmlContent.wix.product.Feature.Feature | Where-Object Id -eq 'Modules'

# Save external modules to tmp
Save-Module -Name $ExternalDependency -Path $scratchExt -Force -Repository PSGallery

# LabSources insertion - dynamically build the entire LabSources directory tree
Microsoft.PowerShell.Utility\Write-Host 'Dynamically adding LabSources content to product.wxs'
$labSourcesPath = Join-Path -Path $SolutionDir -ChildPath 'LabSources'
$labSourcesDirNode = $xmlContent.Wix.Product.Directory.Directory.Where( { $_.Id -eq 'LABSOURCESVOLUME' }).Directory
$labSourcesComponentGroup = ($xmlContent.Wix.Fragment | ForEach-Object { $_.ComponentGroup } | Where-Object Id -eq 'LabSourcesComponentGroup')

$folders, $files = (Get-ChildItem -Path $labSourcesPath -Recurse -Force).Where( { $_.PSIsContainer }, 'Split')
$nodeHash = @{}
$nodeHash.Add($labSourcesPath, $labSourcesDirNode)

# Create directory tree under LABSOURCESDIR
foreach ($folder in $folders)
{
    $parentNode = $nodeHash[$folder.Parent.FullName]
    if ($null -eq $parentNode)
    {
        Microsoft.PowerShell.Utility\Write-Host "  Skipping folder '$($folder.FullName)' - parent not found"
        continue
    }

    $dirNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'Directory', 'http://schemas.microsoft.com/wix/2006/wi')
    $idAttrib = $xmlContent.CreateAttribute('Id')
    $idAttrib.Value = 'ls_dir_{0}' -f ($folder.FullName.Replace($labSourcesPath, '') -replace '\W')
    $nameAttrib = $xmlContent.CreateAttribute('Name')
    $nameAttrib.Value = $folder.Name
    $null = $dirNode.Attributes.Append($idAttrib)
    $null = $dirNode.Attributes.Append($nameAttrib)
    $null = $parentNode.AppendChild($dirNode)
    $nodeHash.Add($folder.FullName, $dirNode)
}

# Create components and files, one component per directory that contains files
$componentHash = @{}
foreach ($file in $files)
{
    $dirPath = $file.DirectoryName
    $dirKey = $dirPath.Replace($labSourcesPath, '') -replace '\W'
    if (-not $dirKey) { $dirKey = 'Root' }

    $relativePath = $file.FullName.Replace("$SolutionDir\", '')

    if (-not $componentHash.ContainsKey($dirKey))
    {
        $compNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'Component', 'http://schemas.microsoft.com/wix/2006/wi')
        $compIdAttrib = $xmlContent.CreateAttribute('Id')
        $compIdAttrib.Value = "ls_cmp_$dirKey"
        $compGuidAttrib = $xmlContent.CreateAttribute('Guid')
        $compGuidAttrib.Value = (New-Guid).Guid
        $compDirAttrib = $xmlContent.CreateAttribute('Directory')
        $compDirAttrib.Value = if ($dirKey -eq 'Root') { 'LABSOURCESDIR' } else { "ls_dir_$dirKey" }
        $null = $compNode.Attributes.Append($compIdAttrib)
        $null = $compNode.Attributes.Append($compGuidAttrib)
        $null = $compNode.Attributes.Append($compDirAttrib)
        $null = $labSourcesComponentGroup.AppendChild($compNode)
        $componentHash.Add($dirKey, $compNode)
    }

    $fileNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'File', 'http://schemas.microsoft.com/wix/2006/wi')
    $fileSourceAttrib = $xmlContent.CreateAttribute('Source')
    $fileSourceAttrib.Value = $file.FullName
    $fileIdAttrib = $xmlContent.CreateAttribute('Id')
    $fileIdAttrib.Value = 'ls_{0}' -f ((New-Guid).Guid -replace '\W')
    $null = $fileNode.Attributes.Append($fileSourceAttrib)
    $null = $fileNode.Attributes.Append($fileIdAttrib)
    $null = $componentHash[$dirKey].AppendChild($fileNode)
}

Microsoft.PowerShell.Utility\Write-Host "  Added $($folders.Count) directories and $($files.Count) files to LabSources"

# Dependent modules insertion
foreach ($depp in $internalModules)
{
    $modPath = Join-Path -Path $scratch -ChildPath $depp
    Microsoft.PowerShell.Utility\Write-Host "Dynamically adding $depp ($modPath) to product.wxs"
    $folders, $files = (Get-ChildItem -Path $modPath -Recurse -Force).Where( { $_.PSIsContainer }, 'Split')
    $nodeHash = @{}

    $rootNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'Directory', 'http://schemas.microsoft.com/wix/2006/wi')
    $idAttrib = $xmlContent.CreateAttribute('Id')
    $idAttrib.Value = "$($depp -replace '\W')Root"
    $nameAttrib = $xmlContent.CreateAttribute('Name')
    $nameAttrib.Value = $depp
    $null = $rootNode.Attributes.Append($idAttrib)
    $null = $rootNode.Attributes.Append($nameAttrib)
    $nodeHash.Add("$($depp -replace '\W')Root", @{Node = $rootNode; Component = $false })

    foreach ($folder in $folders)
    {
        $parentNodeName = ($folder.Parent.FullName).Replace($scratch, '') -replace '\W'
        $dirNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'Directory', 'http://schemas.microsoft.com/wix/2006/wi')
        $idAttrib = $xmlContent.CreateAttribute('Id')
        $idAttrib.Value = $folder.FullName.Replace($scratch, '') -replace '\W'
        $nameAttrib = $xmlContent.CreateAttribute('Name')
        $nameAttrib.Value = $folder.Name
        $null = $dirNode.Attributes.Append($idAttrib)
        $null = $dirNode.Attributes.Append($nameAttrib)

        # Parent node lokalisieren, wenn nicht vorhanden, programFilesNode
        $parentNode = $nodeHash[$parentNodeName].Node
        $nodeHash.Add($idAttrib.Value, @{Node = $dirNode; Component = $false })

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
        $parentNodeName = ($file.DirectoryName).Replace($scratch, '') -replace '\W'
        $parentNode = $nodeHash[$parentNodeName].Node
        if ($null -eq $parentNode)
        {
            $parentNodeName = "$($depp -replace '\W')Root"
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
            $idAttrib = $xmlContent.CreateAttribute('Id')
            $idAttrib.Value = "$($parentNodeName)Component"
            $guidAttrib = $xmlContent.CreateAttribute('Guid')
            $guidAttrib.Value = (New-Guid).Guid
            $null = $compNode.Attributes.Append($idAttrib)
            $null = $compNode.Attributes.Append($guidAttrib)
            $appendComponents.$parentNodeName += $compNode

            # add ref
            $refNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'ComponentRef', 'http://schemas.microsoft.com/wix/2006/wi')
            $refIdAttrib = $xmlContent.CreateAttribute('Id')
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
        $fileId.Value = -join [char[]]$(1..$rnd | ForEach-Object { Get-Random -Minimum 97 -Maximum 122 })
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

# Dependent modules insertion
foreach ($depp in $ExternalDependency)
{
    Microsoft.PowerShell.Utility\Write-Host "Dynamically adding $depp to product.wxs"
    $modPath = Join-Path -Path $scratchExt -ChildPath $depp
    $folders, $files = (Get-ChildItem -Path $modPath -Recurse -Force).Where( { $_.PSIsContainer }, 'Split')
    $nodeHash = @{}

    $rootNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'Directory', 'http://schemas.microsoft.com/wix/2006/wi')
    $idAttrib = $xmlContent.CreateAttribute('Id')
    $idAttrib.Value = "$($depp -replace '\W')Root"
    $nameAttrib = $xmlContent.CreateAttribute('Name')
    $nameAttrib.Value = $depp
    $null = $rootNode.Attributes.Append($idAttrib)
    $null = $rootNode.Attributes.Append($nameAttrib)
    $nodeHash.Add("$($depp -replace '\W')Root", @{Node = $rootNode; Component = $false })

    foreach ($folder in $folders)
    {
        $parentNodeName = ($folder.Parent.FullName).Replace($scratchExt, '') -replace '\W'
        $dirNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'Directory', 'http://schemas.microsoft.com/wix/2006/wi')
        $idAttrib = $xmlContent.CreateAttribute('Id')
        $idAttrib.Value = $folder.FullName.Replace($scratchExt, '') -replace '\W'
        $nameAttrib = $xmlContent.CreateAttribute('Name')
        $nameAttrib.Value = $folder.Name
        $null = $dirNode.Attributes.Append($idAttrib)
        $null = $dirNode.Attributes.Append($nameAttrib)

        # Parent node lokalisieren, wenn nicht vorhanden, programFilesNode
        $parentNode = $nodeHash[$parentNodeName].Node
        $nodeHash.Add($idAttrib.Value, @{Node = $dirNode; Component = $false })

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
        $parentNodeName = ($file.DirectoryName).Replace($scratchExt, '') -replace '\W'
        $parentNode = $nodeHash[$parentNodeName].Node
        if ($null -eq $parentNode)
        {
            $parentNodeName = "$($depp -replace '\W')Root"
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
            $idAttrib = $xmlContent.CreateAttribute('Id')
            $idAttrib.Value = "$($parentNodeName)Component"
            $guidAttrib = $xmlContent.CreateAttribute('Guid')
            $guidAttrib.Value = (New-Guid).Guid
            $null = $compNode.Attributes.Append($idAttrib)
            $null = $compNode.Attributes.Append($guidAttrib)
            $appendComponents.$parentNodeName += $compNode

            # add ref
            $refNode = $xmlContent.CreateNode([System.Xml.XmlNodeType]::Element, 'ComponentRef', 'http://schemas.microsoft.com/wix/2006/wi')
            $refIdAttrib = $xmlContent.CreateAttribute('Id')
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
        $fileId.Value = -join [char[]]$(1..$rnd | ForEach-Object { Get-Random -Minimum 97 -Maximum 122 })
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