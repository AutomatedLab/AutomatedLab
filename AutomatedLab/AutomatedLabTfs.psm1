#region Lab-specific functionality
function Install-LabTeamFoundationEnvironment
{
    [CmdletBinding()]
    param
    ( )

    $tfsMachines = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Where-Object { -not $_.SkipDeployment -and -not (Test-LabTfsEnvironment -ComputerName $_.Name -NoDisplay).ServerDeploymentOk }
    $azDevOpsService = Get-LabVm -Role AzDevOps | Where-Object SkipDeployment

    foreach ($svcConnection in $azDevOpsService)
    {
        $role = $svcConnection.Roles | Where-Object Name -Match 'AzDevOps'

        # Override port or add if empty
        $role.Properties.Port = 443
        $svcConnection.InternalNotes.CertificateThumbprint = 'use SSL'
        if (-not $role.Properties.ContainsKey('PAT'))
        {
            Write-ScreenInfo -Type Error -Message "No Personal Access Token available for Azure DevOps connection to $svcConnection.
                You will be unable to deploy build workers and you will not be able to use the cmdlets New-LabReleasePipeline, Get-LabBuildStep, Get-LabReleaseStep.
            Consider adding the key PAT to your role properties hashtable."
        }

        if (-not $role.Properties.ContainsKey('Organisation'))
        {
            Write-ScreenInfo -Type Error -Message "No Organisation name available for Azure DevOps connection to $svcConnection.
                You will be unable to deploy build workers and you will not be able to use the cmdlets New-LabReleasePipeline, Get-LabBuildStep, Get-LabReleaseStep.
            Consider adding the key Organisation to your role properties hashtable where Organisation = dev.azure.com/<Organisation>"
        }
    }

    if ($azDevOpsService) { Export-Lab }

    $lab = Get-Lab
    $jobs = @()

    foreach ($machine in $tfsMachines)
    {
        Dismount-LabIsoImage -ComputerName $machine -SupressOutput

        $role = $machine.Roles | Where-Object Name -Match 'Tfs\d{4}|AzDevOps'
        $isoPath = ($lab.Sources.ISOs | Where-Object Name -eq $role.Name).Path

        $retryCount = 3
        $autoLogon = (Test-LabAutoLogon -ComputerName $machine)[$machine.Name]
        while (-not $autoLogon -and $retryCount -gt 0)
        {
            Enable-LabAutoLogon -ComputerName $machine
            Restart-LabVm -ComputerName $machine -Wait

            $autoLogon = (Test-LabAutoLogon -ComputerName $machine)[$machine.Name]
            $retryCount--
        }

        if (-not $autoLogon)
        {
            throw "No logon session available for $($machine.InstallationUser.UserName). Cannot continue with TFS setup for $machine"
        }

        Mount-LabIsoImage -ComputerName $machine -IsoPath $isoPath -SupressOutput      

        $jobs += Invoke-LabCommand -ComputerName $machine -ScriptBlock {
            $startTime = (Get-Date)
            while (-not $dvdDrive -and (($startTime).AddSeconds(120) -gt (Get-Date)))
            {
                Start-Sleep -Seconds 2
                $dvdDrive = (Get-WmiObject -Class Win32_CDRomDrive | Where-Object MediaLoaded).Drive
            }

            if ($dvdDrive)
            {
                $executable = (Get-ChildItem -Path $dvdDrive -Filter *.exe).FullName
                $installation = Start-Process -FilePath $executable -ArgumentList '/quiet' -Wait -LoadUserProfile -PassThru
                      
                if ($installation.ExitCode -notin 0, 3010)
                {
                    throw "TFS Setup failed with exit code $($installation.ExitCode)"
                }

                Write-Verbose 'TFS Installation finished. Configuring...'
            }
            else
            {
                Write-Error -Message 'No ISO mounted. Cannot continue.'
            }
        } -AsJob -PassThru -NoDisplay
    }

    # If not already set, ignore certificate issues throughout the TFS interactions
    try { [ServerCertificateValidationCallback]::Ignore() } catch { }

    if ($tfsMachines)
    {        
        Wait-LWLabJob -Job $jobs
        Restart-LabVm -ComputerName $tfsMachines -Wait
        Install-LabTeamFoundationServer
    }

    Install-LabBuildWorker
}

