param(
    [Parameter(Mandatory)]
    [string]$ComputerName,

    [string]$OrganizationName,

    [ValidateSet('True', 'False')]
    [string]$AddAdRightsInRootDomain,

    [ValidateSet('True', 'False')]
    [string]$PrepareSchema,

    [ValidateSet('True', 'False')]
    [string]$PrepareAD,

    [ValidateSet('True', 'False')]
    [string]$PrepareAllDomains,

    [ValidateSet('True', 'False')]
    [string]$InstallExchange,

    [AllowNull()]
    [string]$isoPath,

    [AllowNull()]
    [string]$MailboxDBPath,

    [AllowNull()]
    [string]$MailboxLogPath
)

function Copy-ExchangeSources
{
    Write-ScreenInfo -Message 'Download Exchange 2013 requirements' -TaskStart
    $downloadTargetFolder = "$labSources\SoftwarePackages"

    if ($script:useISO) {
        Write-ScreenInfo -Message "Using Exchange ISO from '$($isoPath)'"
    }
    else
    {
        Write-ScreenInfo -Message "Downloading Exchange 2013 from '$exchangeDownloadLink'" -TaskStart
        $script:exchangeInstallFile = Get-LabInternetFile -Uri $exchangeDownloadLink -Path $downloadTargetFolder -PassThru -ErrorAction Stop
        Write-ScreenInfo 'Done' -TaskEnd
    }

    Write-ScreenInfo -Message "Downloading UCMA from '$ucmaDownloadLink'" -TaskStart
    $script:ucmaInstallFile = Get-LabInternetFile -Uri $ucmaDownloadLink -Path $downloadTargetFolder -PassThru -ErrorAction Stop
    Write-ScreenInfo -Message 'Done' -TaskEnd

    Write-ScreenInfo -Message "Downloading .net Framework 4.7.1 from '$dotnetDownloadLink'" -TaskStart
    $script:dotnetInstallFile = Get-LabInternetFile -Uri $dotnetDownloadLink -Path $downloadTargetFolder -PassThru -ErrorAction Stop
    Write-ScreenInfo 'Done' -TaskEnd

    Write-ScreenInfo -Message "Downloading Visual C++ Redistributables from '$vcRedistDownloadLink'" -TaskStart
    if (-not (Test-Path -LiteralPath $downloadTargetFolder))
    {
        New-Item -Path $downloadTargetFolder -ItemType Directory
    }
    $script:vcredistInstallFile = Get-LabInternetFile -Uri $vcRedistDownloadLink -Path $downloadTargetFolder -FileName vcredist_x64_2013.exe -PassThru -ErrorAction Stop
    Write-ScreenInfo 'Done' -TaskEnd

    #distribute the sources to all exchange servers and the RootDC
    foreach ($vm in $vms)
    {
        Write-ScreenInfo "Copying sources to VM '$vm'" -TaskStart
        if ($vm.HostType -eq 'HyperV')
        {
            if (-not $script:useISO)
            {
                Copy-LabFileItem -Path $exchangeInstallFile.FullName -DestinationFolderPath /Install -ComputerName $vm
            }

            Copy-LabFileItem -Path $ucmaInstallFile.FullName -DestinationFolderPath /Install -ComputerName $vm
            Copy-LabFileItem -Path $dotnetInstallFile.FullName -DestinationFolderPath /Install -ComputerName $vm
            Copy-LabFileItem -Path $vcredistInstallFile.FullName -DestinationFolderPath /Install -ComputerName $vm
        }
        Write-ScreenInfo 'Done' -TaskEnd
    }

    if (-not $script:useISO)
    {
        Write-ScreenInfo 'Extracting Exchange Installation files on all machines' -TaskStart -NoNewLine
        $jobs = Install-LabSoftwarePackage -LocalPath "C:\Install\$($exchangeInstallFile.FileName)" -CommandLine '/extract:"C:\Install\ExchangeInstall" /q' -ComputerName $vms -AsJob -PassThru -NoDisplay
        Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -NoNewLine
        Write-ScreenInfo 'Done' -TaskEnd
    }

    Write-ScreenInfo 'All Requirement downloads finished' -TaskEnd
}

