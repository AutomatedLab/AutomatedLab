function Remove-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    Param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-LogFunctionEntry

    $vm = Get-LWHypervVM -Name $Name -ErrorAction SilentlyContinue

    if (-not $vm) { Write-LogFunctionExit}

    $vmPath = Split-Path -Path $vm.HardDrives[0].Path -Parent

    if ($vm.State -eq 'Saved')
    {
        Write-PSFMessage "Deleting saved state of VM '$($Name)'"
        $vm | Remove-VMSavedState
    }
    else
    {
        Write-PSFMessage "Stopping VM '$($Name)'"
        $vm | Hyper-V\Stop-VM -TurnOff -Force -WarningAction SilentlyContinue
    }

    Write-PSFMessage "Removing VM '$($Name)'"
    $doNotAddToCluster = Get-LabConfigurationItem -Name DoNotAddVmsToCluster -Default $false
    if (-not $doNotAddToCluster -and (Get-Command -Name Get-Cluster -Module FailoverClusters -CommandType Cmdlet -ErrorAction SilentlyContinue) -and (Get-Cluster -ErrorAction SilentlyContinue -WarningAction SilentlyContinue))
    {
        Write-PSFMessage "Removing Clustered Resource: $Name"
        $null = Get-ClusterGroup -Name $Name | Remove-ClusterGroup -RemoveResources -Force
    }

    Remove-LWHypervVmConnectSettingsFile -ComputerName $Name

    $vm | Hyper-V\Remove-VM -Force

    Write-PSFMessage "Removing VM files for '$($Name)'"
    Remove-Item -Path $vmPath -Force -Confirm:$false -Recurse
    
    $vmDescription = Join-Path -Path (Get-Lab).LabPath -ChildPath "$Name.xml"
    if (Test-Path -Path $vmDescription) {
        Remove-Item -Path $vmDescription
    }

    Write-LogFunctionExit
}
