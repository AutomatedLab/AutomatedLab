#region Install-LabDscPullServer
function Install-LabDscPullServer
{
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = 15
    )

    Write-LogFunctionEntry

    $online = $true
    $lab = Get-Lab
    $roleName = [AutomatedLab.Roles]::DSCPullServer
    $requiredModules = 'xPSDesiredStateConfiguration', 'xDscDiagnostics', 'xWebAdministration'

    Write-ScreenInfo "Starting Pull Servers and waiting until they are ready" -NoNewLine
    Start-LabVM -RoleName DSCPullServer -ProgressIndicator 15 -Wait

    if (-not (Get-LabVM))
    {
        Write-ScreenInfo -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        Write-LogFunctionExit
        return
    }

    $machines = Get-LabVM -Role $roleName
    if (-not $machines)
    {
        Write-ScreenInfo -Message 'No DSC Pull Server defined in this lab, so there is nothing to do'
        Write-LogFunctionExit
        return
    }

    if (-not (Get-LabVM -Role Routing) -and $lab.DefaultVirtualizationEngine -eq 'HyperV')
    {
        Write-ScreenInfo 'Routing Role not detected, installing DSC in offline mode.'
        $online = $false
    }
    else
    {
        Write-ScreenInfo 'Routing Role detected, installing DSC in online mode.'
    }

    if ($online)
    {
        $machinesOnline = $machines | ForEach-Object {
            Test-LabMachineInternetConnectivity -ComputerName $_ -AsJob
        } |
        Receive-Job -Wait -AutoRemoveJob |
        Where-Object { $_.TcpTestSucceeded } |
        ForEach-Object { $_.NetAdapter.SystemName }

        #if there are machines online, get the ones that are offline
        if ($machinesOnline)
        {
            $machinesOffline = (Compare-Object -ReferenceObject $machines.FQDN -DifferenceObject $machinesOnline).InputObject
        }

        #if there are machines offline or all machines are offline
        if ($machinesOffline -or -not $machinesOnline)
        {
            Write-Error "The machines $($machinesOffline -join ', ') are not connected to the internet. Switching to offline mode."
            $online = $false
        }
        else
        {
            Write-ScreenInfo 'All DSC Pull Servers can reach the internet.'
        }
    }

    $wrongPsVersion = Invoke-LabCommand -ComputerName $machines -ScriptBlock {
        $PSVersionTable | Add-Member -Name ComputerName -MemberType NoteProperty -Value $env:COMPUTERNAME -PassThru -Force
    } -PassThru -NoDisplay |
    Where-Object { $_.PSVersion.Major -lt 5 } |
    Select-Object -ExpandProperty ComputerName

    if ($wrongPsVersion)
    {
        Write-Error "The following machines have an unsupported PowerShell version. At least PowerShell 5.0 is required. $($wrongPsVersion -join ', ')"
        return
    }

    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 15

    $ca = Get-LabIssuingCA
    if (-not $ca)
    {
        Write-Error 'This role requires a Certificate Authority but there is no one defined in the lab. Please make sure that one machine has the role CaRoot or CaSubordinate.'
        return
    }

    if (-not (Test-LabCATemplate -TemplateName DscPullSsl -ComputerName $ca))
    {
        New-LabCATemplate -TemplateName DscPullSsl -DisplayName 'Dsc Pull Sever SSL' -SourceTemplateName WebServer -ApplicationPolicy 'Server Authentication' `
        -EnrollmentFlags Autoenrollment -PrivateKeyFlags AllowKeyExport -Version 2 -SamAccountName 'Domain Computers' -ComputerName $ca -ErrorAction Stop
    }

    if (-not (Test-LabCATemplate -TemplateName DscMofFileEncryption  -ComputerName $ca))
    {
        New-LabCATemplate -TemplateName DscMofFileEncryption -DisplayName 'Dsc Mof File Encryption' -SourceTemplateName CEPEncryption -ApplicationPolicy 'Document Encryption' `
        -KeyUsage KEY_ENCIPHERMENT, DATA_ENCIPHERMENT -EnrollmentFlags Autoenrollment -PrivateKeyFlags AllowKeyExport -Version 2 -SamAccountName 'Domain Computers' -ComputerName $ca
    }

    if ($Online)
    {
        Invoke-LabCommand -ActivityName 'Setup Dsc Pull Server 1' -ComputerName $machines -ScriptBlock {
            # Due to changes in the gallery: Accept TLS12
            try
            {
                #https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netcore-2.0#System_Net_SecurityProtocolType_SystemDefault
                if ($PSVersionTable.PSVersion.Major -lt 6 -and [Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12')
                {
                    Write-Verbose -Message 'Adding support for TLS 1.2'
                    [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
                }
            }
            catch
            {
                Write-Warning -Message 'Adding TLS 1.2 to supported security protocols was unsuccessful.'
            }

            Install-WindowsFeature -Name DSC-Service
            Install-PackageProvider -Name NuGet -Force
            Install-Module -Name $requiredModules -Force
        } -Variable (Get-Variable -Name requiredModules) -AsJob -PassThru | Wait-Job | Receive-Job -Keep | Out-Null #only interested in errors
    }
    else
    {
        if ((Get-Module -ListAvailable -Name $requiredModules).Count -eq $requiredModules.Count)
        {
            Write-ScreenInfo "The required modules to install DSC ($($requiredModules -join ', ')) are found in PSModulePath"
        }
        else
        {
            Write-ScreenInfo "Downloading the modules '$($requiredModules -join ', ')' locally and copying them to the DSC Pull Servers."
            try
            {
                #https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netcore-2.0#System_Net_SecurityProtocolType_SystemDefault
                if ($PSVersionTable.PSVersion.Major -lt 6 -and [Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12')
                {
                    Write-Verbose -Message 'Adding support for TLS 1.2'
                    [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
                }
            }
            catch
            {
                Write-Warning -Message 'Adding TLS 1.2 to supported security protocols was unsuccessful.'
            }

            Install-PackageProvider -Name NuGet -Force | Out-Null
            Install-Module -Name $requiredModules -Force
        }

        foreach ($module in $requiredModules)
        {
            $moduleBase = Get-Module -Name $module -ListAvailable |
            Sort-Object -Property Version -Descending |
            Select-Object -First 1 -ExpandProperty ModuleBase
            $moduleDestination = Split-Path -Path $moduleBase -Parent

            Copy-LabFileItem -Path $moduleBase -ComputerName $machines -DestinationFolderPath $moduleDestination -Recurse
        }
    }

    Copy-LabFileItem -Path $labSources\PostInstallationActivities\SetupDscPullServer\SetupDscPullServerEdb.ps1,
    $labSources\PostInstallationActivities\SetupDscPullServer\SetupDscPullServerMdb.ps1,
    $labSources\PostInstallationActivities\SetupDscPullServer\SetupDscPullServerSql.ps1,
    $labSources\PostInstallationActivities\SetupDscPullServer\DscTestConfig.ps1 -ComputerName $machines

    foreach ($machine in $machines)
    {
        $role = $machine.Roles | Where-Object Name -eq $roleName
        $doNotPushLocalModules = [bool]$role.Properties.DoNotPushLocalModules

        if (-not $doNotPushLocalModules)
        {
            $moduleNames = (Get-Module -ListAvailable | Where-Object { $_.Tags -contains 'DSCResource' -and $_.Name -notin $requiredModules }).Name
            Write-ScreenInfo "Publishing local DSC resources: $($moduleNames -join ', ')..." -NoNewLine

            foreach ($module in $moduleNames)
            {
                $moduleBase = Get-Module -Name $module -ListAvailable |
                Sort-Object -Property Version -Descending |
                Select-Object -First 1 -ExpandProperty ModuleBase
                $moduleDestination = Split-Path -Path $moduleBase -Parent

                Copy-LabFileItem -Path $moduleBase -ComputerName $machines -DestinationFolderPath $moduleDestination -Recurse
            }

            Write-ScreenInfo 'finished'
        }
    }


    $accessDbEngine = Get-LabInternetFile -Uri $(Get-LabConfigurationItem -Name AccessDatabaseEngine2016x86) -Path $labsources\SoftwarePackages -PassThru
    $jobs = @()

    foreach ($machine in $machines)
    {
        $role = $machine.Roles | Where-Object Name -eq $roleName
        $databaseEngine = if ($role.Properties.DatabaseEngine)
        {
            $role.Properties.DatabaseEngine
        }
        else
        {
            'edb'
        }

        if ($databaseEngine -eq 'sql' -and $role.Properties.SqlServer)
        {
            Invoke-LabCommand -ActivityName 'Creating DSC SQL Database' -FilePath $labSources\PostInstallationActivities\SetupDscPullServer\CreateDscSqlDatabase.ps1 -ComputerName $role.Properties.SqlServer -ArgumentList $machine.DomainAccountName
        }

        if ($databaseEngine -eq 'mdb')
        {
            #Install the missing database driver for access mbd that is no longer available on Windows Server 2016+
            if ((Get-LabVM -ComputerName $machine).OperatingSystem.Version -gt '6.3.0.0')
            {
                Install-LabSoftwarePackage -Path $accessDbEngine.FullName -CommandLine '/passive /quiet' -ComputerName $machines
            }
        }

        if ($machine.DefaultVirtualizationEngine -eq 'Azure')
        {
            Write-PSFMessage -Message ('Adding external port 8080 to Azure load balancer')
            (Get-Lab).AzureSettings.LoadBalancerPortCounter++
            $remotePort = (Get-Lab).AzureSettings.LoadBalancerPortCounter
            Add-LWAzureLoadBalancedPort -Port $remotePort -DestinationPort 8080 -ComputerName $machine -ErrorAction SilentlyContinue
        }

        Request-LabCertificate -Subject "CN=$machine" -TemplateName DscMofFileEncryption -ComputerName $machine -PassThru | Out-Null

        $cert = Request-LabCertificate -Subject "CN=$($machine.Name)" -SAN $machine.Name, $machine.FQDN -TemplateName DscPullSsl -ComputerName $machine -PassThru -ErrorAction Stop

        $setupParams = @{
            ComputerName = $machine
            CertificateThumbPrint = $cert.Thumbprint
            RegistrationKey = Get-LabConfigurationItem -Name DscPullServerRegistrationKey
            DatabaseEngine  = $databaseEngine
        }
        if ($role.Properties.DatabaseName) { $setupParams.DatabaseName = $role.Properties.DatabaseName }
        if ($role.Properties.SqlServer) { $setupParams.SqlServer = $role.Properties.SqlServer }

        $jobs += Invoke-LabCommand -ActivityName "Setting up DSC Pull Server on '$machine'" -ComputerName $machine -ScriptBlock {
            if ($setupParams.DatabaseEngine -eq 'edb')
            {
                C:\SetupDscPullServerEdb.ps1 -ComputerName $setupParams.ComputerName -CertificateThumbPrint $setupParams.CertificateThumbPrint -RegistrationKey $setupParams.RegistrationKey
            }
            elseif ($setupParams.DatabaseEngine -eq 'mdb')
            {
                C:\SetupDscPullServerMdb.ps1 -ComputerName $setupParams.ComputerName -CertificateThumbPrint $setupParams.CertificateThumbPrint -RegistrationKey $setupParams.RegistrationKey
                Copy-Item -Path C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSDesiredStateConfiguration\PullServer\Devices.mdb -Destination 'C:\Program Files\WindowsPowerShell\DscService\Devices.mdb'
            }
            elseif ($setupParams.DatabaseEngine -eq 'sql')
            {
                C:\SetupDscPullServerSql.ps1 -ComputerName $setupParams.ComputerName -CertificateThumbPrint $setupParams.CertificateThumbPrint -RegistrationKey $setupParams.RegistrationKey -SqlServer $setupParams.SqlServer -DatabaseName $setupParams.DatabaseName
            }
            else
            {
                Write-Error "The database engine is unknown"
                return
            }

            C:\DscTestConfig.ps1
            Start-Job -ScriptBlock { Publish-DSCModuleAndMof -Source C:\DscTestConfig } | Wait-Job | Out-Null

        } -Variable (Get-Variable -Name setupParams) -AsJob -PassThru
    }

    Write-ScreenInfo -Message 'Waiting for configuration of DSC Pull Server to complete' -NoNewline
    Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -Timeout $InstallationTimeout -NoDisplay

    if ($jobs | Where-Object -Property State -eq 'Failed')
    {
        throw ('Setting up the DSC pull server failed. Please review the output of the following jobs: {0}' -f ($jobs.Id -join ','))
    }

    $jobs = Install-LabWindowsFeature -ComputerName $machines -FeatureName Web-Mgmt-Tools -AsJob -NoDisplay
    Write-ScreenInfo -Message 'Waiting for installation of IIS web admin tools to complete'
    Wait-LWLabJob -Job $jobs -ProgressIndicator 0 -Timeout $InstallationTimeout -NoDisplay

    foreach ($machine in $machines)
    {
        $registrationKey = Invoke-LabCommand -ActivityName 'Get Registration Key created on the Pull Server' -ComputerName $machine -ScriptBlock {
            Get-Content 'C:\Program Files\WindowsPowerShell\DscService\RegistrationKeys.txt'
        } -PassThru -NoDisplay

        $machine.InternalNotes.DscRegistrationKey = $registrationKey
    }

    Export-Lab

    Write-LogFunctionExit
}
#endregion Install-LabDscPullServer

#region Install-LabDscClient
function Install-LabDscClient
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All,

        [string[]]$PullServer
    )

    if ($All)
    {
        $machines = Get-LabVM | Where-Object { $_.Roles.Name -notin 'DC', 'RootDC', 'FirstChildDC', 'DSCPullServer' }
    }
    else
    {
        $machines = Get-LabVM -ComputerName $ComputerName
    }

    if (-not $machines)
    {
        Write-Error 'Machines to configure DSC Pull not defined or not found in the lab.'
        return
    }

    Start-LabVM -ComputerName $machines -Wait

    if ($PullServer)
    {
        if (-not (Get-LabVM -ComputerName $PullServer | Where-Object { $_.Roles.Name -contains 'DSCPullServer' }))
        {
            Write-Error "The given DSC Pull Server '$PullServer' could not be found in the lab."
            return
        }
        else
        {
            $pullServerMachines = Get-LabVM -ComputerName $PullServer
        }
    }
    else
    {
        $pullServerMachines = Get-LabVM -Role DSCPullServer
    }

    Copy-LabFileItem -Path $labSources\PostInstallationActivities\SetupDscClients\SetupDscClients.ps1 -ComputerName $machines

    foreach ($machine in $machines)
    {
        Invoke-LabCommand -ActivityName 'Setup DSC Pull Clients' -ComputerName $machine -ScriptBlock {
            param
            (
                [Parameter(Mandatory)]
                [string[]]$PullServer,

                [Parameter(Mandatory)]
                [string[]]$RegistrationKey
            )

            C:\SetupDscClients.ps1 -PullServer $PullServer -RegistrationKey $RegistrationKey
        } -ArgumentList $pullServerMachines.FQDN, $pullServerMachines.InternalNotes.DscRegistrationKey -PassThru
    }
}
#endregion Install-LabDscClient

#region Invoke-LabDscConfiguration
function Invoke-LabDscConfiguration
{
    [CmdletBinding(DefaultParameterSetName = 'New')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'New')]
        [System.Management.Automation.ConfigurationInfo]$Configuration,

        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'New')]
        [hashtable]$ConfigurationData,

        [Parameter(ParameterSetName = 'UseExisting')]
        [switch]$UseExisting,

        [switch]$Wait,

        [switch]$Force
    )

    Write-LogFunctionEntry

    $lab = Get-Lab
    $localLabSoures = Get-LabSourcesLocation -Local
    if (-not $lab.Machines)
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -ComputerName $ComputerName
    if ($machines.Count -ne $ComputerName.Count)
    {
        Write-Error -Message 'Not all machines specified could be found in the lab.'
        Write-LogFunctionExit
        return
    }

    if ($PSCmdlet.ParameterSetName -eq 'New')
    {
        $outputPath = "$localLabSoures\$(Get-LabConfigurationItem -Name DscMofPath)\$(New-Guid)"

        if (Test-Path -Path $outputPath)
        {
            Remove-Item -Path $outputPath -Recurse -Force
        }
        New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

        if ($ConfigurationData)
        {
            $result = ValidateUpdate-ConfigurationData -ConfigurationData $ConfigurationData
            if (-not $result)
            {
                return
            }
        }

        $tempPath = [System.IO.Path]::GetTempFileName()
        Remove-Item -Path $tempPath
        New-Item -ItemType Directory -Path $tempPath | Out-Null

        $dscModules = @()

        $null = foreach ($c in $ComputerName)
        {
            if ($ConfigurationData)
            {
                $adaptedConfig = $ConfigurationData.Clone()
            }

            Push-Location -Path Function:
            if ($configuration | Get-Item -ErrorAction SilentlyContinue)
            {
                $configuration | Remove-Item
            }
            $configuration | New-Item -Force
            Pop-Location

            Write-Information -MessageData "Creating Configuration MOF '$($Configuration.Name)' for node '$c'" -Tags DSC
            if ($Configuration.Parameters.ContainsKey('ComputerName'))
            {
                $mof = & $Configuration.Name -OutputPath $tempPath -ConfigurationData $adaptedConfig -ComputerName $c -WarningAction SilentlyContinue
            }
            else
            {
                $mof = & $Configuration.Name -OutputPath $tempPath -ConfigurationData $adaptedConfig -WarningAction SilentlyContinue
            }

            if ($mof.Count -gt 1)
            {
                $mof = $mof | Where-Object { $_.Name -like "*$c*" }
            }
            $mof = $mof | Rename-Item -NewName "$($Configuration.Name)_$c.mof" -Force -PassThru
            $mof | Move-Item -Destination $outputPath -Force

            Remove-Item -Path $tempPath -Force -Recurse
        }

        $mofFiles = Get-ChildItem -Path $outputPath -Filter *.mof | Where-Object Name -Match '(?<ConfigurationName>\w+)_(?<ComputerName>[\w-_]+)\.mof'

        foreach ($c in $ComputerName)
        {
            foreach ($mofFile in $mofFiles)
            {
                if ($mofFile.Name -match "(?<ConfigurationName>$($Configuration.Name))_(?<ComputerName>$c)\.mof")
                {
                    Send-File -Source $mofFile.FullName -Session (New-LabPSSession -ComputerName $Matches.ComputerName) -Destination "C:\AL Dsc\$($Configuration.Name)" -Force
                }
            }
        }

        #Get-DscConfigurationImportedResource now needs to walk over all the resources used in the composite resource
        #to find out all the reuqired modules we need to upload in total
        $requiredDscModules = Get-DscConfigurationImportedResource -Configuration $Configuration -ErrorAction Stop
        foreach ($requiredDscModule in $requiredDscModules)
        {
            Send-ModuleToPSSession -Module (Get-Module -Name $requiredDscModule -ListAvailable) -Session (New-LabPSSession -ComputerName $ComputerName) -Scope AllUsers -IncludeDependencies
        }

        Invoke-LabCommand -ComputerName $ComputerName -ActivityName 'Applying new DSC configuration' -ScriptBlock {

            $path = "C:\AL Dsc\$($Configuration.Name)"

            Remove-Item -Path "$path\localhost.mof" -ErrorAction SilentlyContinue

            $mofFiles = Get-ChildItem -Path $path -Filter *.mof
            if ($mofFiles.Count -gt 1)
            {
                throw "There is more than one MOF file in the folder '$path'. Expected is only one file."
            }

            $mofFiles | Rename-Item -NewName localhost.mof

            Start-DscConfiguration -Path $path -Wait:$Wait -Force:$Force

        } -Variable (Get-Variable -Name Configuration, Wait, Force)
    }
    else
    {
        Invoke-LabCommand -ComputerName $ComputerName -ActivityName 'Applying existing DSC configuration' -ScriptBlock {

            Start-DscConfiguration -UseExisting -Wait:$Wait -Force:$Force

        } -Variable (Get-Variable -Name Wait, Force)
    }

    Remove-Item -Path $outputPath -Recurse -Force

    Write-LogFunctionExit
}
#endregion Invoke-LabDscConfiguration

