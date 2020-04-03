function Set-UnattendedKickstartTimeZone
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$TimeZone
    )

    $tzInfo = Get-TimeZone -Id $TimeZone

    Write-PSFMessage -Message ('Since non-standard timezone names are used, we revert to Etc/GMT{0}' -f $tzInfo.BaseUtcOffset.TotalHours)
    if ($tzInfo.BaseUtcOffset.TotalHours -gt 0)
    {
        $script:un.Add(('timezone Etc/GMT+{0}' -f $tzInfo.BaseUtcOffset.TotalHours))
    }
    elseif ($tzInfo.BaseUtcOffset.TotalHours -eq 0)
    {
        $script:un.Add('timezone Etc/GMT')
    }
    else
    {
        $script:un.Add(('timezone Etc/GMT{0}' -f $tzInfo.BaseUtcOffset.TotalHours))
    }
}
