set-location $PSScriptRoot
Get-childitem "..\..\AutomatedLab\*AutomatedLab.dll" -recurse | % {Add-Type -Path $_.FullName}