function Install-LabTeamFoundationServer
{
    [CmdletBinding()]
    param
    ( )

    $tfsMachines = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Where-Object SkipDeployment -eq $false | Sort-Object { ($_.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps').Name } -Descending
    if (-not $tfsMachines) { return }
    
  
    # Assign unassigned build workers to our most current TFS machine
    Get-LabVm -Role TfsBuildWorker | Where-Object {
        -not ($_.Roles | Where-Object Name -eq TfsBuildWorker).Properties.ContainsKey('TfsServer')
    } | ForEach-Object {
        ($_.Roles | Where-Object Name -eq TfsBuildWorker).Properties.Add('TfsServer', $tfsMachines[0].Name)
    }  

    $jobs = Install-LabWindowsFeature -ComputerName $tfsMachines -FeatureName Web-Mgmt-Tools -AsJob
    Write-ScreenInfo -Message 'Waiting for installation of IIS web admin tools to complete' -NoNewline
    Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -Timeout $InstallationTimeout -NoDisplay

    $installationJobs = @()
    $count = 0
    foreach ( $machine in $tfsMachines)
    {
        if (Get-LabIssuingCA)
        {
            Write-ScreenInfo -Type Verbose -Message "Found CA in lab, requesting certificate"
            $cert = Request-LabCertificate -Subject "CN=$machine" -TemplateName WebServer -SAN $machine.AzureConnectionInfo.DnsName, $machine.FQDN, $machine.Name -ComputerName $machine -PassThru -ErrorAction Stop
            $machine.InternalNotes.Add('CertificateThumbprint', $cert.Thumbprint)
            Export-Lab
        }

        $role = $machine.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps'
        [string]$sqlServer = switch -Regex ($role.Name)
        {
            'Tfs2015' { Get-LabVm -Role SQLServer2014 | Select-Object -First 1 }
            'Tfs2017' { Get-LabVm -Role SQLServer2014, SQLServer2016 | Select-Object -First 1 }
            'Tfs2018|AzDevOps' { Get-LabVm -Role SQLServer2017 | Select-Object -First 1 }
            default { throw 'No fitting SQL Server found in lab!' }
        }

        $initialCollection = 'AutomatedLab'
        $tfsPort = 8080
        $databaseLabel = "TFS$count" # Increment database label in case we deploy multiple TFS
        [string]$machineName = $machine
        $count++
  
        if ($role.Properties.ContainsKey('InitialCollection'))
        {
            $initialCollection = $role.Properties['InitialCollection']
        }

        if ($role.Properties.ContainsKey('Port'))
        {
            $tfsPort = $role.Properties['Port']
        }

        if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
        {
            if (-not (Get-LabAzureLoadBalancedPort -DestinationPort $tfsPort -ComputerName $machine))
            {
                (Get-Lab).AzureSettings.LoadBalancerPortCounter++
                $remotePort = (Get-Lab).AzureSettings.LoadBalancerPortCounter
                Add-LWAzureLoadBalancedPort -ComputerName $machine -DestinationPort $tfsPort -Port $remotePort
            }

            $machineName = $machine.AzureConnectionInfo.DnsName

            if ($role.Properties.ContainsKey('Port'))
            {
                $machine.Roles.Where( { $_.Name -match 'Tfs\d{4}|AzDevOps' }).ForEach( { $_.Properties['Port'] = $tfsPort })
            }
            else
            {
                $machine.Roles.Where( { $_.Name -match 'Tfs\d{4}|AzDevOps' }).ForEach( { $_.Properties.Add('Port', $tfsPort) })
            }

            Export-Lab # Export lab again since we changed role properties
        }

        if ($role.Properties.ContainsKey('DbServer'))
        {
            [string]$sqlServer = Get-LabVm -ComputerName $role.Properties['DbServer'] -ErrorAction SilentlyContinue

            if (-not $sqlServer)
            {
                Write-ScreenInfo -Message "No SQL server called $($role.Properties['DbServer']) found in lab." -NoNewLine -Type Warning
                [string]$sqlServer = Get-LabVM -Role SQLServer2016, SQLServer2017 | Select-Object -First 1
                Write-ScreenInfo -Message " Selecting $sqlServer instead." -Type Warning
            }
        }

        $installationJobs += Invoke-LabCommand -ComputerName $machine -ScriptBlock {
            $tfsConfigPath = (Get-ChildItem -Path $env:ProgramFiles -Filter tfsconfig.exe -Recurse | Select-Object -First 1).FullName
            if (-not $tfsConfigPath) { throw 'tfsconfig.exe could not be found.' }

            if (-not (Test-Path C:\DeployDebug))
            {
                [void] (New-Item -Path C:\DeployDebug -ItemType Directory)
            }

            # Create unattend file with fitting parameters and replace all we can find
            [void] (Start-Process -FilePath $tfsConfigPath -ArgumentList 'unattend /create /type:Standard /unattendfile:C:\DeployDebug\TfsConfig.ini' -NoNewWindow -Wait)
          
            $config = (Get-Item -Path C:\DeployDebug\TfsConfig.ini -ErrorAction Stop).FullName
            $content = [System.IO.File]::ReadAllText($config)
         
            $content = $content -replace 'SqlInstance=.+', ('SqlInstance={0}' -f $sqlServer)
            $content = $content -replace 'DatabaseLabel=.+', ('DatabaseLabel={0}' -f $databaseLabel)
            $content = $content -replace 'UrlHostNameAlias=.+', ('UrlHostNameAlias={0}' -f $machineName)

            if ($cert.Thumbprint)
            {
                $content = $content -replace 'SiteBindings=.+', ('SiteBindings=https:*:{0}::My:{1}' -f $tfsPort, $cert.Thumbprint)
                $content = $content -replace 'PublicUrl=.+', ('PublicUrl=https://{0}:{1}' -f $machineName, $tfsPort)
            }
            else
            {
                $content = $content -replace 'SiteBindings=.+', ('SiteBindings=http:*:{0}:' -f $tfsPort)
                $content = $content -replace 'PublicUrl=.+', ('PublicUrl=http://{0}:{1}' -f $machineName, $tfsPort)
            }

            if ($cert.ThumbPrint -and $tfsConfigPath -match '14\.0')
            {
                Get-WebBinding -Name 'Team Foundation Server' | Remove-WebBinding
                New-WebBinding -Protocol https -Port $tfsPort -IPAddress * -Name 'Team Foundation Server'
                $binding = Get-Website -Name 'Team Foundation Server' | Get-WebBinding
                $binding.AddSslCertificate($cert.Thumbprint, "my")
            }
          
            $content = $content -replace 'webSiteVDirName=.+', 'webSiteVDirName='
            $content = $content -replace 'CollectionName=.+', ('CollectionName={0}' -f $initialCollection)
            $content = $content -replace 'CollectionDescription=.+', 'CollectionDescription=Built by AutomatedLab, your friendly lab automation solution'
            $content = $content -replace 'WebSitePort=.+', ('WebSitePort={0}' -f $tfsPort) # Plain TFS 2015
            $content = $content -replace 'UrlHostNameAlias=.+', ('UrlHostNameAlias={0}' -f $machineName) # Plain TFS 2015
          
            [System.IO.File]::WriteAllText($config, $content)

            $command = "unattend /unattendfile:`"$config`" /continue"
            "`"$tfsConfigPath`" $command" | Set-Content C:\DeployDebug\SetupTfsServer.cmd
            $configurationProcess = Start-Process -FilePath $tfsConfigPath -ArgumentList $command -PassThru -NoNewWindow -Wait

            # Locate log files and cat them
            $log = Get-ChildItem -Path "$env:LOCALAPPDATA\Temp" -Filter dd_*_server_??????????????.log | Sort-Object -Property CreationTime | Select-Object -Last 1
            $log | Get-Content

            if ($configurationProcess.ExitCode -ne 0)
            {
                throw ('Something went wrong while applying the unattended configuration {0}. Try {1} {2} manually. Read the log at {3}.' -f $config, $tfsConfigPath, $command, $log.FullName )
            }
        } -Variable (Get-Variable sqlServer, machineName, InitialCollection, tfsPort, databaseLabel, cert -ErrorAction SilentlyContinue) -AsJob -ActivityName "Setting up TFS server $machine" -PassThru -NoDisplay
    }

    Write-ScreenInfo -Type Verbose -Message "Waiting for the installation of TFS on $tfsMachines to finish."
    
    Wait-LWLabJob -Job $installationJobs

    foreach ($job in $installationJobs)
    {        
        $resultVariable = New-Variable -Name ("AL_TFSServer_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
        Write-ScreenInfo -Type Verbose -Message "The job output of $job can be retrieved with `${$($resultVariable.Name)}"
        $resultVariable.Value = $job | Receive-Job -AutoRemoveJob -Wait
    }
}

function Install-LabBuildWorker
{
    [CmdletBinding()]
    param
    ( )

    $buildWorkers = Get-LabVm -Role TfsBuildWorker
    if (-not $buildWorkers)
    {
        return
    }

    $buildWorkerUri = Get-LabConfigurationItem -Name BuildAgentUri
    $buildWorkerPath = Join-Path -Path $labsources -ChildPath Tools\TfsBuildWorker.zip
    $download = Get-LabInternetFile -Uri $buildWorkerUri -Path $buildWorkerPath -PassThru -Force
    Copy-LabFileItem -ComputerName $buildWorkers -Path $download.Path

    $installationJobs = @()
    foreach ($machine in $buildWorkers)
    {
        $role = $machine.Roles | Where-Object Name -eq TfsBuildWorker
        $tfsServer = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Select-Object -First 1

        $useSsl = $tfsServer.InternalNotes.ContainsKey('CertificateThumbprint') -or ($tfsServer.Roles.Name -eq 'AzDevOps' -and $tfsServer.SkipDeployment)
        $tfsPort = 8080

        if ($role.Properties.ContainsKey('TfsServer'))
        {
            $tfsServer = Get-LabVm -ComputerName $role.Properties['TfsServer'] -ErrorAction SilentlyContinue
            if (-not $tfsServer)
            {
                Write-ScreenInfo -Message "No TFS server called $($role.Properties['TfsServer']) found in lab." -NoNewLine -Type Warning
                $tfsServer = Get-LabVM -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Select-Object -First 1
                $role.Properties['TfsServer'] = $tfsServer.Name
                $shouldExport = $true
                Write-ScreenInfo -Message " Selecting $tfsServer instead." -Type Warning
            }
        }
        else
        {
            $role.Properties.Add('TfsServer', $tfsServer.Name)
            $shouldExport = $true
        }

        if ($shouldExport) { Export-Lab }

        $tfsTest = Test-LabTfsEnvironment -ComputerName $tfsServer -NoDisplay
        if ($tfsTest.ServerDeploymentOk -and $tfsTest.BuildWorker[$machine.Name].WorkerDeploymentOk)
        {
            Write-ScreenInfo -Message "Build worker $machine assigned to $tfsServer appears to be configured. Skipping..."
            continue
        }

        $tfsRole = $tfsServer.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps'
        if ($tfsRole.Properties.ContainsKey('Port'))
        {
            $tfsPort = $tfsRole.Properties['Port']
        }

        [string]$machineName = $tfsServer

        if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and -not ($tfsServer.Roles.Name -eq 'AzDevOps' -and $tfsServer.SkipDeployment))
        {
            $tfsPort = (Get-LabAzureLoadBalancedPort -DestinationPort $tfsPort -ComputerName $tfsServer -ErrorAction SilentlyContinue).Port
            $machineName = $tfsServer.AzureConnectionInfo.DnsName
            
            if (-not $tfsPort)
            {
                Write-Error -Message 'There has been an error setting the Azure port during TFS installation. Cannot continue installing build worker.'
                return
            }
        }

        $pat = if ($tfsRole.Properties.ContainsKey('PAT'))
        {
            $tfsRole.Properties['PAT']
            $machineName = "dev.azure.com/$($tfsRole['Organisation'])"
        }
        else
        {
            [string]::Empty
        }        

        $installationJobs += Invoke-LabCommand -ComputerName $machine -ScriptBlock {

            if (-not (Test-Path C:\TfsBuildWorker.zip)) { throw 'Build worker installation files not available' }

            Microsoft.PowerShell.Archive\Expand-Archive -Path C:\TfsBuildWorker.zip -DestinationPath C:\BuildWorkerSetupFiles -Force
            $configurationTool = Get-Item C:\BuildWorkerSetupFiles\config.cmd -ErrorAction Stop

            $content = if ($useSsl -and [string]::IsNullOrEmpty($pat))
            {
                "$configurationTool --unattended --url https://$($machineName):$($tfsPort) --auth Integrated --pool default --agent $env:COMPUTERNAME --runasservice --sslskipcertvalidation --gituseschannel"
                
            }
            elseif ($useSsl -and -not [string]::IsNullOrEmpty($pat))
            {
                "$configurationTool --unattended --url https://$($machineName) --auth pat --token $pat --pool default --agent $env:COMPUTERNAME --runasservice --sslskipcertvalidation --gituseschannel"
            }
            elseif (-not $useSsl -and -not [string]::IsNullOrEmpty($pat))
            {
                "$configurationTool --unattended --url http://$($machineName) --auth pat --token $pat --pool default --agent $env:COMPUTERNAME --runasservice --gituseschannel"
            }
            else
            {
                "$configurationTool --unattended --url http://$($machineName):$($tfsPort) --auth Integrated --pool default --agent $env:COMPUTERNAME --runasservice --gituseschannel"
            }

            $null = New-Item -ItemType Directory -Path C:\DeployDebug -ErrorAction SilentlyContinue
            Set-Content C:\DeployDebug\SetupBuildWorker.cmd -Value $content -Force
            
            $configresult = & C:\DeployDebug\SetupBuildWorker.cmd

            $log = Get-ChildItem -Path "C:\BuildWorkerSetupFiles\_diag" -Filter *.log | Sort-Object -Property CreationTime | Select-Object -Last 1

            [pscustomobject]@{
                ConfigResult = $configresult
                LogContent   = $log | Get-Content 
            }

            if ($LASTEXITCODE -notin 0, 3010)
            {
                Write-Warning -Message "Build worker $env:COMPUTERNAME failed to install. Exit code was $($LASTEXITCODE). Log is $($Log.FullName)"
            }
        } -AsJob -Variable (Get-Variable machineName, tfsPort, useSsl, pat) -ActivityName "Setting up build agent $machine" -PassThru -NoDisplay
    }

    Wait-LWLabJob -Job $installationJobs

    foreach ($job in $installationJobs)
    {        
        $resultVariable = New-Variable -Name ("AL_TFSBuildWorker_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
        Write-ScreenInfo -Type Verbose -Message "The job output of $job can be retrieved with `${$($resultVariable.Name)}"
        $resultVariable.Value = $job | Receive-Job -AutoRemoveJob -Wait
    }
}
#endregion

#region TFS-specific functionality
function New-LabReleasePipeline
{
    [CmdletBinding(DefaultParameterSetName = 'CloneRepo')]
    param
    (
        [string]
        $ProjectName = 'ALSampleProject',

        [Parameter(Mandatory, ParameterSetName = 'CloneRepo')]
        [Parameter(ParameterSetName = 'LocalSource')]
        [string]
        $SourceRepository,

        [Parameter(Mandatory, ParameterSetName = 'LocalSource')]
        [string]
        $SourcePath,
      
        [ValidateSet('Git', 'FileCopy')]
        [string]$CodeUploadMethod = 'Git',

        [string]
        $ComputerName,

        [hashtable[]]
        $BuildSteps,

        [hashtable[]]
        $ReleaseSteps
    )
  
    if (-not (Get-Lab -ErrorAction SilentlyContinue))
    {
        throw 'No lab imported. Please use Import-Lab to import the target lab containing at least one TFS server'
    }
  
    if ($CodeUploadMethod -eq 'Git' -and -not $SourceRepository)
    {
        throw "Using the code upload method 'Git' requires a source repository to be defined."
    }

    $tfsVm = if ($ComputerName)
    {
        Get-LabVM -ComputerName $ComputerName
    }
    else
    {
        Get-LabVM -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Select-Object -First 1
    }

    if (-not $tfsVm) { throw ('No TFS VM in lab or no machine found with name {0}' -f $ComputerName) }

    $localLabSources = Get-LabSourcesLocationInternal -Local
  
    $role = $tfsVm.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps'
    $initialCollection = 'AutomatedLab'
    $tfsPort = $originalPort = 8080
    $tfsInstance = $tfsVm.FQDN
  
    if ($role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and -not ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment))
    {
        $tfsPort = (Get-LWAzureLoadBalancedPort -DestinationPort $tfsPort -ComputerName $tfsVm -ErrorAction SilentlyContinue).FrontendPort

        if (-not $tfsPort)
        {
            Write-Error -Message 'There has been an error setting the Azure port during TFS installation. Cannot continue rolling out release pipeline'
            return
        }

        $tfsInstance = $tfsVm.AzureConnectionInfo.DnsName
    }

    if ($role.Properties.ContainsKey('InitialCollection'))
    {
        $initialCollection = $role.Properties['InitialCollection']
    }

    if ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment)
    {
        $tfsInstance = 'dev.azure.com'
        $initialCollection = $role.Properties['Organisation']
        $accessToken = $role.Properties['PAT']
    }

    $credential = $tfsVm.GetCredential((Get-Lab))
    $useSsl = $tfsVm.InternalNotes.ContainsKey('CertificateThumbprint')
  
    $gitBinary = if (Get-Command git) { (Get-Command git).Source } elseif (Test-Path -Path $localLabSources\Tools\git.exe) { "$localLabSources\Tools\git.exe" }
    if (-not $gitBinary)
    {
        Write-ScreenInfo -Message 'Git is not installed. We are not be able to push any code to the remote repository and cannot proceed. Please install Git'
        return
    }

    $defaultParam = @{
        InstanceName         = $tfsInstance
        Port                 = $tfsPort
        CollectionName       = $initialCollection
        ProjectName          = $ProjectName
        UseSsl               = $useSsl
        SkipCertificateCheck = $true
    }

    $defaultParam.ApiVersion = switch ($role.Name)
    {
        'Tfs2015' { '2.0'; break }
        'Tfs2017' { '3.0'; break }
        { $_ -match '2018|AzDevOps' } { '4.0'; break }
        default { '2.0' }
    }

    if ($accessToken)
    {
        $defaultParam.PersonalAccessToken = $accessToken
    }
    elseif ($credential)
    {
        $defaultParam.Credential = $credential
    }
    else
    {
        Write-ScreenInfo -Type Error -Message 'Neither Credential nor AccessToken are available. Unable to continue'
        return
    }

    $project = New-TfsProject @defaultParam -SourceControlType Git -TemplateName 'Agile' -Timeout (New-TimeSpan -Minutes 5)
    $repository = Get-TfsGitRepository @defaultParam
    $repository.remoteUrl = $repository.remoteUrl -replace $originalPort, $tfsPort
  
    if ($SourceRepository)
    {
        if (-not $gitBinary)
        {
            Write-Error "Git.exe could not be located, cannot clone repository from '$SourceRepository'"
            return
        }
      
        $repoUrl = $repository.remoteUrl.Insert($repository.remoteUrl.IndexOf('/') + 2, '{0}:{1}@')
        $repoUrl = $repoUrl -f $credential.GetNetworkCredential().UserName.ToLower(), $credential.GetNetworkCredential().Password
        Write-ScreenInfo -Type Verbose -Message "Generated repo url $repoUrl"

        if (-not $SourcePath)
        {
            $SourcePath = "$localLabSources\GitRepositories\$((Get-Lab).Name)"
        }

        if (-not (Test-Path -Path $SourcePath))
        {
            Write-ScreenInfo -Type Verbose -Message "Creating $SourcePath to contain your cloned repos"
            [void] (New-Item -ItemType Directory -Path $SourcePath -Force)
        }

        $repositoryPath = Join-Path -Path $SourcePath -ChildPath (Split-Path -Path $SourceRepository -Leaf)
        if (-not (Test-Path $repositoryPath))
        {
            Write-ScreenInfo -Type Verbose -Message "Creating $repositoryPath to contain your cloned repo"
            [void] (New-Item -ItemType Directory -Path $repositoryPath)
        }

        Push-Location
        Set-Location -Path $repositoryPath

        if (Join-Path -Path $repositoryPath -ChildPath '.git' -Resolve -ErrorAction SilentlyContinue)
        {
            Write-ScreenInfo -Type Verbose -Message ('There already is a clone of {0} in {1}. Pulling latest changes from remote if possible.' -f $SourceRepository, $repositoryPath)
            try
            {
                $errorFile = [System.IO.Path]::GetTempFileName()
                $pullResult = Start-Process -FilePath $gitBinary -ArgumentList @('-c', 'http.sslVerify=false', 'pull', 'origin') -Wait -NoNewWindow -PassThru -RedirectStandardError $errorFile

                if ($pullResult.ExitCode -ne 0)
                {
                    Write-ScreenInfo -Type Warning -Message "Could not pull from $SourceRepository. Git returned: $(Get-Content -Path $errorFile)"
                }
            }
            finally
            {
                Remove-Item -Path $errorFile -Force -ErrorAction SilentlyContinue
            }
        }      
        else
        {
            Write-ScreenInfo -Type Verbose -Message ('Cloning {0} in {1}.' -f $SourceRepository, $repositoryPath)
            try
            {
                $retries = 3
                $errorFile = [System.IO.Path]::GetTempFileName()
              
                $cloneResult = Start-Process -FilePath $gitBinary -ArgumentList @('clone', $SourceRepository, $repositoryPath, '--quiet') -Wait -NoNewWindow -PassThru -RedirectStandardError $errorFile
                while ($cloneResult.ExitCode -ne 0 -and $retries -gt 0)
                {
                    Write-ScreenInfo "Could not clone the repository '$SourceRepository', retrying ($retries)..."
                    Start-Sleep -Seconds 5
                    $cloneResult = Start-Process -FilePath $gitBinary -ArgumentList @('clone', $SourceRepository, $repositoryPath, '--quiet') -Wait -NoNewWindow -PassThru -RedirectStandardError $errorFile
                    $retries--
                }

                if ($cloneResult.ExitCode -ne 0)
                {
                    Write-Error "Could not clone from $SourceRepository. Git returned: $(Get-Content -Path $errorFile)"
                }
            }
            finally
            {
                Remove-Item -Path $errorFile -Force -ErrorAction SilentlyContinue
            }
        }

        Pop-Location
    }
  
    if ($CodeUploadMethod -eq 'Git')
    {
        Push-Location
        Set-Location -Path $repositoryPath
      
        try
        {
            $errorFile = [System.IO.Path]::GetTempFileName()
            $addRemoteResult = Start-Process -FilePath $gitBinary -ArgumentList @('remote', 'add', 'tfs', $repoUrl) -Wait -NoNewWindow -PassThru -RedirectStandardError $errorFile
            if ($addRemoteResult.ExitCode -ne 0)
            {
                Write-Error "Could not add remote tfs to $repoUrl. Git returned: $(Get-Content -Path $errorFile)"
            }
        }
        finally
        {
            Remove-Item -Path $errorFile -Force -ErrorAction SilentlyContinue
        }
        try
        {
            $pattern = '(?>remotes\/origin\/)(?<BranchName>[\w\/]+)'
            $branches = git branch -a | Where-Object { $_ -cnotlike '*HEAD*' -and $_ -like '  remotes/origin*' }

            foreach ($branch in $branches)
            {
                $branch -match $pattern | Out-Null

                git checkout $Matches.BranchName 2>&1
                if ($LASTEXITCODE -eq 0)
                {
                    $retries = 3
                    $errorFile = [System.IO.Path]::GetTempFileName()
          
                    $pushResult = Start-Process -FilePath $gitBinary -ArgumentList @('-c', 'http.sslVerify=false', 'push', 'tfs', '--all', '--quiet') -Wait -NoNewWindow -PassThru -RedirectStandardError $errorFile
                    while ($pushResult.ExitCode -ne 0 -and $retries -gt 0)
                    {
                        Write-ScreenInfo "Could not push the repository in '$pwd' to TFS, retrying ($retries)..."
                        Start-Sleep -Seconds 5
                        $pushResult = Start-Process -FilePath $gitBinary -ArgumentList @('-c', 'http.sslVerify=false', 'push', 'tfs', '--all', '--quiet') -Wait -NoNewWindow -PassThru -RedirectStandardError $errorFile
                        $retries--
                    }
              
                    if ($pushResult.ExitCode -ne 0)
                    {
                        Write-Error "Could not push to $repoUrl. Git returned: $(Get-Content -Path $errorFile)"
                    }
                }
            }
        }
        finally
        {
            Remove-Item -Path $errorFile -Force -ErrorAction SilentlyContinue
        }
      
        Pop-Location
      
        Write-ScreenInfo -Type Verbose -Message ('Pushed code from {0} to remote {1}' -f $SourceRepository, $repoUrl)
    }
    else
    {
        $remoteGitBinary = Invoke-LabCommand -ActivityName 'Test Git availibility' -ComputerName $tfsVm -ScriptBlock {
        
            if (Get-Command git) { (Get-Command git).Source } elseif (Test-Path -Path $localLabSources\Tools\git.exe) { "$localLabSources\Tools\git.exe" }
            
        } -PassThru
        
        if (-not $remoteGitBinary)
        {
            Write-ScreenInfo -Message "Git is not installed on '$tfsVm'. We are not be able to push any code to the remote repository and cannot proceed. Please install Git on '$tfsVm'"
            return
        }
      
        if ($repositoryPath)
        {
            Copy-LabFileItem -Path $repositoryPath -ComputerName $tfsVm -DestinationFolderPath "C:\$ProjectName.temp" -Recurse
        }
        else
        {
            Copy-LabFileItem -Path $SourcePath -ComputerName $tfsVm -DestinationFolderPath "C:\$ProjectName.temp" -Recurse
        }
      
        Invoke-LabCommand -ActivityName 'Push code to TFS/AZDevOps' -ComputerName $tfsVm -ScriptBlock {

            Set-Location -Path "C:\$ProjectName.temp\$ProjectName"
          
            git remote add tfs $repository.remoteUrl
 
            $pattern = '(?>remotes\/origin\/)(?<BranchName>[\w\/]+)'
            $branches = git branch -a | Where-Object { $_ -cnotlike '*HEAD*' -and -not $_.StartsWith('*') }
 
            foreach ($branch in $branches)
            {
                if ($branch -match $pattern)
                {
                    git checkout $Matches.BranchName 2>&1
                    if ($LASTEXITCODE -eq 0)
                    {
                        git add . 2>&1
                        git commit -m 'Initial' 2>&1
                        git push --set-upstream tfs $Matches.BranchName 2>&1
                    }
                }
            }
 
            Set-Location -Path C:\
            Remove-Item -Path "C:\$ProjectName.temp" -Recurse -Force
        } -Variable (Get-Variable -Name repository, ProjectName)
    }
    
    if (-not ($role.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment))
    {
        Invoke-LabCommand -ActivityName 'Clone local repo from TFS' -ComputerName $tfsVm -ScriptBlock {
        
            if (-not (Test-Path -Path C:\Git))
            {
                New-Item -ItemType Directory -Path C:\Git | Out-Null
            }
            Set-Location -Path C:\Git
            git -c http.sslVerify=false clone $repository.remoteUrl 2>&1
            
        } -Variable (Get-Variable -Name repository, ProjectName)
    }

    if ($BuildSteps.Count -gt 0)
    {
        $buildParameters = $defaultParam.Clone()
        $buildParameters.DefinitionName = "$($ProjectName)Build"
        $buildParameters.BuildTasks = $BuildSteps
        New-TfsBuildDefinition @buildParameters
    }
  
    if ($ReleaseSteps.Count -gt 0)
    {
        $releaseParameters = $defaultParam.Clone()
        $releaseParameters.ReleaseName = "$($ProjectName)Release"
        $releaseParameters.ReleaseTasks = $ReleaseSteps
        New-TfsReleaseDefinition @releaseParameters
    }
}

function Get-LabBuildStep
{
    param
    (
        [string]
        $ComputerName
    )

    if (-not (Get-Lab -ErrorAction SilentlyContinue))
    {
        throw 'No lab imported. Please use Import-Lab to import the target lab containing at least one TFS server'
    }

    $tfsvm = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Select-Object -First 1
    $useSsl = $tfsVm.InternalNotes.ContainsKey('CertificateThumbprint')

    if ($ComputerName)
    {
        $tfsVm = Get-LabVm -ComputerName $ComputerName
    }

    if (-not $tfsvm) { throw ('No TFS VM in lab or no machine found with name {0}' -f $ComputerName) }
  
    $role = $tfsVm.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps'
    $initialCollection = 'AutomatedLab'
    $tfsPort = 8080
    $tfsInstance = $tfsvm.FQDN
  
    if ($role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and -not ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment))
    {
        $loadbalancedPort = (Get-LWAzureLoadBalancedPort -DestinationPort $tfsPort -ComputerName $tfsVm -ErrorAction SilentlyContinue).FrontendPort

        if (-not $loadbalancedPort)
        {
            Write-Error -Message 'There has been an error setting the Azure port during TFS installation. Cannot retrieve build steps'
            return
        }

        $tfsPort = $loadbalancedPort
        $tfsInstance = $tfsvm.AzureConnectionInfo.DnsName
    }

    if ($role.Properties.ContainsKey('InitialCollection'))
    {
        $initialCollection = $role.Properties['InitialCollection']
    }

    if ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment)
    {
        $tfsInstance = 'dev.azure.com'
        $initialCollection = $role.Properties['Organisation']
        $accessToken = $role.Properties['PAT']
    }

    $credential = $tfsVm.GetCredential((Get-Lab))
    $defaultParam = @{
        InstanceName   = $tfsInstance
        Port           = $tfsPort
        CollectionName = $initialCollection
        ProjectName    = $ProjectName
        UseSsl         = $useSsl
    }

    $defaultParam.ApiVersion = switch ($role.Name)
    {
        'Tfs2015' { '2.0'; break }
        'Tfs2017' { '3.0'; break }
        { $_ -match '2018|AzDevOps' } { '4.0'; break }
        default { '2.0' }
    }

    if ($accessToken)
    {
        $defaultParam.PersonalAccessToken = $accessToken
    }
    elseif ($credential)
    {
        $defaultParam.Credential = $credential
    }
    else
    {
        Write-ScreenInfo -Type Error -Message 'Neither Credential nor AccessToken are available. Unable to continue'
        return
    }
  
    return (Get-TfsBuildStep @defaultParam)
}