function Add-ExchangeAdRights
{
    #if the exchange server is in a child domain the administrator of the child domain will be added to the group 'Organization Management' of the root domain
    if ($vm.DomainName -ne $schemaPrepVm.DomainName)
    {
        $dc = Get-LabVM -Role FirstChildDC | Where-Object DomainName -eq $vm.DomainName
        $userName = ($lab.Domains | Where-Object Name -eq $vm.DomainName).Administrator.UserName

        Write-ScreenInfo "Adding '$userName' to  'Organization Management' group" -TaskStart
        Invoke-LabCommand -ActivityName "Add '$userName' to Forest Management" -ComputerName $schemaPrepVm -ScriptBlock {
            param($userName, $Server)

            $user = Get-ADUser -Identity $userName -Server $Server

            Add-ADGroupMember -Identity 'Schema Admins' -Members $user
            Add-ADGroupMember -Identity 'Enterprise Admins' -Members $user
        } -ArgumentList $userName, $dc.FQDN -NoDisplay
        Write-ScreenInfo 'Done' -TaskEnd
    }
}

function Install-ExchangeWindowsFeature
{
    Write-ScreenInfo "Installing Windows Features 'Server-Media-Foundation' on '$vm'"  -TaskStart -NoNewLine
    if ((Get-LabWindowsFeature -ComputerName $vm -FeatureName Server-Media-Foundation, RSAT-ADDS-Tools | Where-Object { $_.Installed }).Count -ne 2)
    {
        $jobs += Install-LabWindowsFeature -ComputerName $vm -FeatureName Server-Media-Foundation, RSAT-ADDS-Tools -UseLocalCredential -AsJob -PassThru -NoDisplay
        Wait-LWLabJob -Job $jobs -NoDisplay
        Restart-LabVM -ComputerName $vm -Wait
    }
    Write-ScreenInfo 'Done' -TaskEnd
}

function Install-ExchangeRequirements
{
    #Create the DeployDebug directory to contain log files (the Domain Controller will already have this directory)
    Invoke-LabCommand -ActivityName 'Create Logging Directory' -ComputerName $vm -ScriptBlock {
        if (-not (Test-Path -LiteralPath 'C:\DeployDebug')) {
            New-Item -Path 'C:\DeployDebug' -ItemType Directory
        }
    } -NoDisplay

    Write-ScreenInfo "Installing Exchange Requirements '$vm'"  -TaskStart -NoNewLine

    $isUcmaInstalled = Invoke-LabCommand -ActivityName 'Test UCMA Installation' -ComputerName $vm -ScriptBlock {
        Test-Path -Path 'C:\Program Files\Microsoft UCMA 4.0\Runtime\Uninstaller\Setup.exe'
    } -PassThru -NoDisplay

    $jobs = @()

    if (-not $isUcmaInstalled)
    {
        $jobs += Install-LabSoftwarePackage -ComputerName $vm -LocalPath "C:\Install\$($script:ucmaInstallFile.FileName)" -CommandLine '/Quiet /Log c:\DeployDebug\ucma.txt' -AsJob -PassThru -NoDisplay
        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator 20 -NoNewLine
    }
    else
    {
        Write-ScreenInfo "UCMA is already installed on '$vm'" -Type Verbose
    }

    foreach ($machine in $vms)
    {
        $dotnetFrameworkVersion = Get-LabVMDotNetFrameworkVersion -ComputerName $machine -NoDisplay
        if ($dotnetFrameworkVersion.Version -notcontains '4.7.2')
        {
            Write-ScreenInfo "Installing .net Framework 4.7.2 on '$machine'" -Type Verbose
            $jobs += Install-LabSoftwarePackage -ComputerName $machine -LocalPath "C:\Install\$($script:dotnetInstallFile.FileName)" -CommandLine '/q /norestart /log c:\DeployDebug\dotnet471.txt' -AsJob -NoDisplay -AsScheduledJob -UseShellExecute -PassThru
        }
        else
        {
            Write-ScreenInfo ".net Framework 4.7.2 or later is already installed on '$machine'" -Type Verbose
        }

        $InstalledApps = Invoke-LabCommand -ActivityName 'Get Installed Applications' -ComputerName $machine -ScriptBlock {
            Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
        } -PassThru -NoDisplay

        if (-not ($InstalledApps | Where-Object {$_.DisplayName -match [regex]::Escape("Microsoft Visual C++ 2013 Redistributable (x64)")}))
        {
            Write-ScreenInfo -Message "Installing Visual C++ 2013 Redistributables on machine '$machine'" -Type Verbose
            $jobs += Install-LabSoftwarePackage -ComputerName $machine -LocalPath "C:\Install\$($script:vcredistInstallFile.FileName)" -CommandLine '/Q' -AsJob -NoDisplay -AsScheduledJob -PassThru
        }
        else
        {
            Write-ScreenInfo "Microsoft Visual C++ 2013 Redistributable (x64) is already installed on '$machine'" -Type Verbose
        }
    }

    Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator 20 -NoNewLine
    Write-ScreenInfo "Done"

    Write-ScreenInfo -Message 'Restarting machines' -NoNewLine
    Restart-LabVM -ComputerName $vms -Wait -ProgressIndicator 10 -NoDisplay

    Write-ScreenInfo 'finished' -TaskEnd
}

