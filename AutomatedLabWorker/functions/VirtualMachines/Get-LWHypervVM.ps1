function Get-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification = "Not relevant on Linux")]
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [string[]]
        $Name,

        [Parameter()]
        [bool]
        $DisableClusterCheck = (Get-LabConfigurationItem -Name DisableClusterCheck -Default $false),

        [switch]
        $NoError
    )

    Write-LogFunctionEntry

    $param = @{
        ErrorAction = 'SilentlyContinue'
    }

    if ($Name.Count -gt 0)
    {        
        $param['Name'] = $Name
    }

    [object[]]$vm = Get-VM @param
    $vm = $vm | Sort-Object -Unique -Property Name

    if ($Name.Count -gt 0 -and $vm.Count -eq $Name.Count)
    {
        return $vm
    }

    if (-not $script:clusterDetected -and (Get-Command -Name Get-Cluster -Module FailoverClusters -CommandType Cmdlet -ErrorAction SilentlyContinue)) { $script:clusterDetected = Get-Cluster -ErrorAction SilentlyContinue -WarningAction SilentlyContinue}

    if (-not $DisableClusterCheck -and $script:clusterDetected)
    {
        $vm += Get-ClusterResource | Where-Object -Property ResourceType -eq 'Virtual Machine' | Get-VM
        if ($Name.Count -gt 0)
        {
            $vm = $vm | Where Name -in $Name
        }
    }

    # In case VM was in cluster and has now been added a second time
    $vm = $vm | Sort-Object -Unique -Property Name

    if (-not $NoError.IsPresent -and $Name.Count -gt 0 -and -not $vm)
    {
        Write-Error -Message "No virtual machine $Name found"
        return
    }

    if ($vm.Count -eq 0) { return } # Get-VMNetworkAdapter does not take kindly to $null
    
    $vm

    Write-LogFunctionExit
}
