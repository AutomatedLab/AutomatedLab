function Start-LWVMWareVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,

        [int]$DelayBetweenComputers = 0
    )

    Write-LogFunctionEntry

    foreach ($name in $ComputerName)
    {
        $vm = $null
        $vm = VMware.VimAutomation.Core\Get-VM -Name $name
        if ($vm)
        {
            VMware.VimAutomation.Core\Start-VM $vm -ErrorAction SilentlyContinue | out-null
            $result = VMware.VimAutomation.Core\Get-VM $vm
            if ($result.PowerState -ne "PoweredOn")
            {
                Write-Error "Could not start machine '$name'"
            }
        }
        Start-Sleep -Seconds $DelayBetweenComputers
    }

    Write-LogFunctionExit
}
