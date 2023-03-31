
$root = 'C:\tmp\AutomatedLab\AutomatedLab\functions'
$dest = 'C:\tmp\AutomatedLab\AutomatedLab\internal\functions'
foreach ($module in (Get-ChildItem ./AutomatedLab/*.psm1))
{
    $name = if ($module.BaseName -eq 'AutomatedLab')
    {
        'Core'
    }
    else
    {
        $module.BaseName -replace 'AutomatedLab'
    }

    $destination = Get-Item -Path (Join-Path $root $name) -ErrorAction SilentlyContinue
    if (-not $destination) {$destination = mkdir -Path (Join-Path $root $name)}

    Split-PSMDScriptFile -File $module.FullName -Path $destination.FullName
}

$manifest = Import-PowerShellDataFile -Path (Join-Path $root ../AutomatedLab.psd1)
$functions = (Get-ChildItem -Recurse -Path $root -Filter *.ps1).BaseName
$overflow = Compare-Object $manifest.FunctionsToExport $functions -PassThru | Where SideIndicator -eq '=>'
foreach ($item in $overflow)
{
    Get-ChildItem -Recurse -Path $root -Include "$($item).ps1" | Move-Item -Destination $dest
}

invoke-psmdTemplate -TemplateName MiniModule -Name AutomatedLabDefinition -Parameters @{Description = 'Infra functions'} -OutPath C:\tmp
Copy-Item ./AutomatedLabDefinition/AutomatedLabDefinition.psd1 C:\tmp\AutomatedLabDefinition\AutomatedLabDefinition\AutomatedLabDefinition.psd1 -Force
$root = 'C:\tmp\AutomatedLabDefinition\AutomatedLabDefinition\functions'
$dest = 'C:\tmp\AutomatedLabDefinition\AutomatedLabDefinition\internal\functions'
foreach ($module in (Get-ChildItem ./AutomatedLabDefinition/*.psm1))
{
    $name = if ($module.BaseName -eq 'AutomatedLabDefinition')
    {
        'Core'
    }
    else
    {
        $module.BaseName -replace 'AutomatedLabDefinition'
    }

    $destination = Get-Item -Path (Join-Path $root $name) -ErrorAction SilentlyContinue
    if (-not $destination) {$destination = mkdir -Path (Join-Path $root $name)}

    Split-PSMDScriptFile -File $module.FullName -Path $destination.FullName
}

$manifest = Import-PowerShellDataFile -Path (Join-Path $root ../AutomatedLabDefinition.psd1)
$functions = (Get-ChildItem -Recurse -Path $root -Filter *.ps1).BaseName
$overflow = Compare-Object $manifest.FunctionsToExport $functions -PassThru | Where SideIndicator -eq '=>'
foreach ($item in $overflow)
{
    Get-ChildItem -Recurse -Path $root -Include "$($item).ps1" | Move-Item -Destination $dest
}


invoke-psmdTemplate -TemplateName MiniModule -Name AutomatedLabWorker -Parameters @{Description = 'Infra functions'} -OutPath C:\tmp
Copy-Item ./AutomatedLabWorker/AutomatedLabWorker.psd1 C:\tmp\AutomatedLabWorker\AutomatedLabWorker\AutomatedLabWorker.psd1 -Force
$root = 'C:\tmp\AutomatedLabWorker\AutomatedLabWorker\functions'
$dest = 'C:\tmp\AutomatedLabWorker\AutomatedLabWorker\internal\functions'
foreach ($module in (Get-ChildItem ./AutomatedLabWorker/*.psm1))
{
    $name = if ($module.BaseName -eq 'AutomatedLabWorker')
    {
        'Core'
    }
    else
    {
        $module.BaseName -replace 'AutomatedLabWorker'
    }

    $destination = Get-Item -Path (Join-Path $root $name) -ErrorAction SilentlyContinue
    if (-not $destination) {$destination = mkdir -Path (Join-Path $root $name)}

    Split-PSMDScriptFile -File $module.FullName -Path $destination.FullName
}

$manifest = Import-PowerShellDataFile -Path (Join-Path $root ../AutomatedLabWorker.psd1)
$functions = (Get-ChildItem -Recurse -Path $root -Filter *.ps1).BaseName
$overflow = Compare-Object $manifest.FunctionsToExport $functions -PassThru | Where SideIndicator -eq '=>'
foreach ($item in $overflow)
{
    Get-ChildItem -Recurse -Path $root -Include "$($item).ps1" | Move-Item -Destination $dest
}


invoke-psmdTemplate -TemplateName MiniModule -Name HostsFile -Parameters @{Description = 'Infra functions'} -OutPath C:\tmp
Copy-Item ./HostsFile/HostsFile.psd1 C:\tmp\HostsFile\HostsFile\HostsFile.psd1 -Force
$root = 'C:\tmp\HostsFile\HostsFile\functions'
$dest = 'C:\tmp\HostsFile\HostsFile\internal\functions'
foreach ($module in (Get-ChildItem ./HostsFile/*.psm1))
{
    $name = if ($module.BaseName -eq 'HostsFile')
    {
        'Core'
    }
    else
    {
        $module.BaseName -replace 'HostsFile'
    }

    $destination = Get-Item -Path (Join-Path $root $name) -ErrorAction SilentlyContinue
    if (-not $destination) {$destination = mkdir -Path (Join-Path $root $name)}

    Split-PSMDScriptFile -File $module.FullName -Path $destination.FullName
}

$manifest = Import-PowerShellDataFile -Path (Join-Path $root ../HostsFile.psd1)
$functions = (Get-ChildItem -Recurse -Path $root -Filter *.ps1).BaseName
$overflow = Compare-Object $manifest.FunctionsToExport $functions -PassThru | Where SideIndicator -eq '=>'
foreach ($item in $overflow)
{
    Get-ChildItem -Recurse -Path $root -Include "$($item).ps1" | Move-Item -Destination $dest
}


invoke-psmdTemplate -TemplateName MiniModule -Name PSFileTransfer -Parameters @{Description = 'Infra functions'} -OutPath C:\tmp
Copy-Item ./PSFileTransfer/PSFileTransfer.psd1 C:\tmp\PSFileTransfer\PSFileTransfer\PSFileTransfer.psd1 -Force
$root = 'C:\tmp\PSFileTransfer\PSFileTransfer\functions'
$dest = 'C:\tmp\PSFileTransfer\PSFileTransfer\internal\functions'
foreach ($module in (Get-ChildItem ./PSFileTransfer/*.psm1))
{
    $name = if ($module.BaseName -eq 'PSFileTransfer')
    {
        'Core'
    }
    else
    {
        $module.BaseName -replace 'PSFileTransfer'
    }

    $destination = Get-Item -Path (Join-Path $root $name) -ErrorAction SilentlyContinue
    if (-not $destination) {$destination = mkdir -Path (Join-Path $root $name)}

    Split-PSMDScriptFile -File $module.FullName -Path $destination.FullName
}

$manifest = Import-PowerShellDataFile -Path (Join-Path $root ../PSFileTransfer.psd1)
$functions = (Get-ChildItem -Recurse -Path $root -Filter *.ps1).BaseName
$overflow = Compare-Object $manifest.FunctionsToExport $functions -PassThru | Where SideIndicator -eq '=>'
foreach ($item in $overflow)
{
    Get-ChildItem -Recurse -Path $root -Include "$($item).ps1" | Move-Item -Destination $dest
}


invoke-psmdTemplate -TemplateName MiniModule -Name PSLog -Parameters @{Description = 'Infra functions'} -OutPath C:\tmp
Copy-Item ./PSLog/PSLog.psd1 C:\tmp\PSLog\PSLog\PSLog.psd1 -Force
$root = 'C:\tmp\PSLog\PSLog\functions'
$dest = 'C:\tmp\PSLog\PSLog\internal\functions'
foreach ($module in (Get-ChildItem ./PSLog/*.psm1))
{
    $name = if ($module.BaseName -eq 'PSLog')
    {
        'Core'
    }
    else
    {
        $module.BaseName -replace 'PSLog'
    }

    $destination = Get-Item -Path (Join-Path $root $name) -ErrorAction SilentlyContinue
    if (-not $destination) {$destination = mkdir -Path (Join-Path $root $name)}

    Split-PSMDScriptFile -File $module.FullName -Path $destination.FullName
}

$manifest = Import-PowerShellDataFile -Path (Join-Path $root ../PSLog.psd1)
$functions = (Get-ChildItem -Recurse -Path $root -Filter *.ps1).BaseName
$overflow = Compare-Object $manifest.FunctionsToExport $functions -PassThru | Where SideIndicator -eq '=>'
foreach ($item in $overflow)
{
    Get-ChildItem -Recurse -Path $root -Include "$($item).ps1" | Move-Item -Destination $dest
}



invoke-psmdTemplate -TemplateName MiniModule -Name AutomatedLab.Recipe -Parameters @{Description = 'Infra functions'} -OutPath C:\tmp
invoke-psmdTemplate -TemplateName MiniModule -Name AutomatedLabNotifications -Parameters @{Description = 'Infra functions'} -OutPath C:\tmp
invoke-psmdTemplate -TemplateName MiniModule -Name AutomatedLabTest -Parameters @{Description = 'Infra functions'} -OutPath C:\tmp
Copy-Item ./AutomatedLabTest/AutomatedLabTest.psd1 C:\tmp\AutomatedLabTest\AutomatedLabTest\AutomatedLabTest.psd1 -Force
invoke-psmdTemplate -TemplateName MiniModule -Name AutomatedLabUnattended -Parameters @{Description = 'Infra functions'} -OutPath C:\tmp
Copy-Item ./AutomatedLabUnattended/AutomatedLabUnattended.psd1 C:\tmp\AutomatedLabUnattended\AutomatedLabUnattended\AutomatedLabUnattended.psd1 -Force