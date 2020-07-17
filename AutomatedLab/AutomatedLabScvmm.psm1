﻿$iniContentServer = @{
    UserName                    = 'Administrator'
    CompanyName                 = 'AutomatedLab'
    ProgramFiles                = 'C:\Program Files\Microsoft System Center\Virtual Machine Manager {0}'
    CreateNewSqlDatabase        = '1'
    SqlInstanceName             = 'MSSQL$VMM$'
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
    TopContainerName            = 'VMMServer'
}
$iniContentConsole = @{
    ProgramFiles             = 'C:\Program Files\Microsoft System Center\Virtual Machine Manager {0}'
    IndigoTcpPort            = '8100'
    MUOptIn                  = '0'
    VmmServerForOpsMgrConfig = 'REPLACE'
}
$setupCommandLineServer = '/server /i /f C:\Server.ini /VmmServiceDomain {0} /VmmServiceUserName {1} /VmmServiceUserPassword {2} /SqlDBAdminDomain {0} /SqlDBAdminName {1} /SqlDBAdminPassword {2} /IACCEPTSCEULA'

function Install-LabScvmm
{
    [CmdletBinding()]
    param ( )

    # Prerequisites, all
    $all = Get-LabVM -Role SCVMM
    $sqlcmd = Get-LabConfigurationItem -Name SqlCommandLineUtils
    $adk = Get-LabConfigurationItem -Name WindowsAdk
    $adkpe = Get-LabConfigurationItem -Name WindowsAdkPe
    $odbc = Get-LabConfigurationItem -Name SqlOdbc
    $sqlFile = Get-LabInternetFile -Uri $sqlcmd -Path $labsources\Tools -FileName sqlcmd.msi -PassThru
    $odbcFile = Get-LabInternetFile -Uri $odbc -Path $labsources\Tools -FileName odbc.msi -PassThru
    $adkFile = Get-LabInternetFile -Uri $adk -Path $labsources\Tools -FileName adk.exe -PassThru
    $adkpeFile = Get-LabInternetFile -Uri $adkpe -Path $labsources\Tools -FileName adkpe.exe -PassThru
    Install-LabSoftwarePackage -Path $odbcFile.FullName -ComputerName $all
    Install-LabSoftwarePackage -Path $sqlFile.FullName -ComputerName $all
    
    if ($(Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -or (Test-LabMachineInternetConnectivity -ComputerName $all[0]))
    {
        Install-LabSoftwarePackage -Path $adkFile -ComputerName $all -CommandLine '/quiet /layout c:\ADKoffline'
        Install-LabSoftwarePackage -Path $adkpeFile -ComputerName $all -CommandLine '/quiet /layout c:\ADKPEoffline'
    }
    else
    {
        & $adkFile.FullName /quiet /layout (Join-Path (Get-LabSourcesLocation -Local) Tools/ADKoffline)
        & $adkpeFile.FullName /quiet /layout (Join-Path (Get-LabSourcesLocation -Local) Tools/ADKPEoffline)
        Copy-LabFileItem -Path (Join-Path (Get-LabSourcesLocation -Local) Tools/ADKoffline) -ComputerName $all
        Copy-LabFileItem -Path (Join-Path (Get-LabSourcesLocation -Local) Tools/ADKPEoffline) -ComputerName $all
    }
    
    Install-LabSoftwarePackage -LocalPath C:\ADKOffline\adksetup.exe -ComputerName $all -CommandLine '/quiet /installpath C:\ADK'
    Install-LabSoftwarePackage -LocalPath C:\ADKPEOffline\adkwinpesetup.exe -ComputerName $all -CommandLine '/quiet /installpath C:\ADK'
    Restart-LabVM -ComputerName $all -Wait

    # Server, includes console
    $jobs = foreach ($vm in (Get-LabVM -Role SCVMM))
    {
        $iniServer = $iniContentServer.Clone()
        $role = $vm.Roles | Where-Object Name -in Scvmm2016, Scvmm2019
        
        foreach ($property in $role.Properties.GetEnumerator())
        {
            if (-not $iniServer.ContainsKey($property.Key)) { continue }
            $iniServer[$property.Key] = $property.Value
        }

        if ($role.Properties.ContainsKey('ProductKey'))
        {
            $iniServer['ProductKey'] = $role.Properties['ProductKey']
        }

        $iniServer['ProgramFiles'] = $iniServer['ProgramFiles'] -f $role.Name.Substring(5)
        if ($iniServer['SqlMachineName'] -eq 'REPLACE')
        {
            $iniServer['SqlMachineName'] = Get-LabVM -Role SQLServer | Select-Object -First 1 -ExpandProperty Fqdn
        }

        Invoke-LabCommand -ComputerName (Get-LabVM -Role ADDS | Select-Object -First 1) -ScriptBlock {
            param ($OUName)
            try 
            {
                $ouExists = Get-ADObject -Identity "CN=$($OUName),$((Get-ADDomain).SystemsContainer)" -ErrorAction Stop
            }
            catch { }
            if (-not $ouExists) { New-ADObject -Name $OUName -Path (Get-ADDomain).SystemsContainer -Type Container -ProtectedFromAccidentalDeletion $true }
        } -ArgumentList $iniServer.TopContainerName

        if ([string]::IsNullOrEmpty($role['SkipServer'] -or -not ([Convert]::ToBoolean($role['SkipServer']))))
        {
            $scvmmIso = Mount-LabIsoImage -ComputerName $vm -IsoPath ($lab.Sources.ISOs | Where-Object { $_.Name -eq $role.Name }).Path -SupressOutput -PassThru
            $domainCredential = $vm.GetCredential((Get-Lab))
            $commandLine = $setupCommandLineServer -f $vm.DomainName, $domainCredential.UserName.Replace("$($vm.DomainName)\", ''), $domainCredential.GetNetworkCredential().Password

            Invoke-LabCommand -ComputerName $vm -Variable (Get-Variable iniServer, scvmmIso) -ActivityName 'Extracting SCVMM Server' -ScriptBlock {
                $setup = Get-ChildItem -Path $scvmmIso.DriveLetter -Filter *.exe | Select-Object -First 1
                & $setup.FullName /VERYSILENT /DIR=C:\SCVMM
                '[OPTIONS]' | Set-Content C:\Server.ini
                $iniServer.GetEnumerator() | foreach { "$($_.Key) = $($_.Value)" | Add-Content C:\Server.ini }
            }
            Install-LabSoftwarePackage -ComputerName $vm -LocalPath C:\SCVMM\setup.exe -CommandLine $commandLine -AsJob -PassThru
            Dismount-LabIsoImage -ComputerName $vm -SuppressOutput
        }
    }

    if ($jobs) { Wait-LWLabJob $jobs }

    # Console, if SkipServer was chosen
    $jobs = foreach ($vm in (Get-LabVM -Role SCVMM))
    {
        $iniConsole = $iniContentConsole.Clone()
        $role = $vm.Roles | Where-Object Name -in Scvmm2016, Scvmm2019
        if (-not [string]::IsNullOrEmpty($role['SkipServer'] -and ([Convert]::ToBoolean($role['SkipServer']))))
        {
            foreach ($property in $role.Properties.GetEnumerator())
            {
                if (-not $iniConsole.ContainsKey($property.Key)) { continue }
                $iniConsole[$property.Key] = $property.Value
            }
            $iniConsole.ProgramFiles = $iniConsole.ProgramFiles -f $role.Name.Substring(5)
            if ($iniConsole['VmmServerForOpsMgrConfig'] -eq 'REPLACE')
            {
                $iniConsole['VmmServerForOpsMgrConfig'] = $vm.Fqdn
            }

            $scvmmIso = Mount-LabIsoImage -ComputerName $vm -IsoPath ($lab.Sources.ISOs | Where-Object { $_.Name -eq $role.Name }).Path -SupressOutput -PassThru

            Invoke-LabCommand -ComputerName $vm -Variable (Get-Variable iniConsole, scvmmIso) -ActivityName 'Extracting SCVMM Console' -ScriptBlock {
                $setup = Get-ChildItem -Path $scvmmIso.DriveLetter -Filter *.exe | Select-Object -First 1
                & $setup.FullName /VERYSILENT /DIR=C:\SCVMM
                '[OPTIONS]' | Set-Content C:\Server.ini
                $iniConsole.GetEnumerator() | foreach { "$($_.Key) = $($_.Value)" | Add-Content C:\Console.ini }
            }
            
            Install-LabSoftwarePackage -ComputerName $vm -LocalPath C:\SCVMM\setup.exe -CommandLine '/client /i /f C:\Console.ini' -AsJob -PassThru
            Dismount-LabIsoImage -ComputerName $vm -SuppressOutput
        }
    }
    
    if ($jobs) { Wait-LWLabJob $jobs }
}