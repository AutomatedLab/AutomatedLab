function Copy-LabExchange2013InstallationFiles
{
    Write-LogFunctionEntry
    
    Write-ScreenInfo -Message 'Download Exchange 2013 requirements' -TaskStart
    
    $downloadTargetFolder = Join-Path -Path $labSources -ChildPath SoftwarePackages
    
    Write-ScreenInfo 'Downloading the files to the local or Azure LabSources folder...' -TaskStart
        
    Write-ScreenInfo -Message "Downloading Exchange 2013 from '$exchangeDownloadLink'"
    Get-LabInternetFile -Uri $exchangeDownloadLink -Path $downloadTargetFolder -ErrorAction Stop
    Write-ScreenInfo -Message "Downloading UCMA from '$ucmaDownloadLink'"
    Get-LabInternetFile -Uri $ucmaDownloadLink -Path $downloadTargetFolder -ErrorAction Stop
    Write-ScreenInfo -Message "Downloading .net Framework 4.6.2 from '$dotnet462DownloadLink'"
    Get-LabInternetFile -Uri $dotnet462DownloadLink -Path $downloadTargetFolder -ErrorAction Stop
        
    Write-ScreenInfo 'finished' -TaskEnd
    
    
    #distribute the sources to all exchange servers and the RootDC
    Write-ScreenInfo 'Copying sources to Exchange Servers' -TaskStart
    foreach ($exchangeServer in $exchangeServers | Where-Object HostType -eq HyperV)
    {
        Write-ScreenInfo "Copying to server '$exchangeServer'..." -NoNewLine
        Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $exchangeInstallFileName) -DestinationFolder C:\Install -ComputerName $exchangeServer
        Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $ucmaInstallFileName) -DestinationFolder C:\Install -ComputerName $exchangeServer
        Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $dotnet462InstallFileName) -DestinationFolder C:\Install -ComputerName $exchangeServer
        Write-ScreenInfo 'finished'
    }
    Write-ScreenInfo 'finished copying file to Exchange Servers' -TaskEnd
    
    #now distribute the sources to all Hyper-V Root DCs that
    Write-ScreenInfo 'Copying sources to Root DCs' -TaskStart
    foreach ($rootDc in $exchangeRootDCs)
    {
        Write-ScreenInfo "Copying to server '$rootDc'..." -NoNewLine
        Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $exchangeInstallFileName) -DestinationFolder C:\Install -ComputerName $rootDc
        Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $dotnet462InstallFileName) -DestinationFolder C:\Install -ComputerName $rootDc

        Write-ScreenInfo 'finished'
    }
    Write-ScreenInfo 'Finished copying file to RootDCs' -TaskEnd

    Write-ScreenInfo 'Finished downloading Exchange 2013 requirements' -TaskEnd

    Write-ScreenInfo 'Exctracting Exchange Installation files on all machines' -TaskStart
    $machines = (@($exchangeServers) + $exchangeRootDCs)
    $jobs = Install-LabSoftwarePackage -LocalPath "C:\Install\$ExchangeInstallFileName" -CommandLine '/X:C:\Install\ExchangeInstall /Q' -ComputerName $machines -AsJob -PassThru -NoDisplay
    Wait-LWLabJob -Job $jobs -ProgressIndicator $ProgressIndicatorForJob -NoDisplay
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

    try
    {
        $job = Install-LabSoftwarePackage -ComputerName $ComputerName -LocalPath C:\Install\ExchangeInstall\setup.exe -CommandLine $CommandLine -AsJob -NoDisplay -PassThru -ErrorAction Stop -ErrorVariable exchangeError
        $result = Wait-LWLabJob -Job $job -NoDisplay -NoNewLine -ProgressIndicator 15 -PassThru -ErrorAction Stop
    }
    catch
    {
        if ($_ -match '(.+reboot.+pending.+)|(.+pending.+reboot.+)')
        {
            Write-ScreenInfo "Activity '$Activity' did not succeed, Exchange Server '$ComputerName' needs to be restarted first." -Type Warning
            Restart-LabVM -ComputerName $ComputerName -Wait
            Start-Sleep -Seconds 30 #as the feature installation can trigger a 2nd reboot, wait for the machine after 30 seconds again
            Wait-LabVM -ComputerName $ComputerName
            
            try
            {
                Write-ScreenInfo "Calling activity '$Activity' agian."
                $job = Install-LabSoftwarePackage -ComputerName $ComputerName -LocalPath C:\Install\ExchangeInstall\setup.exe -CommandLine $CommandLine -AsJob -NoDisplay -PassThru -ErrorAction Stop -ErrorVariable exchangeError
                $result = Wait-LWLabJob -Job $job -NoDisplay -NoNewLine -ProgressIndicator 15 -PassThru -ErrorAction Stop
            }
            catch
            {
                Write-ScreenInfo "Activity '$Activity' did not succeed, but did not ask for a reboot, retrying the last time" -Type Warning
                if ($_ -notmatch '(.+reboot.+pending.+)|(.+pending.+reboot.+)')
                {
                    $job = Install-LabSoftwarePackage -ComputerName $ComputerName -LocalPath C:\Install\ExchangeInstall\setup.exe -CommandLine $CommandLine -AsJob -NoDisplay -PassThru -ErrorAction Stop -ErrorVariable exchangeError
                    $result = Wait-LWLabJob -Job $job -NoDisplay -NoNewLine -ProgressIndicator 15 -PassThru
                }
            }
        }
        else
        {
            $resultVariable = New-Variable -Name ("AL_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
            $resultVariable.Value = $exchangeError
            Write-Error "Exchange task '$Activity' failed on '$ComputerName'. See content of $($resultVariable.Name) for details."
        }

        Write-ScreenInfo -Message "Finished activity '$Activity'" -TaskEnd
    
        $result
    
        Write-LogFunctionExit
    }
}

