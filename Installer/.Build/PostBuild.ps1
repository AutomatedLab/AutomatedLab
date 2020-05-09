param(
    [Parameter(Mandatory)]
    [string]$SolutionDir,

    [Parameter()]
    [string[]]
    $ExternalDependency = @('PSFramework', 'newtonsoft.json', 'SHiPS', 'xPSDesiredStateConfiguration', 'xDscDiagnostics', 'xWebAdministration'),

    [Parameter()]
    [string[]]
    $InternalModules = @('AutomatedLab','AutomatedLab.Common\AutomatedLab.Common','AutomatedLab.Recipe', 'AutomatedLab.Ships','AutomatedLabDefinition','AutomatedLabNotifications','AutomatedLabTest','AutomatedLabUnattended','AutomatedLabWorker','HostsFile','PSFileTransfer','PSLog')
)

Remove-Item -Path (Join-Path $SolutionDir scratch) -Recurse -Force -ErrorAction SilentlyContinue

Push-Location

Microsoft.PowerShell.Utility\Write-Host 'Restoring Includes.wxi'
Remove-Item -Path $SolutionDir\Installer\Includes.wxi
Rename-Item -Path $SolutionDir\Installer\Includes.wxi.original -NewName Includes.wxi

Microsoft.PowerShell.Utility\Write-Host 'Restoring Product.wxs'
Remove-Item -Path $SolutionDir\Installer\Product.wxs
Rename-Item -Path $SolutionDir\Installer\Product.wxs.original -NewName Product.wxs

Pop-Location
