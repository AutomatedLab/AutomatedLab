function Repair-LWProxmoxNetworkConfig
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName

    if (-not $machines)
    {
        Write-LogFunctionExit
        return
    }

    # If MAC addresses are empty in the lab definition, retrieve them from the Proxmox VM config
    $needsExport = $false
    foreach ($machine in $machines)
    {
        $emptyMacAdapters = @($machine.NetworkAdapters | Where-Object { [string]::IsNullOrEmpty($_.MacAddress) })
        if ($emptyMacAdapters.Count -gt 0)
        {
            Write-PSFMessage -Message "Fetching MAC addresses from Proxmox VM config for '$($machine.ResourceName)'"
            $vmConfig = Get-LWProxmoxVMConfig -ComputerName $machine.ResourceName -NoCache
            if ($vmConfig)
            {
                $adapterIndex = 0
                foreach ($adapter in $machine.NetworkAdapters)
                {
                    if ([string]::IsNullOrEmpty($adapter.MacAddress))
                    {
                        $netValue = $vmConfig."net$adapterIndex"
                        if ($netValue -match '(?:virtio|vmxnet3|e1000e?|rtl8139)=([0-9A-Fa-f:]{17})')
                        {
                            $adapter.MacAddress = ($matches[1] -replace ':', '')
                            Write-PSFMessage -Message "Recovered MAC for adapter $adapterIndex on '$($machine.ResourceName)': '$($adapter.MacAddress)'"
                            $needsExport = $true
                        }
                    }
                    $adapterIndex++
                }
            }
        }
    }
    if ($needsExport)
    {
        Export-Lab
    }

    # Build a lookup of adapters keyed by machine name so each remote machine can find its own config
    $adaptersByMachine = @{}
    foreach ($machine in $machines)
    {
        $adaptersByMachine[$machine.ResourceName] = $machine.NetworkAdapters
    }
    $allAdaptersStream = [System.Management.Automation.PSSerializer]::Serialize($adaptersByMachine, 4)

    Invoke-LabCommand -ComputerName $machines -ActivityName 'Network config (renaming and ordering)' -ScriptBlock {
        Write-Verbose 'Renaming network adapters'
        $allAdapters = [System.Management.Automation.PSSerializer]::Deserialize($allAdaptersStream)
        $machineAdapter = $allAdapters[$env:COMPUTERNAME]

        if (-not $machineAdapter)
        {
            Write-Verbose "No adapter configuration found for $env:COMPUTERNAME"
            return
        }

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

            $mac = (Get-StringSection -String $adapterInfo.MacAddress -SectionSize 2) -join '-'
            Write-Verbose "Renaming adapter with MAC '$mac' -> '$newName'"
            Get-NetAdapter | Where-Object MacAddress -eq $mac | Rename-NetAdapter -NewName $newName
        }
    } -Function (Get-Command -Name Get-StringSection, Add-StringIncrement) -Variable (Get-Variable -Name allAdaptersStream) -NoDisplay

    Write-LogFunctionExit
}
