function Set-LabADDNSServerForwarder
{
    [CmdletBinding()]
    param ( )

    Write-PSFMessage 'Setting DNS fowarder on all domain controllers in root domains'

    $rootDcs = Get-LabVM -Role RootDC

    $rootDomains = $rootDcs.DomainName

    $dcs = Get-LabVM -Role RootDC, DC | Where-Object DomainName -in $rootDomains
    $router = Get-LabVM -Role Routing
    Write-PSFMessage "Root DCs are '$dcs'"

    foreach ($dc in $dcs)
    {
        $gateway = if ($dc -eq $router)
        {
            Invoke-LabCommand -ActivityName 'Get default gateway' -ComputerName $dc -ScriptBlock {

                Get-CimInstance -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway } | Select-Object -ExpandProperty DefaultIPGateway | Select-Object -First 1

            } -PassThru -NoDisplay
        }
        else
        {
            $netAdapter = $dc.NetworkAdapters | Where-Object Ipv4Gateway
            $netAdapter.Ipv4Gateway.AddressAsString
        }

        Write-PSFMessage "Read gateway '$gateway' from interface '$($netAdapter.InterfaceName)' on machine '$dc'"

        $defaultDnsForwarder1 = Get-LabConfigurationItem -Name DefaultDnsForwarder1
        $defaultDnsForwarder2 = Get-LabConfigurationItem -Name DefaultDnsForwarder2
        Invoke-LabCommand -ActivityName ResetDnsForwarder -ComputerName $dc -ScriptBlock {
            dnscmd /resetforwarders $args[0] $args[1]
        } -ArgumentList $defaultDnsForwarder1, $defaultDnsForwarder2 -AsJob -NoDisplay
    }
}
