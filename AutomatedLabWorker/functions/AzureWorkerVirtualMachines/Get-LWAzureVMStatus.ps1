function Get-LWAzureVMStatus
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Test-LabHostConnected -Throw -Quiet

    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $result = @{ }
    $azureVms = Get-LWAzureVm @PSBoundParameters

    $resourceGroups = (Get-LabVM -IncludeLinux).AzureConnectionInfo.ResourceGroupName | Select-Object -Unique
    $azureVms = $azureVms | Where-Object { $_.Name -in $ComputerName -and $_.ResourceGroupName -in $resourceGroups }

    $vmTable = @{ }
    Get-LabVm -IncludeLinux | Where-Object FriendlyName -in $ComputerName | ForEach-Object { $vmTable[$_.FriendlyName] = $_.Name }

    foreach ($azureVm in $azureVms)
    {
        $vmName = if ($vmTable[$azureVm.Name]) { $vmTable[$azureVm.Name] } else { $azureVm.Name }
        if ($azureVm.PowerState -eq 'VM running')
        {
            $result.Add($vmName, 'Started')
        }
        elseif ($azureVm.PowerState -eq 'VM stopped' -or $azureVm.PowerState -eq 'VM deallocated')
        {
            $result.Add($vmName, 'Stopped')
        }
        else
        {
            $result.Add($vmName, 'Unknown')
        }
    }

    $result

    Write-LogFunctionExit
}
