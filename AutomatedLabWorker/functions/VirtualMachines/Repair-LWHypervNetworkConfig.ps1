function Repair-LWHypervNetworkConfig
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry

    $machine = Get-LabVM -ComputerName $ComputerName
    $vm = Get-LWHypervVM -Name $machine.ResourceName

    if (-not $machine) { return } # No fixing this on a Linux VM

    Wait-LabVM -ComputerName $machine -NoNewLine
    $machineAdapterStream = [System.Management.Automation.PSSerializer]::Serialize($machine.NetworkAdapters,2)

    Invoke-LabCommand -ComputerName $machine -ActivityName "Network config on '$machine' (renaming and ordering)" -ScriptBlock {
        Write-Verbose "Renaming network adapters"
        #rename the adapters as defined in the lab
        $machineAdapter = [System.Management.Automation.PSSerializer]::Deserialize($machineAdapterStream)
        $newNames = @()
        foreach ($adapterInfo in $machineAdapter)
        {
            $newName = if ($adapterInfo.InterfaceName)
            {
                $adapterInfo.InterfaceName
            }
            else
            {
                $tempName = Add-StringIncrement -String $adapterInfo.VirtualSwitch.ResourceName
                while ($tempName -in $newNames)
                {
                    $tempName = Add-StringIncrement -String $tempName
                }
                $tempName
            }
            $newNames += $newName

            if (-not [string]::IsNullOrEmpty($adapterInfo.VirtualSwitch.FriendlyName))
            {
                $adapterInfo.VirtualSwitch.FriendlyName = $newName
            }
            else
            {
                $adapterInfo.VirtualSwitch.Name = $newName
            }

            $machineOs = [Environment]::OSVersion
            if ($machineOs.Version.Major -lt 6 -and $machineOs.Version.Minor -lt 2)
            {
                $mac = (Get-StringSection -String $adapterInfo.MacAddress -SectionSize 2) -join ':'
                $filter = 'MACAddress = "{0}"' -f $mac
                Write-Verbose "Looking for network adapter with using filter '$filter'"
                $adapter = Get-CimInstance -Class Win32_NetworkAdapter -Filter $filter

                Write-Verbose "Renaming adapter '$($adapter.NetConnectionID)' -> '$newName'"
                $adapter.NetConnectionID = $newName
                $adapter.Put()
            }
            else
            {
                $mac = (Get-StringSection -String $adapterInfo.MacAddress -SectionSize 2) -join '-'
                Write-Verbose "Renaming adapter '$($adapter.NetConnectionID)' -> '$newName'"
                Get-NetAdapter | Where-Object MacAddress -eq $mac | Rename-NetAdapter -NewName $newName
            }
        }

        #There is no need to change the network binding order in Windows 10 or 2016
        #Adjusting the Network Protocol Bindings in Windows 10 https://blogs.technet.microsoft.com/networking/2015/08/14/adjusting-the-network-protocol-bindings-in-windows-10/
        if ([System.Environment]::OSVersion.Version.Major -lt 10)
        {
            $retries = $machineAdapter.Count * $machineAdapter.Count * 2
            $i = 0

            $sortedAdapters = New-Object System.Collections.ArrayList
            $sortedAdapters.AddRange(@($machineAdapter | Where-Object { $_.VirtualSwitch.SwitchType.Value -ne 'Internal' }))
            $sortedAdapters.AddRange(@($machineAdapter | Where-Object { $_.VirtualSwitch.SwitchType.Value -eq 'Internal' }))

            Write-Verbose "Setting the network order"
            [array]::Reverse($machineAdapter)
            foreach ($adapterInfo in $sortedAdapters)
            {
                Write-Verbose "Setting the order for adapter '$($adapterInfo.VirtualSwitch.ResourceName)'"
                do {
                    nvspbind.exe /+ $adapterInfo.VirtualSwitch.ResourceName ms_tcpip | Out-File -FilePath c:\nvspbind.log -Append
                    $i++

                    if ($i -gt $retries) { return }
                }  until ($LASTEXITCODE -eq 14)
            }
        }

    } -Function (Get-Command -Name Get-StringSection, Add-StringIncrement) -Variable (Get-Variable -Name machineAdapterStream) -NoDisplay

    foreach ($adapterInfo in $machineAdapter)
    {
        $vmAdapter = $vm | Get-VMNetworkAdapter -Name $adapterInfo.VirtualSwitch.ResourceName

        if ($adapterInfo.VirtualSwitch.ResourceName -ne $vmAdapter.SwitchName)
        {
            $vmAdapter | Connect-VMNetworkAdapter -SwitchName $adapterInfo.VirtualSwitch.ResourceName
        }
    }

    Write-LogFunctionExit
}