function Get-LabReleaseStep
{
    param
    (
        [string]
        $ComputerName
    )

    if (-not (Get-Lab -ErrorAction SilentlyContinue))
    {
        throw 'No lab imported. Please use Import-Lab to import the target lab containing at least one TFS server'
    }

    $tfsvm = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Select-Object -First 1
    $useSsl = $tfsVm.InternalNotes.ContainsKey('CertificateThumbprint')

    if ($ComputerName)
    {
        $tfsVm = Get-LabVm -ComputerName $ComputerName
    }

    if (-not $tfsvm) { throw ('No TFS VM in lab or no machine found with name {0}' -f $ComputerName) }
  
    $role = $tfsVm.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps'
    $initialCollection = 'AutomatedLab'
    $tfsPort = 8080
    $tfsInstance = $tfsvm.FQDN
  
    if ($role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and -not ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment))
    {
        $loadbalancedPort = (Get-LWAzureLoadBalancedPort -DestinationPort $tfsPort -ComputerName $tfsVm -ErrorAction SilentlyContinue).FrontendPort

        if (-not $loadbalancedPort)
        {
            Write-Error -Message 'There has been an error setting the Azure port during TFS installation. Cannot retrieve lab release steps.'
            return
        }

        $tfsPort = $loadbalancedPort
        $tfsInstance = $tfsvm.AzureConnectionInfo.DnsName
    }

    if ($role.Properties.ContainsKey('InitialCollection'))
    {
        $initialCollection = $role.Properties['InitialCollection']
    }

    if ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment)
    {
        $tfsInstance = 'dev.azure.com'
        $initialCollection = $role.Properties['Organisation']
        $accessToken = $role.Properties['PAT']
    }

    $credential = $tfsVm.GetCredential((Get-Lab))

    $defaultParam = @{
        InstanceName   = $tfsInstance
        Port           = $tfsPort
        CollectionName = $initialCollection
        ProjectName    = $ProjectName
        UseSsl         = $useSsl
    }

    $defaultParam.ApiVersion = switch ($role.Name)
    {
        'Tfs2015' { '2.0'; break }
        'Tfs2017' { '3.0'; break }
        { $_ -match '2018|AzDevOps' } { '4.0'; break }
        default { '2.0' }
    }

    if ($accessToken)
    {
        $defaultParam.PersonalAccessToken = $accessToken
    }
    elseif ($credential)
    {
        $defaultParam.Credential = $credential
    }
    else
    {
        Write-ScreenInfo -Type Error -Message 'Neither Credential nor AccessToken are available. Unable to continue'
        return
    }
  
    return (Get-TfsReleaseStep @defaultParam)
}

