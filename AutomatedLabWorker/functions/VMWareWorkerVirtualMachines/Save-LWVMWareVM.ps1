function Save-LWVMWareVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    VMware.VimAutomation.Core\Suspend-VM -VM $ComputerName -ErrorAction SilentlyContinue -Confirm:$false

    Write-LogFunctionExit
}
