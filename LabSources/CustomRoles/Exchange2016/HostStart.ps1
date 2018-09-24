param(
    [Parameter(Mandatory)]
    [string]$ComputerName,

    [string]$OrganizationName
)

function Download-ExchangeSources
{
    
    Write-ScreenInfo -Message 'Download Exchange 2016 requirements' -TaskStart
    $downloadTargetFolder = "$labSources\ISOs"
    Write-ScreenInfo -Message "Downloading Exchange 2016 from '$exchangeDownloadLink'"
    $script:exchangeInstallFile = Get-LabInternetFile -Uri $exchangeDownloadLink -Path $downloadTargetFolder -PassThru -ErrorAction Stop

    $downloadTargetFolder = "$labSources\SoftwarePackages"
    Write-ScreenInfo -Message "Downloading UCMA from '$ucmaDownloadLink'"
    $script:ucmaInstallFile = Get-LabInternetFile -Uri $ucmaDownloadLink -Path $downloadTargetFolder -PassThru -ErrorAction Stop

    Write-ScreenInfo -Message "Downloading .net Framework 4.7.1 from '$dotnetDownloadLink'"
    $script:dotnetInstallFile = Get-LabInternetFile -Uri $dotnetDownloadLink -Path $downloadTargetFolder -PassThru -ErrorAction Stop

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
    Write-ScreenInfo "Installing Windows Features Server-Media-Foundation, RSAT on '$vm'"  -TaskStart -NoNewLine
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
    $jobs += Install-LabSoftwarePackage -ComputerName $vm -Path $ucmaInstallFile.FullName -CommandLine '/Quiet /Log c:\ucma.txt' -AsJob -PassThru -NoDisplay
    Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator 20 -NoNewLine

    foreach ($machine in $machines)
    {
        $dotnetFrameworkVersion = Get-LabVMDotNetFrameworkVersion -ComputerName $machine -NoDisplay
        if ($dotnetFrameworkVersion.Version -lt '4.7.1')
        {
            Write-ScreenInfo "Installing .net Framework 4.7.1 on '$machine'" -Type Verbose
            $jobs += Install-LabSoftwarePackage -ComputerName $machine -Path $dotnetInstallFile.FullName -CommandLine '/q /norestart /log c:\dotnet462.txt' -AsJob -NoDisplay -AsScheduledJob -UseShellExecute -PassThru
        }
        else
        {
            Write-ScreenInfo ".net Framework 4.7.1 is already installed on '$machine'" -Type Verbose
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

        $commandLine = '/PrepareSchema /IAcceptExchangeServerLicenseTerms'
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
        Write-ScreenInfo -Message "Installing Exchange Server 2016 on machine '$vm'" -TaskStart
        
        $disk = Mount-LabIsoImage -ComputerName $prepMachine -IsoPath $exchangeInstallFile.FullName -PassThru -SupressOutput

        #Actual Exchange Installaton
        $commandLine = '/Mode:Install /Roles:mb,mt /InstallWindowsComponents /OrganizationName:"{0}" /IAcceptExchangeServerLicenseTerms' -f $OrganizationName
        $result = Start-ExchangeInstallSequence -Activity 'Exchange Components' -ComputerName $vm -CommandLine $commandLine -ErrorAction Stop
        Set-Variable -Name "AL_Result_ExchangeInstall_$vm" -Value $result -Scope Global

        Dismount-LabIsoImage -ComputerName $prepMachine -SupressOutput
        
        Write-ScreenInfo -Message "Finished installing Exchange Server 2016 on machine '$vm'" -TaskEnd
    
        Write-ScreenInfo -Message "Restarting machines '$vm'" -NoNewLine
        Restart-LabVM -ComputerName $vm -Wait -ProgressIndicator 15
    }
}

$ucmaDownloadLink = 'http://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe'
$exchangeDownloadLink = 'http://download.microsoft.com/download/B/C/9/BC9C77DA-97D9-43D8-A3F8-50D8AF89E3FA/ExchangeServer2016-x64-cu10.iso'
$dotnetDownloadLink = (Get-Module -Name AutomatedLab -ListAvailable)[0].PrivateData.dotnet471DownloadLink

#----------------------------------------------------------------------------------------------------------------------------------------------------

$lab = Import-Lab -Name $data.Name -NoValidation -NoDisplay -PassThru
$vm = Get-LabVM -ComputerName $ComputerName
$rootDc = Get-LabVM -Role RootDC | Where-Object { $_.DomainName -eq $vm.DomainName }
$machines = (@($vm) + $rootDc)
if (-not $OrganizationName)
{
    $OrganizationName = $lab.Name + 'ExOrg'
}

Write-ScreenInfo "Intalling Exchange 2016 '$ComputerName'..." -TaskStart

Download-ExchangeSources
Add-ExchangeAdRights
Install-ExchangeWindowsFeature
Install-ExchangeRequirements
Start-ExchangeInstallation -All

Write-ScreenInfo "Finished installing Exchange 2016 on '$ComputerName'" -TaskEnd