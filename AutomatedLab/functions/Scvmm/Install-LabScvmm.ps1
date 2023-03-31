function Install-LabScvmm
{
    [CmdletBinding()]
    param ( )

    # defaults
    $iniContentServer = @{
        UserName                    = 'Administrator'
        CompanyName                 = 'AutomatedLab'
        ProgramFiles                = 'C:\Program Files\Microsoft System Center\Virtual Machine Manager {0}'
        CreateNewSqlDatabase        = '1'
        SqlInstanceName             = 'MSSQLSERVER'
        SqlDatabaseName             = 'VirtualManagerDB'
        RemoteDatabaseImpersonation = '0'
        SqlMachineName              = 'REPLACE'
        IndigoTcpPort               = '8100'
        IndigoHTTPSPort             = '8101'
        IndigoNETTCPPort            = '8102'
        IndigoHTTPPort              = '8103'
        WSManTcpPort                = '5985'
        BitsTcpPort                 = '443'
        CreateNewLibraryShare       = '1'
        LibraryShareName            = 'MSSCVMMLibrary'
        LibrarySharePath            = 'C:\ProgramData\Virtual Machine Manager Library Files'
        LibraryShareDescription     = 'Virtual Machine Manager Library Files'
        SQMOptIn                    = '0'
        MUOptIn                     = '0'
        VmmServiceLocalAccount      = '0'
        TopContainerName            = 'CN=VMMServer,DC=contoso,DC=com'
    }
    $iniContentConsole = @{
        ProgramFiles  = 'C:\Program Files\Microsoft System Center\Virtual Machine Manager {0}'
        IndigoTcpPort = '8100'
        MUOptIn       = '0'
    }
    $setupCommandLineServer = '/server /i /f C:\Server.ini /VmmServiceDomain {0} /VmmServiceUserName {1} /VmmServiceUserPassword {2} /SqlDBAdminDomain {0} /SqlDBAdminName {1} /SqlDBAdminPassword {2} /IACCEPTSCEULA'

    $lab = Get-Lab
    # Prerequisites, all
    $all = Get-LabVM -Role SCVMM | Where-Object SkipDeployment -eq $false
    Invoke-LabCommand -ComputerName $all -ScriptBlock {
        if (-not (Test-Path C:\DeployDebug))
        {
            $null = New-Item -ItemType Directory -Path C:\DeployDebug
        }
    }
    $server = $all | Where-Object { -not $_.Roles.Properties.ContainsKey('SkipServer') }
    $consoles = $all | Where-Object { $_.Roles.Properties.ContainsKey('SkipServer') }

    if ($consoles)
    {
        $jobs = Install-ScvmmConsole -Computer $consoles
    }

    if ($server)
    {
        Install-ScvmmServer -Computer $server
    }

    # In case console setup took longer than server...
    if ($jobs) { Wait-LWLabJob -Job $jobs }
}
