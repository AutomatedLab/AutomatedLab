function Enable-LabTelemetry
{
    if ($IsLinux -or $IsMacOs)
    {
        $null = New-Item -ItemType File -Path "$((Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot))/telemetry.enabled" -Force
    }
    else
    {
        [Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', 'true', 'Machine')
        $env:AUTOMATEDLAB_TELEMETRY_OPTIN = 'true'
    }
}
