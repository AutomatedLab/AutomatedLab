Write-Host "Publishing AutomatedLab library"
$projPath = Join-Path $env:APPVEYOR_BUILD_FOLDER -ChildPath 'LabXml/LabXml.csproj' -Resolve -ErrorAction Stop
dotnet publish $projPath -f netcoreapp2.2 -o (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER 'AutomatedLab/lib/core')
if (-not $IsLinux)
{
    dotnet publish $projPath -f net462 -o (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER 'AutomatedLab/lib/full')
}

Write-Host "'before_build' block"

Write-Host "Setting version number in files"
Add-AppveyorMessage -Message "Setting version number in files" -Category Information
Get-ChildItem -Filter *.psd1 -Recurse | ForEach-Object { if ($_.Directory.Name -eq $_.BaseName)
    {
        (Get-Content $_.FullName -Raw) -replace "ModuleVersion += '\d\.\d\.\d'", "ModuleVersion = '$env:APPVEYOR_BUILD_VERSION'" | Out-File $_.FullName
    }
}