function Start-ExchangeInstallSequence
{
    param(
        [Parameter(Mandatory)]
        [string]$Activity,

        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [string]$CommandLine
    )

    Write-LogFunctionEntry

    Write-ScreenInfo -Message "Starting activity '$Activity'" -TaskStart -NoNewLine

    try
    {
        if ($script:useISO)
        {
            $MountedOSImage = Mount-LabIsoImage -IsoPath $IsoPath -ComputerName $ComputerName -SupressOutput -PassThru
            Remove-LabPSSession -ComputerName $prepMachine
            $ExchangeInstallCommand = $MountedOSImage.DriveLetter + '\SETUP.EXE'
        }
        else
        {
            $ExchangeInstallCommand = 'C:\Install\ExchangeInstall\SETUP.EXE'
        }

        $job = Install-LabSoftwarePackage -ComputerName $ComputerName -LocalPath $ExchangeInstallCommand -CommandLine $CommandLine `
        -ExpectedReturnCodes 1 -AsJob -NoDisplay -PassThru -ErrorVariable exchangeError
        $result = Wait-LWLabJob -Job $job -NoDisplay -ProgressIndicator 15 -PassThru -ErrorVariable jobError
        if ($jobError)
        {
            Write-Error -ErrorRecord $jobError -ErrorAction Stop
        }
        if ($result -clike '*FAILED*')
        {
            Write-Error -Message 'Exchange Installation failed' -ErrorAction Stop
        }
    }
    catch
    {
        if ($_ -match '(.+reboot.+pending.+)|(.+pending.+reboot.+)')
        {
            Write-ScreenInfo "Activity '$Activity' did not succeed, Exchange Server '$ComputerName' needs to be restarted first." -Type Warning -NoNewLine
            Restart-LabVM -ComputerName $ComputerName -Wait -NoNewLine
            Start-Sleep -Seconds 30 #as the feature installation can trigger a 2nd reboot, wait for the machine after 30 seconds again
            Wait-LabVM -ComputerName $ComputerName

            try
            {
                Write-ScreenInfo "Calling activity '$Activity' agian."
                $job = Install-LabSoftwarePackage -ComputerName $ComputerName -LocalPath $ExchangeInstallCommand -CommandLine $CommandLine `
                -ExpectedReturnCodes 1 -AsJob -NoDisplay -PassThru -ErrorAction Stop -ErrorVariable exchangeError
                $result = Wait-LWLabJob -Job $job -NoDisplay -NoNewLine -ProgressIndicator 15 -PassThru -ErrorVariable jobError
                if ($jobError)
                {
                    Write-Error -ErrorRecord $jobError -ErrorAction Stop
                }
                if ($result -clike '*FAILED*')
                {
                    Write-Error -Message 'Exchange Installation failed' -ErrorAction Stop
                }
            }
            catch
            {
                Write-ScreenInfo "Activity '$Activity' did not succeed, but did not ask for a reboot, retrying the last time" -Type Warning -NoNewLine
                if ($_ -notmatch '(.+reboot.+pending.+)|(.+pending.+reboot.+)')
                {
                    $job = Install-LabSoftwarePackage -ComputerName $ComputerName -LocalPath $ExchangeInstallCommand -CommandLine $CommandLine `
                    -ExpectedReturnCodes 1 -AsJob -NoDisplay -PassThru -ErrorAction Stop -ErrorVariable exchangeError
                    $result = Wait-LWLabJob -Job $job -NoDisplay -NoNewLine -ProgressIndicator 15 -PassThru -ErrorVariable jobError
                    if ($jobError)
                    {
                        Write-Error -ErrorRecord $jobError -ErrorAction Stop
                    }
                    if ($result -clike '*FAILED*')
                    {
                        Write-Error -Message 'Exchange Installation failed' -ErrorAction Stop
                    }
                }
            }
        }
        else
        {
            $resultVariable = New-Variable -Name ("AL_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
            $resultVariable.Value = $exchangeError
            Write-Error "Exchange task '$Activity' failed on '$ComputerName'. See content of $($resultVariable.Name) for details."
        }
    }

    if ($script:useISO) {
        Dismount-LabIsoImage -ComputerName $ComputerName -SupressOutput
    }

    Write-ProgressIndicatorEnd

    Write-ScreenInfo -Message "Finished activity '$Activity'" -TaskEnd

    $result

    Write-LogFunctionExit
}

function Start-ExchangeInstallation
{
    param (
        [switch]$All,

        [switch]$AddAdRightsInRootDomain,
        [switch]$PrepareSchema,
        [switch]$PrepareAD,
        [switch]$PrepareAllDomains,
        [switch]$InstallExchange,

        [switch]$CreateCheckPoints
    )
    if ($vm.DomainName -ne $schemaPrepVm.DomainName)
    {
        $prepMachine = $schemaPrepVm
    }
    else
    {
        $prepMachine = $vm
    }

    #prepare Exchange AD Schema
    if ($PrepareSchema -or $All)
    {
        $commandLine = '/PrepareSchema /IAcceptExchangeServerLicenseTerms'
        $result = Start-ExchangeInstallSequence -Activity 'Exchange PrepareSchema' -ComputerName $prepMachine -CommandLine $commandLine -ErrorAction Stop
        Set-Variable -Name "AL_Result_PrepareSchema_$prepMachine" -Scope Global -Value $result -Force
    }

    #prepare AD
    if ($PrepareAD -or $All)
    {
        $commandLine = '/PrepareAD /OrganizationName:"{0}" /IAcceptExchangeServerLicenseTerms' -f $OrganizationName
        $result = Start-ExchangeInstallSequence -Activity 'Exchange PrepareAD' -ComputerName $prepMachine -CommandLine $commandLine -ErrorAction Stop
        Set-Variable -Name "AL_Result_PrepareAD_$prepMachine" -Scope Global -Value $result -Force
    }

    #prepare all domains
    if ($PrepareAllDomains -or $All)
    {
        $commandLine = '/PrepareAllDomains /IAcceptExchangeServerLicenseTerms'
        $result = Start-ExchangeInstallSequence -Activity 'Exchange PrepareAllDomains' -ComputerName $prepMachine -CommandLine $commandLine -ErrorAction Stop
        Set-Variable -Name "AL_Result_AL_Result_PrepareAllDomains_$prepMachine" -Scope Global -Value $result -Force
    }

    if ($PrepareSchema -or $PrepareAD -or $PrepareAllDomains -or $All)
    {
        Write-ScreenInfo -Message 'Triggering AD replication after preparing AD forest'
        Get-LabVM -Role RootDC | ForEach-Object {
            Sync-LabActiveDirectory -ComputerName $_
        }

        Write-ScreenInfo -Message 'Restarting machines' -NoNewLine
        Restart-LabVM -ComputerName $schemaPrepVm -Wait -ProgressIndicator 10 -NoNewLine
        Restart-LabVM -ComputerName $vm -Wait -ProgressIndicator 10 -NoNewLine
        Write-ProgressIndicatorEnd
    }

    if ($InstallExchange -or $All)
    {
        Write-ScreenInfo -Message "Installing Exchange Server 2013 on machine '$vm'" -TaskStart

        #Actual Exchange Installation
        $commandLine = '/Mode:Install /Roles:ca,mb,mt /InstallWindowsComponents /OrganizationName:"{0}" /IAcceptExchangeServerLicenseTerms' -f $OrganizationName

        if ($MailboxDBPath)
        {
            $commandLine = $commandLine + ' /DbFilePath:"{0}"' -f $MailboxDBPath

            if ($MailboxLogPath) {
                $commandLine = $commandLine + ' /LogFolderPath:"{0}"' -f $MailboxLogPath
            }
        }

        $result = Start-ExchangeInstallSequence -Activity 'Exchange Components' -ComputerName $vm -CommandLine $commandLine -ErrorAction Stop
        Set-Variable -Name "AL_Result_ExchangeInstall_$vm" -Value $result -Scope Global

        Write-ScreenInfo -Message "Finished installing Exchange Server 2013 on machine '$vm'" -TaskEnd

        Write-ScreenInfo -Message "Restarting machines '$vm'" -NoNewLine
        Restart-LabVM -ComputerName $vm -Wait -ProgressIndicator 15
        Write-ScreenInfo -Message 'Done'
    }
}

Function Test-MailboxPath {

    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateSet('Mailbox','Log')]$Type
    )

    <#
            Check that the mailbox path is valid (supports both log file paths and mailbox database paths).

            Requirements:
            Database must be local to machine, no UNC paths - Both types
            File path must be fully qualified (include drive letter) - Mailbox only
            File path must point to the full file name (not just target directory) - Mailbox Only
            File path must end in .EDB (Standard Exchange database format) - Mailbox Only
            File path must point to a valid drive relative to the target machine - Both Types
    #>

    if ($Path.Substring(0,2) -eq '\\')
    {
        throw "Path '$Path' is invalid. UNC Paths are not supported for Exchange Databases or Log Directories"
    }

    if (-not [System.IO.Path]::HasExtension($Path) -and $Type -eq 'Mailbox')
    {
        throw "Path '$Path' is invalid. Mailbox Path must refer to a fully formed file name, eg 'D:\Exchange Server\Mailbox.edb'"
    }

    if ([System.IO.Path]::GetExtension($Path.ToUpper()) -ne '.EDB' -and $Type -eq 'Mailbox')
    {
        throw "Path '$Path' is invalid. Mailbox database file extension must be '.edb'"
    }

    $AvailableVolumes = Invoke-LabCommand -ActivityName 'Get Existing Volumes' -ComputerName $vm -ScriptBlock {
        Get-Volume
    } -PassThru -NoDisplay

    if (-not ($AvailableVolumes | Where-Object {$_.DriveLetter -eq $Path[0]})) {
        throw "Invalid target drive specified in '$Path'"
    }

}

$ucmaDownloadLink = 'http://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe'
$exchangeDownloadLink = 'https://download.microsoft.com/download/7/F/D/7FDCC96C-26C0-4D49-B5DB-5A8B36935903/Exchange2013-x64-cu23.exe'
$vcRedistDownloadLink = 'http://download.microsoft.com/download/0/5/6/056dcda9-d667-4e27-8001-8a0c6971d6b1/vcredist_x64.exe'
$dotnetDownloadLink = Get-LabConfigurationItem -Name dotnet472DownloadLink

#----------------------------------------------------------------------------------------------------------------------------------------------------

$lab = Import-Lab -Name $data.Name -NoValidation -NoDisplay -PassThru
$vm = Get-LabVM -ComputerName $ComputerName
$schemaPrepVm = if ($lab.IsRootDomain($vm.DomainName))
{
    $vm
}
else
{
    $rootDc = Get-LabVM -Role RootDC | Where-Object { $_.DomainName -eq $vm.DomainName }
    if ($rootDc.SkipDeployment)
    {
        Write-Error "VM '$vm' is not in the root domain and the root domain controller '$rootDc' is not available on this host."
        return
    }
    $rootDc
}

#if the schemaPrepVm is the same as the exchange server, Select-Object will filter it out
$vms = (@($vm) + $schemaPrepVm) | Select-Object -Unique

Write-ScreenInfo "Starting machines '$($vms -join ', ')'" -NoNewLine
Start-LabVM -ComputerName $vms -Wait

if (-not $OrganizationName)
{
    $OrganizationName = $lab.Name + 'ExOrg'
}

$psVersion = Invoke-LabCommand -ActivityName 'Get PowerShell Version' -ComputerName $vm -ScriptBlock {
    $PSVersionTable
} -NoDisplay -PassThru
if ($psVersion.PSVersion.Major -gt 4)
{
    Write-Error "Exchange 2013 does not support PowerShell 5+. The installation on '$vm' cannot succeed."
    return
}

#If the machine specification includes additional drives, bring them online
if ($vm.Disks.Count -gt 0)
{
    Invoke-LabCommand -ActivityName 'Bringing Additional Disks Online' -ComputerName $vm -ScriptBlock {
        $dataVolume = Get-Disk | Where-Object -Property OperationalStatus -eq Offline
        $dataVolume | Set-Disk -IsOffline $false
        $dataVolume | Set-Disk -IsReadOnly $false
    }
}

#If an ISO was specified, confirm it exists, otherwise will revert to downloading the files
$useISO = if (-not $isoPath)
{
     $false
}
else
{
    if (Test-Path -LiteralPath $isoPath)
    {
        $true
    }
    else
    {
        Write-ScreenInfo -Message ("Unable to locate ISO at '{0}', defaulting to downloading Exchange source files" -f $isoPath) -Type Warning
        $false
    }
}

if ($MailboxDBPath) {
    Test-MailboxPath -Path $MailboxDBPath -Type Mailbox
}

if ($MailboxLogPath) {
    Test-MailboxPath -Path $MailboxLogPath -Type Log
}

Write-ScreenInfo "Installing Exchange 2013 '$ComputerName'..." -TaskStart

Copy-ExchangeSources

Install-ExchangeWindowsFeature
Install-ExchangeRequirements
Restart-LabVM -ComputerName $vm -Wait

$param = @{}
if ($PrepareSchema -eq 'True') { $param.Add('PrepareSchema', $true) }
if ($PrepareAD -eq 'True') { $param.Add('PrepareAD', $true) }
if ($PrepareAllDomains -eq 'True') { $param.Add('PrepareAllDomains', $true) }
if ($InstallExchange -eq 'True') { $param.Add('InstallExchange', $true) }
if ($AddAdRightsInRootDomain -eq 'True') { $param.Add('AddAdRightsInRootDomain', $true) }
if (-not $PrepareSchema -and -not $PrepareAD -and -not $PrepareAllDomains -and -not $InstallExchange -and -not $AddAdRightsInRootDomain)
{
    $param.Add('All', $True)
}
Start-ExchangeInstallation @param

Write-ScreenInfo "Finished installing Exchange 2013 on '$ComputerName'" -TaskEnd
