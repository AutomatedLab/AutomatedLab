function Get-LWVMWareVMStatus
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    $result = @{ }

    foreach ($name in $ComputerName)
    {
        $vm = VMware.VimAutomation.Core\Get-VM -Name $name
        if ($vm)
        {
            if ($vm.PowerState -eq 'PoweredOn')
            {
                $result.Add($vm.Name, 'Started')
            }
            elseif ($vm.PowerState -eq 'PoweredOff')
            {
                $result.Add($vm.Name, 'Stopped')
            }
            else
            {
                $result.Add($vm.Name, 'Unknown')
            }
        }
    }

    $result

    Write-LogFunctionExit
}
