#region script blocks
$ucmaCmd = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UcmaInstallLink
    )

    $ucmaInstallUri = New-Object System.Uri($UcmaInstallLink)
    $ucmaInstallFileName = $ucmaInstallUri.Segments[$ucmaInstallUri.Segments.Count-1]
    $retries = 5

    New-Item C:\Install -Type Directory -ErrorAction SilentlyContinue | Out-Null

    $start = Get-Date
    Write-Verbose 'Downloading the Unified Communications Managed API 4.0 Runtime installation files...'

    while (-not (Test-Path -Path "C:\Install\$ucmaInstallFileName") -and $retries -gt 0)
    {
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' /v IsInstalled /t REG_DWORD /d 0 /f #disable admin IE Enhanced Security Configuration
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' /v IsInstalled /t REG_DWORD /d 0 /f #disable user IE Enhanced Security Configuration
        
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($UcmaInstallLink, "C:\Install\$ucmaInstallFileName")

        $retries--
        
        if (-not (Test-Path -Path "C:\Install\$ucmaInstallFileName"))
        {
            Start-Sleep -Seconds 30
        }
    }
    $end = Get-Date
    Write-Verbose "...downloading the Unified Communications Managed API 4.0 Runtime installation files took $($end - $start)"

    Write-Verbose 'Installing Unified Communications Managed API 4.0 Runtime...'
    $start = Get-Date
    & "C:\Install\$ucmaInstallFileName" /Quiet | Out-Null
    $end = Get-Date
    Write-Verbose "...installing Unified Communications Managed API 4.0 Runtime took $($end - $start)"
}

$exchangeDownloadCmd = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExchangeInstallLink
    )

    $exchangeInstallUri = New-Object System.Uri($ExchangeInstallLink)
    $exchangeInstallFileName = $ExchangeInstallUri.Segments[$ExchangeInstallUri.Segments.Count-1]
    $retries = 5

    New-Item C:\Install -Type Directory -ErrorAction SilentlyContinue | Out-Null

    $start = Get-Date
    Write-Verbose 'Downloading the Exchange Installation files...'
    while (-not (Test-Path -Path "C:\Install\$exchangeInstallFileName") -and $retries -gt 0)
    {
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' /v IsInstalled /t REG_DWORD /d 0 /f #disable admin IE Enhanced Security Configuration
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' /v IsInstalled /t REG_DWORD /d 0 /f #disable user IE Enhanced Security Configuration
        
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($exchangeInstallLink, "C:\Install\$exchangeInstallFileName")

        $retries--
        
        if (-not (Test-Path -Path "C:\Install\$exchangeInstallFileName"))
        {
            Start-Sleep -Seconds 30
        }
    }
    $end = Get-Date
    Write-Verbose "...downloading the Exchange Installation files took $($end - $start)"

    Write-Verbose 'Extracting the Exchange Installation files...'
    $start = Get-Date
    & "C:\Install\$ExchangeInstallFileName" /X:C:\Install\ExchangeInstall /Q | Out-Null
    $end = Get-Date
    Write-Verbose "...extracting the Exchange Installation files took $($end - $start)"
}

$exchangeExtractCmd = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExchangeInstallLink
    )

    $exchangeInstallUri = New-Object System.Uri($ExchangeInstallLink)
    $exchangeInstallFileName = $ExchangeInstallUri.Segments[$ExchangeInstallUri.Segments.Count-1]

    Write-Verbose 'Extracting the Exchange Installation files...'
    $start = Get-Date
    & "C:\Install\$ExchangeInstallFileName" /X:C:\Install\ExchangeInstall /Q | Out-Null
    $end = Get-Date
    Write-Verbose "...extracting the Exchange Installation files took $($end - $start)"
}