function Get-LabTfsUri
{
    [CmdletBinding()]
    param
    (
        [string]
        $ComputerName
    )

    if (-not (Get-Lab -ErrorAction SilentlyContinue))
    {
        throw 'No lab imported. Please use Import-Lab to import the target lab containing at least one TFS server'
    }

    $tfsvm = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Select-Object -First 1

    if ($ComputerName)
    {
        $tfsVm = Get-LabVm -ComputerName $ComputerName
    }

    if (-not $tfsvm) { throw ('No TFS VM in lab or no machine found with name {0}' -f $ComputerName) }

    $useSsl = $tfsVm.InternalNotes.ContainsKey('CertificateThumbprint')
  
    $role = $tfsVm.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps'
    $initialCollection = 'AutomatedLab'
    $tfsPort = 8080
    $tfsInstance = $tfsvm.FQDN
    $credential = $tfsVm.GetCredential((Get-Lab))
  
    if ($role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and -not ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment))
    {
        $loadbalancedPort = (Get-LWAzureLoadBalancedPort -DestinationPort $tfsPort -ComputerName $tfsVm -ErrorAction SilentlyContinue).FrontendPort

        if (-not $loadbalancedPort)
        {
            Write-Error -Message 'There has been an error setting the Azure port during TFS installation. Cannot open TFS site.'
            return
        }
      
        $tfsPort = $loadbalancedPort
        $tfsInstance = $tfsvm.AzureConnectionInfo.DnsName
    }

    if ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment)
    {
        $tfsInstance = 'dev.azure.com'
        $initialCollection = $role.Properties['Organisation']
    }

    if ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment)
    {
        'https://{0}/{1}' -f $tfsInstance, $initialCollection
    }
    elseif ($UseSsl)
    {
        'https://{0}:{1}@{2}:{3}/{4}' -f $credential.GetNetworkCredential().UserName, $credential.GetNetworkCredential().Password, $tfsInstance, $tfsPort, $initialCollection
    }
    else
    {
        'http://{0}:{1}@{2}:{3}/{4}' -f $credential.GetNetworkCredential().UserName, $credential.GetNetworkCredential().Password, $tfsInstance, $tfsPort, $initialCollection
    }
}

