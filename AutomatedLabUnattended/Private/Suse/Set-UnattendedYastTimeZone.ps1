function Set-UnattendedYastTimeZone
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$TimeZone
    )

    $tzInfo = Get-TimeZone -Id $TimeZone
    Write-PSFMessage -Message ('Since non-standard timezone names are used, we revert to Etc/GMT{0}' -f $tzInfo.BaseUtcOffset.TotalHours)

    $timeNode = $script:un.SelectSingleNode('/un:profile/un:timezone/un:timezone', $script:nsm)

    $timeNode.InnerText = if ($tzInfo.BaseUtcOffset.TotalHours -gt 0)
    {
        'Etc/GMT+{0}' -f $tzInfo.BaseUtcOffset.TotalHours
    }
    elseif ($tzInfo.BaseUtcOffset.TotalHours -eq 0)
    {
        'Etc/GMT'
    }
    else
    {
        'Etc/GMT{0}' -f $tzInfo.BaseUtcOffset.TotalHours
    }
}
