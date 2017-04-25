#region Install-LabSqlServers
function Install-LabSqlServers
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_Sql2012Installation,
		
        [switch]$CreateCheckPoints
    )
	
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

    $machines = Get-LabMachine -Role SQLServer2008, SQLServer2008R2, SQLServer2012, SQLServer2014, SQLServer2016

    #The dafault SQL installation in Azure does not give the standard buildin administrators group access.
    #This section adds the rights. As only the renamed Builtin Admin accout has permissions, Invoke-LabCommand cannot be used.
    $azureMachines = $machines | Where-Object HostType -eq Azure

    if ($azureMachines)
    {
        Write-ScreenInfo -Message 'Waiting for machines to start up'
        Start-LabVM -ComputerName $azureMachines -Wait -ProgressIndicator 2
        Enable-LabVMRemoting -ComputerName $azureMachines
        
        Write-ScreenInfo -Message "Configuring Azure SQL Servers '$($azureMachines -join ', ')'"
        
        foreach ($machine in $azureMachines)
        {            
            Write-ScreenInfo -Type Verbose -Message "Configuring Azure SQL Server '$machine'"
            Write-ScreenInfo -Message (Get-Date)
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
                if ((Get-PSSnapin -Registered -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue) -and -not (Get-PSSnapin -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue)) {
                    Add-PSSnapin -Name SqlServerCmdletSnapin100
                }
                Invoke-Sqlcmd -Query $query
            }

            Invoke-LabCommand -ComputerName $machine -ActivityName SetupSqlPermissions -ScriptBlock $sqlCmd -UseLocalCredential
        }
        Write-ScreenInfo -Type Verbose -Message "Finished configuring Azure SQL Servers '$($azureMachines -join ', ')'"
    }
    
    $hypervMachines = @($machines | Where-Object HostType -eq HyperV)
    if ($hypervMachines)
    {        
        $parallelInstalls = 4
        Write-ScreenInfo -Type Verbose -Message "Parallel installs: $parallelInstalls"
        $machineIndex = 0
        $installBatch = 0
        $totalBatches = [System.Math]::Ceiling($hypervMachines.count / $parallelInstalls)
        do
        {
            $jobs = @()
            
            $installBatch++
            
            $machinesBatch = $($hypervMachines[$machineIndex..($machineIndex + $parallelInstalls - 1)])
            
            Write-ScreenInfo -Message "Starting machines '$($machinesBatch -join ', ')'"
            Start-LabVM -ComputerName $machinesBatch
            
            $installFrameworkJobs = @()
            foreach ($m in $machinesBatch)
            {
                Write-ScreenInfo -Message "Waiting for machine '$m' to be ready" -Type Info
                Wait-LabVM -ComputerName $m -ProgressIndicator 30
                Write-ScreenInfo -Message "Starting installation of pre-requisite .Net 3.5 Framework on machine '$m'" -Type Info
                $installFrameworkJobs += Install-LabWindowsFeature -ComputerName $m -FeatureName Net-Framework-Core -NoDisplay -AsJob -PassThru                
            }
            
            Write-ScreenInfo -Message "Waiting for pre-requisite .Net 3.5 Framework to finish installation on machines '$($machinesBatch -join ', ')'" -NoNewLine
            Wait-LWLabJob -Job $installFrameworkJobs -Timeout 10 -NoDisplay -ProgressIndicator 45
            
            foreach ($machine in $machinesBatch)
            {
                $role = $machine.Roles | Where-Object Name -like SQLServer*
                
                #Dismounting ISO images to have just one drive later
                Dismount-LabIsoImage -ComputerName $machine -SupressOutput
                                
                Mount-LabIsoImage -ComputerName $machine -IsoPath ($lab.Sources.ISOs | Where-Object Name -eq $role.Name).Path -SupressOutput
                
                $global:setupArguments = ' /Q /Action=Install /IndicateProgress'
                
                ?? { $role.Properties.ContainsKey('Features') } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument " /Features=$($role.Properties.Features.Replace(' ', ''))" } `
                { $global:setupArguments += Write-ArgumentVerbose -Argument ' /Features=SQL,AS,RS,IS,Tools' }
                
                ?? { $role.Properties.ContainsKey('InstanceName') } `
                { 
                    $global:setupArguments += Write-ArgumentVerbose -Argument " /InstanceName=$($role.Properties.InstanceName)"
                    $script:instanceName = $role.Properties.InstanceName
                } `
                { 
                    $global:setupArguments += Write-ArgumentVerbose -Argument ' /InstanceName=MSSQLSERVER' 
                    $script:instanceName = 'MSSQLSERVER'
                }
                
                $result = Invoke-LabCommand -ComputerName $machine -ScriptBlock {
                    Get-Service -DisplayName "SQL Server ($instanceName)" -ErrorAction SilentlyContinue
                } -Variable (Get-Variable -Name instanceName) -PassThru -NoDisplay
                
                if ($result)
                {
                    Write-ScreenInfo -Message "Machine '$machine' already has SQL Server installed with requested instance name '$instanceName'" -Type Warning
                    $machine | Add-Member -Name SqlAlreadyInstalled -Value $true -MemberType NoteProperty
                    $machineIndex++
                    continue
                }
                
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('Collation')}             { $global:setupArguments += Write-ArgumentVerbose -Argument (" /SQLCollation=" +          "$($role.Properties.Collation)") }             { $global:setupArguments += Write-ArgumentVerbose -Argument ' /SQLCollation=Latin1_General_CI_AS' }
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('SQLSvcAccount')}         { $global:setupArguments += Write-ArgumentVerbose -Argument (" /SQLSvcAccount=" +       """$($role.Properties.SQLSvcAccount)""") }       { $global:setupArguments += Write-ArgumentVerbose -Argument ' /SQLSvcAccount="NT Authority\Network Service"' }
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('SQLSvcPassword')}        { $global:setupArguments += Write-ArgumentVerbose -Argument (" /SQLSvcPassword=" +      """$($role.Properties.SQLSvcPassword)""") }      { }
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('AgtSvcAccount')}         { $global:setupArguments += Write-ArgumentVerbose -Argument (" /AgtSvcAccount=" +       """$($role.Properties.AgtSvcAccount)""") }       { $global:setupArguments += Write-ArgumentVerbose -Argument ' /AgtSvcAccount="NT Authority\System"' }
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('AgtSvcPassword')}        { $global:setupArguments += Write-ArgumentVerbose -Argument (" /AgtSvcPassword=" +      """$($role.Properties.AgtSvcPassword)""") }      { }
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('RsSvcAccount')}          { $global:setupArguments += Write-ArgumentVerbose -Argument (" /RsSvcAccount=" +        """$($role.Properties.RsSvcAccount)""") }        { $global:setupArguments += Write-ArgumentVerbose -Argument ' /RsSvcAccount="NT Authority\Network Service"' }
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('AgtSvcStartupType')}     { $global:setupArguments += Write-ArgumentVerbose -Argument (" /AgtSvcStartupType=" +     "$($role.Properties.AgtSvcStartupType)") }     { $global:setupArguments += Write-ArgumentVerbose -Argument ' /AgtSvcStartupType=Disabled' }
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('BrowserSvcStartupType')} { $global:setupArguments += Write-ArgumentVerbose -Argument (" /BrowserSvcStartupType=" + "$($role.Properties.BrowserSvcStartupType)") } { $global:setupArguments += Write-ArgumentVerbose -Argument ' /BrowserSvcStartupType=Disabled' }
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('RsSvcStartupType')}      { $global:setupArguments += Write-ArgumentVerbose -Argument (" /RsSvcStartupType=" +      "$($role.Properties.RsSvcStartupType)") }      { $global:setupArguments += Write-ArgumentVerbose -Argument ' /RsSvcStartupType=Automatic' }
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('AsSysAdminAccounts')}    { $global:setupArguments += Write-ArgumentVerbose -Argument (" /AsSysAdminAccounts=" +    "$($role.Properties.AsSysAdminAccounts)") }    { $global:setupArguments += Write-ArgumentVerbose -Argument ' /AsSysAdminAccounts="BUILTIN\Administrators"' }
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('AsSvcAccount')}          { $global:setupArguments += Write-ArgumentVerbose -Argument (" /AsSvcAccount=" +          "$($role.Properties.AsSvcAccount)") }          { $global:setupArguments += Write-ArgumentVerbose -Argument ' /AsSvcAccount="NT Authority\System"' }
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('IsSvcAccount')}          { $global:setupArguments += Write-ArgumentVerbose -Argument (" /IsSvcAccount=" +          "$($role.Properties.IsSvcAccount)") }          { $global:setupArguments += Write-ArgumentVerbose -Argument ' /IsSvcAccount="NT Authority\System"' }
                Invoke-Ternary -Decider {$role.Properties.ContainsKey('SQLSysAdminAccounts')}   { $global:setupArguments += Write-ArgumentVerbose -Argument (" /SQLSysAdminAccounts=" +   "$($role.Properties.SQLSysAdminAccounts)") }   { $global:setupArguments += Write-ArgumentVerbose -Argument ' /SQLSysAdminAccounts="BUILTIN\Administrators"' }
                Invoke-Ternary -Decider {$machine.roles.name -notcontains 'SQLServer2008'}      { $global:setupArguments += Write-ArgumentVerbose -Argument (' /IAcceptSQLServerLicenseTerms') }                                         { }
                
                $scriptBlock = {                    
                    Write-Verbose 'Installing SQL Server...'
				    
                    $dvdDrive = ''
                    $startTime = (Get-Date)
                    while (-not $dvdDrive -and (($startTime).AddSeconds(120) -gt (Get-Date)))
                    {
                        Start-Sleep -Seconds 2
                        $dvdDrive = (Get-WmiObject -Class Win32_CDRomDrive).Drive
                    }
                    
                    if ($dvdDrive)
                    {
                        #Configure App Compatibility for SQL Server 2008. Otherwise a warning pop-up will stop the installation
                        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags' -Name '{f2d3ae3a-bfcc-45e2-bf63-178d1db34294}' -Value 4 -PropertyType 'DWORD'
                        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags' -Name '{45da5a8b-67b5-4896-86b7-a2e838aee035}' -Value 4 -PropertyType 'DWORD'
                        
                        Set-Content -Path C:\InstallSQLServer.cmd -Value "$dvdDrive\Setup.exe$setupArguments"
                        schtasks.exe /Create /SC ONLOGON /TN InstallSQLServer /TR "cmd /c c:\InstallSQLServer.cmd"
                        schtasks.exe /Run /I /TN "InstallSQLServer"
                        
                        #Wait until installation starts
                        while (schtasks.exe /Query /TN "InstallSQLServer" | Where-Object { $_ -like '*InstallSQLServer*' -and $_ -notlike '*Running*' })
                        {
                            Start-Sleep -Seconds 1
                        }
                        
                        #Wait until installation finishes
                        while (schtasks.exe /Query /TN "InstallSQLServer" | Where-Object { $_ -like '*InstallSQLServer*' -and $_ -like '*Running*' })
                        {
                            Start-Sleep -Seconds 5
                        }
                        
                        schtasks.exe /Delete /TN "InstallSQLServer" /F
                        if (-not (Test-Path -Path C:\DeployDebug))
                        {
                            New-Item -ItemType Directory -Path C:\DeployDebug | Out-Null
                        }
                        Move-Item -Path c:\InstallSQLServer.cmd -Destination C:\DeployDebug
                        
                        Write-Verbose 'SQL Installation finished. Restarting machine.'
                        
                        Restart-Computer -Force
                    }
                    else
                    {
                        Write-Error -Message 'Setup.exe in ISO file could not be found (or ISO was not successfully mounted)'
                    }
                }
                
                $param = @{}
                $param.Add('ComputerName', $machine)
                $param.Add('ActivityName', 'Install SQL Server')
                $param.Add('AsJob', $True)
                $param.Add('PassThru', $True)
                $param.Add('NoDisplay', $True)
                $param.Add('Scriptblock', $scriptBlock)
                $param.Add('Variable', (Get-Variable -Name setupArguments))
                
                $jobs += Invoke-LabCommand @param
                
                $machineIndex++
            }
            
            if ($jobs)
            {
                Write-ScreenInfo -Type Verbose -Message "Waiting $InstallationTimeout minutes until the installation is finished"
                Write-ScreenInfo -Message "Waiting for installation of SQL server to complete on machines '$($machinesBatch -join ', ')'" -NoNewline
                
                #Start other machines while waiting for SQL server to install
                $startTime = Get-Date
                $additionalMachinesToInstall = Get-LabMachine -Role SQLServer2008, SQLServer2008R2, SQLServer2012, SQLServer2014, SQLServer2016 |
                Where-Object { (Get-LabVMStatus -ComputerName $_.Name) -eq 'Stopped' }

                if ($additionalMachinesToInstall)
                {
                    Write-Verbose -Message 'Preparing more machines while waiting for installation to finish'
                    
                    $machinesToPrepare = Get-LabMachine -Role SQLServer2008, SQLServer2008R2, SQLServer2012, SQLServer2014, SQLServer2016 |
                    Where-Object { (Get-LabVMStatus -ComputerName $_) -eq 'Stopped' } |
                    Select-Object -First 2
                    
                    while ($startTime.AddMinutes(5) -gt (Get-Date) -and $machinesToPrepare)
                    {
                        Write-Verbose -Message "Starting machines '$($machinesToPrepare -join ', ')'"
                        Start-LabVM -ComputerName $machinesToPrepare
                        
                        $installFrameworkJobs = @()
                        foreach ($m in $machinesToPrepare)
                        {
                            Write-Verbose -Message "Waiting for machine '$m' to be ready"
                            Wait-LabVM -ComputerName $m -ProgressIndicator 120 -NoNewLine
                            Write-Verbose -Message "Starting installation of pre-requisite .Net 3.5 Framework on machine '$m'"
                            $installFrameworkJobs = Install-LabWindowsFeature -ComputerName $m -FeatureName Net-Framework-Core -NoDisplay -AsJob -PassThru
                        }
                        Write-Verbose -Message "Waiting for machines '$($machinesToPrepare -join ', ')' to be finish installation of pre-requisite .Net 3.5 Framework"
                        Wait-LWLabJob -Job $installFrameworkJobs -Timeout 10 -NoDisplay -ProgressIndicator 120 -NoNewLine
                        
                        $machinesToPrepare = Get-LabMachine -Role SQLServer2008, SQLServer2008R2, SQLServer2012, SQLServer2014, SQLServer2016 | Where-Object { (Get-LabVMStatus -ComputerName $_.Name) -eq 'Stopped' } | Select-Object -First 2
                    }
                    Write-Verbose -Message "Resuming waiting for SQL Servers batch ($($machinesBatch -join ', ')) to complete installation and restart"
                }
                
                $installMachines = $machinesBatch | Where-Object { -not $_.SqlAlreadyInstalled }
                Wait-LabVMRestart -ComputerName $installMachines -TimeoutInMinutes $InstallationTimeout -ProgressIndicator 120
                
                Wait-LabVM -ComputerName $installMachines -PostDelaySeconds 30
                
                Dismount-LabIsoImage -ComputerName $machinesBatch -SupressOutput
                
                if ($installBatch -lt $totalBatches)
                {
                    Write-ScreenInfo -Message "Saving machines '$($machinesBatch -join ', ')' as these are not needed right now" -Type Warning
                    Save-VM -Name $machinesBatch
                }
            }    
            
        }
        until ($machineIndex -ge $hypervMachines.Count)
	    
        $machinesToPrepare = Get-LabMachine -Role SQLServer2008, SQLServer2008R2, SQLServer2012, SQLServer2014, SQLServer2016
        $machinesToPrepare = $machinesToPrepare | Where-Object { (Get-LabVMStatus -ComputerName $_) -ne 'Started' }
        if ($machinesToPrepare)
        {
            Start-LabVM -ComputerName $machinesToPrepare -Wait
        }
        
        Write-ScreenInfo -Message "All SQL Servers '$($hypervMachines -join ', ')' have now been installed and restarted. Waiting for these to be ready." -NoNewline
        
        Wait-LabVM -ComputerName $hypervMachines -TimeoutInMinutes 30 -ProgressIndicator 10

        $sql2016 = Get-LabVM -Role SQLServer2016

		if ($sql2016)
		{
			$ssmsUri = $MyInvocation.MyCommand.Module.PrivateData.Sql2016ManagementStudio

			Write-ScreenInfo -Message "Installing SQL Server 2016 Management Studio on machines '$($sql2016.Name -join ', ')'"
			Get-LabInternetFile -Uri $ssmsUri -Path $global:labSources\SoftwarePackages\SSMS-Setup-ENU.exe

			$jobs = Install-LabSoftwarePackage -Path $global:labSources\SoftwarePackages\SSMS-Setup-ENU.exe -CommandLine '/install /quiet' -ComputerName $sql2016 -AsJob -PassThru
			Wait-LWLabJob -Job $jobs -Timeout 10 -NoDisplay -ProgressIndicator 60 -NoNewLine
		}

        if ($CreateCheckPoints)
        {
            Checkpoint-LabVM -ComputerName $machines -SnapshotName 'Post SQL Server Installation'
        }
    }
	
    Write-LogFunctionExit
}
#endregion Install-LabSqlServers