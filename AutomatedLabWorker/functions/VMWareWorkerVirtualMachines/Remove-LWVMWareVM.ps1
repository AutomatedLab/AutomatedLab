function Remove-LWVMWareVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    Param (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [switch]$AsJob,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    if ($AsJob)
    {
        $job = Start-Job -ScriptBlock {
            param (
                [Parameter(Mandatory)]
                [hashtable]$ComputerName
            )

            Add-PSSnapin -Name VMware.VimAutomation.Core, VMware.VimAutomation.Vds

            $vm = VMware.VimAutomation.Core\Get-VM -Name $ComputerName
            if ($vm)
            {
                if ($vm.PowerState -eq "PoweredOn")
                {
                    VMware.VimAutomation.Core\Stop-VM -VM $vm -Confirm:$false
                }
                VMware.VimAutomation.Core\Remove-VM -DeletePermanently -VM $ComputerName -Confirm:$false
            }
        } -ArgumentList $ComputerName


        if ($PassThru)
        {
            $job
        }
    }
    else
    {
        $vm = VMware.VimAutomation.Core\Get-VM -Name $ComputerName
        if ($vm)
        {
            if ($vm.PowerState -eq "PoweredOn")
            {
                VMware.VimAutomation.Core\Stop-VM -VM $vm -Confirm:$false
            }
            VMware.VimAutomation.Core\Remove-VM -DeletePermanently -VM $ComputerName -Confirm:$false
        }
    }

    Write-LogFunctionExit
}
