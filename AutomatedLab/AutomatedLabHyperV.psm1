function Install-LabHyperV
{
    [CmdletBinding()]
    param
    ( )

    Write-LogFunctionEntry

    $vms = Get-LabVm -Role HyperV

    Write-ScreenInfo -Message 'Exposing virtualization extensions...' -NoNewLine
    $hyperVVms = $vms | Where-Object -Property HostType -eq HyperV
    if ($null -ne $hyperVVms)
    {
        Stop-LabVm -Wait -ComputerName $hyperVVms
        $hyperVVms | Set-VMProcessor -ExposeVirtualizationExtensions $true
    }
    
    Start-LabVm -Wait -ComputerName $vms # Start all, regardless of Hypervisor
    Write-ScreenInfo -Message 'Done'

    # Enable Feature
    Write-ScreenInfo -Message "Enabling Hyper-V feature and waiting for restart of $($vms.Count) VMs..." -NoNewLine
    Install-LabWindowsFeature -ComputerName $vms -FeatureName Hyper-V -IncludeAllSubFeature -IncludeManagementTools -NoDisplay

    # Restart
    Restart-LabVm -ComputerName $vms -Wait -NoDisplay
    Write-ScreenInfo -Message 'Done'

    #Configure
    $settingsTable = @{ }

    foreach ($vm in $vms)
    {
        [hashtable]$roleParameters = ($vm.Roles | Where-Object Name -eq HyperV).Properties
        if ($roleParameters.Count -eq 0) { continue }

        $parameters = Sync-Parameter -Command (Get-Command Set-VMHost) -Parameters $roleParameters
        $settingsTable.Add($vm.Name, $parameters)
    }

    if ($settingsTable.Keys.Count -eq 0)
    {
        return
    }
    
    Invoke-LabCommand -ActivityName 'Configuring VM Host settings' -ComputerName $settingsTable.Keys -Variable (Get-Variable -Name settingsTable) -ScriptBlock {
        $vmParameters = $settingsTable[$env:COMPUTERNAME]

        if ($vmParameters)
        {
            Set-VMHost @vmParameters
        }
    }

    Write-LogFunctionExit
}
