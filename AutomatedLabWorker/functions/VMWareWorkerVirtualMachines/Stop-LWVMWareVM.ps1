function Stop-LWVMWareVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    foreach ($name in $ComputerName)
    {
        if (VMware.VimAutomation.Core\Get-VM -Name $name)
        {
            $result = Shutdown-VMGuest -VM $name -ErrorAction SilentlyContinue -Confirm:$false
            if ($result.PowerState -ne "PoweredOff")
            {
                Write-Error "Could not stop machine '$name'"
            }
        }
        else
        {
            Write-ScreenInfo "The machine '$name' does not exist on the connected ESX Server" -Type Warning
        }
    }

    Write-LogFunctionExit
}
