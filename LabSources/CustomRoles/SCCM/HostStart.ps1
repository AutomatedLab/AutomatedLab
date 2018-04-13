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

$sqlServer = Get-LabVM -Role SQLServer | Where-Object Name -eq $SqlServerName
$sccmServer = Get-LabVM -ComputerName $SccmServerName
if (-not $sqlServer)
{
    Write-Error "The specified SQL Server '$SqlServerName' does not exist in the lab."
    return
}    

if ($sccmServer.OperatingSystem.Version -lt 10.0 -or $SqlServer.OperatingSystem.Version -lt 10.0)
{
    Write-Error "The SCCM role requires the SCCM server and the SQL Server to be Windows 2016 or higher."
    return
}

$script = Get-Command -Name $PSScriptRoot\DownloadAdk.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\DownloadAdk.ps1 @param

$script = Get-Command -Name $PSScriptRoot\DownloadSccm.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\DownloadSccm.ps1 @param

$script = Get-Command -Name $PSScriptRoot\InstallSCCM.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\InstallSCCM.ps1 @param