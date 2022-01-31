param(
    [Parameter(Mandatory)]
    [string[]] $PullServer,

    [Parameter(Mandatory)]
    [string[]] $RegistrationKey,

    [bool]
    $UseSsl = $true
)

[DSCLocalConfigurationManager()]
Configuration PullClient
{
    param(
        [Parameter(Mandatory)]
        [string[]] $PullServer,

        [Parameter(Mandatory)]
        [string[]] $RegistrationKey,

        [bool]
        $UseSsl = $true
    )

    [string[]]$flatNames = foreach ($server in $PullServer)
    {
        if ($server.Contains('.'))
        {
            ($server -split '\.')[0]
        }
        else
        {
            $server
        }
    }

    Node localhost
    {
        Settings
        {
            RefreshMode          = 'Pull'
            RefreshFrequencyMins = 30
            ConfigurationModeFrequencyMins = 15
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded   = $true
        }

        $proto = if ($UseSsl) { 'https' } else { 'http' }

        if ($PullServer.Count -eq 1)
        {
            Write-Verbose "ServerUrl = $("$($proto)://$($PullServer[0]):8080/PSDSCPullServer.svc"), RegistrationKey = $($RegistrationKey[0]), ConfigurationNames = $("TestConfig$($flatNames[0])")"
            ConfigurationRepositoryWeb "PullServer_1"
            {
                ServerURL          = "$($proto)://$($PullServer[0]):8080/PSDSCPullServer.svc"
                RegistrationKey    = $RegistrationKey[0]
                ConfigurationNames = @("TestConfig$($flatNames[0])")
                AllowUnsecureConnection = -not $UseSsl.IsPresent
            }
        }
        else
        {
            for ($i = 0; $i -lt $PullServer.Count; $i++)
            {
                Write-Verbose "ServerUrl = $("$($proto)://$($PullServer[$i]):8080/PSDSCPullServer.svc"), RegistrationKey = $($RegistrationKey[$i]), ConfigurationNames = $("TestConfig$($flatNames[$i])")"
                ConfigurationRepositoryWeb "PullServer_$($i + 1)"
                {
                    ServerURL          = "$($proto)://$($PullServer[$i]):8080/PSDSCPullServer.svc"
                    RegistrationKey    = $RegistrationKey[$i]
                    ConfigurationNames = @("TestConfig$($flatNames[$i])")
                    AllowUnsecureConnection = -not $UseSsl
                }

                PartialConfiguration "TestConfigDPull$($i + 1)"
                {
                    Description = "Partial configuration from Pull Server $($i + 1)"
                    ConfigurationSource = "[ConfigurationRepositoryWeb]PullServer_$($i + 1)"
                    RefreshMode = 'Pull'
                }
            }
        }

        ReportServerWeb CONTOSO-PullSrv
        {
            ServerURL       = "$($proto)://$($PullServer[0]):8080/PSDSCPullServer.svc"
            RegistrationKey = $RegistrationKey[0]
            AllowUnsecureConnection = -not $UseSsl
        }
    }
}

if ($PullServer.Count -ne $RegistrationKey.Count)
{
    Write-Error "The number if pull servers ($($PullServer.Count)) is not equal to the number of registration keys ($($RegistrationKey.Count))."
    return
}

PullClient -OutputPath c:\Dsc -PullServer $PullServer -RegistrationKey $RegistrationKey -UseSsl:$UseSsl | Out-Null
Set-DscLocalConfigurationManager -Path C:\Dsc -ComputerName localhost -Verbose

Update-DscConfiguration -Wait -Verbose

Start-DscConfiguration -Force -UseExisting -Wait