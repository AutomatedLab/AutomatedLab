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

    $ca = Get-LabIssuingCA -WarningAction SilentlyContinue
    if ($ca)
    {
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
            $sqledition = ((Get-LabVm -ComputerName $role.Properties.SqlServer).Roles | Where-Object Name -like SQLServer*).Name -replace 'SQLServer'
            $isNew = $sqledition -ge 2019
            Invoke-LabCommand -ActivityName 'Creating DSC SQL Database' -FilePath $labSources\PostInstallationActivities\SetupDscPullServer\CreateDscSqlDatabase.ps1 -ComputerName $role.Properties.SqlServer -ArgumentList $machine.DomainAccountName,$isNew
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

        if (Get-LabIssuingCA -WarningAction SilentlyContinue)
        {
            Request-LabCertificate -Subject "CN=$machine" -TemplateName DscMofFileEncryption -ComputerName $machine -PassThru | Out-Null

            $cert = Request-LabCertificate -Subject "CN=$($machine.Name)" -SAN $machine.Name, $machine.FQDN -TemplateName DscPullSsl -ComputerName $machine -PassThru -ErrorAction Stop
        }
        else
        {
            $cert = @{Thumbprint = 'AllowUnencryptedTraffic'}
        }

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
