#region Lab-specific functionality
function Install-LabTeamFoundationEnvironment
{
    [CmdletBinding()]
    param
    ( )

    $tfsMachines = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018
    $lab = Get-Lab
    $jobs = @()

    foreach ($machine in $tfsMachines)
    {
        Dismount-LabIsoImage -ComputerName $machine -SupressOutput

        $role = $machine.Roles | Where-Object Name -like Tfs*
        $isoPath = ($lab.Sources.ISOs | Where-Object Name -eq $role.Name).Path

        $retryCount = 3
        $autoLogon = (Test-LabAutoLogon -ComputerName $machine)[$machine.Name]
        while (-not $autoLogon -and $retryCount -gt 0)
        {
            Set-LabAutoLogon -ComputerName $machine
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

    Wait-LWLabJob -Job $jobs

    Restart-LabVm -ComputerName $tfsMachines -Wait

    Install-LabTeamFoundationServer

    Install-LabBuildWorker
}

function Install-LabTeamFoundationServer
{
    [CmdletBinding()]
    param
    ( )

    $tfsMachines = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018 | Sort-Object {($_.Roles | Where-Object Name -like Tfs????).Name} -Descending
    [string]$sqlServer = Get-LabVm -Role SQLServer2016, SQLServer2017 | Select-Object -First 1
    
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
        if ( Get-LabIssuingCA)
        {
            $cert = Request-LabCertificate -Subject "CN=$machine" -TemplateName WebServer -ComputerName $machine -PassThru -ErrorAction Stop
            $machine.InternalNotes.Add('CertificateThumbprint', $cert.Thumbprint)
            Export-Lab
        }

        $role = $machine.Roles | Where-Object Name -like Tfs????
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
            if (-not (Get-LabAzureLoadBalancedPort -ComputerName $machine))
            {
                Add-LWAzureLoadBalancedPort -ComputerName $machine
            }

            $tfsPort = Get-LabAzureLoadBalancedPort -ComputerName $machine
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
            $tfsConfigPath = (Get-ChildItem -Path "$env:ProgramFiles\*Team Foundation*" -Filter tfsconfig.exe -Recurse | Select-Object -First 1).FullName
            if (-not $tfsConfigPath) { throw 'tfsconfig.exe could not be found.'}

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
            
            $content = $content -replace 'webSiteVDirName=.+', 'webSiteVDirName='
            $content = $content -replace 'CollectionName=.+', ('CollectionName={0}' -f $initialCollection)
            $content = $content -replace 'CollectionDescription=.+', 'CollectionDescription=Built by AutomatedLab, your friendly lab automation solution'
            $content = $content -replace 'WebSitePort=.+', ('WebSitePort={0}' -f $tfsPort) # Plain TFS 2015
            $content = $content -replace 'UrlHostNameAlias=.+', ('UrlHostNameAlias={0}' -f $machineName) # Plain TFS 2015
            
            [System.IO.File]::WriteAllText($config, $content)

            $command = "unattend /unattendfile:`"$config`" /continue"
            $configurationProcess = Start-Process -FilePath $tfsConfigPath -ArgumentList $command -PassThru -NoNewWindow -Wait

            if ($configurationProcess.ExitCode -ne 0)
            {
                throw ('Something went wrong while applying the unattended configuration {0}. Try {1} {2} manually.' -f $config, $tfsConfigPath, $command )
            }
        } -Variable (Get-Variable sqlServer, machineName, InitialCollection, tfsPort, databaseLabel, cert) -AsJob -ActivityName "Setting up TFS server $machine" -PassThru -NoDisplay
    }

    Wait-LWLabJob -Job $installationJobs
}
function Install-LabBuildWorker
{
    [CmdletBinding()]
    param
    ( )

    $buildWorkers = Get-LabVm -Role TfsBuildWorker

    $buildWorkerUri = (Get-Module AutomatedLab -ListAvailable)[0].PrivateData["BuildAgentUri"]
    $buildWorkerPath = Join-Path -Path $labsources -ChildPath Tools\TfsBuildWorker.zip
    $download = Get-LabInternetFile -Uri $buildWorkerUri -Path $buildWorkerPath -PassThru
    Copy-LabFileItem -ComputerName $buildWorkers -Path $download.Path

    $installationJobs = @()
    foreach ( $machine in $buildWorkers)
    {
        $role = $machine.Roles | Where-Object Name -eq TfsBuildWorker
        $tfsPort = 8080
        $tfsServer = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018 | Select-Object -First 1

        if ($role.Properties.ContainsKey('TfsServer'))
        {
            $tfsServer = Get-LabVm -ComputerName $role.Properties['TfsServer'] -ErrorAction SilentlyContinue
            if (-not $tfsServer)
            {
                Write-ScreenInfo -Message "No TFS server called $($role.Properties['TfsServer']) found in lab." -NoNewLine -Type Warning
                $tfsServer = Get-LabVM -Role Tfs2015, Tfs2017, Tfs2018 | Select-Object -First 1
                Write-ScreenInfo -Message " Selecting $tfsServer instead." -Type Warning
            }

            $tfsRole = $tfsServer.Roles | Where-Object Name -like 'Tfs????'
            if ($tfsRole.Properties.ContainsKey('Port'))
            {
                $tfsPort = $tfsRole.Properties['Port']
            }
        }

        $useSsl = $tfsServer.InternalNotes.ContainsKey('CertificateThumbprint')

        $installationJobs += Invoke-LabCommand -ComputerName $machine -ScriptBlock {

            if (-not (Test-Path C:\TfsBuildWorker.zip)) {throw 'Build worker installation files not available'}

            Expand-Archive -Path C:\TfsBuildWorker.zip -DestinationPath C:\BuildWorkerSetupFiles -Force
            $configurationTool = Get-Item C:\BuildWorkerSetupFiles\config.cmd -ErrorAction Stop

            $commandLine = if ($useSsl)
            {
                '--unattended --url https://{0}:{1} --auth Integrated --pool default --agent {2} --runasservice' -f $tfsServer, $tfsPort, $env:COMPUTERNAME
            }
            else
            {
                '--unattended --url http://{0}:{1} --auth Integrated --pool default --agent {2} --runasservice' -f $tfsServer, $tfsPort, $env:COMPUTERNAME
            }

            $configurationProcess = Start-Process -FilePath $configurationTool -ArgumentList $commandLine -Wait -NoNewWindow -PassThru

            if ($configurationProcess.ExitCode -ne 0)
            {
                Write-ScreenInfo -Message "Build worker $env:COMPUTERNAME failed to install. Exit code was $($configurationProcess.ExitCode)" -Type Warning
            }
        } -AsJob -Variable (Get-Variable tfsServer, tfsPort, useSsl) -ActivityName "Setting up build agent $machine" -PassThru -NoDisplay
    }

    Wait-LWLabJob -Job $installationJobs
}
#endregion

#region TFS-specific functionality
function New-LabReleasePipeline
{
    param
    (
        [string]
        $ProjectName = 'ALSampleProject',

        [string]
        $SourceRepository,

        [string]
        $ComputerName,

        [hashtable[]]
        $BuildSteps,

        [Parameter()]
        [hashtable[]]
        $ReleaseSteps
    )

    if (-not (Get-Lab -ErrorAction SilentlyContinue))
    {
        throw 'No lab imported. Please use Import-Lab to import the target lab containing at least one TFS server'
    }

    $tfsvm = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018 | Select-Object -First 1

    if ($ComputerName)
    {
        $tfsVm = Get-LabVm -ComputerName $ComputerName
    }

    if (-not $tfsvm) { throw ('No TFS VM in lab or no machine found with name {0}' -f $ComputerName)}

    $locallabsources = Get-LabSourcesLocationInternal -Local
    
    $role = $tfsVm.Roles | Where-Object Name -like Tfs????
    $initialCollection = 'AutomatedLab'
    $tfsPort = 8080
    $tfsInstance = $tfsvm.FQDN
    
    if ($role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        if (-not (Get-LabAzureLoadBalancedPort -ComputerName $tfsvm))
        {
            Add-LWAzureLoadBalancedPort -ComputerName $tfsVm
        }
        $originalPort = $tfsPort
        $tfsPort = Get-LabAzureLoadBalancedPort -ComputerName $tfsvm
        $tfsInstance = $tfsvm.AzureConnectionInfo.DnsName
    }

    if ($role.Properties.ContainsKey('InitialCollection'))
    {
        $initialCollection = $role.Properties['InitialCollection']
    }

    $credential = $tfsVm.GetCredential((Get-Lab))
    $useSsl = $tfsVm.InternalNotes.ContainsKey('CertificateThumbprint')
    
    $gitBinary = if (Get-Command git) {(Get-Command git).Source}elseif (Test-Path $locallabsources\Tools\git.exe) {"$locallabsources\Tools\git.exe"}

    if (-not $gitBinary)
    {
        Write-ScreenInfo -Message 'Git is not installed. We will not push any code to the remote repository'
    }

    $project = New-TfsProject -InstanceName $tfsInstance -Port $tfsPort -CollectionName $initialCollection -ProjectName $ProjectName -Credential $credential -UseSsl:$useSsl -SourceControlType Git -TemplateName 'Agile' -Timeout (New-TimeSpan -Minutes 5)

    if ($gitBinary)
    {
        $repository = Get-TfsGitRepository -InstanceName $tfsInstance -Port $tfsPort -CollectionName $initialCollection -ProjectName $ProjectName -Credential $credential -UseSsl:$useSsl
        $repoUrl = $repository.remoteUrl.Insert($repository.remoteUrl.IndexOf('/') + 2, '{0}:{1}@')

        if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
        {
            $repoUrl = $repoUrl -replace ":$originalPort",":$tfsPort"
            $repoUrl = $repoUrl -replace $tfsvm.Name, $tfsvm.AzureConnectionInfo.DnsName
        }
        
        $repoUrl = $repoUrl -f $credential.GetNetworkCredential().UserName, $credential.GetNetworkCredential().Password

        Write-ScreenInfo -Type Verbose -Message "Generated repo url $repoUrl"

        $repoparent = Join-Path -Path $locallabsources -ChildPath GitRepositories
        if (-not (Test-Path $repoparent))
        {
            Write-ScreenInfo -Type Verbose -Message "Creating $repoparent to contain your cloned repos"
            [void] (New-Item -ItemType Directory -Path $repoparent)
        }

        $repositoryPath = Join-Path -Path $repoparent -ChildPath (Split-Path -Path $SourceRepository -Leaf)
        if (-not (Test-Path $repositoryPath))
        {
            Write-ScreenInfo -Type Verbose -Message "Creating $repositoryPath to contain your cloned repo"
            [void] (New-Item -ItemType Directory -Path $repositoryPath)
        }

        Push-Location        
        Set-Location $repositoryPath

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
                $errorFile = [System.IO.Path]::GetTempFileName()
                $cloneResult = Start-Process -FilePath $gitBinary -ArgumentList @('clone', $SourceRepository, $repositoryPath, '--quiet') -Wait -NoNewWindow -PassThru -RedirectStandardError $errorFile

                if ($cloneResult.ExitCode -ne 0)
                {
                    Write-ScreenInfo -Type Warning -Message "Could not clone from $SourceRepository. Git returned: $(Get-Content -Path $errorFile)"
                }
            }
            finally
            {
                Remove-Item -Path $errorFile -Force -ErrorAction SilentlyContinue
            }

            Start-Process -FilePath $gitBinary -ArgumentList @('remote', 'add', 'tfs', $repoUrl) -Wait -NoNewWindow            
        }
        
        try
        {
            $errorFile = [System.IO.Path]::GetTempFileName()
            $pushResult = Start-Process -FilePath $gitBinary @('-c', 'http.sslVerify=false', 'push', 'tfs', '--all', '--quiet') -Wait -NoNewWindow -PassThru -RedirectStandardError $errorFile

            if ($pushResult.ExitCode -ne 0)
            {
                Write-ScreenInfo -Type Warning -Message "Could not push to $repoUrl. Git returned: $(Get-Content -Path $errorFile)"
            }
        }
        finally
        {
            Remove-Item -Path $errorFile -Force -ErrorAction SilentlyContinue
        }
        
        Write-ScreenInfo -Type Verbose -Message ('Pushed code from {0} to remote {1}' -f $SourceRepository, $repoUrl)

        Pop-Location
    }

    $parameters = @{
        InstanceName   = $tfsInstance
        Port           = $tfsPort
        CollectionName = $initialCollection
        ProjectName    = $ProjectName
        Credential     = $credential
        UseSsl         = $useSsl
    }

    $buildParameters = $parameters.Clone()
    $releaseParameters = $parameters.Clone()
    $buildParameters.DefinitionName = 'ALBuild'
    if ($BuildSteps.Count -gt 0)
    {
        $buildParameters.BuildTasks = $BuildSteps
    }
    
    $releaseParameters.ReleaseName = $ProjectName
    if ($ReleaseSteps.Count -gt 0)
    {
        $releaseParameters.ReleaseTasks = $ReleaseSteps
    }

    New-TfsBuildDefinition @buildParameters
    New-TfsReleaseDefinition @releaseParameters
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

    $tfsvm = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018 | Select-Object -First 1
    $useSsl = $tfsVm.InternalNotes.ContainsKey('CertificateThumbprint')

    if ($ComputerName)
    {
        $tfsVm = Get-LabVm -ComputerName $ComputerName
    }

    if (-not $tfsvm) { throw ('No TFS VM in lab or no machine found with name {0}' -f $ComputerName)}
    
    $role = $tfsVm.Roles | Where-Object Name -like Tfs????
    $initialCollection = 'AutomatedLab'
    $tfsPort = 8080
    $tfsInstance = $tfsvm.FQDN
    
    if ($role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        if (-not (Get-LabAzureLoadBalancedPort -ComputerName $tfsvm))
        {
            Add-LWAzureLoadBalancedPort -ComputerName $tfsVm
        }

        $tfsPort = Get-LabAzureLoadBalancedPort -ComputerName $tfsvm
        $tfsInstance = $tfsvm.AzureConnectionInfo.DnsName
    }

    if ($role.Properties.ContainsKey('InitialCollection'))
    {
        $initialCollection = $role.Properties['InitialCollection']
    }

    $credential = $tfsVm.GetCredential((Get-Lab))
    
    return (Get-TfsBuildStep -InstanceName $tfsInstance -CollectionName $initialCollection -Credential $credential -UseSsl:$useSsl -Port $tfsPort)
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

    $tfsvm = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018 | Select-Object -First 1
    $useSsl = $tfsVm.InternalNotes.ContainsKey('CertificateThumbprint')

    if ($ComputerName)
    {
        $tfsVm = Get-LabVm -ComputerName $ComputerName
    }

    if (-not $tfsvm) { throw ('No TFS VM in lab or no machine found with name {0}' -f $ComputerName)}
    
    $role = $tfsVm.Roles | Where-Object Name -like Tfs????
    $initialCollection = 'AutomatedLab'
    $tfsPort = 8080
    $tfsInstance = $tfsvm.FQDN
    
    if ($role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        if (-not (Get-LabAzureLoadBalancedPort -ComputerName $tfsvm))
        {
            Add-LWAzureLoadBalancedPort -ComputerName $tfsVm
        }

        $tfsPort = Get-LabAzureLoadBalancedPort -ComputerName $tfsvm
        $tfsInstance = $tfsvm.AzureConnectionInfo.DnsName
    }

    if ($role.Properties.ContainsKey('InitialCollection'))
    {
        $initialCollection = $role.Properties['InitialCollection']
    }

    $credential = $tfsVm.GetCredential((Get-Lab))
    
    return (Get-TfsReleaseStep -InstanceName $tfsInstance -CollectionName $initialCollection -Credential $credential -UseSsl:$useSsl -Port $tfsPort)
}

function Open-LabTfsSite
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

    $tfsvm = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018 | Select-Object -First 1
    $useSsl = $tfsVm.InternalNotes.ContainsKey('CertificateThumbprint')

    if ($ComputerName)
    {
        $tfsVm = Get-LabVm -ComputerName $ComputerName
    }

    if (-not $tfsvm) { throw ('No TFS VM in lab or no machine found with name {0}' -f $ComputerName)}
    
    $role = $tfsVm.Roles | Where-Object Name -like Tfs????
    $initialCollection = 'AutomatedLab'
    $tfsPort = 8080
    $tfsInstance = $tfsvm.FQDN
    $credential = $tfsVm.GetCredential((Get-Lab))
    
    if ($role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        if (-not (Get-LabAzureLoadBalancedPort -Port $tfsPort -ComputerName $tfsvm))
        {
            Add-LWAzureLoadBalancedPort -Port $tfsPort -ComputerName $tfsVm
        }

        $tfsPort = Get-LabAzureLoadBalancedPort -Port $tfsPort -ComputerName $tfsvm
        $tfsInstance = $tfsvm.AzureConnectionInfo.DnsName
    }

    $requestUrl = if ($UseSsl) 
    {
        'https://{0}:{1}@{2}:{3}' -f $credential.GetNetworkCredential().UserName, $credential.GetNetworkCredential().Password, $tfsInstance, $tfsPort
    } 
    else
    {
        'http://{0}:{1}@{2}:{3}' -f $credential.GetNetworkCredential().UserName, $credential.GetNetworkCredential().Password, $tfsInstance, $tfsPort
    }
    
    Start-Process -FilePath $requestUrl
}
#endregion
