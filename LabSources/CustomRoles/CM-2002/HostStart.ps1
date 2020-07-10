Param (
    
    [Parameter(Mandatory)]
    [String]$ComputerName,
    
    [Parameter(Mandatory)]
    [String]$CMSiteCode,

    [Parameter(Mandatory)]
    [String]$CMSiteName,

    [Parameter(Mandatory)]
    [ValidatePattern('^EVAL$|^\w{5}-\w{5}-\w{5}-\w{5}-\w{5}$', Options = 'IgnoreCase')]
    [String]$CMProductId,

    [Parameter(Mandatory)]
    [String]$CMBinariesDirectory,

    [Parameter(Mandatory)]
    [String]$CMPreReqsDirectory,

    [Parameter(Mandatory)]
    [String]$CMDownloadURL,

    [Parameter(Mandatory)]
    [String]$ADKDownloadURL,

    [Parameter(Mandatory)]
    [String]$ADKDownloadPath,

    [Parameter(Mandatory)]
    [String]$WinPEDownloadURL,

    [Parameter(Mandatory)]
    [String]$WinPEDownloadPath,

    [Parameter(Mandatory)]
    [String]$LogViewer,

    [Parameter()]
    [String]$DoNotDownloadWMIEv2,

    [Parameter(Mandatory)]
    [String]$Version,

    [Parameter(Mandatory)]
    [String]$Branch,

    [Parameter(Mandatory)]
    [String]$AdminUser,

    [Parameter(Mandatory)]
    [String]$AdminPass

)

$script = Get-Command -Name $PSScriptRoot\Invoke-DownloadMisc.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-DownloadMisc.ps1 @param

$script = Get-Command -Name $PSScriptRoot\Invoke-DownloadADK.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-DownloadADK.ps1 @param

$script = Get-Command -Name $PSScriptRoot\Invoke-DownloadCM.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-DownloadCM.ps1 @param

$script = Get-Command -Name $PSScriptRoot\Invoke-InstallCM.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-InstallCM.ps1 @param

$script = Get-Command -Name $PSScriptRoot\Invoke-UpdateCM.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-UpdateCM.ps1 @param

$script = Get-Command -Name $PSScriptRoot\Invoke-CustomiseCM.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-CustomiseCM.ps1 @param

Get-LabVM | ForEach-Object {
    Dismount-LabIsoImage -ComputerName $_.Name -SupressOutput
}
