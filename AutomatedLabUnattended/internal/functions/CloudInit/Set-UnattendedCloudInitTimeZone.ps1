function Set-UnattendedCloudInitTimeZone
{
	[CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$TimeZone
    )

    $tzInfo = Get-TimeZone -Id $TimeZone -ErrorAction SilentlyContinue

    if (-not $tzInfo) { Get-TimeZone }

    Write-PSFMessage -Message ('Since non-standard timezone names are used, we revert to Etc/GMT{0}' -f $tzInfo.BaseUtcOffset.TotalHours)
    $tzname = if ($tzInfo.BaseUtcOffset.TotalHours -gt 0)
    {
        'timezone Etc/GMT+{0}' -f $tzInfo.BaseUtcOffset.TotalHours
    }
    elseif ($tzInfo.BaseUtcOffset.TotalHours -eq 0)
    {
        'timezone Etc/GMT'
    }
    else
    {
        'timezone Etc/GMT{0}' -f $tzInfo.BaseUtcOffset.TotalHours
    }

    $script:un['late-commands'] += 'sudo timedatectl set-timezone {0}' -f $tzname
}