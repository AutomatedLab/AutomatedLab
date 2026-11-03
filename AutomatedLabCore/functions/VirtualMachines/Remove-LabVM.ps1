function Remove-LabVM
{
    [CmdletBinding(DefaultParameterSetName='ByName')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )

    begin
    {
        Write-LogFunctionEntry

        $lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }

        $machines = [System.Collections.Generic.List[object]]::new()

        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $machines = $lab.Machines
        }
    }

    process
    {
        $null = $lab.Machines | Where-Object Name -in $ComputerName | Foreach-Object {$machines.Add($_)}
    }

    end
    {
        if (-not $machines)
        {
            $message = 'No machine found to remove'
            Write-LogFunctionExitWithError -Message $message
            return
        }

        foreach ($machine in $machines)
        {
            $doNotUseGetHostEntry = Get-LabConfigurationItem -Name DoNotUseGetHostEntryInNewLabPSSession
            if (-not $doNotUseGetHostEntry)
            {
                $machineName = (Get-HostEntry -Hostname $machine).IpAddress.IpAddressToString
            }

            if (-not [string]::IsNullOrEmpty($machine.FriendlyName) -or (Get-LabConfigurationItem -Name SkipHostFileModification))
            {
                $machineName = $machine.IPV4Address
            }

            Get-PSSession | Where-Object {$_.ComputerName -eq $machineName} | Remove-PSSession

            Write-ScreenInfo -Message "Removing Lab VM '$($machine.Name)' (and its associated disks)"

            if ($virtualNetworkAdapter.HostType -eq 'VMWare')
            {
                Write-Error 'Managing networks is not yet supported for VMWare'
                continue
            }

            $proxmoxRemoval = $null
            if ($machine.HostType -eq 'HyperV')
            {
                Remove-LWHypervVM -Name $machine.ResourceName
            }
            elseif ($machine.HostType -eq 'Azure')
            {
                Remove-LWAzureVM -Name $machine.ResourceName
            }
            elseif ($machine.HostType -eq 'VMWare')
            {
                Remove-LWVMWareVM -Name $machine.ResourceName
            }
            elseif ($machine.HostType -eq 'Proxmox')
            {
                # The lab stores the VMID as text; a value that is not a number counts as unknown
                $vmId = 0
                $null = [int]::TryParse($machine.ProxmoxProperties['VmId'], [ref]$vmId)
                $proxmoxRemoval = Remove-LWProxmoxVM -Name $machine.ResourceName -VmId $vmId
            }

            UnInstall-LabSshKnownHost -ComputerName $machine

            UnInstall-LabSshKnownHost -ComputerName $machine

            if ((Get-HostEntry -Section (Get-Lab).Name.ToLower() -HostName $machine))
            {
                Remove-HostEntry -Section (Get-Lab).Name.ToLower() -HostName $machine
            }

            if ($machine.HostType -eq 'Proxmox' -and $proxmoxRemoval.Outcome -ne 'Removed')
            {
                Write-ScreenInfo -Message "Lab VM '$machine' was not found, nothing to remove"
            }
            else
            {
                Write-ScreenInfo -Message "Lab VM '$machine' has been removed"
            }
        }
    }
}
