function Install-LabTeamFoundationServer
{
    [CmdletBinding()]
    param
    ( )

    $tfsMachines = Get-LabVM -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Where-Object SkipDeployment -eq $false | Sort-Object { ($_.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps').Name } -Descending
    if (-not $tfsMachines) { return }

    # Assign unassigned build workers to our most current TFS machine
    Get-LabVM -Role TfsBuildWorker | Where-Object {
        -not ($_.Roles | Where-Object Name -eq TfsBuildWorker).Properties.ContainsKey('TfsServer')
    } | ForEach-Object {
        ($_.Roles | Where-Object Name -eq TfsBuildWorker).Properties.Add('TfsServer', $tfsMachines[0].Name)
    }

    $jobs = Install-LabWindowsFeature -ComputerName $tfsMachines -FeatureName Web-Mgmt-Tools -AsJob
    Write-ScreenInfo -Message 'Waiting for installation of IIS web admin tools to complete' -NoNewline
    Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -Timeout $InstallationTimeout -NoDisplay

    $installationJobs = @()
    $count = 0
    foreach ($machine in $tfsMachines)
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
            'Tfs2015' { Get-LabVM -Role SQLServer2014 | Select-Object -First 1 }
            'Tfs2017' { Get-LabVM -Role SQLServer2014, SQLServer2016 | Select-Object -First 1 }
            'Tfs2018|AzDevOps' { Get-LabVM -Role SQLServer2017, SQLServer2019 | Select-Object -First 1 }
            default { throw 'No fitting SQL Server found in lab!' }
        }
        
        if (-not $sqlServer)
        {
            Write-Error 'No fitting SQL Server found in lab for TFS / Azure DevOps role.' -ErrorAction Stop
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
            [string]$sqlServer = Get-LabVM -ComputerName $role.Properties['DbServer'] -ErrorAction SilentlyContinue

            if (-not $sqlServer)
            {
                Write-ScreenInfo -Message "No SQL server called $($role.Properties['DbServer']) found in lab." -NoNewLine -Type Warning
                [string]$sqlServer = Get-LabVM -Role SQLServer2016, SQLServer2017, SQLServer2019 | Select-Object -First 1
                Write-ScreenInfo -Message " Selecting $sqlServer instead." -Type Warning
            }
        }

        if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
        {
            # For good luck, disable the firewall again - in case Invoke-AzVmRunCommand failed to do its job.
            Invoke-LabCommand -ComputerName $machine, $sqlServer -NoDisplay -ScriptBlock { Set-NetFirewallProfile -All -Enabled False -PolicyStore PersistentStore }
        }

        Restart-LabVM -ComputerName $machine -Wait -NoDisplay

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
        } -Variable (Get-Variable sqlServer, machineName, InitialCollection, tfsPort, databaseLabel, cert -ErrorAction SilentlyContinue) -AsJob -ActivityName "TFS_Setup_$machine" -PassThru -NoDisplay
    }

    Write-ScreenInfo -Type Verbose -Message "Waiting for the installation of TFS on $tfsMachines to finish."

    Wait-LWLabJob -Job $installationJobs

    foreach ($job in $installationJobs)
    {
        $name = $job.Name.Replace('TFS_Setup_','')
        $type = if ($job.State -eq 'Completed') { 'Verbose' } else { 'Error' }
        $resultVariable = New-Variable -Name ("AL_TFSServer_$($name)_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
        Write-ScreenInfo -Type $type -Message "TFS Deployment $($job.State.ToLower()) on '$($name)'. The job output of $job can be retrieved with `${$($resultVariable.Name)}"
        $resultVariable.Value = $job | Receive-Job -AutoRemoveJob -Wait
    }
}
