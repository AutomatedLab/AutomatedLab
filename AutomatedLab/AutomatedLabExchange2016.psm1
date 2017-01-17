function Copy-LabExchange2016InstallationFiles
{
    Write-LogFunctionEntry
    
    Write-ScreenInfo -Message 'Download Exchange 2016 requirements' -TaskStart
    
    #if there is one Exchange server on Hyper-V, make sure the required sources are in the LabSources folder
    $downloadTargetFolder = Join-Path -Path $labSources -ChildPath SoftwarePackages
    if ($exchangeServers | Where-Object HostType -eq HyperV)
    {
        Write-ScreenInfo 'Exchange Servers in the lab running on Hyper-V, downloading the files to the local LabSources folder...' -TaskStart
        
        Write-ScreenInfo -Message "Downloading Exchange 2016 from '$exchangeDownloadLink'"
        Get-LabInternetFile -Uri $exchangeDownloadLink -Path $downloadTargetFolder -ErrorAction Stop
        Write-ScreenInfo -Message "Downloading UCMA from '$ucmaDownloadLink'"
        Get-LabInternetFile -Uri $ucmaDownloadLink -Path $downloadTargetFolder -ErrorAction Stop
        Write-ScreenInfo -Message "Downloading .net Framework 4.5.2 from '$dotnet452DownloadLink'"
        Get-LabInternetFile -Uri $dotnet452DownloadLink -Path $downloadTargetFolder -ErrorAction Stop
        
        Write-ScreenInfo 'finished' -TaskEnd
    }
    
    #if there is one Exchange server on Azure, make sure the required sources are in LabSources on Azure
    $1stAzureExchangeServer = $exchangeServers | Where-Object HostType -eq Azure
    if ($exchangeServers | Where-Object HostType -eq 'Azure')
    {
        throw (New-Object System.NotImplementedException)
        #TODO: The destination path on Azure needs to be defined.
        Invoke-LabCommand -ActivityName "Downloading Exchange Server 2016" -ComputerName $1stAzureExchangeServer -ScriptBlock {
            Get-LabInternetFile -Uri $exchangeDownloadLink -Path $downloadTargetFolder -ErrorAction Stop
            Get-LabInternetFile -Uri $ucmaDownloadLink -Path $downloadTargetFolder -ErrorAction Stop
            Get-LabInternetFile -Uri $dotnet452DownloadLink -Path $downloadTargetFolder -ErrorAction Stop
        } -Function (Get-Command -Name Get-LabInternetFile) -Variable (Get-Variable -Name Uri)
    }
    
    #distribute the sources to all exchange servers and the RootDC
    Write-ScreenInfo 'Copying sources to Exchange Servers' -TaskStart
    foreach ($exchangeServer in $exchangeServers | Where-Object HostType -eq HyperV)
    {
        Write-ScreenInfo "Copying to server '$exchangeServer'..." -NoNewLine
        Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $exchangeInstallFileName) -DestinationFolder C:\Install -ComputerName $exchangeServer
        Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $ucmaInstallFileName) -DestinationFolder C:\Install -ComputerName $exchangeServer
        Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $dotnet452InstallFileName) -DestinationFolder C:\Install -ComputerName $exchangeServer
        Write-ScreenInfo 'finished'
    }
    Write-ScreenInfo 'finished copying file to Exchange Servers' -TaskEnd
    
    #now distribute the sources to all Hyper-V Root DCs that
    Write-ScreenInfo 'Copying sources to Root DCs' -TaskStart
    foreach ($rootDc in $exchangeRootDCs)
    {
        Write-ScreenInfo "Copying to server '$rootDc'..." -NoNewLine
        Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $exchangeInstallFileName) -DestinationFolder C:\Install -ComputerName $rootDc
        #Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $ucmaDownloadLink) -DestinationFolder C:\Install -ComputerName $rootDc
        Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $dotnet452InstallFileName) -DestinationFolder C:\Install -ComputerName $rootDc
        Write-ScreenInfo 'finished'
    }
    Write-ScreenInfo 'finished copying file to RootDCs' -TaskEnd
    
    foreach ($exchangeServer in $exchangeServers | Where-Object HostType -eq Azure)
    {
        #TODO: The path of the Azure LabSources folder needs to be determined
        throw (New-Object System.NotImplementedException)
        #Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $exchangeInstallFileName) -DestinationFolder C:\Install -ComputerName $exchangeServer
        #Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $ucmaDownloadLink) -DestinationFolder C:\Install -ComputerName $exchangeServer
        #Copy-LabFileItem -Path (Join-Path -Path $downloadTargetFolder -ChildPath $dotnet452DownloadLink) -DestinationFolder C:\Install -ComputerName $exchangeServer
    }
    
    Write-ScreenInfo 'Finished downloading Exchange 2016 requirements' -TaskEnd

    $machines = (@($exchangeServers) + $exchangeRootDCs)
    $jobs = Install-LabSoftwarePackage -LocalPath "C:\Install\$ExchangeInstallFileName" -CommandLine '/X:C:\Install\ExchangeInstall /Q' -ComputerName $machines -AsJob -PassThru -NoDisplay
    Wait-LWLabJob -Job $jobs -ProgressIndicator $ProgressIndicatorForJob -NoDisplay
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
    
    Write-ScreenInfo -Message $Activity -TaskStart -NoNewLine
    try
    {
        $job = Install-LabSoftwarePackage -ComputerName $ComputerName -LocalPath C:\Install\ExchangeInstall\setup.exe -CommandLine $CommandLine -UseCredSsp -AsJob -PassThru -ErrorAction Stop -ErrorVariable exchangeError
        $result = Wait-LWLabJob -Job $job -NoDisplay -NoNewLine -ProgressIndicator 15 -ReturnResults -ErrorAction Stop
    }
    catch
    {
        if ($_ -match '(.+reboot.+pending.+)|(.+pending.+reboot.+)')
        {
            Restart-LabVM -ComputerName $ComputerName
            try
            {
                $job = Install-LabSoftwarePackage -ComputerName $ComputerName -LocalPath C:\Install\ExchangeInstall\setup.exe -CommandLine $CommandLine -UseCredSsp -AsJob -PassThru -ErrorAction Stop -ErrorVariable exchangeError
                $result = Wait-LWLabJob -Job $job -NoDisplay -NoNewLine -ProgressIndicator 15 -ReturnResults -ErrorAction Stop
            }
            catch
            {
                if ($_ -notmatch '(.+reboot.+pending.+)|(.+pending.+reboot.+)')
                {
                    $job = Install-LabSoftwarePackage -ComputerName $ComputerName -LocalPath C:\Install\ExchangeInstall\setup.exe -CommandLine $CommandLine -UseCredSsp -AsJob -PassThru -ErrorAction Stop -ErrorVariable exchangeError
                    $result = Wait-LWLabJob -Job $job -NoDisplay -NoNewLine -ProgressIndicator 15 -ReturnResults -ErrorAction Stop
                }
            }
        }
        else
        {
            $resultVariable = New-Variable -Name ("AL_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
            $resultVariable.Value = $exchangeError
            Write-Error "Exchange Schema Update failed on server '$ComputerName'. See content of $($resultVariable.Name) for details."
        }
    }

    Write-ScreenInfo -Message "Finished activity '$Activity'" -TaskEnd
    
    $result
}

