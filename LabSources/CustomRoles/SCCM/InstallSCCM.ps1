<#
        .SYNOPSIS
        Install a functional SCCM Primary Site using the Automated-Lab tookit with SCCM being installed using the "CustomRoles" approach
        .DESCRIPTION
        Long description
        .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
        .INPUTS
        Inputs (if any)
        .OUTPUTS
        Output (if any)
        .NOTES
        General notes
#>

param(

    [Parameter(Mandatory)]
    [string]$ComputerName,

    [Parameter(Mandatory)]
    [string]$SccmBinariesDirectory,

    [Parameter(Mandatory)]
    [string]$SccmPreReqsDirectory,

    [Parameter(Mandatory)]
    [string]$SccmSiteCode,

    [Parameter(Mandatory)]
    [string]$SqlServerName
)

function Install-SCCM {
    param
    (
        [Parameter(Mandatory)]
        [string]$SccmServerName,

        [Parameter(Mandatory)]
        [string]$SccmBinariesDirectory,

        [Parameter(Mandatory)]
        [string]$SccmPreReqsDirectory,

        [Parameter(Mandatory)]
        [string]$SccmSiteCode,

        [Parameter(Mandatory)]
        [string]$SqlServerName
    )

    $sccmServer = Get-LabVM -ComputerName $SccmServerName
    $sccmServerFqdn = $sccmServer.FQDN
    $sqlServer = Get-LabVM -Role SQLServer | Where-Object Name -eq $SqlServerName
    $sqlServerFqdn = $sqlServer.FQDN
    $rootDC = Get-LabVM -Role RootDC | Where-Object { $_.DomainName -eq  $sccmServer.DomainName }

    if (-not $sqlServer)
    {
        Write-Error "The specified SQL Server '$SqlServerName' does not exist in the lab."
        return
    }

    $mdtDownloadLocation = 'https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi'
    $downloadTargetFolder = "$labSources\SoftwarePackages"

    #Do Some quick checks before we get going
    #Check for existance of ADK Installation Files
    if (-not (Test-Path -Path "$downloadTargetFolder\ADK")) {
        Write-LogFunctionExitWithError -Message "ADK Installation files not located at '$downloadTargetFolder\ADK'"
        return
    }

    if (-not (Test-Path -Path $SccmBinariesDirectory)) {
        Write-LogFunctionExitWithError -Message "SCCM Installation files not located at '$($SccmBinariesDirectory)'"
        return
    }

    if (-not (Test-Path -Path $SccmPreReqsDirectory)) {
        Write-LogFunctionExitWithError -Message "SCCM PreRequisite files not located at '$($SccmPreReqsDirectory)'"
        return
    }

    #Bring all available disks online (this is to cater for the secondary drive)
    #For some reason, cant make the disk online and RW in the one command, need to perform two seperate actions
    Invoke-LabCommand -ActivityName 'Bring Disks Online' -ComputerName $SccmServerName -ScriptBlock {
        $dataVolume = Get-Disk | Where-Object -Property OperationalStatus -eq Offline
        $dataVolume | Set-Disk -IsOffline $false
        $dataVolume | Set-Disk -IsReadOnly $false
    }

    #Copy the SCCM Binaries
    Copy-LabFileItem -Path $SccmBinariesDirectory -DestinationFolderPath /Install -ComputerName $SccmServerName -Recurse
    #Copy the SCCM Prereqs (must have been previously downloaded)
    Copy-LabFileItem -Path $SccmPreReqsDirectory -DestinationFolderPath /Install -ComputerName $SccmServerName -Recurse

    #Extend the AD Schema
    Invoke-LabCommand -ActivityName 'Extend AD Schema' -ComputerName $SccmServerName -ScriptBlock {
        C:\Install\SCCM1702\SMSSETUP\BIN\X64\extadsch.exe
    }

    #Need to execute this command on the Domain Controller, since it has the AD Powershell cmdlets available
    #Create the Necessary OU and permissions for the SCCM container in AD
    Invoke-LabCommand -ActivityName 'Configure SCCM Systems Management Container' -ComputerName $rootDC -ScriptBlock {
        param
        (
            [Parameter(Mandatory)]
            [string]$SCCMServerName
        )

        Import-Module ActiveDirectory
        # Figure out our domain
        $rootDomainNc = (Get-ADRootDSE).defaultNamingContext

        # Get or create the System Management container
        $ou = $null
        try
        {
            $ou = Get-ADObject "CN=System Management,CN=System,$rootDomainNc"
        }
        catch
        {
            Write-Verbose "System Management container does not currently exist."
            $ou = New-ADObject -Type Container -name "System Management" -Path "CN=System,$rootDomainNc" -Passthru
        }

        # Get the current ACL for the OU
        $acl = Get-ACL -Path "ad:CN=System Management,CN=System,$rootDomainNc"

        # Get the computer's SID (we need to get the computer object, which is in the form <ServerName>$)
        $sccmComputer = Get-ADComputer "$SCCMServerName$"
        $sccmServerSId = [System.Security.Principal.SecurityIdentifier] $sccmComputer.SID

        $ActiveDirectoryRights = "GenericAll"
        $AccessControlType = "Allow"
        $Inherit = "SelfAndChildren"
        $nullGUID = [guid]'00000000-0000-0000-0000-000000000000'

        # Create a new access control entry to allow access to the OU
        $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $sccmServerSId, $ActiveDirectoryRights, $AccessControlType, $Inherit, $nullGUID

        # Add the ACE to the ACL, then set the ACL to save the changes
        $acl.AddAccessRule($ace)
        Set-ACL -AclObject $acl "ad:CN=System Management,CN=System,$rootDomainNc"

    } -ArgumentList $SccmServerName

    Write-ScreenInfo -Message "Downloading MDT Installation Files from '$mdtDownloadLocation'"
    $mdtInstallFile = Get-LabInternetFile -Uri $mdtDownloadLocation -Path $downloadTargetFolder -ErrorAction Stop -PassThru

    Write-ScreenInfo "Copying MDT Install Files to server '$SccmServerName'..."
    Copy-LabFileItem -Path $mdtInstallFile.FullName -DestinationFolderPath /Install -ComputerName $SccmServerName

    Write-ScreenInfo "Copying ADK Install Files to server '$SccmServerName'..."
    Copy-LabFileItem -Path "$downloadTargetFolder\ADK" -DestinationFolderPath /Install -ComputerName $SccmServerName -Recurse

    Write-ScreenInfo "Installing ADK on server '$SccmServerName'..." -NoNewLine
    $job = Install-LabSoftwarePackage -LocalPath C:\Install\ADK\adksetup.exe -CommandLine "/norestart /q /ceip off /features OptionId.WindowsPreinstallationEnvironment OptionId.DeploymentTools OptionId.UserStateMigrationTool OptionId.ImagingAndConfigurationDesigner" `
    -ComputerName $SccmServerName -NoDisplay -AsJob -PassThru
    Wait-LWLabJob -Job $job -NoDisplay

    Write-ScreenInfo "Installing .net 3.5 on '$SccmServerName'..." -NoNewLine
    $job = Install-LabWindowsFeature -ComputerName $SccmServerName -FeatureName NET-Framework-Core -NoDisplay -AsJob -PassThru
    Wait-LWLabJob -Job $job -NoDisplay

    Write-ScreenInfo "Installing WDS on '$SccmServerName'..." -NoNewLine
    $job = Install-LabWindowsFeature -ComputerName $SccmServerName -FeatureName WDS -NoDisplay -AsJob -PassThru
    Wait-LWLabJob -Job $job -NoDisplay

    Write-ScreenInfo "Installing 'MDT' on server '$SccmServerName'..." -NoNewLine
    Install-LabSoftwarePackage -ComputerName $SccmServerName -LocalPath "C:\Install\$($mdtInstallFile.FileName)" -CommandLine '/qb' -NoDisplay -AsJob -PassThru
    Wait-LWLabJob -Job $job -NoDisplay

    Invoke-LabCommand -ActivityName 'Configure WDS' -ComputerName $SccmServerName -ScriptBlock {
        Start-Process -FilePath "C:\Windows\System32\WDSUTIL.EXE" -ArgumentList "/Initialize-Server /RemInst:C:\RemoteInstall" -Wait
        Start-Sleep -Seconds 10
        Start-Process -FilePath "C:\Windows\System32\WDSUTIL.EXE" -ArgumentList "/Set-Server /AnswerClients:All" -Wait
    }

    #SCCM Needs a ton of additional features installed...
    Write-ScreenInfo "Installing a ton of additional features on server '$SccmServerName'..." -NoNewLine
    $job = Install-LabWindowsFeature -ComputerName $SccmServerName -FeatureName 'FS-FileServer,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Web-WMI,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Static-Content,Web-Http-Redirect,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-Asp-Net,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter' -NoDisplay -AsJob -PassThru
    Wait-LWLabJob -Job $job -NoDisplay
    Write-ScreenInfo done

    $job = Install-LabWindowsFeature -ComputerName $SccmServerName -FeatureName 'NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-Framework-45-ASPNET,NET-WCF-HTTP-Activation45,BITS,RDC' -NoDisplay -AsJob -PassThru
    Wait-LWLabJob -Job $job -NoDisplay
    Write-ScreenInfo done

    #Before we start the SCCM Install, restart the computer
    Write-ScreenInfo "Restarting server '$SccmServerName'..." -NoNewLine
    Restart-LabVM -ComputerName $SccmServerName -Wait -NoDisplay

    #Build the Installation unattended .INI file
    $setupConfigFileContent = @"
[Identification]
Action=InstallPrimarySite

[Options]
ProductID=EVAL
SiteCode=$SccmSiteCode
SiteName=Primary Site 1
SMSInstallDir=C:\Program Files\Microsoft Configuration Manager
SDKServer=$sccmServerFqdn
RoleCommunicationProtocol=HTTPorHTTPS
ClientsUsePKICertificate=0
PrerequisiteComp=1
PrerequisitePath=C:\Install\SCCMPreReqs
MobileDeviceLanguage=0
ManagementPoint=$sccmServerFqdn
ManagementPointProtocol=HTTP
DistributionPoint=$sccmServerFqdn
DistributionPointProtocol=HTTP
DistributionPointInstallIIS=0
AdminConsole=1
JoinCEIP=0

[SQLConfigOptions]
SQLServerName=$SqlServerFqdn
DatabaseName=CM_$SccmSiteCode
SQLSSBPort=4022
SQLDataFilePath=C:\CMSQL\SQLDATA\
SQLLogFilePath=C:\CMSQL\SQLLOGS\

[CloudConnectorOptions]
CloudConnector=0
CloudConnectorServer=$sccmServerFqdn
UseProxy=0

[SystemCenterOptions]

[HierarchyExpansionOption]
"@

    #Save the config file to disk, and copy it to the SCCM Server
    $setupConfigFileContent | Out-File -FilePath "$($lab.LabPath)\ConfigMgrUnattend.ini" -Encoding ascii

    Copy-LabFileItem -Path "$($lab.LabPath)\ConfigMgrUnattend.ini" -DestinationFolderPath /Install -ComputerName $SccmServerName

    $sccmComputerAccount = '{0}\{1}$' -f
    $sccmServer.DomainName.Substring(0, $sccmServer.DomainName.IndexOf('.')),
    $SccmServerName

    Invoke-LabCommand -ActivityName 'Create Folders for SQL DB' -ComputerName $sqlServer -ScriptBlock {
        #SQL Server does not like creating databases without the directories already existing, so make sure to create them first
        New-Item -Path 'C:\CMSQL\SQLDATA' -ItemType Directory -Force | Out-Null
        New-Item -Path 'C:\CMSQL\SQLLOGS' -ItemType Directory -Force | Out-Null

        if (-not (Get-LocalGroupMember -Group Administrators -Member $sccmComputerAccount -ErrorAction SilentlyContinue))
        {
            Add-LocalGroupMember -Group Administrators -Member $sccmComputerAccount
        }
    } -Variable (Get-Variable -Name sccmComputerAccount) -NoDisplay

    Write-ScreenInfo 'Install SCCM. This step will take quite some time...' -NoNewLine
    $job = Install-LabSoftwarePackage -ComputerName $SccmServerName -LocalPath C:\Install\SCCM1702\SMSSETUP\BIN\X64\setup.exe -CommandLine '/Script "C:\Install\ConfigMgrUnattend.ini" /NoUserInput' -AsJob -PassThru
    Wait-LWLabJob -Job $job -NoDisplay
}

Write-ScreenInfo ''
$lab = Import-Lab -Name $data.Name -NoValidation -NoDisplay -PassThru

Install-SCCM -SccmServerName $ComputerName -SccmBinariesDirectory $SCCMBinariesDirectory -SccmPreReqsDirectory $SCCMPreReqsDirectory -SccmSiteCode $SCCMSiteCode -SqlServerName $SqlServerName