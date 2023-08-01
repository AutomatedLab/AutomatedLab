function Add-LWVMVHDX
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$VMName,

        [Parameter(Mandatory = $true)]
        [string]$VhdxPath
    )

    Write-LogFunctionEntry

    if (-not (Test-Path -Path $VhdxPath))
    {
        Write-Error 'VHDX cannot be found'
        return
    }

    $vm = Get-LWHypervVM -Name $VMName -ErrorAction SilentlyContinue
    if (-not $vm)
    {
        Write-Error 'VM cannot be found'
        return
    }

    Add-VMHardDiskDrive -VM $vm -Path $VhdxPath

    Write-LogFunctionExit
}
