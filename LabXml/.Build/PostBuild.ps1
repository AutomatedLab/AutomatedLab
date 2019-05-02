param(
    [Parameter(Mandatory)]
    [string]$SolutionDir,

    [Parameter(Mandatory)]
    [string]$TargetDir
)

Microsoft.PowerShell.Utility\Write-Host "Copy-Item -Path $TargetDir -Destination $SolutionDir\AutomatedLab\*.dll"
$tDir = (Resolve-Path -Path $TargetDir\..).Path

if (-not (Microsoft.PowerShell.Management\Test-Path -Path $SolutionDir\AutomatedLab\lib\core))
{
	$null = New-Item -Path $SolutionDir\AutomatedLab\lib\core -Force -ItemType Directory
}

if (-not (Microsoft.PowerShell.Management\Test-Path -Path $SolutionDir\AutomatedLab\lib\full))
{
	$null = New-Item -Path $SolutionDir\AutomatedLab\lib\full -Force -ItemType Directory
}

$coreClr = Get-ChildItem -Recurse -Filter *.dll -Path $tDir | Where {$_.FullName -match 'coreapp' }
$fullClr = Get-ChildItem -Recurse -Filter *.dll -Path $tDir | Where {$_.FullName -notmatch 'coreapp|standard' }

$coreClr | Copy-Item -Destination $SolutionDir\AutomatedLab\lib\core
$fullClr | Copy-Item -Destination $SolutionDir\AutomatedLab\lib\full