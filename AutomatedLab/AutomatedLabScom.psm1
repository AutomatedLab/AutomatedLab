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
        InstallLocation               = 'C:\Program Files\{0}'
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

    $iniNativeConsole = @{
        EnableErrorReporting          = 'Never'
        InstallLocation               = 'C:\Program Files\{0}'
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
        DataReaderPassword            = ''
        SendODRReports                = '0'
        UseMicrosoftUpdate            = '0'
        AcceptEndUserLicenseAgreement = '1'
    }
    
    $lab = Get-Lab
    $all = Get-LabVM -Role Scom
    $scomConsoleRole = Get-LabVM -Role ScomConsole
    $scomManagementServer = Get-LabVm -Role ScomManagement
    $scomWebConsoleRole = Get-LabVM -Role ScomWebConsole
    $scomReportingServer = Get-LabVm -Role ScomReporting

    # Prerequisites, all
    $odbc = Get-LabConfigurationItem -Name SqlOdbc13
    $SQLSysClrTypes = Get-LabConfigurationItem -Name SqlClrType2014
    $ReportViewer = Get-LabConfigurationItem -Name ReportViewer2015
    $odbcFile = Get-LabInternetFile -Uri $odbc -Path $labsources\SoftwarePackages -FileName odbc.msi -PassThru
    $SQLSysClrTypesFile = Get-LabInternetFile -uri $SQLSysClrTypes -Path $labsources\SoftwarePackages -FileName SQLSysClrTypes.msi -PassThru
    $ReportViewerFile = Get-LabInternetFile -uri $ReportViewer -Path $labsources\SoftwarePackages -FileName ReportViewer.msi -PassThru
    Install-LabSoftwarePackage -Path $odbcFile.FullName -ComputerName $all -CommandLine '/QN ADDLOCAL=ALL IACCEPTMSODBCSQLLICENSETERMS=YES /L*v C:\odbc.log' -NoDisplay
    
    if (Get-LabVm -Role ScomConsole,ScomWebConsole)
    {
        Install-LabSoftwarePackage -path $SQLSysClrTypesFile.FullName -ComputerName (Get-LabVm -Role ScomConsole,ScomWebConsole) -CommandLine '/quiet /norestart /log C:\DeployDebug\SQLSysClrTypes.log' -NoDisplay
        Install-LabSoftwarePackage -path $ReportViewerFile.FullName -ComputerName (Get-LabVm -Role ScomConsole,ScomWebConsole) -CommandLine '/quiet /norestart /log C:\DeployDebug\ReportViewer.log' -NoDisplay
        Install-LabWindowsFeature -Computername (Get-LabVm -Role ScomConsole,ScomWebConsole) NET-WCF-HTTP-Activation45, Web-Static-Content, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-Http-Logging, Web-Request-Monitor, Web-Filtering, Web-Stat-Compression, Web-Mgmt-Console, Web-Metabase, Web-Asp-Net, Web-Windows-Auth  -NoDisplay
    }

    # Extract SCOM on all machines
    $scomIso = ($lab.Sources.ISOs | Where-Object { $_.Name -like 'Scom*' }).Path
    $isos = Mount-LabIsoImage -ComputerName $all -IsoPath $scomIso -SupressOutput -PassThru
    Invoke-LabCommand -ComputerName $all -Variable (Get-Variable isos) -ActivityName 'Extracting SCOM Server' -ScriptBlock {
        $setup = Get-ChildItem -Path $($isos.Where( { $_.InternalComputerName -eq $env:COMPUTERNAME })).DriveLetter -Filter *.exe | Select-Object -First 1
        Start-Process -FilePath $setup.FullName -ArgumentList '/VERYSILENT', '/DIR=C:\SCOM' -Wait
    } -NoDisplay
    
    # Server
    $jobs = foreach ($vm in $scomManagementServer)
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
            foreach ($kvp in $iniManagement.GetEnumerator().Where({$_.Key -like '*User'}))
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

        foreach ($kvp in $iniManagement.GetEnumerator().Where({$_.Key -like '*User'}))
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
            $iniManagement['SqlServerInstance'] = $sqlMachine
        }
        if ([string]::IsNullOrWhiteSpace($iniManagement['DwSqlServerInstance']))
        {
            $iniManagement['DwSqlServerInstance'] = $sqlMachine
        }

        # Setup Command Line Management-Server
        Invoke-LabCommand -ComputerName $vm -ScriptBlock {
            Add-LocalGroupMember -Sid S-1-5-32-544 -Member $iniManagement['DASAccountUser']
        } -Variable (Get-Variable iniManagement)
        $CommandlineArgumentsServer = $iniManagement.GetEnumerator() | Where-Object Key -notin ProductKey, ScomAdminGroupName | ForEach-Object { '/{0}:"{1}"' -f $_.Key, $_.Value }
        $setupCommandlineServer = "/install /silent /components:OMServer $CommandlineArgumentsServer"
        Install-LabSoftwarePackage -ComputerName $vm -LocalPath C:\SCOM\setup.exe -CommandLine $setupCommandlineServer -AsJob -PassThru -UseShellExecute -Timeout 20 -NoDisplay
    }

    if ($jobs) { Wait-LWLabJob -Job $jobs }

    # Licensing
    foreach ($vm in $scomManagementServer)
    {
        $role = $vm.Roles | Where-Object Name -eq ScomManagement
        if (-not $role.Properties.ContainsKey('ProductKey')) { continue }
        if ([string]::IsNullOrWhiteSpace($role.Properties['ProductKey'])) { continue }
        $productKey = $role.Properties['ProductKey']
 
        Invoke-LabCommand -ComputerName $vm -Variable (Get-Variable -Name productKey) -ScriptBlock {
            Set-SCOMLicense -ProductId $productKey
        } -NoDisplay
    }

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

        Install-LabSoftwarePackage -ComputerName $vm -LocalPath C:\SCOM\setup.exe -CommandLine $setupCommandlineNativeConsole -AsJob -PassThru -UseShellExecute -Timeout 20 -NoDisplay
    }

    if ($jobs) { Wait-LWLabJob -Job $jobs }

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
            $iniWeb['ManagementServer'] = $mgtMachine
        }

        $CommandlineArgumentsWebConsole = $iniWeb.GetEnumerator() | ForEach-Object { '/{0}:"{1}"' -f $_.Key, $_.Value }
        $setupCommandlineWebConsole = "/install /silent /components:OMWebConsole $commandlineArgumentsWebConsole"

        Install-LabSoftwarePackage -ComputerName $vm -LocalPath C:\SCOM\setup.exe -CommandLine $setupCommandlineWebConsole -AsJob -PassThru -UseShellExecute -Timeout 20 -UseExplicitCredentialsForScheduledJob -AsScheduledJob -NoDisplay
    }

    if ($jobs) { Wait-LWLabJob -Job $jobs }

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
            $iniReport['ManagementServer'] = $mgtMachine
        }

        if (-not [string]::IsNullOrWhiteSpace($iniReport['SRSInstance']))
        {
            $ssrsName = $iniReport['SRSInstance'].Split('\')[0]
            $ssrsVm = Get-LabVm -ComputerName $ssrsName
        }

        if (-not $ssrsVm)
        {
            $ssrsVm = Get-LabVm -Role SQLServer2016,SQLServer2017 | Select-Object -First 1
        }

        if ([string]::IsNullOrWhiteSpace($iniReport['SRSInstance']))
        {
            $iniReport['SRSInstance'] = $ssrsVm
        }

        if ([string]::IsNullOrWhiteSpace($iniReport['DataReaderPassword']))
        {
            $iniReport['DataReaderPassword'] = $vm.GetCredential($lab).GetNetworkCredential().Password
        }

        Invoke-LabCommand -ComputerName (Get-LabVm -Role RootDc | Select-Object -First 1) -ScriptBlock {
            foreach ($kvp in $iniManagement.GetEnumerator().Where({$_.Key -like '*User'}))
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

        $CommandlineArgumentsReportServer = $iniReport.GetEnumerator() | ForEach-Object { '/{0}:"{1}"' -f $_.Key, $_.Value }
        $setupCommandlineReportServer = "/install /silent /components:OMReporting $commandlineArgumentsReportServer"

        Install-LabSoftwarePackage -ComputerName $vm -LocalPath C:\SCOM\setup.exe -CommandLine $setupCommandlineReportServer -AsJob -PassThru -UseShellExecute -Timeout 20 -NoDisplay
    }

    if ($jobs) { Wait-LWLabJob -Job $jobs }

    Write-LogFunctionExit
}
