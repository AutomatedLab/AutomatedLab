function Disable-LWAzureAutoShutdown
{
    param
    (
        [string[]]
        $ComputerName,

        [switch]
        $Wait
    )

    $lab = Get-Lab -ErrorAction Stop
    $labVms = Get-AzVm -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
    if ($ComputerName)
    {
        $labVms = $labVms | Where-Object Name -in $ComputerName
    }
    $resourceIdString = '{0}/providers/microsoft.devtestlab/schedules/shutdown-computevm-' -f $lab.AzureSettings.DefaultResourceGroup.ResourceId

    $jobs = foreach ($vm in $labVms)
    {
        Remove-AzResource -ResourceId ("$($resourceIdString)$($vm.Name)") -Force -ErrorAction SilentlyContinue -AsJob
    }

    if ($jobs -and $Wait.IsPresent)
    {
        $null = $jobs | Wait-Job
    }
}