function Test-LabTfsEnvironment
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ComputerName,

        [switch]
        $NoDisplay
    )

    $lab = Get-Lab -ErrorAction Stop
    $machine = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Where-Object -Property Name -eq $ComputerName
    $assignedBuildWorkers = Get-LabVm -Role TfsBuildWorker | Where-Object { ($_.Roles | Where-Object Name -eq TfsBuildWorker)[0].Properties['TfsServer'] -eq $machine.Name }
    
    if (-not $machine) { return }

    if (-not $script:tfsDeploymentStatus)
    {
        $script:tfsDeploymentStatus = @{ }
    }
    
    if (-not $script:tfsDeploymentStatus.ContainsKey($ComputerName))
    {
        $script:tfsDeploymentStatus[$ComputerName] = @{ServerDeploymentOk = $false; BuildWorker = @{ } }
    }

    if (-not $script:tfsDeploymentStatus[$ComputerName].ServerDeploymentOk)
    {
        $uri = Get-LabTfsUri -ComputerName $machine -ErrorAction SilentlyContinue
        if ($null -eq $uri)
        {
            Write-PSFMessage -Message "TFS URI could not be determined."
            return $script:tfsDeploymentStatus[$ComputerName]
        }

        $role = $machine.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps'
        $initialCollection = 'AutomatedLab'
        $tfsPort = 8080
        $tfsInstance = $machine.FQDN
        $credential = $machine.GetCredential((Get-Lab))
        $useSsl = $machine.InternalNotes.ContainsKey('CertificateThumbprint')
  
        if ($role.Properties.ContainsKey('Port'))
        {
            $tfsPort = $role.Properties['Port']
        }

        if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and -not ($machine.Roles.Name -eq 'AzDevOps' -and $machine.SkipDeployment))
        {
            $tfsPort = (Get-LWAzureLoadBalancedPort -DestinationPort $tfsPort -ComputerName $machine -ErrorAction SilentlyContinue).FrontendPort
            $tfsInstance = $machine.AzureConnectionInfo.DnsName
        }

        if ($role.Properties.ContainsKey('InitialCollection'))
        {
            $initialCollection = $role.Properties['InitialCollection']
        }

        if ($machine.Roles.Name -eq 'AzDevOps' -and $machine.SkipDeployment)
        {
            $tfsInstance = 'dev.azure.com'
            $initialCollection = $role.Properties['Organisation']
            $accessToken = $role.Properties['PAT']
        }

        $defaultParam = @{
            InstanceName   = $tfsInstance
            Port           = $tfsPort
            CollectionName = $initialCollection
            UseSsl         = $useSsl
            ErrorAction    = 'Stop'
            ErrorVariable  = 'apiErr'
        }
    
        $defaultParam.ApiVersion = switch ($role.Name)
        {
            'Tfs2015' { '2.0'; break }
            'Tfs2017' { '3.0'; break }
            { $_ -match '2018|AzDevOps' } { '4.0'; break }
            default { '2.0' }
        }
    
        if ($accessToken)
        {
            $defaultParam.PersonalAccessToken = $accessToken
        }
        elseif ($credential)
        {
            $defaultParam.Credential = $credential
        }

        try
        {
            $parma = @{
                Method      = 'Get'
                Uri         = $uri
                ErrorAction = 'Stop'
            }

            if ($PSEdition -eq 'Core' -and (Get-Command INvoke-RestMethod).Parameters.COntainsKey('SkipCertificateCheck'))
            {
                $parma.SkipCertificateCheck = $true
            }

            if ($accessToken)
            {
                $parma.Headers = @{Authorization = Get-TfsAccessTokenString -PersonalAccessToken $accessToken }
            }
            else
            {
                $parma.Credential = $credential
            }

            $null = Invoke-RestMethod @parma
        }
        catch
        {
            Write-ScreenInfo -Type Error -Message "TFS URI $uri could not be accessed. Exception: $($_.Exception)"
            return $script:tfsDeploymentStatus[$ComputerName]
        }

        try
        {
            $null = Get-TfsProject @defaultParam
        }
        catch
        {
            Write-ScreenInfo -Type Error -Message "TFS URI $uri accessible, but no API call was possible. Exception: $($apiErr)"
            return $script:tfsDeploymentStatus[$ComputerName]
        }

        $script:tfsDeploymentStatus[$ComputerName].ServerDeploymentOk = $true
    }

    foreach ($worker in $assignedBuildWorkers)
    {
        if ($script:tfsDeploymentStatus[$ComputerName].BuildWorker[$worker.Name].WorkerDeploymentOk)
        {
            continue
        }
        if (-not $script:tfsDeploymentStatus[$ComputerName].BuildWorker[$worker.Name])
        {
            $script:tfsDeploymentStatus[$ComputerName].BuildWorker[$worker.Name] = @{ }
        }

        $svcRunning = Invoke-LabCommand -PassThru -ComputerName $worker -ScriptBlock { Get-Service -Name *vsts* } -NoDisplay
        $script:tfsDeploymentStatus[$ComputerName].BuildWorker[$worker.Name].WorkerDeploymentOk = $svcRunning.Status -eq 'Running'
    }

    return $script:tfsDeploymentStatus[$ComputerName]
}

