
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

function Install-ScvmmServer
{
    [CmdletBinding()]
    param
    (
        [AutomatedLab.Machine[]]
        $Computer
    )

    $sqlcmd = Get-LabConfigurationItem -Name SqlCommandLineUtils
    $adk = Get-LabConfigurationItem -Name WindowsAdk
    $adkpe = Get-LabConfigurationItem -Name WindowsAdkPe
    $odbc = Get-LabConfigurationItem -Name SqlOdbc13
    $cpp64 = Get-LabConfigurationItem -Name cppredist64_2012
    $cpp32 = Get-LabConfigurationItem -Name cppredist32_2012
    $cpp1464 = Get-LabConfigurationItem -Name cppredist64_2015
    $cpp1432 = Get-LabConfigurationItem -Name cppredist32_2015
    $sqlFile = Get-LabInternetFile -Uri $sqlcmd -Path $labsources\SoftwarePackages -FileName sqlcmd.msi -PassThru
    $odbcFile = Get-LabInternetFile -Uri $odbc -Path $labsources\SoftwarePackages -FileName odbc.msi -PassThru
    $adkFile = Get-LabInternetFile -Uri $adk -Path $labsources\SoftwarePackages -FileName adk.exe -PassThru
    $adkpeFile = Get-LabInternetFile -Uri $adkpe -Path $labsources\SoftwarePackages -FileName adkpe.exe -PassThru
    $cpp64File = Get-LabInternetFile -uri $cpp64 -Path $labsources\SoftwarePackages -FileName vcredist_64_2012.exe -PassThru
    $cpp32File = Get-LabInternetFile -uri $cpp32 -Path $labsources\SoftwarePackages -FileName vcredist_32_2012.exe -PassThru
    $cpp1464File = Get-LabInternetFile -uri $cpp1464 -Path $labsources\SoftwarePackages -FileName vcredist_64_2015.exe -PassThru
    $cpp1432File = Get-LabInternetFile -uri $cpp1432 -Path $labsources\SoftwarePackages -FileName vcredist_32_2015.exe -PassThru
    Install-LabSoftwarePackage -Path $odbcFile.FullName -ComputerName $Computer -CommandLine '/QN ADDLOCAL=ALL IACCEPTMSODBCSQLLICENSETERMS=YES /L*v C:\odbc.log'
    Install-LabSoftwarePackage -Path $sqlFile.FullName -ComputerName $Computer -CommandLine '/QN IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES /L*v C:\sqlcmd.log'
    Install-LabSoftwarePackage -path $cpp64File.FullName -ComputerName $Computer -CommandLine '/quiet /norestart /log C:\DeployDebug\cpp64_2012.log'
    Install-LabSoftwarePackage -path $cpp32File.FullName -ComputerName $Computer -CommandLine '/quiet /norestart /log C:\DeployDebug\cpp32_2012.log'
    Install-LabSoftwarePackage -path $cpp1464File.FullName -ComputerName $Computer -CommandLine '/quiet /norestart /log C:\DeployDebug\cpp64_2015.log'
    Install-LabSoftwarePackage -path $cpp1432File.FullName -ComputerName $Computer -CommandLine '/quiet /norestart /log C:\DeployDebug\cpp32_2015.log'

    if ($(Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -or (Test-LabMachineInternetConnectivity -ComputerName $Computer[0]))
    {
        Install-LabSoftwarePackage -Path $adkFile.FullName -ComputerName $Computer -CommandLine '/quiet /layout c:\ADKoffline'
        Install-LabSoftwarePackage -Path $adkpeFile.FullName -ComputerName $Computer -CommandLine '/quiet /layout c:\ADKPEoffline'
    }
    else
    {
        Start-Process -FilePath $adkFile.FullName -ArgumentList "/quiet /layout $(Join-Path (Get-LabSourcesLocation -Local) SoftwarePackages/ADKoffline)" -Wait -NoNewWindow
        Start-Process -FilePath $adkpeFile.FullName -ArgumentList " /quiet /layout $(Join-Path (Get-LabSourcesLocation -Local) SoftwarePackages/ADKPEoffline)" -Wait -NoNewWindow
        Copy-LabFileItem -Path (Join-Path (Get-LabSourcesLocation -Local) SoftwarePackages/ADKoffline) -ComputerName $Computer
        Copy-LabFileItem -Path (Join-Path (Get-LabSourcesLocation -Local) SoftwarePackages/ADKPEoffline) -ComputerName $Computer
    }

    Install-LabSoftwarePackage -LocalPath C:\ADKOffline\adksetup.exe -ComputerName $Computer -CommandLine '/quiet /installpath C:\ADK'
    Install-LabSoftwarePackage -LocalPath C:\ADKPEOffline\adkwinpesetup.exe -ComputerName $Computer -CommandLine '/quiet /installpath C:\ADK'
    Install-LabWindowsFeature -ComputerName $Computer -FeatureName RSAT-Clustering -IncludeAllSubFeature
    Restart-LabVM -ComputerName $Computer -Wait

    # Server, includes console
    $jobs = foreach ($vm in $Computer)
    {
        $iniServer = $iniContentServer.Clone()
        $role = $vm.Roles | Where-Object Name -in Scvmm2016, Scvmm2019, Scvmm2022

        foreach ($property in $role.Properties.GetEnumerator())
        {
            if (-not $iniServer.ContainsKey($property.Key)) { continue }
            $iniServer[$property.Key] = $property.Value
        }

        if ($role.Properties.ContainsKey('ProductKey'))
        {
            $iniServer['ProductKey'] = $role.Properties['ProductKey']
        }

        $iniServer['ProgramFiles'] = $iniServer['ProgramFiles'] -f $role.Name.ToString().Substring(5)
        if ($iniServer['SqlMachineName'] -eq 'REPLACE' -and $role.Name -eq 'Scvmm2016')
        {
            $iniServer['SqlMachineName'] = Get-LabVM -Role SQLServer2012, SQLServer2014, SQLServer2016 | Select-Object -First 1 -ExpandProperty Fqdn
        }

        if ($iniServer['SqlMachineName'] -eq 'REPLACE' -and $role.Name -eq 'Scvmm2019')
        {
            $iniServer['SqlMachineName'] = Get-LabVM -Role SQLServer2016, SQLServer2017 | Select-Object -First 1 -ExpandProperty Fqdn
        }

        if ($iniServer['SqlMachineName'] -eq 'REPLACE' -and $role.Name -eq 'Scvmm2022')
        {
            $iniServer['SqlMachineName'] = Get-LabVM -Role SQLServer2016, SQLServer2017, SQLServer2019, SQLServer2022 | Select-Object -First 1 -ExpandProperty Fqdn
        }

        Invoke-LabCommand -ComputerName (Get-LabVM -Role ADDS | Select-Object -First 1) -ScriptBlock {
            param ($OUName)
            if ($OUName -match 'CN=')
            {
                $path = ($OUName -split ',')[1..999] -join ','
                $name = ($OUName -split ',')[0] -replace 'CN='
            }
            else
            {
                $path = (Get-ADDomain).SystemsContainer
                $name = $OUName
            }

            try
            {
                $ouExists = Get-ADObject -Identity "CN=$($name),$path" -ErrorAction Stop
            }
            catch { }
            if (-not $ouExists) { New-ADObject -Name $name -Path $path -Type Container -ProtectedFromAccidentalDeletion $true }
        } -ArgumentList $iniServer.TopContainerName

        $scvmmIso = Mount-LabIsoImage -ComputerName $vm -IsoPath ($lab.Sources.ISOs | Where-Object { $_.Name -eq $role.Name }).Path -SupressOutput -PassThru
        $domainCredential = $vm.GetCredential((Get-Lab))
        $commandLine = $setupCommandLineServer -f $vm.DomainName, $domainCredential.UserName.Replace("$($vm.DomainName)\", ''), $domainCredential.GetNetworkCredential().Password

        Invoke-LabCommand -ComputerName $vm -Variable (Get-Variable iniServer, scvmmIso, commandLine) -ActivityName 'Extracting SCVMM Server' -ScriptBlock {
            $setup = Get-ChildItem -Path $scvmmIso.DriveLetter -Filter *.exe | Select-Object -First 1
            Start-Process -FilePath $setup.FullName -ArgumentList '/VERYSILENT', '/DIR=C:\SCVMM' -Wait
            '[OPTIONS]' | Set-Content C:\Server.ini
            $iniServer.GetEnumerator() | ForEach-Object { "$($_.Key) = $($_.Value)" | Add-Content C:\Server.ini }
            "cd C:\SCVMM; C:\SCVMM\setup.exe $commandline" | Set-Content C:\DeployDebug\VmmSetup.cmd
            Set-Location -Path C:\SCVMM
        }
        Install-LabSoftwarePackage -ComputerName $vm -WorkingDirectory C:\SCVMM -LocalPath C:\SCVMM\setup.exe -CommandLine $commandLine -AsJob -PassThru -UseShellExecute -Timeout 20
     }

    if ($jobs) { Wait-LWLabJob -Job $jobs }

    # Jobs seem to end prematurely...
    Remove-LabPSSession
    Dismount-LabIsoImage -ComputerName (Get-LabVm -Role SCVMM) -SupressOutput
    Invoke-LabCommand -ComputerName (Get-LabVm -Role SCVMM) -ScriptBlock {        
        $installer = Get-Process -Name Setup,SetupVM -ErrorAction SilentlyContinue
        if ($installer)
        {
            $installer.WaitForExit((New-TimeSpan -Minutes 20).TotalMilliseconds)
        }

        robocopy (Join-Path -Path $env:ProgramData VMMLogs) "C:\DeployDebug\VMMLogs" /S /E
    }

    # Onboard Hyper-V servers
    foreach ($vm in $Computer)
    {
        $role = $vm.Roles | Where-Object Name -in Scvmm2016, Scvmm2019, Scvmm2022

        if ($role.Properties.ContainsKey('ConnectHyperVRoleVms') -or $role.Properties.ContainsKey('ConnectClusters'))
        {
            $vmNames = $role.Properties['ConnectHyperVRoleVms'] -split '\s*(?:,|;)\s*'
            $clusterNames = $role.Properties['ConnectClusters'] -split '\s*(?:,|;)\s*'
            $hyperVisors = (Get-LabVm -Role HyperV -Filter { $_.Name -in $vmNames }).FQDN
            $clusters = Get-LabVm | foreach { $_.Roles | Where Name -eq FailoverNode }
            [string[]] $clusterNameProperties = $clusters.Foreach({ $_.Properties['ClusterName'] }) | Select-Object -Unique
            if ($clusters.Where({ -not $_.Properties.ContainsKey('ClusterName') }))
            {
                $clusterNameProperties += 'ALCluster'
            }

            $clusterNameProperties = $clusterNameProperties.Where({ $_ -in $clusterNames })

            $joinCred = $vm.GetCredential((Get-Lab))
            Invoke-LabCommand -ComputerName $vm -ActivityName "Registering Hypervisors with $vm" -ScriptBlock {
                $module = Get-Item "C:\Program Files\Microsoft System Center\Virtual Machine Manager *\bin\psModules\virtualmachinemanager\virtualmachinemanager.psd1"
                Import-Module -Name $module.FullName
                
                foreach ($vmHost in $hyperVisors)
                {
                    $null = Add-SCVMHost -ComputerName $vmHost -Credential $joinCred -VmmServer $vm.FQDN -ErrorAction SilentlyContinue
                }

                foreach ($cluster in $clusterNameProperties)
                {
                    Add-SCVMHostCluster -Name $cluster -Credential $joinCred -VmmServer $vm.FQDN -ErrorAction SilentlyContinue
                }
            } -Variable (Get-Variable hyperVisors, joinCred, vm, clusterNameProperties)
        }
    }
}

function Install-ScvmmConsole
{
    [CmdletBinding()]
    param
    (
        [AutomatedLab.Machine[]]
        $Computer
    )

    foreach ($vm in $Computer)
    {
        $iniConsole = $iniContentConsole.Clone()
        $role = $vm.Roles | Where-Object Name -in Scvmm2016, Scvmm2019, Scvmm2022
        if ($role.Properties -and [Convert]::ToBoolean($role.Properties['SkipServer']))
        {
            foreach ($property in $role.Properties.GetEnumerator())
            {
                if (-not $iniConsole.ContainsKey($property.Key)) { continue }
                $iniConsole[$property.Key] = $property.Value
            }
            $iniConsole.ProgramFiles = $iniConsole.ProgramFiles -f $role.Name.ToString().Substring(5)

            $scvmmIso = Mount-LabIsoImage -ComputerName $vm -IsoPath ($lab.Sources.ISOs | Where-Object { $_.Name -eq $role.Name }).Path -SupressOutput -PassThru

            Invoke-LabCommand -ComputerName $vm -Variable (Get-Variable iniConsole, scvmmIso) -ActivityName 'Extracting SCVMM Console' -ScriptBlock {
                $setup = Get-ChildItem -Path $scvmmIso.DriveLetter -Filter *.exe | Select-Object -First 1
                Start-Process -FilePath $setup.FullName -ArgumentList '/VERYSILENT', '/DIR=C:\SCVMM' -Wait
                '[OPTIONS]' | Set-Content C:\Console.ini
                $iniConsole.GetEnumerator() | ForEach-Object { "$($_.Key) = $($_.Value)" | Add-Content C:\Console.ini }
                "cd C:\SCVMM; C:\SCVMM\setup.exe /client /i /f C:\Console.ini /IACCEPTSCEULA" | Set-Content C:\DeployDebug\VmmSetup.cmd
                Set-Location -Path C:\SCVMM
            }

            Install-LabSoftwarePackage -ComputerName $vm -WorkingDirectory C:\SCVMM -LocalPath C:\SCVMM\setup.exe -CommandLine '/client /i /f C:\Console.ini /IACCEPTSCEULA' -AsJob -PassThru -UseShellExecute -Timeout 20
            Dismount-LabIsoImage -ComputerName $vm -SupressOutput
        }
    }
}
