param
(
    [string]$ComputerName,

    [string]$CertificateThumbPrint,

    [Parameter(Mandatory)]
    [string]$RegistrationKey
)

Import-Module -Name xPSDesiredStateConfiguration, PSDesiredStateConfiguration

Configuration SetupDscPullServer
{
    param
    (
        [string[]]$NodeName = 'localhost',

        [string]$CertificateThumbPrint = 'AllowUnencryptedTraffic',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RegistrationKey
    )

    LocalConfigurationManager
    {
        RebootNodeIfNeeded = $false
        ConfigurationModeFrequencyMins = 15
        ConfigurationMode = 'ApplyAndAutoCorrect'
        RefreshMode = 'PUSH'
    }

    Import-DSCResource -ModuleName xPSDesiredStateConfiguration, PSDesiredStateConfiguration

    Node $NodeName
    {
        WindowsFeature DSCServiceFeature
        {
            Ensure = 'Present'
            Name   = 'DSC-Service'
        }

        xDscWebService PSDSCPullServer
        {
            Ensure                  = 'Present'
            EndpointName            = 'PSDSCPullServer'
            Port                    = 8080
            PhysicalPath            = "$env:SystemDrive\inetpub\PSDSCPullServer"
            CertificateThumbPrint   = $certificateThumbPrint
            ModulePath              = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State                   = 'Started'
            UseSecurityBestPractices = $false
            DependsOn               = '[WindowsFeature]DSCServiceFeature'
        }

        File RegistrationKeyFile
        {
            Ensure          = 'Present'
            Type            = 'File'
            DestinationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
            Contents        = $RegistrationKey
        }
    }
}

$params = @{
	RegistrationKey = $RegistrationKey
	NodeName = $ComputerName
	OutputPath = 'C:\Dsc'
}
if ($CertificateThumbPrint)
{
	$params.CertificateThumbPrint = $CertificateThumbPrint
}

SetupDscPullServer @params | Out-Null

Start-DscConfiguration -Path C:\Dsc -Wait