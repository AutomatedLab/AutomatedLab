param(
    
    [Parameter(Mandatory)]
    [string]$ComputerName,
    
    [Parameter(Mandatory)]
    [string]$SccmSiteCode,

    [Parameter(Mandatory)]
    [string]$SccmBinariesDirectory,

    [Parameter(Mandatory)]
    [string]$SccmPreReqsDirectory,

    [Parameter(Mandatory)]
    [string]$AdkDownloadPath,

    [Parameter(Mandatory)]
    [string]$SqlServerName
)

$script = Get-Command -Name $PSScriptRoot\DownloadAdk.ps1 
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters 
& $PSScriptRoot\DownloadAdk.ps1 @param 

$script = Get-Command -Name $PSScriptRoot\InstallSCCM.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters 
& $PSScriptRoot\InstallSCCM.ps1 @param 