#region Install-LabExchange2013
function Install-LabExchange2013
{
    [cmdletBinding()]
    param (
        [switch]$All,
        
        [switch]$CopyExchange2013InstallationFiles,
        [switch]$AddAdRightsInRootDomain,
        [switch]$InstallWindowsFeatures,
        [switch]$InstallRequirements,
        [switch]$PrepareSchema,
        [switch]$PrepareAD,
        [switch]$PrepareAllDomains,
        [switch]$InstallExchange,        
        
        [switch]$CreateCheckPoints
    )

    Write-LogFunctionEntry
    
    $exchangeDownloadLink =  New-Object System.Uri((Get-Module AutomatedLab)[0].PrivateData.Exchange2013DownloadLink)
    $ucmaDownloadLink = New-Object System.Uri((Get-Module AutomatedLab)[0].PrivateData.ExchangeUcmaDownloadLink)
    $dotnet462DownloadLink = New-Object System.Uri((Get-Module AutomatedLab)[0].PrivateData.dotnet462DownloadLink)
    
    $exchangeInstallFileName = $exchangeDownloadLink.Segments[$exchangeDownloadLink.Segments.Count-1]
    $ucmaInstallFileName = $ucmaDownloadLink.Segments[$ucmaDownloadLink.Segments.Count-1]
    $dotnet462DownloadLink = New-Object System.Uri((Get-Module AutomatedLab)[0].PrivateData.dotnet462DownloadLink)

    $start = Get-Date
    $lab = Get-Lab
    $jobs = @()
    $progressIndicatorForJob = 15
    
    $exchangeServers = Get-LabMachine -Role Exchange2013
    if (-not $exchangeServers)
    {
        Write-Error 'No Exchange 2013 servers defined in the lab. Skipping installation'
        return
    }
    
    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewLine
    Start-LabVM -ComputerName $exchangeServers -ProgressIndicator 15

    $exchangeRootDomains = (Get-LabMachine -Role Exchange2013).DomainName | Select-Object -Unique | ForEach-Object {
        $lab.GetParentDomain($_).Name
    }
    $exchangeRootDCs = Get-LabMachine -Role RootDC | Where-Object DomainName -in $exchangeRootDomains
    
    Wait-LabVM -ComputerName $exchangeRootDCs
    Wait-LabVM -ComputerName $exchangeServers
    
    if ($CopyExchange2013InstallationFiles -or $All)
    { 
        Copy-LabExchange2013InstallationFiles
    }
    
    if ($AddAdRightsInRootDomain -or $All)
    {
        #region Add AD permissions in the root domain if Exchange is installed in a child domain 
        foreach ($machine in $exchangeServers)
        {
            $rootDomain = $lab.GetParentDomain($machine.DomainName)
            $rootDc = Get-LabMachine -Role RootDC | Where-Object DomainName -eq $rootDomain

            #if the exchange server is in a child domain the administrator of the child domain will be added to the group 'Organization Management' of the root domain
            if ($machine.DomainName -ne $rootDc.DomainName)
            {
                $dc = Get-LabMachine -Role FirstChildDC | Where-Object DomainName -eq $machine.DomainName
                $userName = ($lab.Domains | Where-Object Name -eq $machine.DomainName).Administrator.UserName

                Invoke-LabCommand -ComputerName $rootDc -ActivityName "Add '$userName' to Forest Management" -NoDisplay -ScriptBlock {
                    param($userName, $Server)

                    $user = Get-ADUser -Identity $userName -Server $Server

                    Add-ADGroupMember -Identity 'Schema Admins' -Members $user
                    Add-ADGroupMember -Identity 'Enterprise Admins' -Members $user
                } -ArgumentList $userName, $dc.FQDN
            }
        }
    }
    
    Write-ScreenInfo -Message "Preparing machines: '$($exchangeServers -join ', ')'" -TaskStart
    
    if ($InstallWindowsFeatures -or $All)
    {
        Write-Verbose 'Installing Windows Features Server-Media-Foundation, RSAT'
        $jobs += Install-LabWindowsFeature -ComputerName $exchangeServers -FeatureName Server-Media-Foundation, RSAT -UseLocalCredential -AsJob -PassThru -NoDisplay
        Wait-LWLabJob -Job $jobs -ProgressIndicator $progressIndicatorForJob -NoDisplay
        Restart-LabVM -ComputerName $exchangeServers -Wait -ProgressIndicator 45
    }
    
    if ($InstallRequirements -or $All)
    {
        $jobs += Install-LabSoftwarePackage -ComputerName $exchangeServers -LocalPath "C:\Install\$ucmaInstallFileName" -CommandLine '/Quiet /Log c:\ucma.txt' -AsJob -PassThru -NoDisplay
        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator 10

        $jobs += Install-LabSoftwarePackage -ComputerName $exchangeServers -LocalPath "C:\Install\$dotnet462InstallFileName" -CommandLine '/q /norestart /log c:\dotnet462.txt' -AsJob -NoDisplay -AsScheduledJob -UseShellExecute -PassThru
        $jobs += Install-LabSoftwarePackage -ComputerName $exchangeRootDCs -LocalPath "C:\Install\$dotnet462InstallFileName" -CommandLine '/q /norestart /log c:\dotnet462.txt' -AsJob -NoDisplay -AsScheduledJob -UseShellExecute -PassThru
        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator 10
        
        Write-ScreenInfo -Message 'Restarting machines' -NoNewLine
        Restart-LabVM -ComputerName $exchangeRootDCs -Wait -ProgressIndicator 10
        
        Sync-LabActiveDirectory -ComputerName $exchangeRootDCs
    }
    
    Write-ScreenInfo -Message "Finished preparing machines: '$($exchangeServers -join ', ')'" -TaskEnd
    
    $exchangeServersByDomain = Get-LabVM -Role Exchange2013 | Group-Object -Property DomainName
    foreach ($machine in ($exchangeServersByDomain.Group | Select-Object -First 1))
    {
        $rootDomain = $lab.GetParentDomain($machine.DomainName)
        $rootDc = $lab.Machines | Where-Object { $_.Roles.Name -contains 'RootDC' -and $_.DomainName -eq $rootDomain } | Select-Object -First 1
        $exchangeOrganization = ($machine.Roles | Where-Object Name -eq Exchange2013).Properties.OrganizationName

        if ($machine.DomainName -ne $rootDc.DomainName)
        {
            $prepMachine = $rootDc
        }
        else
        {
            $prepMachine = $machine
        }
        
        Write-ScreenInfo -Message "Performing AD prerequisites on machine '$prepMachine'" -TaskStart

        # PREPARE SCHEMA
        if ($PrepareSchema -or $All)
        {
            $global:AL_Result_PrepareSchema = Start-ExchangeInstallSequence -Activity 'Exchange PrepareSchema' -ComputerName $prepMachine -CommandLine '/PrepareSchema /IAcceptExchangeServerLicenseTerms' -ErrorAction Stop
        }
        
        # PREPARE AD
        if ($PrepareAD -or $All)
        {
            $commandLine = '/PrepareAD /OrganizationName:"{0}" /IAcceptExchangeServerLicenseTerms' -f $exchangeOrganization
            $global:AL_Result_PrepareAD = Start-ExchangeInstallSequence -Activity 'Exchange PrepareAD' -ComputerName $prepMachine -CommandLine $commandLine -ErrorAction Stop
        }
        
        #PREPARE ALL DOMAINS
        if ($PrepareAllDomains -or $All)
        {
            $global:AL_Result_PrepareAllDomains = Start-ExchangeInstallSequence -Activity 'Exchange PrepareAllDomains' -ComputerName $prepMachine -CommandLine '/PrepareAllDomains /IAcceptExchangeServerLicenseTerms' -ErrorAction Stop
        }
    }
    
    if ($PrepareSchema -or $PrepareAD -or $PrepareAllDomains -or $All)
    {
        Write-ScreenInfo -Message 'Triggering AD replication'
        Get-LabMachine -Role RootDC | ForEach-Object {
            Sync-LabActiveDirectory -ComputerName $_
        }
    
        Write-ScreenInfo -Message 'Restarting machines' -NoNewLine
        Restart-LabVM -ComputerName $exchangeRootDCs -Wait -ProgressIndicator 10
        Restart-LabVM -ComputerName $exchangeServers -Wait -ProgressIndicator 10
    }
    
    if ($InstallExchange -or $All)
    {
        foreach ($machine in $exchangeServers)
        {
            Write-ScreenInfo -Message "Installing Exchange Server 2013 on machine '$machine'" -TaskStart
        
            $exchangeOrganization = ($machine.Roles | Where-Object Name -eq Exchange2013).Properties.OrganizationName

            #FINALLY INSTALL EXCHANGE
            Write-ScreenInfo -Message 'Install Exchange Server 2013'
       
            $commandLine = '/Mode:Install /Roles:ca,mb,mt /InstallWindowsComponents /OrganizationName:{0} /IAcceptExchangeServerLicenseTerms' -f $exchangeOrganization
            $result = Start-ExchangeInstallSequence -Activity 'Exchange Components' -ComputerName $machine -CommandLine $commandLine -ErrorAction Stop
            
            Set-Variable -Name "AL_Result_ExchangeInstall_$machine" -Value $result -Scope Global 
        
            Write-ScreenInfo -Message "Finished installing Exchange Server 2013 on machine '$machine'" -TaskEnd
        }
    }
    
    if ($InstallExchange -or $All)
    {    
        Write-ScreenInfo -Message 'Restarting machines' -NoNewLine
        Restart-LabVM -ComputerName $exchangeServers -Wait -ProgressIndicator 5
    }
    
    Write-LogFunctionExit
}
#endregion Install-LabExchange2013