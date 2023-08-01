﻿function Install-LabSqlServers
{
    [CmdletBinding()]
    param (
        [int]$InstallationTimeout = (Get-LabConfigurationItem -Name Timeout_Sql2012Installation),

        [switch]$CreateCheckPoints,

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = (Get-LabConfigurationItem -Name DefaultProgressIndicator)
    )

    Write-LogFunctionEntry

    if (-not $PSBoundParameters.ContainsKey('ProgressIndicator')) { $PSBoundParameters.Add('ProgressIndicator', $ProgressIndicator) } #enables progress indicator

    function Write-ArgumentVerbose
    {
        param
        (
            $Argument
        )

        Write-ScreenInfo -Type Verbose -Message "Argument '$Argument'"
        $Argument
    }

    Write-LogFunctionEntry

    $lab = Get-Lab -ErrorAction SilentlyContinue

    if (-not $lab)
    {
        Write-LogFunctionExitWithError -Message 'No lab definition imported, so there is nothing to do. Please use the Import-Lab cmdlet first'
        return
    }

    $machines = Get-LabVM -Role SQLServer | Where-Object SkipDeployment -eq $false
    
    Invoke-LabCommand -ComputerName $machines -ScriptBlock {
        if (-not (Test-Path C:\DeployDebug))
        {
            $null = New-Item -ItemType Directory -Path C:\DeployDebug
        }
    }

    #The default SQL installation in Azure does not give the standard buildin administrators group access.
    #This section adds the rights. As only the renamed Builtin Admin account has permissions, Invoke-LabCommand cannot be used.
    $azureMachines = $machines | Where-Object {
        $_.HostType -eq 'Azure' -and -not (($_.Roles |
            Where-Object Name -like 'SQL*').Properties.Keys |
    Where-Object {$_ -ne 'InstallSampleDatabase'})}

    if ($azureMachines)
    {
        Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewLine
        Start-LabVM -ComputerName $azureMachines -Wait -ProgressIndicator 2
        Enable-LabVMRemoting -ComputerName $azureMachines

        Write-ScreenInfo -Message "Configuring Azure SQL Servers '$($azureMachines -join ', ')'"

        foreach ($machine in $azureMachines)
        {
            Write-ScreenInfo -Type Verbose -Message "Configuring Azure SQL Server '$machine'"
            $sqlCmd = {
                $query = @"
USE [master]
GO

CREATE LOGIN [BUILTIN\Administrators] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO

-- ALTER SERVER ROLE [sysadmin] ADD MEMBER [BUILTIN\Administrators]
-- The folloing statement works in SQL 2008 to 2016
EXEC master..sp_addsrvrolemember @loginame = N'BUILTIN\Administrators', @rolename = N'sysadmin'
GO
"@
                if ((Get-PSSnapin -Registered -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue) -and -not (Get-PSSnapin -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue))
                {
                    Add-PSSnapin -Name SqlServerCmdletSnapin100
                }
                Invoke-Sqlcmd -Query $query
            }

            Invoke-LabCommand -ComputerName $machine -ActivityName SetupSqlPermissions -ScriptBlock $sqlCmd -UseLocalCredential
        }
        Write-ScreenInfo -Type Verbose -Message "Finished configuring Azure SQL Servers '$($azureMachines -join ', ')'"
    }

    $onPremisesMachines = @($machines | Where-Object HostType -eq HyperV)
    $onPremisesMachines += $machines | Where-Object {$_.HostType -eq 'Azure' -and (($_.Roles |
            Where-Object Name -like 'SQL*').Properties.Keys |
    Where-Object {$_ -ne 'InstallSampleDatabase'})}

    $downloadTargetFolder = "$labSources\SoftwarePackages"
    $dotnet48DownloadLink = Get-LabConfigurationItem -Name dotnet48DownloadLink
    Write-ScreenInfo -Message "Downloading .net Framework 4.8 from '$dotnet48DownloadLink'"
    $dotnet48InstallFile = Get-LabInternetFile -Uri $dotnet48DownloadLink -Path $downloadTargetFolder -PassThru -ErrorAction Stop

    if ($onPremisesMachines)
    {
        $cppRedist64_2017 = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name cppredist64_2017) -Path $downloadTargetFolder -FileName vcredist_x64_2017.exe -PassThru
        $cppredist32_2017 = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name cppredist32_2017) -Path $downloadTargetFolder -FileName vcredist_x86_2017.exe -PassThru
        $cppRedist64_2015 = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name cppredist64_2015) -Path $downloadTargetFolder -FileName vcredist_x64_2015.exe -PassThru
        $cppredist32_2015 = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name cppredist32_2015) -Path $downloadTargetFolder -FileName vcredist_x86_2015.exe -PassThru

        $parallelInstalls = 4
        Write-ScreenInfo -Type Verbose -Message "Parallel installs: $parallelInstalls"
        $machineIndex = 0
        $installBatch = 0
        $totalBatches = [System.Math]::Ceiling($onPremisesMachines.count / $parallelInstalls)

        do
        {
            $jobs = @()

            $installBatch++

            $machinesBatch = $($onPremisesMachines[$machineIndex..($machineIndex + $parallelInstalls - 1)])

            Write-ScreenInfo -Message "Starting machines '$($machinesBatch -join ', ')'" -NoNewLine
            Start-LabVM -ComputerName $machinesBatch -Wait

            Write-ScreenInfo -Message "Starting installation of pre-requisite .Net 3.5 Framework on machine '$($machinesBatch -join ', ')'" -NoNewLine
            $installFrameworkJobs = Install-LabWindowsFeature -ComputerName $machinesBatch -FeatureName Net-Framework-Core -NoDisplay -AsJob -PassThru
            Wait-LWLabJob -Job $installFrameworkJobs -Timeout 10 -NoDisplay -NoNewLine
            Write-ScreenInfo -Message 'done'

            Write-ScreenInfo -Message "Starting installation of pre-requisite C++ 2015 redist on machine '$($machinesBatch -join ', ')'" -NoNewLine
            Install-LabSoftwarePackage -Path $cppredist32_2015.FullName -CommandLine ' /quiet /norestart /log C:\DeployDebug\cpp32_2015.log' -ComputerName $machinesBatch -ExpectedReturnCodes 0,3010 -AsScheduledJob -NoDisplay
            Install-LabSoftwarePackage -Path $cppRedist64_2015.FullName -CommandLine ' /quiet /norestart /log C:\DeployDebug\cpp64_2015.log' -ComputerName $machinesBatch -ExpectedReturnCodes 0,3010 -AsScheduledJob -NoDisplay
            Write-ScreenInfo -Message 'done'

            Write-ScreenInfo -Message "Starting installation of pre-requisite C++ 2017 redist on machine '$($machinesBatch -join ', ')'" -NoNewLine
            Install-LabSoftwarePackage -Path $cppredist32_2017.FullName -CommandLine ' /quiet /norestart /log C:\DeployDebug\cpp32_2017.log' -ComputerName $machinesBatch -ExpectedReturnCodes 0,3010 -AsScheduledJob -NoDisplay
            Install-LabSoftwarePackage -Path $cppRedist64_2017.FullName -CommandLine ' /quiet /norestart /log C:\DeployDebug\cpp64_2017.log' -ComputerName $machinesBatch -ExpectedReturnCodes 0,3010 -AsScheduledJob -NoDisplay
            Write-ScreenInfo -Message 'done'

            Write-ScreenInfo -Message "Restarting '$($machinesBatch -join ', ')'" -NoNewLine
            Restart-LabVM -ComputerName $machinesBatch -Wait -NoDisplay
            Write-ScreenInfo -Message 'done'

            foreach ($machine in $machinesBatch)
            {
                $role = $machine.Roles | Where-Object Name -like SQLServer*

                #Dismounting ISO images to have just one drive later
                Dismount-LabIsoImage -ComputerName $machine -SupressOutput

                $retryCount = 10
                $autoLogon = (Test-LabAutoLogon -ComputerName $machine)[$machine.Name]
                while (-not $autoLogon -and $retryCount -gt 0)
                {
                    Enable-LabAutoLogon -ComputerName $machine
                    Restart-LabVM -ComputerName $machine -Wait -NoDisplay -NoNewLine

                    $autoLogon = (Test-LabAutoLogon -ComputerName $machine)[$machine.Name]
                    $retryCount--
                }

                if (-not $autoLogon)
                {
                    throw "No logon session available for $($machine.InstallationUser.UserName). Cannot continue with SQL Server setup for $machine"
                }
                Write-ScreenInfo 'Done'

                $dvdDrive = Mount-LabIsoImage -ComputerName $machine -IsoPath ($lab.Sources.ISOs | Where-Object Name -eq $role.Name).Path -PassThru -SupressOutput
                Remove-LabPSSession -Machine $machine # Remove session to refresh drives, otherwise FileNotFound even if ISO is mounted

                $global:setupArguments = ' /Q /Action=Install /IndicateProgress'

                Invoke-Ternary -Decider { $role.Properties.ContainsKey('Features') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument " /Features=$($role.Properties.Features.Replace(' ', ''))" } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument ' /Features=SQL,AS,RS,IS,Tools' }

                #Check the usage of SQL Configuration File
                if ($role.Properties.ContainsKey('ConfigurationFile'))
                {
                    $global:setupArguments = ''
                    $fileName = Join-Path -Path 'C:\' -ChildPath (Split-Path -Path $role.Properties.ConfigurationFile -Leaf)
                    $confPath = if ($lab.DefaultVirtualizationEngine -eq 'Azure' -and (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $role.Properties.ConfigurationFile))
                    {
                        $blob = Get-LabAzureLabSourcesContent -Path $role.Properties.ConfigurationFile.Replace($labSources,'')
                        $null = Get-AzStorageFileContent -File $blob -Destination (Join-Path $env:TEMP azsql.ini) -Force
                        Join-Path $env:TEMP azsql.ini
                    }
                    elseif ($lab.DefaultVirtualizationEngine -ne 'Azure' -or ($lab.DefaultVirtualizationEngine -eq 'Azure' -and -not (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $role.Properties.ConfigurationFile)))
                    {
                        $role.Properties.ConfigurationFile
                    }

                    $configurationFileContent = Get-Content $confPath | ConvertFrom-String -Delimiter = -PropertyNames Key, Value
                    Write-PSFMessage -Message ($configurationFileContent | Out-String)
                    try
                    {
                        Copy-LabFileItem -Path $role.Properties.ConfigurationFile -ComputerName $machine -ErrorAction Stop
                        $global:setupArguments += Write-ArgumentVerbose -Argument (" /ConfigurationFile=`"$fileName`"")
                    }
                    catch
                    {
                        Write-PSFMessage -Message ('Could not copy "{0}" to {1}. Skipping configuration file' -f $role.Properties.ConfigurationFile, $machine)
                    }
                }

                Invoke-Ternary -Decider { $role.Properties.ContainsKey('InstanceName') } {
                    $global:setupArguments += Write-ArgumentVerbose -Argument " /InstanceName=$($role.Properties.InstanceName)"
                    $script:instanceName = $role.Properties.InstanceName
                } `
                {
                    if ($null -eq $configurationFileContent.Where({$_.Key -eq 'INSTANCENAME'}).Value)
                    {
                        $global:setupArguments += Write-ArgumentVerbose -Argument ' /InstanceName=MSSQLSERVER'
                        $script:instanceName = 'MSSQLSERVER'
                    }
                    else
                    {
                        $script:instanceName = $configurationFileContent.Where({$_.Key -eq 'INSTANCENAME'}).Value -replace "'|`""
                    }
                }

                $result = Invoke-LabCommand -ComputerName $machine -ScriptBlock {
                    Get-Service -DisplayName "SQL Server ($instanceName)" -ErrorAction SilentlyContinue
                } -Variable (Get-Variable -Name instanceName) -PassThru -NoDisplay

                if ($result)
                {
                    Write-ScreenInfo -Message "Machine '$machine' already has SQL Server installed with requested instance name '$instanceName'" -Type Warning
                    $machine | Add-Member -Name SqlAlreadyInstalled -Value $true -MemberType NoteProperty -Force
                    $machineIndex++
                    continue
                }

                Invoke-Ternary -Decider { $role.Properties.ContainsKey('Collation') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /SQLCollation=" + "$($role.Properties.Collation)") } `
                { if ($null -eq $configurationFileContent.Where({$_.Key -eq 'SQLCollation'}).Value) {$global:setupArguments += Write-ArgumentVerbose -Argument ' /SQLCollation=Latin1_General_CI_AS'} else {} }
                Invoke-Ternary -Decider { $role.Properties.ContainsKey('SQLSvcAccount') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /SQLSvcAccount=" + """$($role.Properties.SQLSvcAccount)""") } `
                { if ($null -eq $configurationFileContent.Where({$_.Key -eq 'SQLSvcAccount'}).Value) { $global:setupArguments += Write-ArgumentVerbose -Argument ' /SQLSvcAccount="NT Authority\Network Service"' } else {} }
                Invoke-Ternary -Decider { $role.Properties.ContainsKey('SQLSvcPassword') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /SQLSvcPassword=" + """$($role.Properties.SQLSvcPassword)""") } `
                { }
                Invoke-Ternary -Decider { $role.Properties.ContainsKey('AgtSvcAccount') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /AgtSvcAccount=" + """$($role.Properties.AgtSvcAccount)""") } `
                { if ($null -eq $configurationFileContent.Where({$_.Key -eq 'AgtSvcAccount'}).Value) { $global:setupArguments += Write-ArgumentVerbose -Argument ' /AgtSvcAccount="NT Authority\System"' } else {} }
                Invoke-Ternary -Decider { $role.Properties.ContainsKey('AgtSvcPassword') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /AgtSvcPassword=" + """$($role.Properties.AgtSvcPassword)""") } `
                { }
                if($role.Name -notin 'SQLServer2022')
                {
                    Invoke-Ternary -Decider { $role.Properties.ContainsKey('RsSvcAccount') } `
                    { $global:setupArguments += Write-ArgumentVerbose -Argument (" /RsSvcAccount=" + """$($role.Properties.RsSvcAccount)""") } `
                    { if ($null -eq $configurationFileContent.Where({$_.Key -eq 'RsSvcAccount'}).Value) { $global:setupArguments += Write-ArgumentVerbose -Argument ' /RsSvcAccount="NT Authority\Network Service"' } else {} }
                    Invoke-Ternary -Decider { $role.Properties.ContainsKey('RsSvcPassword') } `
                    { $global:setupArguments += Write-ArgumentVerbose -Argument (" /RsSvcPassword=" + """$($role.Properties.RsSvcPassword)""") } `
                    { }
                    Invoke-Ternary -Decider { $role.Properties.ContainsKey('RsSvcStartupType') } `
                    { $global:setupArguments += Write-ArgumentVerbose -Argument (" /RsSvcStartupType=" + "$($role.Properties.RsSvcStartupType)") } `
                    { if ($null -eq $configurationFileContent.Where({$_.Key -eq 'RsSvcStartupType'}).Value) { $global:setupArguments += Write-ArgumentVerbose -Argument ' /RsSvcStartupType=Automatic' } else {} }
                }
                Invoke-Ternary -Decider { $role.Properties.ContainsKey('AgtSvcStartupType') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /AgtSvcStartupType=" + "$($role.Properties.AgtSvcStartupType)") } `
                { if ($null -eq $configurationFileContent.Where({$_.Key -eq 'AgtSvcStartupType'}).Value) { $global:setupArguments += Write-ArgumentVerbose -Argument ' /AgtSvcStartupType=Disabled' } else {} }
                Invoke-Ternary -Decider { $role.Properties.ContainsKey('BrowserSvcStartupType') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /BrowserSvcStartupType=" + "$($role.Properties.BrowserSvcStartupType)") } `
                { if ($null -eq $configurationFileContent.Where({$_.Key -eq 'BrowserSvcStartupType'}).Value) { $global:setupArguments += Write-ArgumentVerbose -Argument ' /BrowserSvcStartupType=Disabled' } else {} }
                Invoke-Ternary -Decider { $role.Properties.ContainsKey('AsSysAdminAccounts') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /AsSysAdminAccounts=" + "$($role.Properties.AsSysAdminAccounts)") } `
                { if ($null -eq $configurationFileContent.Where({$_.Key -eq 'AsSysAdminAccounts'}).Value) { $global:setupArguments += Write-ArgumentVerbose -Argument ' /AsSysAdminAccounts="BUILTIN\Administrators"' } else {} }
                Invoke-Ternary -Decider { $role.Properties.ContainsKey('AsSvcAccount') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /AsSvcAccount=" + "$($role.Properties.AsSvcAccount)") } `
                { if ($null -eq $configurationFileContent.Where({$_.Key -eq 'AsSvcAccount'}).Value) { $global:setupArguments += Write-ArgumentVerbose -Argument ' /AsSvcAccount="NT Authority\System"' } else {} }
                Invoke-Ternary -Decider { $role.Properties.ContainsKey('AsSvcPassword') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /AsSvcPassword=" + "$($role.Properties.AsSvcPassword)") } `
                { }
                Invoke-Ternary -Decider { $role.Properties.ContainsKey('IsSvcAccount') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /IsSvcAccount=" + "$($role.Properties.IsSvcAccount)") } `
                { if ($null -eq $configurationFileContent.Where({$_.Key -eq 'IsSvcAccount'}).Value) { $global:setupArguments += Write-ArgumentVerbose -Argument ' /IsSvcAccount="NT Authority\System"' } else {} }
                Invoke-Ternary -Decider { $role.Properties.ContainsKey('IsSvcPassword') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /IsSvcPassword=" + "$($role.Properties.IsSvcPassword)") } `
                { }
                Invoke-Ternary -Decider { $role.Properties.ContainsKey('SQLSysAdminAccounts') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (" /SQLSysAdminAccounts=" + "$($role.Properties.SQLSysAdminAccounts)") } `
                { if ($null -eq $configurationFileContent.Where({$_.Key -eq 'SQLSysAdminAccounts'}).Value) { $global:setupArguments += Write-ArgumentVerbose -Argument ' /SQLSysAdminAccounts="BUILTIN\Administrators"' } else {} }
                Invoke-Ternary -Decider { $machine.Roles.Name -notcontains 'SQLServer2008' } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument (' /IAcceptSQLServerLicenseTerms') } `
                { }

                if ($role.Name -notin 'SQLServer2008R2', 'SQLServer2008')
                {
                    $global:setupArguments += " /UpdateEnabled=`"False`"" # Otherwise we get AccessDenied
                }

                New-LabSqlAccount -Machine $machine -RoleProperties $role.Properties

                $param = @{}
                $param.Add('ComputerName', $machine)
                $param.Add('LocalPath', "$($dvdDrive.DriveLetter)\Setup.exe")
                $param.Add('AsJob', $true)
                $param.Add('PassThru', $true)
                $param.Add('NoDisplay', $true)
                $param.Add('CommandLine', $setupArguments)
                $param.Add('ExpectedReturnCodes', (0,3010))
                $jobs += Install-LabSoftwarePackage @param -UseShellExecute

                $machineIndex++
            }

            if ($jobs)
            {
                Write-ScreenInfo -Message "Waiting $InstallationTimeout minutes until the installation is finished" -Type Verbose
                Write-ScreenInfo -Message "Waiting for installation of SQL server to complete on machines '$($machinesBatch -join ', ')'" -NoNewLine

                #Start other machines while waiting for SQL server to install
                $startTime = Get-Date
                $additionalMachinesToInstall = Get-LabVM -Role SQLServer | Where-Object { (Get-LabVMStatus -ComputerName $_.Name) -eq 'Stopped' }

                if ($additionalMachinesToInstall)
                {
                    Write-PSFMessage -Message 'Preparing more machines while waiting for installation to finish'

                    $machinesToPrepare = Get-LabVM -Role SQLServer |
                    Where-Object { (Get-LabVMStatus -ComputerName $_) -eq 'Stopped' } |
                    Select-Object -First 2

                    while ($startTime.AddMinutes(5) -gt (Get-Date) -and $machinesToPrepare)
                    {
                        Write-PSFMessage -Message "Starting machines '$($machinesToPrepare -join ', ')'"
                        Start-LabVM -ComputerName $machinesToPrepare -Wait -NoNewline

                        Write-PSFMessage -Message "Starting installation of pre-requisite .Net 3.5 Framework on machine '$($machinesToPrepare -join ', ')'"
                        $installFrameworkJobs = Install-LabWindowsFeature -ComputerName $machinesToPrepare -FeatureName Net-Framework-Core -NoDisplay -AsJob -PassThru
                        Write-PSFMessage -Message "Waiting for machines '$($machinesToPrepare -join ', ')' to be finish installation of pre-requisite .Net 3.5 Framework"
                        Wait-LWLabJob -Job $installFrameworkJobs -Timeout 10 -NoDisplay -ProgressIndicator 120 -NoNewLine

                        $machinesToPrepare = Get-LabVM -Role SQLServer |
                        Where-Object { (Get-LabVMStatus -ComputerName $_.Name) -eq 'Stopped' } |
                        Select-Object -First 2
                    }
                    Write-PSFMessage -Message "Resuming waiting for SQL Servers batch ($($machinesBatch -join ', ')) to complete installation and restart"
                }

                $installMachines = $machinesBatch | Where-Object { -not $_.SqlAlreadyInstalled }
                Wait-LWLabJob -Job $jobs -Timeout 40 -NoDisplay -ProgressIndicator 15 -NoNewLine
                Dismount-LabIsoImage -ComputerName $machinesBatch -SupressOutput
                Restart-LabVM -ComputerName $installMachines -NoDisplay

                Wait-LabVM -ComputerName $installMachines -PostDelaySeconds 30 -NoNewLine

                if ($installBatch -lt $totalBatches -and ($machinesBatch | Where-Object HostType -eq 'HyperV'))
                {
                    Write-ScreenInfo -Message "Saving machines '$($machinesBatch -join ', ')' as these are not needed right now" -Type Warning
                    Save-LabVM -Name $machinesBatch
                }
            }

        }
        until ($machineIndex -ge $onPremisesMachines.Count)

        $machinesToPrepare = Get-LabVM -Role SQLServer
        $machinesToPrepare = $machinesToPrepare | Where-Object { (Get-LabVMStatus -ComputerName $_) -ne 'Started' }
        if ($machinesToPrepare)
        {
            Start-LabVM -ComputerName $machinesToPrepare -Wait -NoNewline
        }
        else
        {
            Write-ProgressIndicatorEnd
        }

        Write-ScreenInfo -Message "All SQL Servers '$($onPremisesMachines -join ', ')' have now been installed and restarted. Waiting for these to be ready." -NoNewline

        Wait-LabVM -ComputerName $onPremisesMachines -TimeoutInMinutes 30 -ProgressIndicator 10
        $logResult = Invoke-LabCommand -ComputerName $onPremisesMachines -ScriptBlock {
            $log = Get-ChildItem -Path (Join-Path -Path $env:ProgramFiles -ChildPath 'Microsoft SQL Server\*\Setup Bootstrap\Log\summary.txt') | Select-String -Pattern 'Exit code \(Decimal\):\s+(-?\d+)'
            if ($log.Matches.Groups[1].Value -notin 0,3010)
            {
                @{
                    Content  = Get-ChildItem -Path (Join-Path -Path $env:ProgramFiles -ChildPath 'Microsoft SQL Server\*\Setup Bootstrap\Log\summary.txt') | Get-Content -Raw
                    Node     = $env:COMPUTERNAME
                    ExitCode = $log.Matches.Groups[1].Value
                }
            }
        } -ActivityName 'Collecting installation logs' -NoDisplay -PassThru
        
        foreach ($log in $logResult)
        {
            New-Variable -Name "$($log.Node)SQLSETUP" -Value $log.Content -Force -Scope Global
            Write-PSFMessage -Message "====$($log.Node) SQL log content begin===="
            Write-PSFMessage -Message $log.Content
            
            Write-PSFMessage -Message "====$($log.Node) SQL log content end===="
            Write-ScreenInfo -Type Error -Message "Installation of SQL Server seems to have failed with exit code $($log.ExitCode) on $($log.Node). Examine the result of `$$($log.Node)SQLSETUP"
        }
    }
        
    $servers = Get-LabVM -Role SQLServer | Where-Object { $_.Roles.Name -ge 'SQLServer2016' }
    foreach ($server in $servers)
    {
        $sqlRole = $server.Roles | Where-Object { $_.Name -band [AutomatedLab.Roles]::SQLServer }
        $sqlRole.Name -match '(?<Version>\d+)' | Out-Null
        $server | Add-Member -Name SqlVersion -MemberType NoteProperty -Value $Matches.Version -Force

        if (($sqlRole.Properties.Features -split ',') -contains 'RS' -or
            (($configurationFileContent | Where-Object Key -eq Features).Value -split ',') -contains 'RS' -or
            (-not $sqlRole.Properties.ContainsKey('ConfigurationFile') -and -not $sqlRole.Properties.Features))
        {
            $server | Add-Member -Name SsRsUri -MemberType NoteProperty -Value (Get-LabConfigurationItem -Name "Sql$($Matches.Version)SSRS") -Force
        }

        if (($sqlRole.Properties.Features -split ',') -contains 'Tools' -or
            (($configurationFileContent | Where-Object Key -eq Features).Value -split ',') -contains 'Tools' -or
            (-not $sqlRole.Properties.ContainsKey('ConfigurationFile') -and -not $sqlRole.Properties.Features))
        {
            $server | Add-Member -Name SsmsUri -MemberType NoteProperty -Value (Get-LabConfigurationItem -Name "Sql$($Matches.Version)ManagementStudio") -Force
        }
    }

    #region install SSRS
    $servers = Get-LabVM -Role SQLServer | Where-Object { $_.SsRsUri }

    if ($servers)
    {
        Write-ScreenInfo -Message "Installing SSRS on'$($servers.Name -join ',')'"
        Write-ScreenInfo -Message "Installing .net Framework 4.8 on '$($servers.Name -join ',')'"
        Install-LabSoftwarePackage -Path $dotnet48InstallFile.FullName -CommandLine '/q /norestart /log c:\DeployDebug\dotnet48.txt' -ComputerName $servers -UseShellExecute
        Restart-LabVM -ComputerName $servers -Wait
    }

    $jobs = @()

    foreach ($server in $servers)
    {
        Write-ScreenInfo "Installing SQL Server Reporting Services on $server" -NoNewLine
        if (-not $server.SsRsUri)
        {
            Write-ScreenInfo -Message "No SSRS URI available for $server. Please provide a valid URI in AutomatedLab.psd1 and try again. Skipping..." -Type Warning
            continue
        }
        $downloadFolder = Join-Path -Path $global:labSources\SoftwarePackages -ChildPath "SQL$($server.SqlVersion)"

        if ($lab.DefaultVirtualizationEngine -ne 'Azure' -and -not (Test-Path $downloadFolder))
        {
            $null = New-Item -ItemType Directory -Path $downloadFolder
        }

        Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name SqlServerReportBuilder) -Path $labSources\SoftwarePackages\ReportBuilder.msi
        Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name Sql$($server.SqlVersion)SSRS) -Path $downloadFolder\SQLServerReportingServices.exe

        Install-LabSoftwarePackage -Path $labsources\SoftwarePackages\ReportBuilder.msi -ComputerName $server
        Install-LabSoftwarePackage -Path $downloadFolder\SQLServerReportingServices.exe -CommandLine '/Quiet /IAcceptLicenseTerms' -ComputerName $server
        Invoke-LabCommand -ActivityName 'Configuring SSRS' -ComputerName $server -FilePath $labSources\PostInstallationActivities\SqlServer\SetupSqlServerReportingServices.ps1
    }
    #endregion

    #region Install Tools
    $servers = Get-LabVM -Role SQLServer | Where-Object { $_.SsmsUri }

    if ($servers)
    {
        Write-ScreenInfo -Message "Installing SQL Server Management Studio on '$($servers.Name -join ',')' in the background."
    }

    $jobs = @()

    foreach ($server in $servers)
    {
        if (-not $server.SsmsUri)
        {
            Write-ScreenInfo -Message "No SSMS URI available for $server. Please provide a valid URI in AutomatedLab.psd1 and try again. Skipping..." -Type Warning
            continue
        }

        $downloadFolder = Join-Path -Path $global:labSources\SoftwarePackages -ChildPath "SQL$($server.SqlVersion)"
        $downloadPath = Join-Path -Path $downloadFolder -ChildPath 'SSMS-Setup-ENU.exe'

        if ($lab.DefaultVirtualizationEngine -ne 'Azure' -and -not (Test-Path $downloadFolder))
        {
            $null = New-Item -ItemType Directory -Path $downloadFolder
        }

        Get-LabInternetFile -Uri $server.SsmsUri -Path $downloadPath -NoDisplay

        $jobs += Install-LabSoftwarePackage -Path $downloadPath -CommandLine '/install /quiet' -ComputerName $server -NoDisplay -AsJob -PassThru
    }

    if ($jobs)
    {
        Write-ScreenInfo 'Waiting for SQL Server Management Studio installation jobs to finish' -NoNewLine
        Wait-LWLabJob -Job $jobs -Timeout 10 -NoDisplay -ProgressIndicator 30
    }
    #endregion

    if ($CreateCheckPoints)
    {
        Checkpoint-LabVM -ComputerName ($machines | Where-Object HostType -eq 'HyperV') -SnapshotName 'Post SQL Server Installation'
    }

    foreach ($machine in $machines)
    {
        $role = $machine.Roles | Where-Object Name -like SQLServer*

        if ([System.Convert]::ToBoolean($role.Properties['InstallSampleDatabase']))
        {
            Install-LabSqlSampleDatabases -Machine $machine
        }
    }

    Write-LogFunctionExit
}
