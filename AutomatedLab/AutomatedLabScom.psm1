function Install-LabScom
{
    [CmdletBinding()]
    param ( )

    Write-LogFunctionEntry

    # defaults
    $iniManagementServer = @{
        ManagementGroupName           = 'SCOM2019'
        SqlServerInstance             = ''
        SqlInstancePort               = '1433'
        DatabaseName                  = 'OperationsManager'
        DwSqlServerInstance           = ''
        InstallLocation               = 'C:\Program Files\Microsoft System Center\Operations Manager'
        DwSqlInstancePort             = '1433'
        DwDatabaseName                = 'OperationsManagerDW'
        ActionAccountUser             = 'OM19AA'
        ActionAccountPassword         = ''
        DASAccountUser                = 'OM19DAS' 
        DASAccountPassword            = ''
        DataReaderUser                = 'OM19READ'
        DataReaderPassword            = ''
        DataWriterUser                = 'OM19WRITE'
        DataWriterPassword            = ''
        EnableErrorReporting          = 'Never'
        SendCEIPReports               = '0'
        UseMicrosoftUpdate            = '0'
        AcceptEndUserLicenseAgreement = '1'
        ProductKey                    = ''        
    }

    $iniAddManagementServer = @{
        SqlServerInstance             = ''
        SqlInstancePort               = '1433'
        DatabaseName                  = 'OperationsManager'
        InstallLocation               = 'C:\Program Files\Microsoft System Center\Operations Manager'
        ActionAccountUser             = 'OM19AA'
        ActionAccountPassword         = ''
        DASAccountUser                = 'OM19DAS' 
        DASAccountPassword            = ''
        DataReaderUser                = 'OM19READ'
        DataReaderPassword            = ''
        DataWriterUser                = 'OM19WRITE'
        DataWriterPassword            = ''
        EnableErrorReporting          = 'Never'
        SendCEIPReports               = '0'
        AcceptEndUserLicenseAgreement = '1'
        UseMicrosoftUpdate            = '0'
    }

    $iniNativeConsole = @{
        EnableErrorReporting          = 'Never'
        InstallLocation               = 'C:\Program Files\Microsoft System Center\Operations Manager'
        SendCEIPReports               = '0'
        UseMicrosoftUpdate            = '0'
        AcceptEndUserLicenseAgreement = '1'
    }

    $iniWebConsole = @{
        ManagementServer              = ''
        WebSiteName                   = 'Default Web Site'
        WebConsoleAuthorizationMode   = 'Mixed'
        SendCEIPReports               = '0'
        UseMicrosoftUpdate            = '0'
        AcceptEndUserLicenseAgreement = '1'
    }

    $iniReportServer = @{
        ManagementServer              = ''
        SRSInstance                   = ''
        DataReaderUser                = 'OM19READ'
        InstallLocation               = 'C:\Program Files\Microsoft System Center\Operations Manager'
        DataReaderPassword            = ''
        SendODRReports                = '0'
        UseMicrosoftUpdate            = '0'
        AcceptEndUserLicenseAgreement = '1'
    }
    
    $lab = Get-Lab
    $all = Get-LabVM -Role Scom
    $scomConsoleRole = Get-LabVM -Role ScomConsole
    $scomManagementServer = Get-LabVm -Role ScomManagement
    $firstmgmt = $scomManagementServer | Select-Object -First 1
    $addtlmgmt = $scomManagementServer | Select-Object -Skip 1
    $scomWebConsoleRole = Get-LabVM -Role ScomWebConsole
    $scomReportingServer = Get-LabVm -Role ScomReporting

    Start-LabVM -ComputerName $all -Wait

    Invoke-LabCommand -ComputerName $all -ScriptBlock {
        if (-not (Test-Path C:\DeployDebug))
        {
            $null = New-Item -ItemType Directory -Path C:\DeployDebug
        }

        $null = New-Item -ItemType Directory -Path HKLM:\software\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters -Force
        # Yup, this Setup requires RC4 enabled to be able to "resolve" accounts
        $null = Set-ItemProperty HKLM:\software\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters -Name SupportedEncryptionTypes -Value 0x7fffffff
    }

    Restart-LabVM -ComputerName $all -Wait

    # Prerequisites, all
    $odbc = Get-LabConfigurationItem -Name SqlOdbc13
    $SQLSysClrTypes = Get-LabConfigurationItem -Name SqlClrType2014
    $ReportViewer = Get-LabConfigurationItem -Name ReportViewer2015
    $odbcFile = Get-LabInternetFile -Uri $odbc -Path $labsources\SoftwarePackages -FileName odbc.msi -PassThru
    $SQLSysClrTypesFile = Get-LabInternetFile -uri $SQLSysClrTypes -Path $labsources\SoftwarePackages -FileName SQLSysClrTypes.msi -PassThru
    $ReportViewerFile = Get-LabInternetFile -uri $ReportViewer -Path $labsources\SoftwarePackages -FileName ReportViewer.msi -PassThru
    Install-LabSoftwarePackage -Path $odbcFile.FullName -ComputerName $all -CommandLine '/QN ADDLOCAL=ALL IACCEPTMSODBCSQLLICENSETERMS=YES /L*v C:\odbc.log' -NoDisplay
    
    if (Get-LabVm -Role ScomConsole, ScomWebConsole)
    {
        Install-LabSoftwarePackage -path $SQLSysClrTypesFile.FullName -ComputerName (Get-LabVm -Role ScomConsole, ScomWebConsole) -CommandLine '/quiet /norestart /log C:\DeployDebug\SQLSysClrTypes.log' -NoDisplay
        Install-LabSoftwarePackage -path $ReportViewerFile.FullName -ComputerName (Get-LabVm -Role ScomConsole, ScomWebConsole) -CommandLine '/quiet /norestart /log C:\DeployDebug\ReportViewer.log' -NoDisplay
        Install-LabWindowsFeature -Computername (Get-LabVm -Role ScomConsole, ScomWebConsole) NET-WCF-HTTP-Activation45, Web-Static-Content, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-Http-Logging, Web-Request-Monitor, Web-Filtering, Web-Stat-Compression, Web-Mgmt-Console, Web-Metabase, Web-Asp-Net, Web-Windows-Auth  -NoDisplay
    }

    if ($scomReportingServer)
    {
        Invoke-LabCommand -ComputerName $scomReportingServer -ScriptBlock {
            Get-Service -Name SQLSERVERAGENT* | Set-Service -StartupType Automatic -Status Running
        } -NoDisplay
    }

    # Extract SCOM on all machines
    $scomIso = ($lab.Sources.ISOs | Where-Object { $_.Name -like 'Scom*' }).Path
    $isos = Mount-LabIsoImage -ComputerName $all -IsoPath $scomIso -SupressOutput -PassThru
    Invoke-LabCommand -ComputerName $all -Variable (Get-Variable isos) -ActivityName 'Extracting SCOM Server' -ScriptBlock {
        $setup = Get-ChildItem -Path $($isos | Where InternalComputerName -eq $env:COMPUTERNAME).DriveLetter -Filter *.exe | Select-Object -First 1
        Start-Process -FilePath $setup.FullName -ArgumentList '/VERYSILENT', '/DIR=C:\SCOM' -Wait
    } -NoDisplay
    
    # Server
    $installationPaths = @{}
    $jobs = foreach ($vm in $firstmgmt)
    {
        $iniManagement = $iniManagementServer.Clone()
        $role = $vm.Roles | Where-Object Name -eq ScomManagement

        foreach ($kvp in $iniManagement.GetEnumerator().Where( { $_.Key -like '*Password' }))
        {
            $iniManagement[$kvp.Key] = $vm.GetCredential((Get-Lab)).GetNetworkCredential().Password # Default lab credential
        }

        foreach ($property in $role.Properties.GetEnumerator())
        {
            if (-not $iniManagement.ContainsKey($property.Key)) { continue }
            $iniManagement[$property.Key] = $property.Value
        }

        if ($role.Properties.ContainsKey('ProductKey'))
        {
            $iniServer['ProductKey'] = $role.Properties['ProductKey']
        }

        # Create users/groups
        Invoke-LabCommand -ComputerName (Get-LabVm -Role RootDc | Select-Object -First 1) -ScriptBlock {
            foreach ($kvp in $iniManagement.GetEnumerator().Where( { $_.Key -like '*User' }))
            {
                if ($kvp.Key -like '*User')
                {
                    $userName = $kvp.Value
                    $password = $iniManagement[($kvp.Key -replace 'User', 'Password')]
                }
                $userAccount = $null # Damn AD cmdlets.

                try
                {
                    $userAccount = Get-ADUser -Identity $userName -ErrorAction Stop
                }
                catch
                { }

                if (-not $userAccount)
                {
                    $userAccount = New-ADUser -Name $userName -SamAccountName $userName -PassThru -Enabled $true -AccountPassword ($password | ConvertTo-SecureString -AsPlainText -Force)
                }
            }

            $group = $iniManagement['ScomAdminGroupName']
            if (-not $group) { return }
            try
            {
                $group = Get-ADGroup -Identity $group -ErrorAction Stop
            }
            catch {}
            if (-not $group)
            {
                New-ADGroup -Name $group -GroupScope Global -GroupType Security
            }
        } -Variable (Get-Variable iniManagement) -NoDisplay

        foreach ($kvp in $iniManagement.GetEnumerator().Where( { $_.Key -like '*User' }))
        {
            if ($kvp.Value.Contains('\')) { continue }
            
            $iniManagement[$kvp.Key] = '{0}\{1}' -f $vm.DomainAccountName.Split('\')[0], $kvp.Value
        }
        
        if ($iniManagement['SqlServerInstance'] -like '*\*')
        {
            $sqlMachineName = $iniManagement['SqlServerInstance'].Split('\')[0]
            $sqlMachine = Get-LabVm -ComputerName $sqlMachineName
        }

        if ($iniManagement['DwSqlServerInstance'] -like '*\*')
        {
            $sqlDwMachineName = $iniManagement['DwSqlServerInstance'].Split('\')[0]
            $sqlDwMachine = Get-LabVm -ComputerName $sqlDwMachineName
        }

        if (-not $sqlMachine)
        {
            $sqlMachine = Get-LabVm -Role SQLServer2016, SQLServer2017 | Select-Object -First 1
        }

        if (-not $sqlDwMachine)
        {
            $sqlDwMachine = Get-LabVm -Role SQLServer2016, SQLServer2017 | Select-Object -First 1
        }

        if ([string]::IsNullOrWhiteSpace($iniManagement['SqlServerInstance']))
        {
            $iniManagement['SqlServerInstance'] = $sqlMachine.Name
        }
        if ([string]::IsNullOrWhiteSpace($iniManagement['DwSqlServerInstance']))
        {
            $iniManagement['DwSqlServerInstance'] = $sqlMachine.Name
        }

        # Setup Command Line Management-Server
            
        Invoke-LabCommand -ComputerName $vm -ScriptBlock {
            Add-LocalGroupMember -Sid S-1-5-32-544 -Member $iniManagement['DASAccountUser'] -ErrorAction SilentlyContinue
        } -Variable (Get-Variable iniManagement)
        $CommandlineArgumentsServer = $iniManagement.GetEnumerator() | Where-Object Key -notin ProductKey, ScomAdminGroupName | ForEach-Object { '/{0}:"{1}"' -f $_.Key, $_.Value }
            
        $setupCommandlineServer = "/install /silent /components:OMServer $CommandlineArgumentsServer"
        Invoke-LabCommand -ComputerName $vm -ScriptBlock { Set-Content -Path C:\DeployDebug\SetupScomManagement.cmd -Value "C:\SCOM\setup.exe $setupCommandLineServer" } -Variable (Get-Variable setupCommandlineServer) -NoDisplay
        Install-LabSoftwarePackage -ComputerName $vm -LocalPath C:\SCOM\setup.exe -CommandLine $setupCommandlineServer -AsJob -PassThru -UseShellExecute -UseExplicitCredentialsForScheduledJob -AsScheduledJob -Timeout 20 -NoDisplay
        $isPrimaryManagementServer = $isPrimaryManagementServer - 1
        $installationPaths[$vm.Name] = $iniManagement.InstallLocation
    }
    
    if ($jobs)
    {
        Wait-LWLabJob -Job $jobs
    }

    $jobs = foreach ($vm in $addtlmgmt)
    {
        $iniManagement = $iniAddManagementServer.Clone()
        $role = $vm.Roles | Where-Object Name -eq ScomManagement

        foreach ($kvp in $iniManagement.GetEnumerator().Where( { $_.Key -like '*Password' }))
        {
            $iniManagement[$kvp.Key] = $vm.GetCredential((Get-Lab)).GetNetworkCredential().Password # Default lab credential
        }

        foreach ($property in $role.Properties.GetEnumerator())
        {
            if (-not $iniManagement.ContainsKey($property.Key)) { continue }
            $iniManagement[$property.Key] = $property.Value
        }

        if ($role.Properties.ContainsKey('ProductKey'))
        {
            $iniServer['ProductKey'] = $role.Properties['ProductKey']
        }

        foreach ($kvp in $iniManagement.GetEnumerator().Where( { $_.Key -like '*User' }))
        {
            if ($kvp.Value.Contains('\')) { continue }
            
            $iniManagement[$kvp.Key] = '{0}\{1}' -f $vm.DomainAccountName.Split('\')[0], $kvp.Value
        }
        
        if ($iniManagement['SqlServerInstance'] -like '*\*')
        {
            $sqlMachineName = $iniManagement['SqlServerInstance'].Split('\')[0]
            $sqlMachine = Get-LabVm -ComputerName $sqlMachineName
        }

        if ($iniManagement['DwSqlServerInstance'] -like '*\*')
        {
            $sqlDwMachineName = $iniManagement['DwSqlServerInstance'].Split('\')[0]
            $sqlDwMachine = Get-LabVm -ComputerName $sqlDwMachineName
        }

        if (-not $sqlMachine)
        {
            $sqlMachine = Get-LabVm -Role SQLServer2016, SQLServer2017 | Select-Object -First 1
        }

        if (-not $sqlDwMachine)
        {
            $sqlDwMachine = Get-LabVm -Role SQLServer2016, SQLServer2017 | Select-Object -First 1
        }

        if ([string]::IsNullOrWhiteSpace($iniManagement['SqlServerInstance']))
        {
            $iniManagement['SqlServerInstance'] = $sqlMachine.Name
        }
        if ([string]::IsNullOrWhiteSpace($iniManagement['DwSqlServerInstance']))
        {
            $iniManagement['DwSqlServerInstance'] = $sqlMachine.Name
        }
        
        # Setup Command Line Management-Server
        Invoke-LabCommand -ComputerName $vm -ScriptBlock {
            Add-LocalGroupMember -Sid S-1-5-32-544 -Member $iniManagement['DASAccountUser'] -ErrorAction SilentlyContinue
        } -Variable (Get-Variable iniManagement)
        $CommandlineArgumentsServer = $iniManagement.GetEnumerator() | Where-Object Key -notin ProductKey, ScomAdminGroupName | ForEach-Object { '/{0}:"{1}"' -f $_.Key, $_.Value }
            
        $setupCommandlineServer = "/install /silent /components:OMServer $CommandlineArgumentsServer"
        Invoke-LabCommand -ComputerName $vm -ScriptBlock { Set-Content -Path C:\DeployDebug\SetupScomManagement.cmd -Value "C:\SCOM\setup.exe $setupCommandLineServer" } -Variable (Get-Variable setupCommandlineServer) -NoDisplay
        Install-LabSoftwarePackage -ComputerName $vm -LocalPath C:\SCOM\setup.exe -CommandLine $setupCommandlineServer -AsJob -PassThru -UseShellExecute -UseExplicitCredentialsForScheduledJob -AsScheduledJob -Timeout 20 -NoDisplay
        $installationPaths[$vm.Name] = $iniManagement.InstallLocation
    }
    
    if ($jobs)
    {
        Wait-LWLabJob -Job $jobs
    }

    # After SCOM is set up, we need to wait a bit for it to "settle", otherwise there might be timing issues later on
    Start-Sleep -Seconds 30
    Remove-LabPSSession -ComputerName $firstmgmt

    if ($firstmgmt.Count -gt 0 -or $addtlmgmt.Count -gt 0)
    {
        $installationStatus = Invoke-LabCommand -PassThru -NoDisplay -ComputerName ([object[]]$firstmgmt + [object[]]$addtlmgmt) -Variable (Get-Variable installationPaths) -ScriptBlock {
            if (Get-Command -Name Get-Package -ErrorAction SilentlyContinue)
            {
                @{
                    Node   = $env:COMPUTERNAME
                    Status = [bool](Get-Package -Name 'System Center Operations Manager Server' -ProviderName msi -ErrorAction SilentlyContinue)
                }
            }
            else
            {
                @{
                    Node   = $env:COMPUTERNAME
                    Status = (Test-Path -Path (Join-Path -Path $installationPaths[$env:COMPUTERNAME] -ChildPath Server))
                }
            }
        }

        foreach ($failedInstall in ($installationStatus | Where-Object { $_.Status -contains $false }))
        {
            Write-ScreenInfo -Type Error -Message "Installation of SCOM Management failed on $($failedInstall.Node). Please refer to the logs in C:\DeployDebug on the VM"
        }

        $cmdAvailable = Invoke-LabCommand -PassThru -NoDisplay -ComputerName $firstmgmt { Get-Command Get-ScomManagementServer -ErrorAction SilentlyContinue }
        if (-not $cmdAvailable)
        {
            Start-Sleep -Seconds 30
            Remove-LabPSSession -ComputerName $firstmgmt
        }

        Invoke-LabCommand -ComputerName $firstmgmt -ActivityName 'Waiting for SCOM Management to get in gear' -ScriptBlock {
            $start = Get-Date
            do
            {
                Start-Sleep -Seconds 10
                if ((Get-Date).Subtract($start) -gt '00:05:00') { throw 'SCOM startup not finished after 5 minutes' }
            }
            until (Get-ScomManagementServer -ErrorAction SilentlyContinue)
        }

        # Licensing
        foreach ($vm in $firstmgmt)
        {
            $role = $vm.Roles | Where-Object Name -eq ScomManagement
            if (-not $role.Properties.ContainsKey('ProductKey')) { continue }
            if ([string]::IsNullOrWhiteSpace($role.Properties['ProductKey'])) { continue }
            $productKey = $role.Properties['ProductKey']
 
            Invoke-LabCommand -ComputerName $vm -Variable (Get-Variable -Name productKey) -ScriptBlock {
                Set-SCOMLicense -ProductId $productKey
            } -NoDisplay
        }
    }

    $installationPaths = @{}
    $jobs = foreach ($vm in $scomConsoleRole)
    {
        $iniConsole = $iniNativeConsole.Clone()
        $role = $vm.Roles | Where-Object Name -in ScomConsole
        
        foreach ($property in $role.Properties.GetEnumerator())
        {
            if (-not $iniConsole.ContainsKey($property.Key)) { continue }
            $iniConsole[$property.Key] = $property.Value
        }

        $CommandlineArgumentsNativeConsole = $iniNativeConsole.GetEnumerator() | ForEach-Object { '/{0}:"{1}"' -f $_.Key, $_.Value }
        $setupCommandlineNativeConsole = "/install /silent /components:OMConsole $CommandlineArgumentsNativeConsole"
        Invoke-LabCommand -ComputerName $vm -ScriptBlock { Set-Content -Path C:\DeployDebug\SetupScomConsole.cmd -Value "C:\SCOM\setup.exe $setupCommandlineNativeConsole" } -Variable (Get-Variable setupCommandlineNativeConsole) -NoDisplay

        Install-LabSoftwarePackage -ComputerName $vm -LocalPath C:\SCOM\setup.exe -CommandLine $setupCommandlineNativeConsole -AsJob -PassThru -UseShellExecute -UseExplicitCredentialsForScheduledJob -AsScheduledJob -Timeout 20 -NoDisplay
        $installationPaths[$vm.Name] = $iniConsole.InstallLocation
    }

    if ($jobs)
    {
        Wait-LWLabJob -Job $jobs

        $installationStatus = Invoke-LabCommand -PassThru -NoDisplay -ComputerName $scomConsoleRole -Variable (Get-Variable installationPaths) -ScriptBlock {
            if (Get-Command -Name Get-Package -ErrorAction SilentlyContinue)
            {
                @{
                    Node   = $env:COMPUTERNAME
                    Status = [bool](Get-Package -Name 'System Center Operations Manager Console' -ProviderName msi -ErrorAction SilentlyContinue)
                }
            }
            else
            {
                @{
                    Node   = $env:COMPUTERNAME
                    Status = (Test-Path -Path (Join-Path -Path $installationPaths[$env:COMPUTERNAME] -ChildPath Console))
                }
            }
        }

        foreach ($failedInstall in ($installationStatus | Where-Object { $_.Status -contains $false }))
        {
            Write-ScreenInfo -Type Error -Message "Installation of SCOM Console failed on $($failedInstall.Node). Please refer to the logs in C:\DeployDebug on the VM"
        }
    }

    $installationPaths = @{}
    $jobs = foreach ($vm in $scomWebConsoleRole)
    {
        $iniWeb = $iniWebConsole.Clone()
        $role = $vm.Roles | Where-Object Name -in ScomWebConsole
        foreach ($property in $role.Properties.GetEnumerator())
        {
            if (-not $iniWeb.ContainsKey($property.Key)) { continue }
            $iniWeb[$property.Key] = $property.Value
        }

        if (-not [string]::IsNullOrWhiteSpace($iniWeb['ManagementServer']))
        {
            $mgtMachineName = $iniWeb['ManagementServer']
            $mgtMachine = Get-LabVm -ComputerName $mgtMachineName
        }

        if (-not $mgtMachine)
        {
            $mgtMachine = Get-LabVm -Role ScomManagement | Select-Object -First 1
        }

        if ([string]::IsNullOrWhiteSpace($iniWeb['ManagementServer']))
        {
            $iniWeb['ManagementServer'] = $mgtMachine.Name
        }

        $CommandlineArgumentsWebConsole = $iniWeb.GetEnumerator() | ForEach-Object { '/{0}:"{1}"' -f $_.Key, $_.Value }
        $setupCommandlineWebConsole = "/install /silent /components:OMWebConsole $commandlineArgumentsWebConsole"
        Invoke-LabCommand -ComputerName $vm -ScriptBlock { Set-Content -Path C:\DeployDebug\SetupScomWebConsole.cmd -Value "C:\SCOM\setup.exe $setupCommandlineWebConsole" } -Variable (Get-Variable setupCommandlineWebConsole) -NoDisplay

        Install-LabSoftwarePackage -ComputerName $vm -LocalPath C:\SCOM\setup.exe -CommandLine $setupCommandlineWebConsole -AsJob -PassThru -UseShellExecute -UseExplicitCredentialsForScheduledJob -AsScheduledJob -Timeout 20 -NoDisplay
        $installationPaths[$vm.Name] = $iniWeb.WebSiteName
    }

    if ($jobs)
    {
        Wait-LWLabJob -Job $jobs

        $installationStatus = Invoke-LabCommand -PassThru -NoDisplay -ComputerName $scomWebConsoleRole -Variable (Get-Variable installationPaths) -ScriptBlock {
            @{
                Node   = $env:COMPUTERNAME
                Status = [bool]($website = Get-Website -Name $installationPaths[$env:COMPUTERNAME] -ErrorAction SilentlyContinue)
            }
        }

        foreach ($failedInstall in ($installationStatus | Where-Object { $_.Status -contains $false }))
        {
            Write-ScreenInfo -Type Error -Message "Installation of SCOM Web Console failed on $($failedInstall.Node). Please refer to the logs in C:\DeployDebug on the VM"
        }
    }

    $installationPaths = @{}
    $jobs = foreach ($vm in $scomReportingServer)
    {
        $iniReport = $iniReportServer.Clone()
        $role = $vm.Roles | Where-Object Name -in ScomReporting

        foreach ($property in $role.Properties.GetEnumerator())
        {
            if (-not $iniReport.ContainsKey($property.Key)) { continue }
            $iniReport[$property.Key] = $property.Value
        }

        if (-not [string]::IsNullOrWhiteSpace($iniReport['ManagementServer']))
        {
            $mgtMachineName = $iniReport['ManagementServer']
            $mgtMachine = Get-LabVm -ComputerName $mgtMachineName
        }

        if (-not $mgtMachine)
        {
            $mgtMachine = Get-LabVm -Role ScomManagement | Select-Object -First 1
        }

        if ([string]::IsNullOrWhiteSpace($iniReport['ManagementServer']))
        {
            $iniReport['ManagementServer'] = $mgtMachine.Name
        }

        if (-not [string]::IsNullOrWhiteSpace($iniReport['SRSInstance']))
        {
            $ssrsName = $iniReport['SRSInstance'].Split('\')[0]
            $ssrsVm = Get-LabVm -ComputerName $ssrsName
        }

        if (-not $ssrsVm)
        {
            $ssrsVm = Get-LabVm -Role SQLServer2016, SQLServer2017 | Select-Object -First 1
        }

        if ([string]::IsNullOrWhiteSpace($iniReport['SRSInstance']))
        {
            $iniReport['SRSInstance'] = "$ssrsVm\SSRS"
        }

        if ([string]::IsNullOrWhiteSpace($iniReport['DataReaderPassword']))
        {
            $iniReport['DataReaderPassword'] = $vm.GetCredential($lab).GetNetworkCredential().Password
        }

        Invoke-LabCommand -ComputerName (Get-LabVm -Role RootDc | Select-Object -First 1) -ScriptBlock {
            foreach ($kvp in $iniManagement.GetEnumerator().Where( { $_.Key -like '*User' }))
            {
                if ($kvp.Key -like '*User')
                {
                    $userName = $kvp.Value
                    $password = $iniManagement[($kvp.Key -replace 'User', 'Password')]
                }
                $userAccount = $null # Damn AD cmdlets.

                try
                {
                    $userAccount = Get-ADUser -Identity $userName -ErrorAction Stop
                }
                catch
                { }

                if (-not $userAccount)
                {
                    $userAccount = New-ADUser -Name $userName -SamAccountName $userName -PassThru -Enabled $true -AccountPassword ($password | ConvertTo-SecureString -AsPlainText -Force)
                }

            }
        } -Variable (Get-Variable iniReport) -NoDisplay

        if (-not $iniReport['DataReaderUser'].Contains('\'))
        {
            $iniReport['DataReaderUser'] = '{0}\{1}' -f $vm.DomainAccountName.Split('\')[0], $iniReport['DataReaderUser']
        }

        $CommandlineArgumentsReportServer = $iniReport.GetEnumerator() | ForEach-Object { '/{0}:"{1}"' -f $_.Key, $_.Value }
        $setupCommandlineReportServer = "/install /silent /components:OMReporting $commandlineArgumentsReportServer"
        Invoke-LabCommand -ComputerName $vm -ScriptBlock { Set-Content -Path C:\DeployDebug\SetupScomReporting.cmd -Value "C:\SCOM\setup.exe $setupCommandlineReportServer" } -Variable (Get-Variable setupCommandlineReportServer) -NoDisplay
        Invoke-LabCommand -ComputerName $scomReportingServer -ScriptBlock {
            Get-Service -Name SQLSERVERAGENT* | Set-Service -StartupType Automatic -Status Running
        } -NoDisplay

        Install-LabSoftwarePackage -ComputerName $vm -LocalPath C:\SCOM\setup.exe -CommandLine $setupCommandlineReportServer -AsJob -PassThru -UseShellExecute -UseExplicitCredentialsForScheduledJob -AsScheduledJob -Timeout 20 -NoDisplay
        $installationPaths[$vm.Name] = $iniReport.InstallLocation
    }

    if ($jobs)
    {
        Wait-LWLabJob -Job $jobs
        
        $installationStatus = Invoke-LabCommand -PassThru -NoDisplay -ComputerName $scomReportingServer -Variable (Get-Variable installationPaths) -ScriptBlock {
            if (Get-Command -Name Get-Package -ErrorAction SilentlyContinue)
            {
                @{
                    Node   = $env:COMPUTERNAME
                    Status = [bool](Get-Package -Name 'System Center Operations Manager Reporting Server' -ProviderName msi -ErrorAction SilentlyContinue)
                }
            }
            else
            {
                @{
                    Node   = $env:COMPUTERNAME
                    Status = (Test-Path -Path (Join-Path -Path $installationPaths[$env:COMPUTERNAME] -ChildPath Reporting))
                }
            }
        }

        foreach ($failedInstall in ($installationStatus | Where-Object { $_.Status -contains $false }))
        {
            Write-ScreenInfo -Type Error -Message "Installation of SCOM Reporting failed on $($failedInstall.Node). Please refer to the logs in C:\DeployDebug on the VM"
        }
    }
        
    # Collect installation logs from $env:LOCALAPPDATA\SCOM\Logs
    Write-PSFMessage -Message "====SCOM log content errors begin===="
    $errors = Invoke-LabCommand -ComputerName $all -NoDisplay -ScriptBlock {    
        $null = robocopy (Join-Path -Path $env:LOCALAPPDATA SCOM\Logs) "C:\DeployDebug\SCOMLogs" /S /E
        Get-ChildItem -Path C:\DeployDebug\SCOMLogs -ErrorAction SilentlyContinue | Get-Content
    } -PassThru | Where-Object {$_ -like '*Error*'}
    foreach ($err in $errors) { Write-PSFMessage $err }
    Write-PSFMessage -Message "====SCOM log content errors end===="

    Write-LogFunctionExit
}
