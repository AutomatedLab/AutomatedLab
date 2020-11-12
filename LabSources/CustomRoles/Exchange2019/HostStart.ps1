param(
    [Parameter(Mandatory)]
    [string]$ComputerName,

    [string]$OrganizationName,

    [Parameter(Mandatory)]
    [string]$IsoPath
)

function Download-ExchangeSources
{

    Write-ScreenInfo -Message 'Download Exchange 2019 requirements' -TaskStart

    #The image is no longer available publicly
    #$downloadTargetFolder = "$labSources\ISOs"
    #Write-ScreenInfo -Message "Adding Exchange 2019 iso from '$exchangeDownloadLink'"
    #$script:exchangeInstallFile = Get-LabInternetFile -Uri $exchangeDownloadLink -Path $downloadTargetFolder -PassThru -ErrorAction Stop -FileName 'mu_exchange_server_2019-x64-cu2.iso'

    $downloadTargetFolder = "$labSources\SoftwarePackages"
    Write-ScreenInfo -Message "Downloading .net Framework 4.8 from '$dotnet48DownloadLink'"
    $script:dotnet48InstallFile = Get-LabInternetFile -Uri $dotnet48DownloadLink -Path $downloadTargetFolder -PassThru -ErrorAction Stop

    Write-ScreenInfo -Message "Downloading the Visual C++ 2012 Redistributable Package from '$VC2012RedristroDownloadLink'"
    $script:vc2012InstallFile = Get-LabInternetFile -Uri $VC2012RedristroDownloadLink -Path $downloadTargetFolder -FileName vcredist_x64_2012.exe -PassThru -ErrorAction Stop

    Write-ScreenInfo -Message "Downloading the Visual C++ 2013 Redistributable Package from '$VC2013RedristroDownloadLink'"
    $script:vc2013InstallFile = Get-LabInternetFile -Uri $VC2013RedristroDownloadLink -Path $downloadTargetFolder -FileName vcredist_x64_2013.exe -PassThru -ErrorAction Stop

    Write-ScreenInfo 'finished' -TaskEnd
}

function Add-ExchangeAdRights
{
    #if the exchange server is in a child domain the administrator of the child domain will be added to the group 'Organization Management' of the root domain
    if ($vm.DomainName -ne $rootDc.DomainName)
    {
        $dc = Get-LabVM -Role FirstChildDC | Where-Object DomainName -eq $vm.DomainName
        $userName = ($lab.Domains | Where-Object Name -eq $vm.DomainName).Administrator.UserName

        Write-ScreenInfo "Adding '$userName' to  'Organization Management' group" -TaskStart
        Invoke-LabCommand -ActivityName "Add '$userName' to Forest Management" -ComputerName $rootDc -ScriptBlock {
            param($userName, $Server)

            $user = Get-ADUser -Identity $userName -Server $Server

            Add-ADGroupMember -Identity 'Schema Admins' -Members $user
            Add-ADGroupMember -Identity 'Enterprise Admins' -Members $user
        } -ArgumentList $userName, $dc.FQDN -NoDisplay
        Write-ScreenInfo 'finished' -TaskEnd
    }
}

function Install-ExchangeWindowsFeature
{
    Write-ScreenInfo "Installing Windows Features Server-Media-Foundation on '$vm'"  -TaskStart -NoNewLine

    $jobs += Install-LabWindowsFeature -ComputerName $vm -FeatureName Server-Media-Foundation, RSAT -UseLocalCredential -AsJob -PassThru -NoDisplay
    Wait-LWLabJob -Job $jobs -NoDisplay
    Restart-LabVM -ComputerName $vm -Wait

    Write-ScreenInfo 'finished' -TaskEnd
}

