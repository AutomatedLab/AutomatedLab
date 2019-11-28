param
(
    [string]$ComputerName,

    [string]$CertificateThumbPrint,

    [Parameter(Mandatory)]
    [string]$RegistrationKey,

    [Parameter(Mandatory)]
    [string]$SqlServer,

    [Parameter(Mandatory)]
    [string]$DatabaseName
)

Import-Module -Name xPSDesiredStateConfiguration, PSDesiredStateConfiguration

Configuration SetupDscPullServer
{
    param
    (
        [string[]]$NodeName = 'localhost',

        [string]$CertificateThumbPrint = 'AllowUnencryptedTraffic',

        [Parameter(Mandatory)]
        [string]$RegistrationKey,

        [Parameter(Mandatory)]
        [string]$SqlServer,

        [Parameter(Mandatory)]
        [string]$DatabaseName
    )

    Import-DSCResource -ModuleName xPSDesiredStateConfiguration, PSDesiredStateConfiguration, xWebAdministration

    Node $NodeName
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $false
            ConfigurationModeFrequencyMins = 15
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RefreshMode = 'PUSH'
        }

        WindowsFeature DSCServiceFeature
        {
            Ensure = 'Present'
            Name   = 'DSC-Service'
        }

        $sqlConnectionString = "Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security Info=False;Initial Catalog=$DatabaseName;Data Source=$SqlServer"

        xDscWebService PSDSCPullServer
        {
            Ensure                       = 'Present'
            EndpointName                 = 'PSDSCPullServer'
            Port                         = 8080
            PhysicalPath                 = "$env:SystemDrive\inetpub\PSDSCPullServer"
            CertificateThumbPrint        = $certificateThumbPrint
            ModulePath                   = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath            = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State                        = 'Started'
            UseSecurityBestPractices     = $true
            AcceptSelfSignedCertificates = $true
            SqlProvider                  = $true
            SqlConnectionString          = $sqlConnectionString
            DependsOn                    = '[WindowsFeature]DSCServiceFeature'
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

    }
}

$params = @{
    RegistrationKey = $RegistrationKey
    SqlServer = $SqlServer
    DatabaseName = $DatabaseName
    OutputPath = 'C:\Dsc'
}
if ($CertificateThumbPrint)
{
    $params.CertificateThumbPrint = $CertificateThumbPrint
}
if ($ComputerName)
{
    $params.NodeName = $ComputerName
}

SetupDscPullServer @params | Out-Null

Start-DscConfiguration -Path C:\Dsc -Wait