$exchangeSchemaUpdateCmd = {
    $VerbosePreference = 'Continue'
    Write-Verbose 'Starting the Exchange Schema Update...'

    $start = Get-Date
    $Error.Clear()
    $result = New-Object PSObject -Property @{ InstallStatus = $null; InstallMessage = $null; InstallErrors = $null }

    $result.InstallMessage = & 'c:\Install\ExchangeInstall\setup.exe' /PrepareSchema /IAcceptExchangeServerLicenseTerms
    if ($Error.Exception.Message -match '(.+reboot.+pending.+)|(.+pending.+reboot.+)')
    {
        $result.InstallStatus = 'RebootRequired'
    }
    elseif ($Error.Count -eq 0)
    {
        $result.InstallStatus = 'Success'
    }
    else
    {
        $result.InstallStatus = 'Failed'
    }

    $end = Get-Date

    Write-Verbose "...Exchange Schema Update took $($end - $start)"

    $result.InstallErrors = $Error
    return $result
}

$exchangePrepAllDomainsCmd = {
    $VerbosePreference = 'Continue'
    Write-Verbose 'Starting the Exchange Domain Prep for all domains...'

    $start = Get-Date
    $Error.Clear()
    $result = New-Object PSObject -Property @{ InstallStatus = $null; InstallMessage = $null; InstallErrors = $null }

    $result.InstallMessage = & 'c:\Install\ExchangeInstall\setup.exe' /PrepareAllDomains /IAcceptExchangeServerLicenseTerms
    if ($Error.Exception.Message -match '(.+reboot.+pending.+)|(.+pending.+reboot.+)')
    {
        $result.InstallStatus = 'RebootRequired'
    }
    elseif ($Error.Count -eq 0)
    {
        $result.InstallStatus = 'Success'
    }
    else
    {
        $result.InstallStatus = 'Failed'
    }

    $end = Get-Date

    Write-Verbose "...Exchange Domain Prep for all domains took $($end - $start)"

    $result.InstallErrors = $Error
    return $result
}

$exchangePrepareADCmd = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName
    )

    $VerbosePreference = 'Continue'
    Write-Verbose 'Starting the Exchange AD Prep...'

    $start = Get-Date
    $Error.Clear()
    $result = New-Object PSObject -Property @{ InstallStatus = $null; InstallMessage = $null; InstallErrors = $null }

    $result.InstallMessage = & 'c:\Install\ExchangeInstall\setup.exe' /PrepareAD /OrganizationName:"$OrganizationName" /IAcceptExchangeServerLicenseTerms
    if ($Error.Exception.Message -match '(.+reboot.+pending.+)|(.+pending.+reboot.+)')
    {
        $result.InstallStatus = 'RebootRequired'
    }
    elseif ($Error.Count -eq 0)
    {
        $result.InstallStatus = 'Success'
    }
    else
    {
        $result.InstallStatus = 'Failed'
    }

    $end = Get-Date

    Write-Verbose "...Exchange AD Prep took $($end - $start)"

    $result.InstallErrors = $Error
    return $result
}

$exchangeSetupCmd = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName
    )
    
    $VerbosePreference = 'Continue'
    Write-Verbose 'Starting the Exchange Installation...'

    $start = Get-Date
    $Error.Clear()
    $result = New-Object PSObject -Property @{ InstallStatus = $null; InstallMessage = $null; InstallErrors = $null }

    $result.InstallMessage = & 'c:\Install\ExchangeInstall\setup.exe' /Mode:Install /Roles:ca,mb /InstallWindowsComponents /OrganizationName:"$OrganizationName" /IAcceptExchangeServerLicenseTerms
    if ($Error.Exception.Message -match '(.+reboot.+pending.+)|(.+pending.+reboot.+)')
    {
        $result.InstallStatus = 'RebootRequired'
    }
    elseif ($Error.Count -eq 0)
    {
        $result.InstallStatus = 'Success'
    }
    else
    {
        $result.InstallStatus = 'Failed'
    }

    $end = Get-Date

    Write-Verbose "...Exchange Installation took $($end - $start)"

    $result.InstallErrors = $Error
    return $result
}

