﻿param(
    [Parameter(Mandatory)]
    [string]$SolutionDir
)

Push-Location

Microsoft.PowerShell.Utility\Write-Host 'Restoring AutomatedLab.Common.psd1'
Remove-Item -Path $SolutionDir\AutomatedLab.Common\AutomatedLab.Common\AutomatedLab.Common.psd1
Rename-Item -Path $SolutionDir\AutomatedLab.Common\AutomatedLab.Common\AutomatedLab.Common.psd1.original -NewName AutomatedLab.Common.psd1

Microsoft.PowerShell.Utility\Write-Host 'Restoring Includes.wxi'
Remove-Item -Path $SolutionDir\Installer\Includes.wxi
Rename-Item -Path $SolutionDir\Installer\Includes.wxi.original -NewName Includes.wxi

Microsoft.PowerShell.Utility\Write-Host 'Restoring Product.wxs'
Remove-Item -Path $SolutionDir\Installer\Product.wxs
Rename-Item -Path $SolutionDir\Installer\Product.wxs.original -NewName Product.wxs

Pop-Location
