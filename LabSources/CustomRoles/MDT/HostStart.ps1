param(
    [string]$DeploymentFolderLocation = 'C:\DeploymentShare',

    [string]$InstallUserID = 'MdtService',
    
    [string]$InstallPassword = 'Somepass1',

    [Parameter(Mandatory)]
    [string]$ComputerName,

    [Parameter(Mandatory)]
    [string[]]$OperatingSystems,

    [string]$AdkDownloadPath = "$labSources\SoftwarePackages\ADK"
)

Import-Lab -Name $data.Name
$vm = Get-LabVM -ComputerName $ComputerName
if ($vm.OperatingSystem.Version.Major -lt 10)
{
	Write-Error "The MDT custom role is supported only on a Windows Server with version 10.0.0.0 or higher. The computer '$vm' has the operating system '$($vm.OperatingSystem)' ($($vm.OperatingSystem.Version)). Please change the operating system of the machine and try again."
	return
}

$script = Get-Command -Name $PSScriptRoot\DownloadAdk.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\DownloadAdk.ps1 @param

$script = Get-Command -Name $PSScriptRoot\InstallMDT.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\InstallMDT.ps1 @param