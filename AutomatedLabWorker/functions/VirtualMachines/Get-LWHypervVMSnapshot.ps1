function Get-LWHypervVMSnapshot
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param
    (
        [string[]]$VMName,

        [string]$Name
    )

    Write-LogFunctionEntry

    (Hyper-V\Get-VMSnapshot @PSBoundParameters).ForEach({
            [AutomatedLab.Snapshot]::new($_.Name, $_.VMName, $_.CreationTime)
    })

    Write-LogFunctionExit
}