function Copy-LabExchangeInstallationFiles
{
	# .ExternalHelp AutomatedLab.Help.xml
    param(
        [Parameter(Mandatory = $true)]
        [AutomatedLab.Machine]$Machine
    )

    $exchangeInstallLink = $MyInvocation.MyCommand.Module.PrivateData.Exchange2013DownloadLink
    $ucmaInstallLink = $MyInvocation.MyCommand.Module.PrivateData.ExchangeUcmaDownloadLink

    #copy the files to the destination machine
    if ($Machine.HostType -eq 'HyperV')
    {
        $exchangeInstallUri = New-Object System.Uri($exchangeInstallLink)
        $exchangeInstallFileName = $ExchangeInstallUri.Segments[$ExchangeInstallUri.Segments.Count-1]
        $ucmaInstallUri = New-Object System.Uri($ucmaInstallLink)
        $ucmaInstallFileName = $ucmaInstallUri.Segments[$ucmaInstallUri.Segments.Count-1]

        $labSources = Get-LabSourcesLocation

        $ucmaFile = Get-ChildItem -Path $labSources -Filter $ucmaInstallFileName -Recurse
        if (-not $ucmaFile)
        {
            try
            {
                Write-Host "Downloading '$ucmaInstallFileName' from '$ucmaInstallLink'..." -NoNewline
                Get-LabInternetFile -Uri $ucmaInstallLink -Path $labSources\SoftwarePackages\$ucmaInstallFileName -ErrorAction Stop
                Write-Host 'finished'
                $ucmaFile = Get-ChildItem -Path $labSources -Filter $ucmaInstallFileName -Recurse
            }
            catch
            {
                throw "The Unified Communications Managed API 4.0 Runtime installation file ($ucmaInstallFileName) does not exist and could not be downloaded. Please put the file in the LabSources\SoftwarePackages folder and start the Exchange installation again (Install-Lab -Exchange2013)"
            }
        }
        Copy-LabFileItem -Path $ucmaFile.FullName -DestinationFolder C:\Install -ComputerName $Machine
    
        $exchangeFile = Get-ChildItem -Path $labSources -Filter $exchangeInstallFileName -Recurse
        if (-not $exchangeFile)
        {
            try
            {
                Write-Host "Downloading '$exchangeInstallFileName' from '$exchangeInstallLink'..." -NoNewline
                Get-LabInternetFile -Uri $exchangeInstallLink -Path $labSources\SoftwarePackages\$exchangeInstallFileName -ErrorAction Stop
                Write-Host 'finished'
                $exchangeFile = Get-ChildItem -Path $labSources -Filter $exchangeInstallFileName -Recurse
            }
            catch
            {
                throw "The Exchange 2013 installation file ($exchangeInstallFileName) does not exist and could not be downloaded. Please put the file in the LabSources\SoftwarePackages folder and start the Exchange installation again (Install-Lab -Exchange2013)"
            }
        }
        Copy-LabFileItem -Path $exchangeFile.FullName -DestinationFolder C:\Install -ComputerName $Machine
    }
}
#endregion script blocks

