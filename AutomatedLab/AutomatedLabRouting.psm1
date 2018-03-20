#region Install-LabRouting
function Install-LabRouting
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = 15
    )
    
    Write-LogFunctionEntry

    Write-ScreenInfo -Message 'Configuring Routing role...'
    
    $roleName = [AutomatedLab.Roles]::Routing
    
    if (-not (Get-LabVM))
    {
        Write-Warning -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        Write-LogFunctionExit
        return
    }
    
    $machines = Get-LabVM -Role $roleName | Where-Object HostType -eq 'HyperV'
    
    if (-not $machines)
    {
        return
    }
    
    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 15

    Install-LabWindowsFeature -ComputerName $machines -FeatureName Routing, RSAT-RemoteAccess -IncludeAllSubFeature
    
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
            
                $externalAdapter = Get-WmiObject -Class Win32_NetworkAdapter -Filter ('MACAddress = "{0}"' -f $args[0]) |
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
        Write-Verbose "This lab knows about an Active Directory, calling 'Set-LabADDNSServerForwarder'"
        Set-LabADDNSServerForwarder
    }
    
    Write-ScreenInfo -Message 'Waiting for configuration of routing to complete' -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -Timeout $InstallationTimeout -NoDisplay

    #to make sure the routing service works, restart the routers
    Write-Verbose "Restarting machines '$($machines -join ', ')'"
    Restart-LabVM -ComputerName $machines -Wait
    
    Write-LogFunctionExit
}
#endregion Install-LabRouting

#region Set-LabADDNSServerForwarder
function Set-LabADDNSServerForwarder
{
    # .ExternalHelp AutomatedLab.Help.xml

    Write-Verbose 'Setting DNS fowarder on all domain controllers in root domains'

    $rootDcs = Get-LabVM -Role RootDC

    $rootDomains = $rootDcs.DomainName

    $dcs = Get-LabVM -Role RootDC, DC | Where-Object DomainName -in $rootDomains
    $router = Get-LabVM -Role Routing
    Write-Verbose "Root DCs are '$dcs'"

    foreach ($dc in $dcs)
    {
        $gateway = if ($dc -eq $router)
        {
            Invoke-LabCommand -ActivityName 'Get default gateway' -ComputerName $dc -ScriptBlock {
            
                Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway } | Select-Object -ExpandProperty DefaultIPGateway | Select-Object -First 1
                
            } -PassThru -NoDisplay
        }
        else
        {
            $netAdapter = $dc.NetworkAdapters | Where-Object Ipv4Gateway
            $netAdapter.Ipv4Gateway.AddressAsString
        }

        Write-Verbose "Read gateway '$gateway' from interface '$($netAdapter.InterfaceName)' on machine '$dc'"
    
        Invoke-LabCommand -ActivityName ResetDnsForwarder -ComputerName $dc -ScriptBlock {
            dnscmd /resetforwarders $args[0]
        } -ArgumentList $gateway -AsJob
    }
}
#endregion Set-LabADDNSServerForwarder
