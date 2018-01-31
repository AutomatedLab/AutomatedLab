function Install-LabTeamFoundationEnvironment
{
    [CmdletBinding()]
    param
    ( )

    $tfsMachines = Get-LabVm -Role Tfs2015, Tfs2017
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

    Install-LabTeamFoundationServer

    Install-LabBuildWorker
}

function Install-LabTeamFoundationServer
{
    [CmdletBinding()]
    param
    ( )

    $tfsMachines = Get-LabVm -Role Tfs2015, Tfs2017 | Sort-Object {($_.Roles | Where-Object Name -like Tfs????).Name} -Descending
    [string]$sqlServer = Get-LabVm -Role SQLServer2016, SQLServer2017 | Select-Object -First 1
    
    # Assign unassigned build workers to our most current TFS machine
    Get-LabVm -Role TfsBuildWorker | Where-Object {
        -not ($_.Roles | Where-Object Name -eq TfsBuildWorker).Properties.ContainsKey('TfsServer')
    } | ForEach-Object {
        ($_.Roles | Where-Object Name -eq TfsBuildWorker).Properties.Add('TfsServer', $tfsMachines[0].Name)
    }

    $installationJobs = @()
    $count = 0
    foreach ( $machine in $tfsMachines)
    {
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

        if ($role.Properties.ContainsKey('DbServer'))
        {
            [string]$sqlServer = Get-LabVm -ComputerName $role.Properties['DbServer'] -ErrorAction SilentlyContinue

            if (-not $sqlServer)
            {
                Write-ScreenInfo -Message "No SQL server called $($role.Properties['DbServer']) found in lab." -NoNewLine -Type Warning
                [string]$sqlServer = Get-LabMachine -Role SQLServer2016, SQLServer2017 | Select-Object -First 1
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
            $content = $content -replace 'SiteBindings=.+', ('SiteBindings=http:*:{0}:' -f $tfsPort)
            $content = $content -replace 'PublicUrl=.+', ('PublicUrl=http://{0}:{1}/tfs' -f $machineName, $tfsPort)
            $content = $content -replace 'PublicUrl=.+', ('PublicUrl=http://{0}:{1}/tfs' -f $machineName, $tfsPort)
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
        } -Variable (Get-Variable sqlServer, machineName, InitialCollection, tfsPort, databaseLabel) -AsJob -ActivityName "Setting up TFS server $machine" -PassThru -NoDisplay
    }

    Wait-LWLabJob -Job $installationJobs
}

function Install-LabBuildWorker
{
    [CmdletBinding()]
    param
    ( )

    $buildWorkers = Get-LabVm -Role TfsBuildWorker

    [void] (New-Item -Path (Join-Path -Path $labsources -ChildPath Tools\TFS) -ErrorAction SilentlyContinue -ItemType Directory)
    $buildWorkerUri = (Get-Module AutomatedLab -ListAvailable).PrivateData["BuildAgentUri"]
    $buildWorkerPath = Join-Path -Path $labsources -ChildPath Tools\TFS\TfsBuildWorker.zip
    Get-LabInternetFile -Uri $buildWorkerUri -Path $buildWorkerPath
    Copy-LabFileItem -ComputerName $buildWorkers -Path $buildWorkerPath

    $installationJobs = @()
    foreach ( $machine in $buildWorkers)
    {
        $role = $machine.Roles | Where-Object Name -eq TfsBuildWorker
        $tfsPort = 8080
        $tfsServer = Get-LabVm -Role Tfs2015, Tfs2017 | Select-Object -First 1

        if ($role.Properties.ContainsKey('TfsServer'))
        {
            $tfsServer = Get-LabVm -ComputerName $role.Properties['TfsServer'] -ErrorAction SilentlyContinue
            if (-not $tfsServer)
            {
                Write-ScreenInfo -Message "No TFS server called $($role.Properties['TfsServer']) found in lab." -NoNewLine -Type Warning
                $tfsServer = Get-LabMachine -Role Tfs2015, Tfs2017 | Select-Object -First 1
                Write-ScreenInfo -Message " Selecting $tfsServer instead." -Type Warning
            }

            $tfsRole = $tfsServer.Roles | Where-Object Name -like 'Tfs????'
            if ($tfsRole.Properties.ContainsKey('Port'))
            {
                $tfsPort = $tfsRole.Properties['Port']
            }
        }

        $installationJobs += Invoke-LabCommand -ComputerName $machine -ScriptBlock {

            if (-not (Test-Path C:\TfsBuildWorker.zip)) {throw 'Build worker installation files not available'}

            Expand-Archive -Path C:\TfsBuildWorker.zip -DestinationPath C:\BuildWorkerSetupFiles -Force
            $configurationTool = Get-Item C:\BuildWorkerSetupFiles\config.cmd -ErrorAction Stop

            $commandLine = '--unattended --url http://{0}:{1}/tfs --auth Integrated --pool default --agent {2} --runasservice' -f `
                $tfsServer, $tfsPort, $env:COMPUTERNAME
            $configurationProcess = Start-Process -FilePath $configurationTool -ArgumentList $commandLine -Wait -NoNewWindow -PassThru

            if ($configurationProcess.ExitCode -ne 0)
            {
                Write-Warning -Message "Build worker $env:COMPUTERNAME failed to install. Exit code was $($configurationProcess.ExitCode)"
            }
        } -AsJob -Variable (Get-Variable tfsServer, tfsPort) -ActivityName "Setting up build agent $machine" -PassThru -NoDisplay
    }

    Wait-LWLabJob -Job $installationJobs
}

function Open-LabTeamFoundationSite
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string[]]
        $ComputerName
    )

    $machines = Get-LabVm @PSBoundParameters

    foreach ( $machine in $machines)
    {
        $role = $machine.Roles | Where-Object Name -eq Tfs????
        $tfsPort = 8080
        if ($role.Properties.ContainsKey('Port'))
        {
            $tfsPort = $role.Properties['Port']
        }
        Start-Process ('http://{1}:{3}/tfs' -f $machine, $tfsPort)
    }
}