function Open-LabTfsSite
{
    param
    (
        [string]
        $ComputerName
    )

    Start-Process -FilePath (Get-LabTfsUri @PSBoundParameters)
}

function New-LabTfsFeed
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        
        [Parameter(Mandatory)]
        [string]
        $FeedName,
        
        [object[]]
        $FeedPermissions,
        
        [switch]
        $PassThru
    )
    
    $tfsVm = Get-LabVM -ComputerName $computerName
    $role = $tfsVm.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps'
    $initialCollection = 'AutomatedLab'
    $tfsPort = $originalPort = 8080
    $tfsInstance = $tfsVm.FQDN

    if ($role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and -not ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment))
    {
        $tfsPort = (Get-LWAzureLoadBalancedPort -DestinationPort $tfsPort -ComputerName $tfsVm -ErrorAction SilentlyContinue).FrontendPort

        if (-not $tfsPort)
        {
            Write-Error -Message 'There has been an error setting the Azure port during TFS installation. Cannot continue rolling out release pipeline'
            return
        }

        $tfsInstance = $tfsVm.AzureConnectionInfo.DnsName
    }

    if ($role.Properties.ContainsKey('InitialCollection'))
    {
        $initialCollection = $role.Properties['InitialCollection']
    }

    if ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment)
    {
        $tfsInstance = 'dev.azure.com'
        $initialCollection = $role.Properties['Organisation']
        $accessToken = $role.Properties['PAT']
    }

    $credential = $tfsVm.GetCredential((Get-Lab))
    $useSsl = $tfsVm.InternalNotes.ContainsKey('CertificateThumbprint')
    
    $defaultParam = @{
        InstanceName         = $tfsInstance
        Port                 = $tfsPort
        CollectionName       = $initialCollection
        FeedName             = $FeedName
        UseSsl               = $useSsl
        SkipCertificateCheck = $true
        ApiVersion           = '5.0-preview.1'
    }

    if ($accessToken)
    {
        $defaultParam.PersonalAccessToken = $accessToken
    }
    elseif ($credential)
    {
        $defaultParam.Credential = $credential
    }
    else
    {
        Write-ScreenInfo -Type Error -Message 'Neither Credential nor AccessToken are available. Unable to continue'
        return
    }
    
    try
    {
        New-TfsFeed @defaultParam -ErrorAction Stop
        
        if ($FeedPermissions)
        {
            Set-TfsFeedPermission @defaultParam -Permissions $FeedPermissions
        }
    }
    catch
    {
        Write-Error $_
    }
    
    if ($PassThru)
    {
        Get-LabTfsFeed -ComputerName $ComputerName -FeedName $FeedName
    }
}

