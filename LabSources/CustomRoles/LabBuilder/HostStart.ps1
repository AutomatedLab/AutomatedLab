param(
    [Parameter(Mandatory)]
    [string]$ComputerName
)

if (-not (Get-Lab))
{
    Import-Lab -Name $data.Name
}

$polarisUri = 'https://github.com/PowerShell/Polaris/archive/master.zip'

# Enable Virtualization
$vm = Get-LabVm -Role LabBuilder
Stop-LabVm -ComputerName $vm
$hyperVvm = Get-Vm -Name $vm.Name
$hyperVvm | Set-VMProcessor -ExposeVirtualizationExtensions $true
Start-LabVM $vm

# Download Polaris (as long as it isn't in the Gallery)
$downloadPath = Join-Path -Path (Get-LabSourcesLocationInternal -Local) -ChildPath SoftwarePackages\Polaris.zip
$polarisArchive = Get-LabInternetFile -Uri $polarisUri -Path $downloadPath -PassThru
Copy-LabFileItem -Path $polarisArchive.Fullname -ComputerName $vm
Copy-LabFileItem -Path .\PolarisLabBuilder.ps1 -ComputerName $vm

Invoke-LabCommand -ComputerName $vm -ActivityName EnablePolaris -ScriptBlock {
    Expand-Archive -Path C:\Polaris.zip -DestinationPath C:\
    Rename-Item -Path C:\Polaris-master -NewName C:\Polaris
    Copy-Item -Recurse -Path C:\Polaris 'C:\Program Files\WindowsPowerShell\Modules'

    $trigger = New-ScheduledTaskTrigger -Daily -At 9:00
    $action = New-ScheduledTaskAction -Execute "$pshome\powershell.exe" -Argument '-NoProfile -FilePath "C:\PolarisLabBuilder.ps1'
    Register-ScheduledTask -TaskName AutomatedLabBuilder -Action $action -Trigger $trigger
}
