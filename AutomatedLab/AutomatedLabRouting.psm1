#region Install-LabRouting
function Install-LabRouting
{
    [CmdletBinding()]
    param (
        [int]$InstallationTimeout = 15,

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = (Get-LabConfigurationItem -Name DefaultProgressIndicator)
    )

    Write-LogFunctionEntry

    if (-not $PSBoundParameters.ContainsKey('ProgressIndicator')) { $PSBoundParameters.Add('ProgressIndicator', $ProgressIndicator) } #enables progress indicator

    $roleName = [AutomatedLab.Roles]::Routing

    if (-not (Get-LabVM))
    {
        Write-ScreenInfo -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first' -Type Warning
        Write-LogFunctionExit
        return
    }

    $machines = Get-LabVM -Role $roleName | Where-Object HostType -eq 'HyperV'

    if (-not $machines)
    {
        return
    }

    Write-ScreenInfo -Message 'Waiting for machines with Routing Role to startup' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 15

    Write-ScreenInfo -Message 'Configuring Routing role...' -NoNewLine
    $jobs = Install-LabWindowsFeature -ComputerName $machines -FeatureName RSAT ,Routing, RSAT-RemoteAccess -IncludeAllSubFeature -NoDisplay -AsJob -PassThru
    Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -Timeout 15 -NoDisplay -NoNewLine

    Restart-LabVM -ComputerName $machines -Wait -NoDisplay

    $jobs = @()

    foreach ($machine in $machines)
    {
        $externalAdapters = $machine.NetworkAdapters | Where-Object { $_.VirtualSwitch.SwitchType -eq 'External' }

        if ($externalAdapters.Count -gt 1)
        {
            Write-Error "Automatic configuration of routing can only be done if there is 0 or 1 network adapter connected to an external network switch. The machine '$machine' knows about $($externalAdapters.Count) externally connected adapters"
            continue
        }

        if ($externalAdapters)
        {
            $mac = $machine.NetworkAdapters | Where-Object { $_.VirtualSwitch.SwitchType -eq 'External' } | Select-Object -ExpandProperty MacAddress
            $mac = ($mac | Get-StringSection -SectionSize 2) -join ':'
        }

        $parameters = @{}
        $parameters.Add('ComputerName', $machine)
        $parameters.Add('ActivityName', 'ConfigurationRouting')
        $parameters.Add('Verbose', $VerbosePreference)
        $parameters.Add('Scriptblock', {
                $VerbosePreference = 'Continue'
                Write-Verbose 'Setting up routing...'

                Set-Service -Name RemoteAccess -StartupType Automatic
                Start-Service -Name RemoteAccess

                Write-Verbose '...done'

                if (-not $args[0])
                {
                    Write-Verbose 'No externally connected adapter available'
                    return
                }

                Write-Verbose 'Setting up NAT...'

                $externalAdapter = Get-CimInstance -Class Win32_NetworkAdapter -Filter ('MACAddress = "{0}"' -f $args[0]) |
                    Select-Object -ExpandProperty NetConnectionID

                netsh.exe routing ip nat install

                netsh.exe routing ip nat add interface $externalAdapter

                netsh.exe routing ip nat set interface $externalAdapter mode=full

                netsh.exe ras set conf confstate = enabled

                netsh.exe routing ip dnsproxy install

                Restart-Service -Name RemoteAccess

                Write-Verbose '...done'
            }
        )
        $parameters.Add('ArgumentList', $mac)

        $jobs += Invoke-LabCommand @parameters -AsJob -PassThru -NoDisplay
    }

    if (Get-LabVM -Role RootDC)
    {
        Write-PSFMessage "This lab knows about an Active Directory, calling 'Set-LabADDNSServerForwarder'"
        Set-LabADDNSServerForwarder
    }

    Write-ScreenInfo -Message 'Waiting for configuration of routing to complete' -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -Timeout $InstallationTimeout -NoDisplay -NoNewLine

    #to make sure the routing service works, restart the routers
    Write-PSFMessage "Restarting machines '$($machines -join ', ')'"
    Restart-LabVM -ComputerName $machines -Wait -NoNewLine

    Write-ProgressIndicatorEnd
    Write-LogFunctionExit
}
#endregion Install-LabRouting

#region Set-LabADDNSServerForwarder
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
#endregion Set-LabADDNSServerForwarder
