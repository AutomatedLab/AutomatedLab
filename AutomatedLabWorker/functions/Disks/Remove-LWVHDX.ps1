function Remove-LWVHDX
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param (
        #Path to reference VHD
        [Parameter(Mandatory = $true)]
        [string]$VhdxPath
    )

    Write-LogFunctionEntry

    $VmDisk = Get-VHD -Path $VhdxPath -ErrorAction SilentlyContinue
    if (-not $VmDisk)
    {
        Write-ScreenInfo -Message "VHDX '$VhdxPath' does not exist, cannot remove it" -Type Warning
    }
    else
    {
        $VmDisk | Remove-Item
        Write-PSFMessage "VHDX '$($vmDisk.Path)' removed"
    }

    Write-LogFunctionExit
}
