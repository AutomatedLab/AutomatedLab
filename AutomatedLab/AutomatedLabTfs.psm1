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

        $role = $machine.Roles | Where-Object Name -Match 'TFS\d{4}'
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
        if (Get-LabIssuingCA)
        {
            $cert = Request-LabCertificate -Subject "CN=$machine" -TemplateName WebServer -SAN $machine.AzureConnectionInfo.DnsName -ComputerName $machine -PassThru -ErrorAction Stop
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
            $machineName = $machine.AzureConnectionInfo.DnsName

            if ($role.Properties.ContainsKey('Port'))
            {
                $machine.Roles.Where( {$_.Name -like 'TFS????'}).ForEach( {$_.Properties['Port'] = $tfsPort})
            }
            else
            {
                $machine.Roles.Where( {$_.Name -like 'TFS????'}).ForEach( {$_.Properties.Add('Port', $tfsPort)})
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
        } -Variable (Get-Variable sqlServer, machineName, InitialCollection, tfsPort, databaseLabel, cert -ErrorAction SilentlyContinue) -AsJob -ActivityName "Setting up TFS server $machine" -PassThru -NoDisplay
    }

    Wait-LWLabJob -Job $installationJobs
}
function Install-LabBuildWorker
{
    [CmdletBinding()]
    param
    ( )

    $buildWorkers = Get-LabVm -Role TfsBuildWorker

    $buildWorkerUri = Get-LabConfigurationItem -Name BuildAgentUri
    $buildWorkerPath = Join-Path -Path $labsources -ChildPath Tools\TfsBuildWorker.zip
    $download = Get-LabInternetFile -Uri $buildWorkerUri -Path $buildWorkerPath -PassThru -Force
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

        [string]$machineName = $tfsServer

        if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
        {
            $tfsPort = Get-LabAzureLoadBalancedPort -Port $tfsPort -ComputerName $tfsServer -ErrorAction SilentlyContinue

            if (-not $tfsPort)
            {
                Write-Error -Message 'There has been an error setting the Azure port during TFS installation. Cannot continue installing build worker.'
                return
            }
            $machineName = $tfsServer.AzureConnectionInfo.DnsName
        }

        $useSsl = $tfsServer.InternalNotes.ContainsKey('CertificateThumbprint')

        $installationJobs += Invoke-LabCommand -ComputerName $machine -ScriptBlock {

            if (-not (Test-Path C:\TfsBuildWorker.zip)) {throw 'Build worker installation files not available'}

            Microsoft.PowerShell.Archive\Expand-Archive -Path C:\TfsBuildWorker.zip -DestinationPath C:\BuildWorkerSetupFiles -Force
            $configurationTool = Get-Item C:\BuildWorkerSetupFiles\config.cmd -ErrorAction Stop

            $commandLine = if ($useSsl)
            {
				#sslskipcertvalidation is used as git.exe could not test the certificate chain
                '--unattended --url https://{0}:{1} --auth Integrated --pool default --agent {2} --runasservice --sslskipcertvalidation --gituseschannel' -f $machineName, $tfsPort, $env:COMPUTERNAME
            }
            else
            {
                '--unattended --url http://{0}:{1} --auth Integrated --pool default --agent {2} --runasservice --gituseschannel' -f $machineName, $tfsPort, $env:COMPUTERNAME
            }

            $configurationProcess = Start-Process -FilePath $configurationTool -ArgumentList $commandLine -Wait -NoNewWindow -PassThru

            if ($configurationProcess.ExitCode -ne 0)
            {
                Write-ScreenInfo -Message "Build worker $env:COMPUTERNAME failed to install. Exit code was $($configurationProcess.ExitCode)" -Type Warning
            }
        } -AsJob -Variable (Get-Variable machineName, tfsPort, useSsl) -ActivityName "Setting up build agent $machine" -PassThru -NoDisplay
    }

    Wait-LWLabJob -Job $installationJobs
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

    $tfsVm = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018 | Select-Object -First 1

    if ($ComputerName)
    {
        $tfsVm = Get-LabVm -ComputerName $ComputerName
    }

    if (-not $tfsVm) { throw ('No TFS VM in lab or no machine found with name {0}' -f $ComputerName)}

    $localLabSources = Get-LabSourcesLocationInternal -Local
  
    $role = $tfsVm.Roles | Where-Object Name -like Tfs????
    $initialCollection = 'AutomatedLab'
    $tfsPort = 8080
    $tfsInstance = $tfsVm.FQDN
  
    if ($role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }

    if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        $tfsPort = Get-LabAzureLoadBalancedPort -Port $tfsPort -ComputerName $tfsVm -ErrorAction SilentlyContinue

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

    $credential = $tfsVm.GetCredential((Get-Lab))
    $useSsl = $tfsVm.InternalNotes.ContainsKey('CertificateThumbprint')
  
    $gitBinary = if (Get-Command git) { (Get-Command git).Source } elseif (Test-Path -Path $localLabSources\Tools\git.exe) { "$localLabSources\Tools\git.exe" }
    if (-not $gitBinary)
    {
        Write-ScreenInfo -Message 'Git is not installed. We are not be able to push any code to the remote repository and cannot proceed. Please install Git'
        return
    }

    $project = New-TfsProject -InstanceName $tfsInstance -Port $tfsPort -CollectionName $initialCollection -ProjectName $ProjectName -Credential $credential -UseSsl:$useSsl -SourceControlType Git -TemplateName 'Agile' -Timeout (New-TimeSpan -Minutes 5)
    $repository = Get-TfsGitRepository -InstanceName $tfsInstance -Port $tfsPort -CollectionName $initialCollection -ProjectName $ProjectName -Credential $credential -UseSsl:$useSsl
  
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
      
        Invoke-LabCommand -ActivityName 'Clone local repo' -ComputerName $tfsVm -ScriptBlock {
            if (-not (Test-Path -Path C:\Git))
            {
                mkdir -Path C:\Git | Out-Null
            }
            Set-Location -Path C:\Git
            git -c http.sslVerify=false clone $repository.remoteUrl 2>&1
        } -Variable (Get-Variable -Name repository, ProjectName)
      
        if ($repositoryPath)
        {
            Copy-LabFileItem -Path $repositoryPath\* -ComputerName $tfsVm -DestinationFolderPath "C:\$ProjectName.temp"
        }
        else
        {
            Copy-LabFileItem -Path $SourcePath\* -ComputerName $tfsVm -DestinationFolderPath "C:\$ProjectName.temp"
        }
      
        Invoke-LabCommand -ActivityName 'Remove .git folder' -ComputerName $tfsVm -ScriptBlock {
            Set-Location -Path C:\Git\$ProjectName
            Copy-Item -Path "C:\$ProjectName.temp\*" -Destination . -Recurse -Exclude .git
          
            git checkout -b master 2>&1
            git add . 2>&1
            git commit -m 'Initial' 2>&1
            git push 2>&1

            git checkout -b dev 2>&1
            git push --set-upstream origin dev 2>&1
          
            Set-Location -Path C:\
            Remove-Item -Path "C:\$ProjectName.temp" -Recurse -Force
        } -Variable (Get-Variable -Name repository, ProjectName)
    }

    $parameters = @{
        InstanceName   = $tfsInstance
        Port           = $tfsPort
        CollectionName = $initialCollection
        ProjectName    = $ProjectName
        Credential     = $credential
        UseSsl         = $useSsl
    }

    if ($BuildSteps.Count -gt 0)
    {
        $buildParameters = $parameters.Clone()
        $buildParameters.DefinitionName = "$($ProjectName)Build"
        $buildParameters.BuildTasks = $BuildSteps
        New-TfsBuildDefinition @buildParameters
    }
  
    if ($ReleaseSteps.Count -gt 0)
    {
        $releaseParameters = $parameters.Clone()
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
        $loadbalancedPort = Get-LabAzureLoadBalancedPort -Port $tfsPort -ComputerName $tfsVm -ErrorAction SilentlyContinue

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
        $loadbalancedPort = Get-LabAzureLoadBalancedPort -Port $tfsPort -ComputerName $tfsvm -ErrorAction SilentlyContinue

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
        $loadbalancedPort = Get-LabAzureLoadBalancedPort -Port $tfsPort -ComputerName $tfsvm -ErrorAction SilentlyContinue

        if (-not $loadbalancedPort)
        {
            Write-Error -Message 'There has been an error setting the Azure port during TFS installation. Cannot open TFS site.'
            return
        }
      
        $tfsPort = $loadbalancedPort
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