#region Remove-LabDscLocalConfigurationManagerConfiguration
function Remove-LabDscLocalConfigurationManagerConfiguration
{
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    function Remove-DscLocalConfigurationManagerConfiguration
    {
        param(
            [string[]]$ComputerName = 'localhost'
        )

        $configurationScript = @'
        [DSCLocalConfigurationManager()]
        configuration LcmDefaultConfiguration
        {
            param(
                [string[]]$ComputerName = 'localhost'
            )

            Node $ComputerName
            {
                Settings
                {
                    RefreshMode = 'Push'
                    ConfigurationModeFrequencyMins = 15
                    ConfigurationMode = 'ApplyAndMonitor'
                    RebootNodeIfNeeded = $true
                }
            }
        }
'@

        [scriptblock]::Create($configurationScript).Invoke()
        $path = New-Item -ItemType Directory -Path "$([System.IO.Path]::GetTempPath())\$(New-Guid)"

        Remove-DscConfigurationDocument -Stage Current, Pending -Force
        LcmDefaultConfiguration -OutputPath $path.FullName | Out-Null
        Set-DscLocalConfigurationManager -Path $path.FullName -Force

        Remove-Item -Path $path.FullName -Recurse -Force

        try
        {
            Test-DscConfiguration -ErrorAction Stop
            Write-Error 'There was a problem resetting the Local Configuration Manger configuration'
        }
        catch
        {
            Write-Host 'DSC Local Configuration Manger was reset to default values'
        }
    }

    $lab = Get-Lab
    if (-not $lab.Machines)
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -ComputerName $ComputerName
    if ($machines.Count -ne $ComputerName.Count)
    {
        Write-Error -Message 'Not all machines specified could be found in the lab.'
        Write-LogFunctionExit
        return
    }

    Invoke-LabCommand -ActivityName 'Removing DSC LCM configuration' -ComputerName $ComputerName -ScriptBlock (Get-Command -Name Remove-DscLocalConfigurationManagerConfiguration).ScriptBlock

    Write-LogFunctionExit
}
#endregion Remove-LabDscLocalConfigurationManagerConfiguration