function Install-ExchangeRequirements
{
    Write-ScreenInfo "Installing Exchange Requirements '$vm'"  -TaskStart

    Write-ScreenInfo "Starting machines '$($machines -join ', ')'" -NoNewLine
    Start-LabVM -ComputerName $machines -Wait

    $jobs = @()

    $ucmaInstalled = Invoke-LabCommand -ActivityName 'Test UCMA Installation' -ScriptBlock {
        Test-Path -Path 'C:\Program Files\Microsoft UCMA 4.0\Runtime\Uninstaller\Setup.exe'
    } -ComputerName $vm -PassThru

    if (-not $ucmaInstalled)
    {
        $drive = Mount-LabIsoImage -ComputerName $vm -IsoPath $exchangeInstallFile.FullName -PassThru
        $jobs += Install-LabSoftwarePackage -ComputerName $vm -LocalPath "$($drive.DriveLetter)\UCMARedist\Setup.exe" -CommandLine '/Quiet /Log c:\ucma.txt' -AsJob -PassThru
        Wait-LWLabJob -Job $jobs  -ProgressIndicator 20
        Dismount-LabIsoImage -ComputerName $vm
    }

    foreach ($machine in $machines)
    {
        $dotnetFrameworkVersion = Get-LabVMDotNetFrameworkVersion -ComputerName $machine #-NoDisplay
        if ($dotnetFrameworkVersion.Version -lt '4.8')
        {
            Write-ScreenInfo "Installing .net Framework 4.8 on '$machine'" -Type Verbose
            $jobs += Install-LabSoftwarePackage -ComputerName $machine -Path $dotnet48InstallFile.FullName -CommandLine '/q /norestart /log c:\dotnet48.txt' -AsJob -AsScheduledJob -UseShellExecute -PassThru
        }
        else
        {
            Write-ScreenInfo ".net Framework 4.8 is already installed on '$machine'" -Type Verbose
        }

        if (-not (Test-Path -Path 'Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\VisualStudio'))
        {
            Write-ScreenInfo "Installing Visual C++ redistributals 2012 and 2013 on '$machine'" -Type Verbose
            $cppJobs = @()
            $cppJobs += Install-LabSoftwarePackage -ComputerName $machine -Path $vc2012InstallFile.FullName -CommandLine '/install /quiet /norestart /log C:\DeployDebug\cpp64_2012.log' -AsJob -AsScheduledJob -UseShellExecute -PassThru
            $cppJobs += Install-LabSoftwarePackage -ComputerName $machine -Path $vc2013InstallFile.FullName -CommandLine '/install /quiet /norestart /log C:\DeployDebug\cpp64_2013.log' -AsJob -AsScheduledJob -UseShellExecute -PassThru
            Wait-LWLabJob -Job $cppJobs -NoDisplay -ProgressIndicator 20 -NoNewLine
        }
        else
        {
            Write-ScreenInfo 'Visual C++ 2012 & 2013 redistributed files installed'
        }

    }

    Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator 20 -NoNewLine
    Write-ScreenInfo done

    Write-ScreenInfo -Message 'Restarting machines' -NoNewLine
    Restart-LabVM -ComputerName $machines -Wait -ProgressIndicator 10 -NoDisplay

    Sync-LabActiveDirectory -ComputerName $rootDc
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
        $job = Install-LabSoftwarePackage -ComputerName $ComputerName -LocalPath "$($disk.DriveLetter)\setup.exe" -CommandLine $CommandLine `
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
                $job = Install-LabSoftwarePackage -ComputerName $ComputerName -LocalPath "$($disk.DriveLetter)\setup.exe" -CommandLine $CommandLine `
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
                    $job = Install-LabSoftwarePackage -ComputerName $ComputerName -LocalPath "$($disk.DriveLetter)\setup.exe" -CommandLine $CommandLine `
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
    if ($vm.DomainName -ne $rootDc.DomainName)
    {
        $prepMachine = $rootDc
    }
    else
    {
        $prepMachine = $vm
    }

    #prepare Excahnge AD Schema
    if ($PrepareSchema -or $All)
    {
        $disk = Mount-LabIsoImage -ComputerName $prepMachine -IsoPath $exchangeInstallFile.FullName -PassThru -SupressOutput

        $commandLine = '/InstallWindowsComponents /PrepareSchema /IAcceptExchangeServerLicenseTerms'
        $result = Start-ExchangeInstallSequence -Activity 'Exchange PrepareSchema' -ComputerName $prepMachine -CommandLine $commandLine -ErrorAction Stop
        Set-Variable -Name "AL_Result_PrepareSchema_$prepMachine" -Scope Global -Value $result -Force

        Dismount-LabIsoImage -ComputerName $prepMachine -SupressOutput
    }

    #prepare AD
    if ($PrepareAD -or $All)
    {
        $disk = Mount-LabIsoImage -ComputerName $prepMachine -IsoPath $exchangeInstallFile.FullName -PassThru -SupressOutput

        $commandLine = '/PrepareAD /OrganizationName:"{0}" /IAcceptExchangeServerLicenseTerms' -f $OrganizationName
        $result = Start-ExchangeInstallSequence -Activity 'Exchange PrepareAD' -ComputerName $prepMachine -CommandLine $commandLine -ErrorAction Stop
        Set-Variable -Name "AL_Result_PrepareAD_$prepMachine" -Scope Global -Value $result -Force

        Dismount-LabIsoImage -ComputerName $prepMachine -SupressOutput
    }

    #prepare all domains
    if ($PrepareAllDomains -or $All)
    {
        $disk = Mount-LabIsoImage -ComputerName $prepMachine -IsoPath $exchangeInstallFile.FullName -PassThru -SupressOutput

        $commandLine = '/PrepareAllDomains /IAcceptExchangeServerLicenseTerms'
        $result = Start-ExchangeInstallSequence -Activity 'Exchange PrepareAllDomains' -ComputerName $prepMachine -CommandLine $commandLine -ErrorAction Stop
        Set-Variable -Name "AL_Result_AL_Result_PrepareAllDomains_$prepMachine" -Scope Global -Value $result -Force

        Dismount-LabIsoImage -ComputerName $prepMachine -SupressOutput
    }

    if ($PrepareSchema -or $PrepareAD -or $PrepareAllDomains -or $All)
    {
        Write-ScreenInfo -Message 'Triggering AD replication after preparing AD forest'
        Get-LabVM -Role RootDC | ForEach-Object {
            Sync-LabActiveDirectory -ComputerName $_
        }

        Write-ScreenInfo -Message 'Restarting machines' -NoNewLine
        Restart-LabVM -ComputerName $rootDc -Wait -ProgressIndicator 10 -NoNewLine
        Restart-LabVM -ComputerName $vm -Wait -ProgressIndicator 10 -NoNewLine
        Write-ProgressIndicatorEnd
    }

    if ($InstallExchange -or $All)
    {
        Write-ScreenInfo -Message "Installing Exchange Server 2019 on machine '$vm'" -TaskStart

        $disk = Mount-LabIsoImage -ComputerName $prepMachine -IsoPath $exchangeInstallFile.FullName -PassThru -SupressOutput

        #Actual Exchange Installaton
        $commandLine = '/Mode:Install /Roles:mb,mt /InstallWindowsComponents /OrganizationName:"{0}" /IAcceptExchangeServerLicenseTerms' -f $OrganizationName
        $result = Start-ExchangeInstallSequence -Activity 'Exchange Components' -ComputerName $vm -CommandLine $commandLine -ErrorAction Stop
        Set-Variable -Name "AL_Result_ExchangeInstall_$vm" -Value $result -Scope Global

        Dismount-LabIsoImage -ComputerName $prepMachine -SupressOutput

        Write-ScreenInfo -Message "Finished installing Exchange Server 2019 on machine '$vm'" -TaskEnd

        Write-ScreenInfo -Message "Restarting machines '$vm'" -NoNewLine
        Restart-LabVM -ComputerName $vm -Wait -ProgressIndicator 15
    }
}

$dotnet48DownloadLink = Get-LabConfigurationItem -Name dotnet48DownloadLink
$VC2013RedristroDownloadLink = Get-LabConfigurationItem -Name cppredist64_2013
$VC2012RedristroDownloadLink = Get-LabConfigurationItem -Name cppredist64_2012
#----------------------------------------------------------------------------------------------------------------------------------------------------

$lab = Import-Lab -Name $data.Name -NoValidation -NoDisplay -PassThru
$vm = Get-LabVM -ComputerName $ComputerName
$rootDc = Get-LabVM -Role RootDC | Where-Object { $_.DomainName -eq $vm.DomainName }
$machines = (@($vm) + $rootDc)
if (-not $OrganizationName)
{
    $OrganizationName = $lab.Name + 'ExOrg'
}

if (-not (Test-Path -Path $IsoPath))
{
    Write-Error "The ISO file '$IsoPath' could not be found."
    return
}
$exchangeInstallFile = Get-Item -Path $IsoPath

Write-ScreenInfo "Intalling Exchange 2019 '$ComputerName'..." -TaskStart

Download-ExchangeSources
Add-ExchangeAdRights
Install-ExchangeWindowsFeature
Install-ExchangeRequirements
Start-ExchangeInstallation -All

Write-ScreenInfo "Finished installing Exchange 2019 on '$ComputerName'" -TaskEnd