#region Install-LabExchange2016
function Install-LabExchange2016
{
    [cmdletBinding()]
    param ([switch]$CreateCheckPoints)

    Write-LogFunctionEntry

    $start = Get-Date
    
    $labSources = Get-LabSourcesLocation
    $lab = Get-Lab
    
    $exchangeServers = Get-LabMachine -Role Exchange2016
    if (-not $exchangeServers)
    {
        Write-Verbose 'No Exchange 2016 servers defined in the lab. Skipping installation'
        return
    }

    $exchangeRootDomains = $lab.GetParentDomain((Get-LabMachine -Role Exchange2016).DomainName).Name
    $exchangeRootDCs = Get-LabMachine -Role RootDC | Where-Object DomainName -in $exchangeRootDomains
    
    
    $exchangeDownloadLink =  New-Object System.Uri($MyInvocation.MyCommand.Module.PrivateData.Exchange2016DownloadLink)
    $ucmaDownloadLink = New-Object System.Uri($MyInvocation.MyCommand.Module.PrivateData.ExchangeUcmaDownloadLink)
    $dotnet452DownloadLink = New-Object System.Uri($MyInvocation.MyCommand.Module.PrivateData.dotnet452DownloadLink)
    
    $exchangeInstallFileName = $exchangeDownloadLink.Segments[$ucmaInstallUri.Segments.Count-1]
    $ucmaInstallFileName = $ucmaDownloadLink.Segments[$ucmaInstallUri.Segments.Count-1]
    $dotnet452InstallFileName = $dotnet452DownloadLink.Segments[$ucmaInstallUri.Segments.Count-1]
    
    Copy-LabExchange2016InstallationFiles    
    
    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewLine
    Start-LabVM -ComputerName $exchangeServers -Wait -ProgressIndicator 15

    $jobs = @()

    Write-ScreenInfo -Message "Preparing machines: '$($exchangeServers -join ', ')'" -TaskStart
    
    #region Add AD permissions in the root domain if Exchange is installed in a child domain
    $progressIndicatorForJob = 15
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
            } -ArgumentList $userName, $dc.FQDN -UseCredSsp
        }
    }
    #endregion
    
    Write-Verbose 'Installing Windows Features Server-Media-Foundation, RSAT'
    $jobs += Install-LabWindowsFeature -ComputerName $exchangeServers -FeatureName Server-Media-Foundation, RSAT -UseLocalCredential -AsJob -PassThru -NoDisplay
    Wait-LWLabJob -Job $jobs -ProgressIndicator $progressIndicatorForJob -NoDisplay
    Restart-LabVM -ComputerName $exchangeServers -Wait -ProgressIndicator 45
    
    $jobs += Install-LabSoftwarePackage -ComputerName $exchangeServers -LocalPath "C:\Install\$ucmaInstallFileName" -CommandLine '/Quiet /Log c:\ucma.txt' -AsJob -PassThru -NoDisplay
    Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator 10
    
    $jobs += Install-LabSoftwarePackage -ComputerName $exchangeServers -LocalPath "C:\Install\$dotnet452InstallFileName" -CommandLine '/q /norestart /log c:\dotnet452.txt' -AsJob -AsScheduledJob -UseShellExecute -PassThru -NoDisplay
    $jobs += Install-LabSoftwarePackage -ComputerName $exchangeRootDCs -LocalPath "C:\Install\$dotnet452InstallFileName" -CommandLine '/q /norestart /log c:\dotnet452.txt' -AsJob -AsScheduledJob -UseShellExecute -PassThru -NoDisplay
    Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator 10
    
    Write-ScreenInfo -Message "Finished preparing machines: '$($exchangeServers -join ', ')'" -TaskEnd
    
    Write-ScreenInfo -Message 'Restarting machines' -NoNewLine
    Restart-LabVM -ComputerName $exchangeServers -Wait -ProgressIndicator 45
    
    Sync-LabActiveDirectory -ComputerName $rootDc
    
    foreach ($machine in $exchangeServers)
    {
        Write-ScreenInfo -Message "Performing pre-requisites for machine '$machine'" -TaskStart
        
        $rootDomain = $lab.GetParentDomain($machine.DomainName)
        $rootDc = $lab.Machines | Where-Object { $_.Roles.Name -contains 'RootDC' -and $_.DomainName -eq $rootDomain } | Select-Object -First 1
        $exchangeOrganization = ($machine.Roles | Where-Object Name -eq Exchange2016).Properties.OrganizationName

        if ($machine.DomainName -ne $rootDc.DomainName)
        {
            $prepMachine = $rootDc
        }
        else
        {
            $prepMachine = $machine
        }

        # PREPARE SCHEMA
        $result = Start-ExchangeInstallSequence -Activity 'Exchange PrepareSchema' -ComputerName $prepMachine -CommandLine '/PrepareSchema /IAcceptExchangeServerLicenseTerms' -ErrorAction Stop
        
        # PREPARE AD
        $commandLine = '/PrepareAD /OrganizationName:"{0}" /IAcceptExchangeServerLicenseTerms' -f $exchangeOrganization
        $result = Start-ExchangeInstallSequence -Activity 'Exchange PrepareAD' -ComputerName $prepMachine -CommandLine $commandLine -ErrorAction Stop
        
        #PREPARE ALL DOMAINS
        $result = Start-ExchangeInstallSequence -Activity 'Exchange PrepareAllDomains' -ComputerName $prepMachine -CommandLine '/PrepareAllDomains /IAcceptExchangeServerLicenseTerms' -ErrorAction Stop
    }
    
    Write-ScreenInfo -Message 'Triggering replication' -NoNewLine
    Get-LabMachine -Role RootDC | ForEach-Object {
        Sync-LabActiveDirectory -ComputerName $_
    }
    
    Write-ScreenInfo -Message 'Restarting machines' -NoNewLine
    Restart-LabVM -ComputerName $exchangeServers -Wait -ProgressIndicator 5
    
    foreach ($machine in $exchangeServers)
    {
        Write-ScreenInfo -Message "Installing Exchange Server 2016 on machine '$machine'" -TaskStart
        
        $exchangeOrganization = ($machine.Roles | Where-Object Name -eq Exchange2016).Properties.OrganizationName

        #FINALLY INSTALL EXCHANGE
        Write-ScreenInfo -Message 'Install Exchange Server 2016' -NoNewLine
       
        $commandLine = '/Mode:Install /Roles:mb /InstallWindowsComponents /OrganizationName:{0} /IAcceptExchangeServerLicenseTerms' -f $exchangeOrganization
        $result = Start-ExchangeInstallSequence -Activity 'Exchange PrepareAllDomains' -ComputerName $prepMachine -CommandLine $commandLine -ErrorAction Stop
        
        Write-ScreenInfo -Message "Finished installing Exchange Server 2016 on machine '$machine'" -TaskEnd
    }
	
    Write-LogFunctionExit
}
#endregion Install-LabExchange2016