function Get-LabTfsFeed
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ComputerName,

        [string]
        $FeedName
    )
    
    $lab = Get-Lab
    $tfsVm = Get-LabVM -ComputerName $computerName
    $role = $tfsVm.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps'
    $initialCollection = 'AutomatedLab'
    $tfsPort = $originalPort = 8080
    $tfsInstance = $tfsVm.FQDN

    if ($role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and -not ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment))
    {
        $tfsPort = (Get-LWAzureLoadBalancedPort -DestinationPort $tfsPort -ComputerName $tfsVm -ErrorAction SilentlyContinue).FrontendPort

        if (-not $tfsPort)
        {
            Write-Error -Message 'There has been an error setting the Azure port during TFS installation. Cannot continue rolling out release pipeline'
            return
        }

        $tfsInstance = $tfsVm.AzureConnectionInfo.DnsName
    }

    if ($role.Properties.ContainsKey('InitialCollection'))
    {
        $initialCollection = $role.Properties['InitialCollection']
    }

    if ($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment)
    {
        $tfsInstance = 'dev.azure.com'
        $initialCollection = $role.Properties['Organisation']
        $accessToken = $role.Properties['PAT']
    }

    $credential = $tfsVm.GetCredential((Get-Lab))
    $useSsl = $tfsVm.InternalNotes.ContainsKey('CertificateThumbprint')
    
    $defaultParam = @{
        InstanceName         = $tfsInstance
        Port                 = $tfsPort
        CollectionName       = $initialCollection
        FeedName             = $FeedName
        UseSsl               = $useSsl
        SkipCertificateCheck = $true
        ApiVersion           = '5.0-preview.1'
    }

    if ($accessToken)
    {
        $defaultParam.PersonalAccessToken = $accessToken
    }
    elseif ($credential)
    {
        $defaultParam.Credential = $credential
    }
    else
    {
        Write-ScreenInfo -Type Error -Message 'Neither Credential nor AccessToken are available. Unable to continue'
        return
    }
    
    $feed = Get-TfsFeed @defaultParam
    if ($feed.url -match '(?<url>http.*)\/_apis')
    {
        $nugetV2Url = '{0}/_packaging/{1}/nuget/v2' -f $Matches.url, $feed.name
        $feed | Add-Member -Name NugetV2Url -MemberType NoteProperty $nugetV2Url
        
        $feed | Add-Member -Name NugetCredential -MemberType NoteProperty ($tfsVm.GetCredential($lab))
        
        $nugetApiKey = '{0}@{1}:{2}' -f $feed.NugetCredential.GetNetworkCredential().UserName, $feed.NugetCredential.GetNetworkCredential().Domain, $feed.NugetCredential.GetNetworkCredential().Password
        $feed | Add-Member -Name NugetApiKey -MemberType NoteProperty -Value $nugetApiKey
    }
    
    $feed
}
#endregion
