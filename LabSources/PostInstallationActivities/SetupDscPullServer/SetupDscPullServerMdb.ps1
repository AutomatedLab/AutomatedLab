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

        [ValidateNotNullOrEmpty()]
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

    Import-DSCResource -ModuleName xPSDesiredStateConfiguration, PSDesiredStateConfiguration, xWebAdministration

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

        xWebConfigKeyValue CorrectDBProvider
        {
            ConfigSection = 'AppSettings'
            Key = 'dbprovider'
            Value = 'System.Data.OleDb'
            WebsitePath = 'IIS:\sites\PSDSCPullServer'
            DependsOn = '[xDSCWebService]PSDSCPullServer'
        }

        xWebConfigKeyValue CorrectDBConnectionStr
        {
            ConfigSection = 'AppSettings'
            Key = 'dbconnectionstr'
            Value = if ([System.Environment]::OSVersion.Version -gt '6.3.0.0') #greater then Windows Server 2012 R2
            {
                'Provider=Microsoft.Jet.OLEDB.4.0;Data Source=C:\Program Files\WindowsPowerShell\DscService\Devices.mdb;' #does no longer work with Server 2016+
            }
            else
            {
                'Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\Program Files\WindowsPowerShell\DscService\Devices.mdb;'
            }
            WebsitePath = 'IIS:\sites\PSDSCPullServer'
            DependsOn = '[xDSCWebService]PSDSCPullServer'
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