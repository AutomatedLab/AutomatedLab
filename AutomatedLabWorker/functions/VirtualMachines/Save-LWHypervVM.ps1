function Save-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    $runspaceScript = {
        param
        (
            [string]$Name,
            [bool]$DisableClusterCheck
        )
        Write-LogFunctionEntry
        Get-LWHypervVM -Name $Name -DisableClusterCheck $DisableClusterCheck | Hyper-V\Save-VM
        Write-LogFunctionExit
    }

    $pool = New-RunspacePool -ThrottleLimit 50 -Function (Get-Command Get-LWHypervVM)

    $jobs = foreach ($Name in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -ScriptBlock $runspaceScript -Argument $Name,(Get-LabConfigurationItem -Name DoNotAddVmsToCluster -Default $false)
    }

    [void] ($jobs | Wait-RunspaceJob)

    $pool | Remove-RunspacePool
}
