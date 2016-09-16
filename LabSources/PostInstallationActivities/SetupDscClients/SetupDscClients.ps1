param(
    [Parameter(Mandatory)]
    [string] $PullServer,

    [Parameter(Mandatory)]
    [string] $RegistrationKey
)

[DSCLocalConfigurationManager()]
Configuration PullClient
{
    param(
        [Parameter(Mandatory)]
        [string] $PullServer,

        [Parameter(Mandatory)]
        [string] $RegistrationKey
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

        ConfigurationRepositoryWeb CONTOSO-PullSrv
        {
            ServerURL          = "https://$($PullServer):8080/PSDSCPullServer.svc"
            RegistrationKey    = $RegistrationKey
            ConfigurationNames = @('TestConfig')
            #AllowUnsecureConnection = $true
        }   

        ReportServerWeb CONTOSO-PullSrv
        {
            ServerURL       = "https://$($PullServer):8080/PSDSCPullServer.svc"
            RegistrationKey = $RegistrationKey
            #AllowUnsecureConnection = $true
        }
    }
}
    
PullClient -OutputPath c:\Dsc -PullServer $PullServer -RegistrationKey $RegistrationKey | Out-Null
Set-DscLocalConfigurationManager -Path C:\Dsc -ComputerName localhost

Update-DscConfiguration -Wait