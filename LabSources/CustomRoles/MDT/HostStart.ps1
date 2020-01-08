param(
    [Parameter(Mandatory)]
    [string]$DeploymentFolder,

    [Parameter(Mandatory)]
    [string]$DeploymentShare,

    [Parameter(Mandatory)]
    [string]$InstallUserID,
    
    [Parameter(Mandatory)]
    [string]$InstallPassword,

    [Parameter(Mandatory)]
    [string]$ComputerName,

    [Parameter(Mandatory)]
    [string[]]$OperatingSystems,

    [Parameter(Mandatory)]
    [string]$AdkDownloadUrl,

    [Parameter(Mandatory)]
    [string]$AdkDownloadPath,

    [Parameter(Mandatory)]
    [string]$AdkWinPeDownloadUrl,
    
    [Parameter(Mandatory)]
    [string]$AdkWinPeDownloadPath,

    [Parameter(Mandatory)]
    [string]$MdtDownloadUrl
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
