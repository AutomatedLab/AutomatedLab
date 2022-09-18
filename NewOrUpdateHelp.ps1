param
(
    [switch]
    $Create,

    [string[]]
    $Module = @('AutomatedLabUnattended' # Careful... This is also the import order!
        'AutomatedLabTest',
        'PSLog',
        'PSFileTransfer',
        'AutomatedLabDefinition',
        'AutomatedLabWorker',
        'HostsFile',
        'AutomatedLabNotifications',
        'AutomatedLab',
        'AutomatedLab.Recipe')
)

$location = $PSScriptRoot

$outPath = foreach ($moduleName in $Module)
{
    $outputFolder = Join-Path $location -ChildPath "Help/$moduleName/en-us"
    $outputFolder
    Import-Module ./$moduleName -Force
    if ($Create.IsPresent)
    {
        $null = New-MarkdownHelp -Module $moduleName -WithModulePage -OutputFolder $outputFolder -Force -AlphabeticParamsOrder
    }
}

if (-not $Create.IsPresent)
{
    Update-MarkdownHelpModule -Path $outPath -RefreshModulePage -AlphabeticParamsOrder
}

foreach ($md in (Get-ChildItem -Filter *.md -Recurse -Path (Join-Path -Path $location -ChildPath Help)))
{
    if (-not (Get-Command -ErrorAction SilentlyContinue -Name $md.BaseName)) { continue }

    $content = Get-Content -Raw -Path $md.FullName
    $moduleName = $md.Directory.Parent.Name
    $url = [System.Uri]::EscapeUriString(('https://automatedlab.org/en/latest/{0}/en-us/{1}' -f $moduleName, $md.BaseName))
    $content = $content -replace 'online version:.*', "online version: $url"
    $content | Set-Content -Path $md.FullName
}

$mkdocs = Join-Path -Path $location -ChildPath mkdocs.yml -Resolve -ErrorAction Stop
$mkdocsContent = Get-Content -Raw -Path $mkdocs | ConvertFrom-Yaml

# Update Sample Scripts help content
$null = ($mkdocsContent.nav | Where-Object {$_.Keys -contains 'Sample scripts'})['Sample scripts'] = New-Object System.Collections.ArrayList
foreach ($folder in (Get-ChildItem -Path (Join-Path -Path $location -ChildPath 'LabSources\SampleScripts') -Directory))
{

    $folderObject = @{ $folder.Name = New-Object System.Collections.ArrayList}
    foreach ($sample in $folder.GetFiles('*.ps1'))
    {
        $mdRelativePathMkDocs = "Wiki/SampleScripts/$($folder.BaseName)/en-us/$($sample.BaseName).md"
        $mdRelativePath = "Help/Wiki/SampleScripts/$($folder.BaseName)/en-us/$($sample.BaseName).md"
        $mdFullPath = Join-Path -Path $location -ChildPath $mdRelativePath
        $scriptObject = @{
            $sample.Name = $mdRelativePathMkDocs
        }
        $null = $folderObject[$folder.BaseName].Add($scriptObject)
        if (Test-Path -Path $mdFullPath) { continue }
        if (-not (Test-Path -Path (Split-Path -Path $mdFullPath -Parent) )) 
        {
            $null = New-Item -ItemType Directory -Path (Split-Path -Path $mdFullPath -Parent)
        }

        $mdContent = @"
# $($folder.Name) - $($sample.BaseName)

INSERT TEXT HERE

``````powershell
$(Get-Content -Raw -Path $sample.FullName)
``````
"@
        $mdContent | Set-Content -Path $mdFullPath
    }

    $null = ($mkdocsContent.nav | Where-Object {$_.Keys -contains 'Sample scripts'})['Sample scripts'].Add($folderObject)
}

# Update mkdocs.yml as part of a new help commit
$null = ($mkdocsContent.nav | Where-Object {$_.Keys -contains 'Module help'})['Module help'] = New-Object System.Collections.ArrayList

foreach ($moduleName in ($Module | Sort-Object))
{
    $moduleObject = @{$moduleName = New-Object System.Collections.ArrayList}
    foreach ($command in (Get-Command -Module $moduleName))
    {
        $commandObject = @{
            $command.Name = "$moduleName/en-us/$($command.Name).md"
        }
        $null = $moduleObject.$moduleName.Add($commandObject)
    }

    $null = ($mkdocsContent.nav | Where-Object {$_.Keys -contains 'Module help'})['Module help'].Add($moduleObject)
}

$mkdocsContent | ConvertTo-Yaml -OutFile $mkdocs -Force
