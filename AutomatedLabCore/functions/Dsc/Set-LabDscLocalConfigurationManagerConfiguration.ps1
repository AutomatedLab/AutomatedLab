function Set-LabDscLocalConfigurationManagerConfiguration
{
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [ValidateSet('ContinueConfiguration', 'StopConfiguration')]
        [string]$ActionAfterReboot,

        [string]$CertificateID,

        [string]$ConfigurationID,

        [int]$RefreshFrequencyMins,

        [bool]$AllowModuleOverwrite,

        [ValidateSet('ForceModuleImport','All', 'None')]
        [string]$DebugMode,

        [string[]]$ConfigurationNames,

        [int]$StatusRetentionTimeInDays,

        [ValidateSet('Push', 'Pull')]
        [string]$RefreshMode,

        [int]$ConfigurationModeFrequencyMins,

        [ValidateSet('ApplyAndAutoCorrect', 'ApplyOnly', 'ApplyAndMonitor')]
        [string]$ConfigurationMode,

        [bool]$RebootNodeIfNeeded,

        [hashtable[]]$ConfigurationRepositoryWeb,

        [hashtable[]]$ReportServerWeb,

        [hashtable[]]$PartialConfiguration
    )

    Write-LogFunctionEntry

    function Set-DscLocalConfigurationManagerConfiguration
    {
        param(
            [string[]]$ComputerName = 'localhost',

            [ValidateSet('ContinueConfiguration', 'StopConfiguration')]
            [string]$ActionAfterReboot,

            [string]$CertificateID,

            [string]$ConfigurationID,

            [int]$RefreshFrequencyMins,

            [bool]$AllowModuleOverwrite,

            [ValidateSet('ForceModuleImport','All', 'None')]
            [string]$DebugMode,

            [string[]]$ConfigurationNames,

            [int]$StatusRetentionTimeInDays,

            [ValidateSet('Push', 'Pull')]
            [string]$RefreshMode,

            [int]$ConfigurationModeFrequencyMins,

            [ValidateSet('ApplyAndAutoCorrect', 'ApplyOnly', 'ApplyAndMonitor')]
            [string]$ConfigurationMode,

            [bool]$RebootNodeIfNeeded,

            [hashtable[]]$ConfigurationRepositoryWeb,

            [hashtable[]]$ReportServerWeb,

            [hashtable[]]$PartialConfiguration
        )

        if ($PartialConfiguration)
        {
            throw (New-Object System.NotImplementedException)
        }

        if ($ConfigurationRepositoryWeb)
        {
            $validKeys = 'Name', 'ServerURL', 'RegistrationKey', 'ConfigurationNames', 'AllowUnsecureConnection'
            foreach ($hashtable in $ConfigurationRepositoryWeb)
            {

                if (-not (Test-HashtableKeys -Hashtable $hashtable -ValidKeys $validKeys))
                {
                    Write-Error 'The parameter hashtable contains invalid keys. Check the previous error to see details'
                    return
                }
            }
        }

        if ($ReportServerWeb)
        {
            $validKeys = 'Name', 'ServerURL', 'RegistrationKey', 'AllowUnsecureConnection'
            foreach ($hashtable in $ReportServerWeb)
            {

                if (-not (Test-HashtableKeys -Hashtable $hashtable -ValidKeys $validKeys))
                {
                    Write-Error 'The parameter hashtable contains invalid keys. Check the previous error to see details'
                    return
                }
            }
        }

        $sb = New-Object System.Text.StringBuilder

        [void]$sb.AppendLine('[DSCLocalConfigurationManager()]')
        [void]$sb.AppendLine('configuration LcmConfiguration')
        [void]$sb.AppendLine('{')
        [void]$sb.AppendLine('param([string[]]$ComputerName = "localhost")')
        [void]$sb.AppendLine('Node $ComputerName')
        [void]$sb.AppendLine('{')
        [void]$sb.AppendLine('Settings')
        [void]$sb.AppendLine('{')
        if ($PSBoundParameters.ContainsKey('ActionAfterReboot')) { [void]$sb.AppendLine("ActionAfterReboot = '$ActionAfterReboot'") }
        if ($PSBoundParameters.ContainsKey('RefreshMode')) { [void]$sb.AppendLine("RefreshMode = '$RefreshMode'") }
        if ($PSBoundParameters.ContainsKey('ConfigurationModeFrequencyMins')) { [void]$sb.AppendLine("ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins") }
        if ($PSBoundParameters.ContainsKey('CertificateID')) { [void]$sb.AppendLine("CertificateID = $CertificateID") }
        if ($PSBoundParameters.ContainsKey('ConfigurationID')) { [void]$sb.AppendLine("ConfigurationID = $ConfigurationID") }
        if ($PSBoundParameters.ContainsKey('AllowModuleOverwrite')) { [void]$sb.AppendLine("AllowModuleOverwrite = `$$AllowModuleOverwrite") }
        if ($PSBoundParameters.ContainsKey('RebootNodeIfNeeded')) { [void]$sb.AppendLine("RebootNodeIfNeeded = `$$RebootNodeIfNeeded") }
        if ($PSBoundParameters.ContainsKey('DebugMode')) { [void]$sb.AppendLine("DebugMode = '$DebugMode'") }
        if ($PSBoundParameters.ContainsKey('ConfigurationNames')) { [void]$sb.AppendLine("ConfigurationNames = @('$($ConfigurationNames -join "', '")')") }
        if ($PSBoundParameters.ContainsKey('StatusRetentionTimeInDays')) { [void]$sb.AppendLine("StatusRetentionTimeInDays = $StatusRetentionTimeInDays") }
        if ($PSBoundParameters.ContainsKey('ConfigurationMode')) { [void]$sb.AppendLine("ConfigurationMode = '$ConfigurationMode'") }
        if ($PSBoundParameters.ContainsKey('RefreshFrequencyMins')) { [void]$sb.AppendLine("RefreshFrequencyMins = $RefreshFrequencyMins") }

        [void]$sb.AppendLine('}')
        foreach ($web in $ConfigurationRepositoryWeb)
        {
            [void]$sb.AppendLine("ConfigurationRepositoryWeb '$($web.Name)'")
            [void]$sb.AppendLine('{')
            [void]$sb.AppendLine("ServerURL = 'https://$($web.ServerURL):$($web.Port)/PSDSCPullServer.svc'")
            [void]$sb.AppendLine("RegistrationKey = '$($Web.RegistrationKey)'")
            [void]$sb.AppendLine("ConfigurationNames = @('$($Web.ConfigurationNames)')")
            [void]$sb.AppendLine("AllowUnsecureConnection = `$$($web.AllowUnsecureConnection)")
            [void]$sb.AppendLine('}')
        }
        [void]$sb.AppendLine('}')

        [void]$sb.AppendLine('{')
        foreach ($web in $ConfigurationRepositoryWeb)
        {
            [void]$sb.AppendLine("ReportServerWeb '$($web.Name)'")
            [void]$sb.AppendLine('{')
            [void]$sb.AppendLine("ServerURL = 'https://$($web.ServerURL):$($web.Port)/PSDSCPullServer.svc'")
            [void]$sb.AppendLine("RegistrationKey = '$($Web.RegistrationKey)'")
            [void]$sb.AppendLine("AllowUnsecureConnection = `$$($web.AllowUnsecureConnection)")
            [void]$sb.AppendLine('}')
        }
        [void]$sb.AppendLine('}')

        [void]$sb.AppendLine('}')

        Invoke-Expression $sb.ToString()
        $sb.ToString() | Out-File -FilePath c:\AL_DscLcm_Debug.txt

        $path = New-Item -ItemType Directory -Path "$([System.IO.Path]::GetTempPath())\$(New-Guid)"

        LcmConfiguration -OutputPath $path.FullName | Out-Null
        Set-DscLocalConfigurationManager -Path $path.FullName

        Remove-Item -Path $path.FullName -Recurse -Force

        try
        {
            Test-DscConfiguration -ErrorAction Stop | Out-Null
            Write-Host 'DSC Local Configuration Manger was set to the new values'
        }
        catch
        {
            Write-Error 'There was a problem resetting the Local Configuration Manger configuration'
        }
    }

    $lab = Get-Lab
    if (-not $lab.Machines)
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -ComputerName $ComputerName
    if ($machines.Count -ne $ComputerName.Count)
    {
        Write-Error -Message 'Not all machines specified could be found in the lab.'
        Write-LogFunctionExit
        return
    }

    $params = ([hashtable]$PSBoundParameters).Clone()
    Invoke-LabCommand -ActivityName 'Setting DSC LCM configuration' -ComputerName $ComputerName -ScriptBlock {
        Set-DscLocalConfigurationManagerConfiguration @params
    } -Function (Get-Command -Name Set-DscLocalConfigurationManagerConfiguration) -Variable (Get-Variable -Name params)

    Write-LogFunctionExit
}
