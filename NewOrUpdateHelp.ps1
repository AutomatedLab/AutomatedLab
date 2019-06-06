param
(
    [switch]
    $Create,

    [string[]]
    $Module = @('AutomatedLabUnattended' # Careful... This is also the import order!
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
    Join-Path $location -ChildPath "Help\$moduleName\en-us"
    Import-Module .\$moduleName -Force
    if ($Create.IsPresent)
    {
        $null = New-MarkdownHelp -Module $moduleName -WithModulePage -OutputFolder $outputFolder
    }
}

if (-not $Create.IsPresent)
{
    Update-MarkdownHelpModule -Path $outPath -RefreshModulePage
}

# Update mkdocs.yml as part of a new help commit
$mkdocs = Join-Path -Path $location -ChildPath mkdocs.yml -Resolve -ErrorAction Stop
$mkdocsContent = Get-Content -Raw -Path $mkdocs | ConvertFrom-Yaml

foreach ($moduleName in ($Module | Sort))
{
    $moduleObject = @{$moduleName = New-Object System.Collections.ArrayList}
    foreach ($command in (Get-Command -Module $moduleName))
    {
        $commandObject = @{
            $command.Name = "$moduleName/en-us/$($command.Name).md"
        }
        $null = $moduleObject.$moduleName.Add($commandObject)
    }

    $null = $mkdocsContent.nav.Add($moduleObject)
}

$mkdocsContent | ConvertTo-Yaml -OutFile $mkdocs -Force
