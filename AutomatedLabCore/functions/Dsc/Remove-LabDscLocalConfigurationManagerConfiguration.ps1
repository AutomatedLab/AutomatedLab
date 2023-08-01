function Remove-LabDscLocalConfigurationManagerConfiguration
{
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    function Remove-DscLocalConfigurationManagerConfiguration
    {
        param(
            [string[]]$ComputerName = 'localhost'
        )

        $configurationScript = @'
        [DSCLocalConfigurationManager()]
        configuration LcmDefaultConfiguration
        {
            param(
                [string[]]$ComputerName = 'localhost'
            )

            Node $ComputerName
            {
                Settings
                {
                    RefreshMode = 'Push'
                    ConfigurationModeFrequencyMins = 15
                    ConfigurationMode = 'ApplyAndMonitor'
                    RebootNodeIfNeeded = $true
                }
            }
        }
'@

        [scriptblock]::Create($configurationScript).Invoke()
        $path = New-Item -ItemType Directory -Path "$([System.IO.Path]::GetTempPath())\$(New-Guid)"

        Remove-DscConfigurationDocument -Stage Current, Pending -Force
        LcmDefaultConfiguration -OutputPath $path.FullName | Out-Null
        Set-DscLocalConfigurationManager -Path $path.FullName -Force

        Remove-Item -Path $path.FullName -Recurse -Force

        try
        {
            Test-DscConfiguration -ErrorAction Stop
            Write-Error 'There was a problem resetting the Local Configuration Manger configuration'
        }
        catch
        {
            Write-Host 'DSC Local Configuration Manger was reset to default values'
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

    Invoke-LabCommand -ActivityName 'Removing DSC LCM configuration' -ComputerName $ComputerName -ScriptBlock (Get-Command -Name Remove-DscLocalConfigurationManagerConfiguration).ScriptBlock

    Write-LogFunctionExit
}
