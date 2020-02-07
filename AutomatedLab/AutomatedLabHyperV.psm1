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
		$hyperVVms | Get-VMNetworkAdapter | Set-VMNetworkAdapter -MacAddressSpoofing On
    }

    Start-LabVm -Wait -ComputerName $vms # Start all, regardless of Hypervisor
    Write-ScreenInfo -Message 'Done'

    # Enable Feature
    Write-ScreenInfo -Message "Enabling Hyper-V feature and waiting for restart of $($vms.Count) VMs..." -NoNewLine

    $clients, $servers = $vms.Where({$_.OperatingSystem.Installation -eq 'Client'}, 'Split')

    $jobs = @()

    if ($clients)
    {
        $jobs += Install-LabWindowsFeature -ComputerName $clients -FeatureName Microsoft-Hyper-V-All -NoDisplay -AsJob -PassThru
    }
    
    if ($servers)
    {
        $jobs += Install-LabWindowsFeature -ComputerName $servers -FeatureName Hyper-V -IncludeAllSubFeature -IncludeManagementTools -NoDisplay -AsJob -PassThru
    }

    Wait-LWLabJob -Job $jobs

    # Restart
    Restart-LabVm -ComputerName $vms -Wait -NoDisplay
    Write-ScreenInfo -Message 'Done'

    #Configure
    $settingsTable = @{ }
    
    # Correct data types for individual settings
    $parametersAndTypes = @{
        MaximumStorageMigrations                  = [uint32]
        MaximumVirtualMachineMigrations           = [uint32]
        VirtualMachineMigrationAuthenticationType = [Microsoft.HyperV.PowerShell.MigrationAuthenticationType]
        UseAnyNetworkForMigration                 = [bool]
        VirtualMachineMigrationPerformanceOption  = [Microsoft.HyperV.PowerShell.VMMigrationPerformance]
        ResourceMeteringSaveInterval              = [timespan]
        NumaSpanningEnabled                       = [bool]
        EnableEnhancedSessionMode                 = [bool]
    }

    foreach ($vm in $vms)
    {
        [hashtable]$roleParameters = ($vm.Roles | Where-Object Name -eq HyperV).Properties
        if ($roleParameters.Count -eq 0) { continue }

        $parameters = Sync-Parameter -Command (Get-Command Set-VMHost) -Parameters $roleParameters
        foreach ($parameter in $parameters.Clone().GetEnumerator())
        {
            $type = $parametersAndTypes[$parameter.Key]
    
            if ($type -eq [bool])
            {
                $parameters[$parameter.Key] = [Convert]::ToBoolean($parameter.Value)
            }
            else
            {
                $parameters[$parameter.Key] = $parameter.Value -as $type
            }
        }
        
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
