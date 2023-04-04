function Reset-DNSConfiguration
{
    [CmdletBinding()]
    param
    (
        [string[]]$ComputerName,

        [int]$ProgressIndicator,

        [switch]$NoNewLine
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName

    $jobs = @()
    foreach ($machine in $machines)
    {
        $jobs += Invoke-LabCommand -ComputerName $machine -ActivityName 'Reset DNS client configuration to match specified DNS configuration' -ScriptBlock `
        {
            param
            (
                $DnsServers
            )
            $AdapterNames = if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)
            {
                (Get-CimInstance -Namespace Root\CIMv2 -Class Win32_NetworkAdapter | Where-Object {$_.PhysicalAdapter}).NetConnectionID
            }
            else
            {
                (Get-WmiObject -Namespace Root\CIMv2 -Class Win32_NetworkAdapter | Where-Object {$_.PhysicalAdapter}).NetConnectionID
            }
            foreach ($AdapterName in $AdapterNames)
            {
                netsh.exe interface ipv4 set dnsservers "$AdapterName" static $DnsServers primary

                "netsh interface ipv6 delete dnsservers '$AdapterName' all"
                netsh.exe interface ipv6 delete dnsservers "$AdapterName" all
            }
        } -AsJob -PassThru -NoDisplay -ArgumentList $machine.DNSServers
    }

    Wait-LWLabJob -Job $jobs -NoDisplay -Timeout 30 -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine

    Write-LogFunctionExit
}
