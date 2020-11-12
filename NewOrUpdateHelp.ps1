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
        $null = New-MarkdownHelp -Module $moduleName -WithModulePage -OutputFolder $outputFolder -Force
    }
}

if (-not $Create.IsPresent)
{
    Update-MarkdownHelpModule -Path $outPath -RefreshModulePage
}

# Update mkdocs.yml as part of a new help commit
$mkdocs = Join-Path -Path $location -ChildPath mkdocs.yml -Resolve -ErrorAction Stop
$mkdocsContent = Get-Content -Raw -Path $mkdocs | ConvertFrom-Yaml
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
