#region Install-LabDscPullServer
function Install-LabDscPullServer
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = 15
    )
    
    Write-LogFunctionEntry
    
    $online = $true
    $lab = Get-Lab
    $roleName = [AutomatedLab.Roles]::DSCPullServer
    $requiredModules = 'xPSDesiredStateConfiguration', 'xDscDiagnostics', 'xWebAdministration'
    
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

    if (-not (Test-LabCATemplate -TemplateName DscMofEncryption  -ComputerName $ca))
    {
        New-LabCATemplate -TemplateName DscMofEncryption -DisplayName 'Dsc Mof File Encryption' -SourceTemplateName CEPEncryption -ApplicationPolicy 'Document Encryption' `
        -KeyUsage KEY_ENCIPHERMENT, DATA_ENCIPHERMENT -EnrollmentFlags Autoenrollment -PrivateKeyFlags AllowKeyExport -Version 2 -SamAccountName 'Domain Computers' -ComputerName $ca
    }

    if ($Online)
    {        
        Invoke-LabCommand -ActivityName 'Setup Dsc Pull Server 1' -ComputerName $machines -ScriptBlock {
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


    $accessDbEngine = Get-LabInternetFile -Uri (Get-Module -Name AutomatedLab).PrivateData.AccessDatabaseEngine2016x86 -Path $labsources\SoftwarePackages -PassThru
    $jobs = @()

    foreach ($machine in $machines)
    {
        #Install the missing database driver for access mbd that is no longer available on Windows Server 2016+
        if ((Get-LabVM -ComputerName dpull1).OperatingSystem.Version -gt '6.3.0.0')
        {
            Install-LabSoftwarePackage -Path $accessDbEngine.FullName -CommandLine '/passive /quiet' -ComputerName $machines 
        }
        
        $role = $machine.Roles | Where-Object Name -eq $roleName
        if ($role.Properties.DatabaseEngine -eq 'mdb')
        {
            $databaseEngine = 'mdb'
        }
        else
        {
            $databaseEngine = 'edb'
        }

        if ($machine.DefaultVirtualizationEngine -eq 'Azure')
        {
            Write-Verbose -Message ('Adding external port 8080 to Azure load balancer')
            Add-LWAzureLoadBalancedPort -Port 8080 -ComputerName $machine -ErrorAction SilentlyContinue
        }

        Request-LabCertificate -Subject "CN=$machine" -TemplateName DscMofEncryption -ComputerName $machine -PassThru
        $cert = Request-LabCertificate -Subject "CN=*.$($machine.DomainName)" -TemplateName DscPullSsl -ComputerName $machine -PassThru -ErrorAction Stop
        
        $guid = (New-Guid).Guid
        
        $jobs += Invoke-LabCommand -ActivityName "Setting up DSC Pull Server on '$machine'" -ComputerName $machine -ScriptBlock { 
            param  
            (
                [Parameter(Mandatory)]
                [string]$ComputerName,

                [Parameter(Mandatory)]
                [string]$CertificateThumbPrint,

                [Parameter(Mandatory)]
                [string] $RegistrationKey,

                [string]$DatabaseEngine
            )
    
            if ($DatabaseEngine -eq 'edb')
            {
                C:\SetupDscPullServerEdb.ps1 -ComputerName $ComputerName -CertificateThumbPrint $CertificateThumbPrint -RegistrationKey $RegistrationKey
            }
            elseif ($DatabaseEngine -eq 'mdb')
            {
                C:\SetupDscPullServerMdb.ps1 -ComputerName $ComputerName -CertificateThumbPrint $CertificateThumbPrint -RegistrationKey $RegistrationKey
                Copy-Item -Path C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSDesiredStateConfiguration\PullServer\Devices.mdb -Destination 'C:\Program Files\WindowsPowerShell\DscService\Devices.mdb'
            }
            else
            {
                Write-Error "The database engine is unknown"
                return
            }
    
            C:\DscTestConfig.ps1
            Start-Job -ScriptBlock { Publish-DSCModuleAndMof -Source C:\DscTestConfig } | Wait-Job | Out-Null
    
        } -ArgumentList $machine, $cert.Thumbprint, $guid, $databaseEngine -AsJob -PassThru
    }
    
    Write-ScreenInfo -Message 'Waiting for configuration of DSC Pull Server to complete' -NoNewline
    Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -Timeout $InstallationTimeout -NoDisplay

    if ($jobs | Where-Object -Property State -eq 'Failed')
    {
        throw ('Setting up the DSC pull server failed. Please review the output of the following jobs: {0}' -f ($jobs.Id -join ','))
    }

    $jobs = Install-LabWindowsFeature -ComputerName $machines -FeatureName Web-Mgmt-Tools -AsJob
    Write-ScreenInfo -Message 'Waiting for installation of IIS web admin tools to complete' -NoNewline
    Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -Timeout $InstallationTimeout -NoDisplay
    
    foreach ($machine in $machines)
    {
        $registrationKey = Invoke-LabCommand -ActivityName 'Get Registration Key created on the Pull Server' -ComputerName $machine -ScriptBlock {
            Get-Content 'C:\Program Files\WindowsPowerShell\DscService\RegistrationKeys.txt'
        } -PassThru
        
        $machine.InternalNotes.DscRegistrationKey = $registrationKey
    }
    
    Export-Lab
    
    Write-LogFunctionExit
}
#endregion Install-LabDscPullServer

#region Install-LabDscClient
function Install-LabDscClient
{
    # .ExternalHelp AutomatedLab.Help.xml
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
        
        [switch]$Wait
    )
    
    Write-LogFunctionEntry
    
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
    
    if ($PSCmdlet.ParameterSetName -eq 'New')
    {
        $outputPath = Invoke-Expression -Command (Get-Module AutomatedLab).PrivateData.DscMofPath
        if (-not (Test-Path -Path $outputPath))
        {
            mkdir -Path $outputPath -Force
        }

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
        mkdir -Path $tempPath | Out-Null  

        $dscModules = @()

        $null = foreach ($c in $ComputerName)
        {
            if ($ConfigurationData)
            {
                $adaptedConfig = $ConfigurationData.Clone()
            }

            Write-Information -MessageData "Creating Configuration MOF '$($Configuration.Name)' for node '$c'" -Tags DSC
            if ($Configuration.Parameters.ContainsKey('ComputerName'))
            {
                $mof = & $Configuration.Name -OutputPath $tempPath -ConfigurationData $adaptedConfig -ComputerName $c
            }
            else
            {
                $mof = & $Configuration.Name -OutputPath $tempPath -ConfigurationData $adaptedConfig
            }

            if ($mof.Count -gt 1)
            {
                $mof = $mof | Where-Object { $_.Name -like "*$c*" }
            }
            $mof = $mof | Rename-Item -NewName "$($Configuration.Name)_$c.mof" -Force -PassThru
            $mof | Move-Item -Destination $outputPath -Force
            
            Remove-Item -Path $tempPath -Force -Recurse
        }

        $mofFiles = Get-ChildItem -Path $outputPath -Filter *.mof | Where-Object Name -Match '(?<ConfigurationName>\w+)_(?<ComputerName>\w+)\.mof'
    
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
        $requiredDscModules = Get-DscConfigurationImportedResource -Name $Configuration.Name -ErrorAction Stop
        foreach ($requiredDscModule in $requiredDscModules)
        {
            Send-ModuleToPSSession -Module (Get-Module -Name $requiredDscModule -ListAvailable) -Session (New-LabPSSession -ComputerName $ComputerName) -Scope AllUsers -IncludeDependencies
        }
    
        Invoke-LabCommand -ComputerName $ComputerName -ActivityName 'Applying new DSC configuration' -ScriptBlock {
    
            $path = "C:\AL Dsc\$($args[0])"
        
            Remove-Item -Path "$path\localhost.mof" -ErrorAction SilentlyContinue
        
            $mofFiles = Get-ChildItem -Path $path -Filter *.mof
            if ($mofFiles.Count -gt 1)
            {
                throw "There is more than one MOF file in the folder '$path'. Expected is only one file."
            }
        
            $mofFiles | Rename-Item -NewName localhost.mof
        
            Start-DscConfiguration -Path $path -Wait:$Wait
    
        } -ArgumentList $Configuration.Name, $Wait
    }
    else
    {
        Invoke-LabCommand -ComputerName $ComputerName -ActivityName 'Applying existing DSC configuration' -ScriptBlock {
            
            Start-DscConfiguration -UseExisting -Wait:$Wait
    
        } -ArgumentList $Wait
    }

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

        $path = mkdir -Path "$([System.IO.Path]::GetTempPath())\$(New-Guid)"
    
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

        $path = mkdir -Path "$([System.IO.Path]::GetTempPath())\$(New-Guid)"
    
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