#region Set-LabDscLocalConfigurationManagerConfiguration
function Set-LabDscLocalConfigurationManagerConfiguration
{
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [ValidateSet('ContinueConfiguration', 'StopConfiguration')]
        [string]$ActionAfterReboot,

        [string]$CertificateID,

        [string]$ConfigurationID,

        [int]$RefreshFrequencyMins,

        [bool]$AllowModuleOverwrite,

        [ValidateSet('ForceModuleImport','All', 'None')]
        [string]$DebugMode,

        [string[]]$ConfigurationNames,

        [int]$StatusRetentionTimeInDays,

        [ValidateSet('Push', 'Pull')]
        [string]$RefreshMode,

        [int]$ConfigurationModeFrequencyMins,

        [ValidateSet('ApplyAndAutoCorrect', 'ApplyOnly', 'ApplyAndMonitor')]
        [string]$ConfigurationMode,

        [bool]$RebootNodeIfNeeded,

        [hashtable[]]$ConfigurationRepositoryWeb,

        [hashtable[]]$ReportServerWeb,

        [hashtable[]]$PartialConfiguration
    )

    Write-LogFunctionEntry

    function Set-DscLocalConfigurationManagerConfiguration
    {
        param(
            [string[]]$ComputerName = 'localhost',

            [ValidateSet('ContinueConfiguration', 'StopConfiguration')]
            [string]$ActionAfterReboot,

            [string]$CertificateID,

            [string]$ConfigurationID,

            [int]$RefreshFrequencyMins,

            [bool]$AllowModuleOverwrite,

            [ValidateSet('ForceModuleImport','All', 'None')]
            [string]$DebugMode,

            [string[]]$ConfigurationNames,

            [int]$StatusRetentionTimeInDays,

            [ValidateSet('Push', 'Pull')]
            [string]$RefreshMode,

            [int]$ConfigurationModeFrequencyMins,

            [ValidateSet('ApplyAndAutoCorrect', 'ApplyOnly', 'ApplyAndMonitor')]
            [string]$ConfigurationMode,

            [bool]$RebootNodeIfNeeded,

            [hashtable[]]$ConfigurationRepositoryWeb,

            [hashtable[]]$ReportServerWeb,

            [hashtable[]]$PartialConfiguration
        )

        if ($PartialConfiguration)
        {
            throw (New-Object System.NotImplementedException)
        }

        if ($ConfigurationRepositoryWeb)
        {
            $validKeys = 'Name', 'ServerURL', 'RegistrationKey', 'ConfigurationNames', 'AllowUnsecureConnection'
            foreach ($hashtable in $ConfigurationRepositoryWeb)
            {

                if (-not (Test-HashtableKeys -Hashtable $hashtable -ValidKeys $validKeys))
                {
                    Write-Error 'The parameter hashtable contains invalid keys. Check the previous error to see details'
                    return
                }
            }
        }

        if ($ReportServerWeb)
        {
            $validKeys = 'Name', 'ServerURL', 'RegistrationKey', 'AllowUnsecureConnection'
            foreach ($hashtable in $ReportServerWeb)
            {

                if (-not (Test-HashtableKeys -Hashtable $hashtable -ValidKeys $validKeys))
                {
                    Write-Error 'The parameter hashtable contains invalid keys. Check the previous error to see details'
                    return
                }
            }
        }

        $sb = New-Object System.Text.StringBuilder

        [void]$sb.AppendLine('[DSCLocalConfigurationManager()]')
        [void]$sb.AppendLine('configuration LcmConfiguration')
        [void]$sb.AppendLine('{')
        [void]$sb.AppendLine('param([string[]]$ComputerName = "localhost")')
        [void]$sb.AppendLine('Node $ComputerName')
        [void]$sb.AppendLine('{')
        [void]$sb.AppendLine('Settings')
        [void]$sb.AppendLine('{')
        if ($PSBoundParameters.ContainsKey('ActionAfterReboot')) { [void]$sb.AppendLine("ActionAfterReboot = '$ActionAfterReboot'") }
        if ($PSBoundParameters.ContainsKey('RefreshMode')) { [void]$sb.AppendLine("RefreshMode = '$RefreshMode'") }
        if ($PSBoundParameters.ContainsKey('ConfigurationModeFrequencyMins')) { [void]$sb.AppendLine("ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins") }
        if ($PSBoundParameters.ContainsKey('CertificateID')) { [void]$sb.AppendLine("CertificateID = $CertificateID") }
        if ($PSBoundParameters.ContainsKey('ConfigurationID')) { [void]$sb.AppendLine("ConfigurationID = $ConfigurationID") }
        if ($PSBoundParameters.ContainsKey('AllowModuleOverwrite')) { [void]$sb.AppendLine("AllowModuleOverwrite = `$$AllowModuleOverwrite") }
        if ($PSBoundParameters.ContainsKey('RebootNodeIfNeeded')) { [void]$sb.AppendLine("RebootNodeIfNeeded = `$$RebootNodeIfNeeded") }
        if ($PSBoundParameters.ContainsKey('DebugMode')) { [void]$sb.AppendLine("DebugMode = '$DebugMode'") }
        if ($PSBoundParameters.ContainsKey('ConfigurationNames')) { [void]$sb.AppendLine("ConfigurationNames = @('$($ConfigurationNames -join "', '")')") }
        if ($PSBoundParameters.ContainsKey('StatusRetentionTimeInDays')) { [void]$sb.AppendLine("StatusRetentionTimeInDays = $StatusRetentionTimeInDays") }
        if ($PSBoundParameters.ContainsKey('ConfigurationMode')) { [void]$sb.AppendLine("ConfigurationMode = '$ConfigurationMode'") }
        if ($PSBoundParameters.ContainsKey('RefreshFrequencyMins')) { [void]$sb.AppendLine("RefreshFrequencyMins = $RefreshFrequencyMins") }

        [void]$sb.AppendLine('}')
        foreach ($web in $ConfigurationRepositoryWeb)
        {
            [void]$sb.AppendLine("ConfigurationRepositoryWeb '$($web.Name)'")
            [void]$sb.AppendLine('{')
            [void]$sb.AppendLine("ServerURL = 'https://$($web.ServerURL):$($web.Port)/PSDSCPullServer.svc'")
            [void]$sb.AppendLine("RegistrationKey = '$($Web.RegistrationKey)'")
            [void]$sb.AppendLine("ConfigurationNames = @('$($Web.ConfigurationNames)')")
            [void]$sb.AppendLine("AllowUnsecureConnection = `$$($web.AllowUnsecureConnection)")
            [void]$sb.AppendLine('}')
        }
        [void]$sb.AppendLine('}')

        [void]$sb.AppendLine('{')
        foreach ($web in $ConfigurationRepositoryWeb)
        {
            [void]$sb.AppendLine("ReportServerWeb '$($web.Name)'")
            [void]$sb.AppendLine('{')
            [void]$sb.AppendLine("ServerURL = 'https://$($web.ServerURL):$($web.Port)/PSDSCPullServer.svc'")
            [void]$sb.AppendLine("RegistrationKey = '$($Web.RegistrationKey)'")
            [void]$sb.AppendLine("AllowUnsecureConnection = `$$($web.AllowUnsecureConnection)")
            [void]$sb.AppendLine('}')
        }
        [void]$sb.AppendLine('}')

        [void]$sb.AppendLine('}')

        Invoke-Expression $sb.ToString()
        $sb.ToString() | Out-File -FilePath c:\AL_DscLcm_Debug.txt

        $path = New-Item -ItemType Directory -Path "$([System.IO.Path]::GetTempPath())\$(New-Guid)"

        LcmConfiguration -OutputPath $path.FullName | Out-Null
        Set-DscLocalConfigurationManager -Path $path.FullName

        Remove-Item -Path $path.FullName -Recurse -Force

        try
        {
            Test-DscConfiguration -ErrorAction Stop
            Write-Error 'There was a problem resetting the Local Configuration Manger configuration'
        }
        catch
        {
            Write-Host 'DSC Local Configuration Manger was set to the new values'
        }
    }

    $lab = Get-Lab
    if (-not $lab.Machines)
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -ComputerName $ComputerName
    if ($machines.Count -ne $ComputerName.Count)
    {
        Write-Error -Message 'Not all machines specified could be found in the lab.'
        Write-LogFunctionExit
        return
    }

    $params = ([hashtable]$PSBoundParameters).Clone()
    Invoke-LabCommand -ActivityName 'Setting DSC LCM configuration' -ComputerName $ComputerName -ScriptBlock {
        Set-DscLocalConfigurationManagerConfiguration @params
    } -Function (Get-Command -Name Set-DscLocalConfigurationManagerConfiguration) -Variable (Get-Variable -Name params)

    Write-LogFunctionExit
}
#endregion Set-LabDscLocalConfigurationManagerConfiguration

