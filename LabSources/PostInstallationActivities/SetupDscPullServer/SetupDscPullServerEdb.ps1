param
(
    [Parameter()]
    [string]$ComputerName = 'localhost',

    [Parameter()]
    [string]$CertificateThumbPrint,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RegistrationKey
)

Import-Module -Name xPSDesiredStateConfiguration, PSDesiredStateConfiguration

configuration SetupDscPullServer
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$NodeName,

        [Parameter()]
        [string]$CertificateThumbPrint = 'AllowUnencryptedTraffic',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RegistrationKey
    )

    Import-DSCResource -ModuleName xPSDesiredStateConfiguration, PSDesiredStateConfiguration
    
    node $NodeName
    {
    
        localconfigurationmanager {
            RebootNodeIfNeeded             = $false
            ConfigurationModeFrequencyMins = 15
            ConfigurationMode              = 'ApplyAndAutoCorrect'
            RefreshMode                    = 'PUSH'
        }

        windowsfeature DSCServiceFeature {
            Ensure = 'Present'
            Name   = 'DSC-Service'
        }

        windowsfeature WebMgmtConsole {
            Ensure = 'Present'
            Name   = 'Web-Mgmt-Console'
        }        

        xDscWebService PSDSCPullServer
        {
            Ensure                   = 'Present'
            EndpointName             = 'PSDSCPullServer'
            Port                     = 8080
            PhysicalPath             = "$env:SystemDrive\inetpub\PSDSCPullServer"
            CertificateThumbPrint    = $certificateThumbPrint
            ModulePath               = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath        = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State                    = 'Started'
            UseSecurityBestPractices = $false
            DependsOn                = '[WindowsFeature]DSCServiceFeature'
        }

        file RegistrationKeyFile {
            Ensure          = 'Present'
            Type            = 'File'
            DestinationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
            Contents        = $RegistrationKey
        }
    }
}

$params = @{
    RegistrationKey = $RegistrationKey
    NodeName        = $ComputerName
    OutputPath      = 'C:\Dsc'
}
if ($CertificateThumbPrint) {
    $params.CertificateThumbPrint = $CertificateThumbPrint
}

SetupDscPullServer @params | Out-Null

Start-DscConfiguration -Path C:\Dsc -Wait -Force -Verbose
