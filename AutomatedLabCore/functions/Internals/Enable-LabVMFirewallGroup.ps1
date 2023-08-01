function Enable-LabVMFirewallGroup
{

    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string[]]$FirewallGroup
    )

    Write-LogFunctionEntry

    $machine = Get-LabVM -ComputerName $ComputerName

    Invoke-LabCommand -ComputerName $machine -ActivityName 'Enable firewall group' -NoDisplay -ScriptBlock `
    {
        param
        (
            [string]$FirewallGroup
        )

        $FirewallGroups = $FirewallGroup.Split(';')

        foreach ($group in $FirewallGroups)
        {
            Write-Verbose -Message "Enable firewall group '$group' on '$(hostname)'"
            netsh.exe advfirewall firewall set rule group="$group" new enable=Yes
        }
    } -ArgumentList ($FirewallGroup -join ';')

    Write-LogFunctionExit
}
