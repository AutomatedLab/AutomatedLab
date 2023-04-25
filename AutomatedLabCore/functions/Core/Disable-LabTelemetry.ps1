function Disable-LabTelemetry
{
    if ($IsLinux -or $IsMacOs)
    {
        $null = New-Item -ItemType File -Path "$((Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot))/telemetry.disabled" -Force
    }
    else
    {
        [Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', 'false', 'Machine')
        $env:AUTOMATEDLAB_TELEMETRY_OPTIN = 'false'
    }
}
