function Enable-LWAzureAutoShutdown
{
    param
    (
        [string[]]
        $ComputerName,

        [timespan]
        $Time,

        [string]
        $TimeZone = (Get-TimeZone).Id,

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
        $properties = @{
            status           = 'Enabled'
            taskType         = 'ComputeVmShutdownTask'
            dailyRecurrence  = @{time = $Time.ToString('hhmm') }
            timeZoneId       = $TimeZone
            targetResourceId = $vm.Id
        }

        New-AzResource -ResourceId ("$($resourceIdString)$($vm.Name)") -Location $vm.Location -Properties $properties -Force -ErrorAction SilentlyContinue -AsJob
    }

    if ($jobs -and $Wait.IsPresent)
    {
        $null = $jobs | Wait-Job
    }
}
