param  
(
    [Parameter(Mandatory)]
    [string]$ComputerName,

    [Parameter(Mandatory)]
    [string]$CertificateThumbPrint,

    [Parameter(Mandatory)]
    [string] $RegistrationKey
)

Import-Module -Name xPSDesiredStateConfiguration, PSDesiredStateConfiguration

Configuration SetupDscPullServer
{
    param  
    ( 
        [string[]]$NodeName = 'localhost', 

        [ValidateNotNullOrEmpty()] 
        [string]$CertificateThumbPrint,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $RegistrationKey
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
            #CertificateThumbPrint   = 'AllowUnencryptedTraffic'
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
            Value = 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source=C:\Program Files\WindowsPowerShell\DscService\Devices.mdb;'
            WebsitePath = 'IIS:\sites\PSDSCPullServer'
            DependsOn = '[xDSCWebService]PSDSCPullServer'
        }
    }
}

SetupDscPullServer -CertificateThumbPrint $CertificateThumbPrint -RegistrationKey $RegistrationKey -NodeName $ComputerName -OutputPath C:\Dsc | Out-Null

Start-DscConfiguration -Path C:\Dsc -Wait