#region Install-LabExchange2013
function Install-LabExchange2013
{
	# .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param ([switch]$CreateCheckPoints)
	
    #$start = Get-Date

    Write-LogFunctionEntry
    
    $lab = Get-Lab
    $machines = Get-LabMachine -Role Exchange2013
    $exchangeInstallLink = $MyInvocation.MyCommand.Module.PrivateData.Exchange2013DownloadLink
    $ucmaInstallLink = $MyInvocation.MyCommand.Module.PrivateData.ExchangeUcmaDownloadLink

    if (-not $machines)
    {
        Write-Verbose 'No Exchange 2013 servers defined in the lab. Skipping installation'
        return
    }
    
    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewLine
    Start-LabVM -ComputerName $machines -Wait -ProgressIndicator 15

    $jobs = @()

    Write-ScreenInfo -Message "Preparing machines: '$($machines -join ', ')'" -TaskStart
    
    $ProgressIndicatorForJob = 15
    foreach ($machine in $machines)
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

            if ($rootDc.HostType -eq 'HyperV')
            {
                Write-ScreenInfo -Message 'Extracting Files' -NoNewLine
                Copy-LabExchangeInstallationFiles -Machine $rootDc
                $jobs += Invoke-LabCommand -ActivityName 'Extracting Files' -ComputerName $rootDc -ScriptBlock $exchangeExtractCmd -ArgumentList $exchangeInstallLink -AsJob -PassThru -NoDisplay
            }
            elseif ($rootDc.HostType -eq 'Azure')
            {
                Write-ScreenInfo -Message 'Downloading Files' -NoNewLine
                $jobs += Invoke-LabCommand -ActivityName 'Downloading Files' -ComputerName $rootDc -ScriptBlock $exchangeDownloadCmd -ArgumentList $exchangeInstallLink -AsJob -PassThru -NoDisplay
                $ProgressIndicatorForJob = 30
            }
        }

        if ($machine.HostType -eq 'HyperV')
        {
            Write-ScreenInfo -Message 'Extracting Files' -NoNewLine
            Copy-LabExchangeInstallationFiles -Machine $machine
            $jobs += Invoke-LabCommand -ActivityName 'Extracting Files' -ComputerName $machine -ScriptBlock $exchangeExtractCmd `
            -ArgumentList $exchangeInstallLink -AsJob -PassThru -NoDisplay
        }
        elseif ($rootDc.HostType -eq 'Azure')
        {
            Write-ScreenInfo -Message 'Downloading Files' -NoNewLine
            $jobs += Invoke-LabCommand -ActivityName 'Downloading Files' -ComputerName $machine -ScriptBlock $exchangeDownloadCmd `
            -ArgumentList $exchangeInstallLink -AsJob -PassThru -NoDisplay
            $ProgressIndicatorForJob = 30
        }
    }
    
    Wait-LWLabJob -Job (Install-LabWindowsFeature -ComputerName $machines -FeatureName Server-Media-Foundation, RSAT -UseLocalCredential -AsJob -PassThru -NoDisplay) `
    -NoDisplay -NoNewLine -ProgressIndicator 15
    Wait-LWLabJob -Job $jobs -ProgressIndicator $ProgressIndicatorForJob -NoDisplay
    
    Write-ScreenInfo -Message "Finished preparing machines: '$($machines -join ', ')'" -TaskEnd
    
    
    Write-ScreenInfo -Message 'Restarting machines' -NoNewLine
    Restart-LabVM -ComputerName $machines -Wait -ProgressIndicator 45
    
    Sync-LabActiveDirectory -ComputerName $rootDc

    $jobs.Clear()
    
    foreach ($machine in $machines)
    {
        Write-ScreenInfo -Message "Performing pre-requisites for machine '$machine'" -TaskStart
        
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

        

        # PREPARE SCHEMA
        Write-ScreenInfo -Message 'Performing Exchange Schema Update' -NoNewLine
        $exchangeSchemaUpdateJob = Invoke-LabCommand -ActivityName 'Performing Exchange Schema Update' -ComputerName $prepMachine -ScriptBlock $exchangeSchemaUpdateCmd -UseCredSsp -PassThru -NoDisplay -AsJob
        $result = Wait-LwLabJob -Job $exchangeSchemaUpdateJob -ProgressIndicator 30 -NoDisplay -ReturnResults -ErrorAction SilentlyContinue
            
        if ($result.InstallStatus -eq 'RebootRequired')
        {
            Write-ScreenInfo -Message "Restarting '$prepMachine' before updating the schema"
            Restart-LabVM -ComputerName $prepMachine -Wait -ProgressIndicator 45
            Write-ScreenInfo -Message 'Restarting Exchange Schema Update'
            $exchangeSchemaUpdateJob = Invoke-LabCommand -ActivityName '(Re)Performing Exchange Schema Update' -ComputerName $prepMachine -ScriptBlock $exchangeSchemaUpdateCmd -UseCredSsp -PassThru -NoDisplay -AsJob
            $result = Wait-LwLabJob -Job $exchangeSchemaUpdateJob -ProgressIndicator 30 -NoDisplay -ReturnResults -ErrorAction SilentlyContinue
        }
        
        if ($result.InstallStatus -ne 'Success')
        {
            $resultVariable = New-Variable -Name ("AL_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
            $resultVariable.Value = $result
            Write-Error "Exchange Schema Update failed on server '$prepMachine'. See content of $($resultVariable.Name) for details."
            return
        }

            

        # PREPARE AD
        Write-ScreenInfo -Message 'Performing Exchange AD Prep' -NoNewLine
        $exchangeADPrepJob = Invoke-LabCommand -ActivityName 'Performing Exchange AD Prep' -ComputerName $prepMachine -ScriptBlock $exchangePrepareADCmd `
        -ArgumentList $exchangeOrganization -UseCredSsp -PassThru -NoDisplay -AsJob -ErrorAction SilentlyContinue
        $result = Wait-LwLabJob -Job $exchangeADPrepJob -ReturnResults -ProgressIndicator 30 -NoDisplay -ErrorAction SilentlyContinue

        if ($result.InstallStatus -eq 'RebootRequired')
        {
            Write-ScreenInfo -Message "Restarting machine '$prepMachine' before updating the schema"
            Restart-LabVM -ComputerName $prepMachine -Wait -ProgressIndicator 45
            Write-ScreenInfo -Message 'Restarting Exchange AD Prep'
            $exchangeADPrepJob = Invoke-LabCommand -ActivityName 'Restarting Exchange AD Prep' -ComputerName $prepMachine -ScriptBlock $exchangePrepareADCmd `
            -ArgumentList $exchangeOrganization -UseCredSsp -PassThru -NoDisplay -AsJob -ErrorAction SilentlyContinue
            $result = Wait-LwLabJob -Job $exchangeADPrepJob -ProgressIndicator 30 -NoDisplay -ReturnResults -ErrorAction SilentlyContinue
        }
        
        if ($result.InstallStatus -ne 'Success')
        {
            $resultVariable = New-Variable -Name ("AL_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
            $resultVariable.Value = $result
            Write-Error "Exchange AD Prep failed on server '$prepMachine'. See content of $($resultVariable.Name) for details."
            return
        }
        
        
        
        #PREPARE ALL DOMAINS
        Write-ScreenInfo -Message 'Preparing All Domains' -NoNewLine
        $ExchangePrepareAllDomains = Invoke-LabCommand -ActivityName 'Preparing All Domains' -ComputerName $prepMachine -ScriptBlock $exchangePrepAllDomainsCmd `
        -UseCredSsp -PassThru -NoDisplay -AsJob
        $result = Wait-LwLabJob -Job $ExchangePrepareAllDomains -ReturnResults -ErrorAction SilentlyContinue -ProgressIndicator 10 -NoDisplay
        
        if ($result.InstallStatus -eq 'RebootRequired')
        {
            Write-ScreenInfo -Message "Restarting machine '$prepMachine' before preparing all domains"
            Restart-LabVM -ComputerName $prepMachine -Wait -ProgressIndicator 45
            $ExchangePrepareAllDomains = Invoke-LabCommand -ActivityName 'Restarting preparing All Domains' -ComputerName $prepMachine `
            -ScriptBlock $exchangePrepAllDomainsCmd -UseCredSsp -PassThru -NoDisplay -AsJob
            
            $result = Wait-LwLabJob -Job $ExchangePrepareAllDomains -ReturnResults -ErrorAction SilentlyContinue -ProgressIndicator 10 -NoDisplay
        }
        
        if ($result.InstallStatus -ne 'Success')
        {
            $resultVariable = New-Variable -Name ("AL_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
            $resultVariable.Value = $result
            Write-Error "Exchange Prep all domains failed on server '$prepMachine'. See content of $($resultVariable.Name) for details."
            return
        }
        
        Write-ScreenInfo -Message "Finished performing pre-requisites for machine '$machine'" -TaskEnd
    }
    
    
    
    Write-ScreenInfo -Message 'Triggering replication and installing Ucma' -NoNewLine
    Get-LabMachine -Role RootDC | ForEach-Object {
        Sync-LabActiveDirectory -ComputerName $_
    }

    $jobs += Invoke-LabCommand -ActivityName 'Install Ucma' -ComputerName $machines -ScriptBlock $ucmaCmd `
    -ArgumentList $ucmaInstallLink -AsJob -PassThru -NoDisplay
    
    Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator 10
    
    Write-ScreenInfo -Message 'Restarting machines' -NoNewLine
    Restart-LabVM -ComputerName $machines -Wait -ProgressIndicator 45
    
    foreach ($machine in $machines)
    {
        Write-ScreenInfo -Message "Installing Exchange Server 2013 on machine '$machine'" -TaskStart
        
        $exchangeOrganization = ($machine.Roles | Where-Object Name -eq Exchange2013).Properties.OrganizationName

        #FINALLY INSTALL EXCHANGE
        Write-ScreenInfo -Message 'Install Exchange Server 2013' -NoNewLine
        $exchangeInstallJob = Invoke-LabCommand -ActivityName 'Install Exchange' -ComputerName $machine -ScriptBlock $exchangeSetupCmd `
        -ArgumentList $exchangeOrganization -UseCredSsp -PassThru -NoDisplay -Asjob -ErrorAction SilentlyContinue
        $result = Wait-LwLabJob -Job $exchangeInstallJob -ReturnResults -ErrorAction SilentlyContinue -ProgressIndicator 120 -NoDisplay
        
        if ($result.InstallStatus -eq 'RebootRequired')
        {
            Write-ScreenInfo -Message "Restarting machine '$machine' as part of the installation" -NoNewLine
            Restart-LabVM -ComputerName $machine -Wait -ProgressIndicator 45
            Write-ScreenInfo -Message 'Continuing installation' -NoNewLine
            $exchangeInstallJob = Invoke-LabCommand -ActivityName 'Install Exchange' -ComputerName $machine -ScriptBlock $exchangeSetupCmd `
            -ArgumentList $exchangeOrganization -UseCredSsp -PassThru -NoDisplay -Asjob -ErrorAction SilentlyContinue
            $result = Wait-LwLabJob -Job $exchangeInstallJob -ReturnResults -ErrorAction SilentlyContinue -ProgressIndicator 120 -NoDisplay -Timeout 120
        }
        
        
        if (-not $result)
        {
            Write-ScreenInfo -Message "No result, restarting '$machine' to retry install" -NoNewLine
            Restart-LabVM -ComputerName $machine -Wait -ProgressIndicator 45
            Write-ScreenInfo -Message 'Install Exchange Server 2013' -NoNewLine
            $exchangeInstallJob = Invoke-LabCommand -ActivityName 'Install Exchange (retry)' -ComputerName $machine -ScriptBlock $exchangeSetupCmd -ArgumentList $exchangeOrganization -UseCredSsp -PassThru -NoDisplay -Asjob -ErrorAction SilentlyContinue
            Wait-LwLabJob -Job $exchangeInstallJob -ProgressIndicator 120 -NoDisplay -Timeout 120
            $result = $exchangeInstallJob | Receive-Job -ErrorAction SilentlyContinue
        }

        if ($result.InstallStatus -ne 'Success')
        {
            $resultVariable = New-Variable -Name ("AL_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
            $resultVariable.Value = $result
            Write-Error "Exchange installation failed on server '$machine'. See content of $($resultVariable.Name) for details."
            continue
        }
        
        Write-ScreenInfo -Message "Finished installing Exchange Server 2013 on machine '$machine'" -TaskEnd
    }
	
    Write-LogFunctionExit
}
#endregion Install-LabExchange2013