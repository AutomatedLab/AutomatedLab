param(
    [Parameter(Mandatory)]
    [string[]] $PullServer,

    [Parameter(Mandatory)]
    [string[]] $RegistrationKey
)

[DSCLocalConfigurationManager()]
Configuration PullClient
{
    param(
        [Parameter(Mandatory)]
        [string[]] $PullServer,

        [Parameter(Mandatory)]
        [string[]] $RegistrationKey
    )

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
        
        if ($PullServer.Count -eq 1)
        {
            ConfigurationRepositoryWeb "PullServer_1"
            {
                ServerURL          = "https://$($PullServer[0]):8080/PSDSCPullServer.svc"
                RegistrationKey    = $RegistrationKey[0]
                ConfigurationNames = @("TestConfig$($PullServer[0])")
                #AllowUnsecureConnection = $true
            }
        }
        else
        {
            for ($i = 0; $i -lt $PullServer.Count; $i++)
            {
                ConfigurationRepositoryWeb "PullServer_$($i + 1)"
                {
                    ServerURL          = "https://$($PullServer[$i]):8080/PSDSCPullServer.svc"
                    RegistrationKey    = $RegistrationKey[$i]
                    ConfigurationNames = @("TestConfig$($PullServer[$i])")
                    #AllowUnsecureConnection = $true
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
            ServerURL       = "https://$($PullServer[0]):8080/PSDSCPullServer.svc"
            RegistrationKey = $RegistrationKey[0]
            #AllowUnsecureConnection = $true
        }
    }
}

if ($PullServer.Count -ne $RegistrationKey.Count)
{
    Write-Error "The number if pull servers ($($PullServer.Count)) is not equal to the number of registration keys ($($RegistrationKey.Count))."
    return
}
    
PullClient -OutputPath c:\Dsc -PullServer $PullServer -RegistrationKey $RegistrationKey | Out-Null
Set-DscLocalConfigurationManager -Path C:\Dsc -ComputerName localhost -Verbose

Update-DscConfiguration -Wait -Verbose

Start-DscConfiguration -Force -UseExisting -Wait