#region ValidateUpdate-ConfigurationData
#taken from C:\Windows\system32\WindowsPowerShell\v1.0\Modules\PSDesiredStateConfiguration\PSDesiredStateConfiguration.psm1
function ValidateUpdate-ConfigurationData
{
    param (
        [Parameter(Mandatory)]
        [hashtable]$ConfigurationData
    )

    if( -not $ConfigurationData.ContainsKey('AllNodes'))
    {
        $errorMessage = 'ConfigurationData parameter need to have property AllNodes.'
        $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
        Write-Error -Exception $exception -Message $errorMessage -Category InvalidOperation -ErrorId ConfiguratonDataNeedAllNodes
        return $false
    }

    if($ConfigurationData.AllNodes -isnot [array])
    {
        $errorMessage = 'ConfigurationData parameter property AllNodes needs to be a collection.'
        $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
        Write-Error -Exception $exception -Message $errorMessage -Category InvalidOperation -ErrorId ConfiguratonDataAllNodesNeedHashtable
        return $false
    }

    $nodeNames = New-Object -TypeName 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    foreach($Node in $ConfigurationData.AllNodes)
    {
        if($Node -isnot [hashtable] -or -not $Node.NodeName)
        {
            $errorMessage = "all elements of AllNodes need to be hashtable and has a property 'NodeName'."
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            Write-Error -Exception $exception -Message $errorMessage -Category InvalidOperation -ErrorId ConfiguratonDataAllNodesNeedHashtable
            return $false
        }

        if($nodeNames.Contains($Node.NodeName))
        {
            $errorMessage = "There are duplicated NodeNames '{0}' in the configurationData passed in." -f $Node.NodeName
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            Write-Error -Exception $exception -Message $errorMessage -Category InvalidOperation -ErrorId DuplicatedNodeInConfigurationData
            return $false
        }

        if($Node.NodeName -eq '*')
        {
            $AllNodeSettings = $Node
        }
        [void] $nodeNames.Add($Node.NodeName)
    }

    if($AllNodeSettings)
    {
        foreach($Node in $ConfigurationData.AllNodes)
        {
            if($Node.NodeName -ne '*')
            {
                foreach($nodeKey in $AllNodeSettings.Keys)
                {
                    if(-not $Node.ContainsKey($nodeKey))
                    {
                        $Node.Add($nodeKey, $AllNodeSettings[$nodeKey])
                    }
                }
            }
        }

        $ConfigurationData.AllNodes = @($ConfigurationData.AllNodes | Where-Object -FilterScript {
                $_.NodeName -ne '*'
            }
        )
    }

    return $true
}
#endregion ValidateUpdate-ConfigurationData
