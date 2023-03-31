function Get-LWAzureAutoShutdown
{
    [CmdletBinding()]
    param ( )

    $lab = Get-Lab -ErrorAction Stop
    $resourceGroup = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName

    $schedules = (Get-AzResource -ResourceGroupName $resourceGroup -ResourceType Microsoft.DevTestLab/schedules -ExpandProperties -ErrorAction SilentlyContinue).Properties

    foreach ($schedule in $schedules)
    {
        $hour, $minute = Get-StringSection -SectionSize 2 -String $schedule.dailyRecurrence.time

        if ($schedule)
        {
            [PSCustomObject]@{
                ComputerName = ($schedule.targetResourceId -split '/')[-1]
                Time         = New-TimeSpan -Hours $hour -Minutes $minute
                TimeZone     = Get-TimeZone -Id $schedule.timeZoneId
            }
        }
    }
}
