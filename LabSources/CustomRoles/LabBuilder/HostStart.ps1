param(
    [Parameter(Mandatory)]
    [string]
    $ComputerName
)

if (-not (Get-Lab -ErrorAction SilentlyContinue))
{
    Import-Lab -Name $data.Name -NoDisplay -NoValidation
}

$polarisUri = 'https://github.com/PowerShell/Polaris/archive/master.zip'

# Enable Virtualization
$vm = Get-LabVm -ComputerName $ComputerName
Stop-LabVm -ComputerName $vm -Wait
$hyperVvm = Get-Vm -Name $vm.Name
$hyperVvm | Set-VMProcessor -ExposeVirtualizationExtensions $true
Start-LabVM $vm

Invoke-LabCommand -ComputerName $ComputerName -ScriptBlock {
    Get-Disk | Where-Object IsOffline | Set-Disk -IsOffline $false
}

# Download Polaris (as long as it isn't in the Gallery)
$downloadPath = Join-Path -Path (Get-LabSourcesLocationInternal -Local) -ChildPath SoftwarePackages\Polaris.zip
$polarisArchive = Get-LabInternetFile -Uri $polarisUri -Path $downloadPath -PassThru
Copy-LabFileItem -Path $polarisArchive.Path -ComputerName $vm
Copy-LabFileItem -Path $PSScriptRoot\PolarisLabBuilder.ps1 -ComputerName $vm

$driveLetter = if ($vm.Disks.Count -gt 0)
{
    'D'
}
else
{
    'C'
}

$session = New-LabPSSession -Machine $vm
Send-ModuleToPSSession -Module (Get-Module AutomatedLab -ListAvailable)[0] -Session $session
Copy-LabFileItem -Path $global:labSources -ComputerName $ComputerName -DestinationFolderPath "$($driveLetter):\" -Recurse

Invoke-LabCommand -ComputerName $vm -ActivityName EnablePolaris -ScriptBlock {
    Expand-Archive -Path C:\Polaris.zip -DestinationPath C:\
    Rename-Item -Path C:\Polaris-master -NewName C:\Polaris
    Copy-Item -Recurse -Path C:\Polaris 'C:\Program Files\WindowsPowerShell\Modules'

    $trigger = New-ScheduledTaskTrigger -Daily -At 9:00
    $action = New-ScheduledTaskAction -Execute "$pshome\powershell.exe" -Argument '-NoProfile -File "C:\PolarisLabBuilder.ps1'
    Register-ScheduledTask -TaskName AutomatedLabBuilder -Action $action -Trigger $trigger
} -Variable (Get-Variable driveLetter)
