<#
0 - SQL Server
1 - TFS Server
2 - Initial collection name
3 - Port
#>
$tfsConfiguration = @"
[Configuration]
Activity=Microsoft.TeamFoundation.Admin.ServerConfigurationActivity
Assembly=Microsoft.TeamFoundation.Admin, Version=15.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a
Scenario=NewServerAdvanced
SqlInstance={0}
UseExistingEmptyDatabase=False
CreateConfigurationDatabase=True
DatabaseLabel=
StartTrial=False
IsServiceAccountBuiltIn=True
ServiceAccountName=NT AUTHORITY\NETWORK SERVICE
UrlHostNameAlias={1}
WebSiteVDirName=tfs
SiteBindings=http:*:{3}:
PublicUrl=http://{1}:{3}/tfs
FileCacheFolder=C:\TfsData\ApplicationTier\_fileCache
SmtpEmailEnabled=False
EnableSshService=True
SshPort=22
UseReporting=False
UseWss=False
ConfigureSearch=False
InstallSearchService=True
CreateInitialCollection=True
CollectionName={2}
CollectionDescription=Built by AutomatedLab, your friendly lab automation solution
"@

<#
0 - Number of build agents
1 - Build machine
2 - TFS
3 - TFS web site port
4 - Build worker port
#>
$buildWorkerConfiguration = @"
[Configuration]
Activity=Microsoft.TeamFoundation.Admin.TeamBuildActivity
Assembly=Microsoft.TeamFoundation.Admin, Version=15.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a
AcknowledgedDeprecated=False
ConfigurationType=Create
AgentCount={0}
NewControllerName={1} - Controller
CleanResources=False
CollectionUrl=http://{2}:{3}/tfs
IsServiceAccountBuiltIn=True
ServiceAccountName=NT AUTHORITY\NETWORK SERVICE
Port={4}
MaxConcurrentBuilds=0
"@

function Install-LabTeamFoundationEnvironment
{
    [CmdletBinding()]
    param
    ( )

    $tfsMachines = Get-LabVm -Role Tfs2015, Tfs2017, TfsBuildWorker
    
    $jobs = @()

    foreach ($machine in $tfsMachines)
    {
        Dismount-LabIsoImage -ComputerName $machine -SupressOutput

        $role = $machine.Roles | Where-Object Name -like Tfs????

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

        Mount-LabIsoImage -ComputerName $machine -IsoPath ($lab.Sources.ISOs | Where-Object Name -eq $role.Name).Path -SupressOutput        

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
        } -Variable (Get-Variable drive) -AsJob
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

    $tfsMachines = Get-LabVm -Role Tfs2015, Tfs2017
    $sqlServer = Get-LabVm -Role SQLServer2016, SQLServer2017

    $installationJobs = @()

    foreach ( $machine in $tfsMachines)
    {
        $role = $machine.Roles | Where-Object Name -like Tfs????
        $initialCollection = 'AutomatedLab'
        $tfsPort = 8080
    
        if ($role.Properties.ContainsKey('InitialCollection'))
        {
            $initialCollection = $role.Properties['InitialCollection']
        }

        if ($role.Properties.ContainsKey('Port'))
        {
            $tfsPort = $role.Properties['Port']
        }

        $targetConfiguration = $tfsConfiguration -f $sqlServer, $machine, $initialCollection, $tfsPort

        $installationJobs += Invoke-LabCommand -ComputerName $machine -ScriptBlock {
            $tfsConfigPath = (Get-ChildItem -Path "$env:ProgramFiles\*Team Foundation*" -Filter tfsconfig.exe -Recurse | Select-Object -First 1).FullName
            if (-not $tfsConfiguration) { throw 'tfsconfig.exe could not be found.'}

            $config = (New-Item -Path C:\DeployDebug\TfsConfig.ini -Force).FullName
            Set-Content -Path $config -Value $targetConfiguration -Encoding UTF8

            & $tfsConfigPath "unattend /configure /unattendfile:$config"
        } -Variable (Get-Variable targetConfiguration) -AsJob:$AsJob
    }
}

Wait-LWLabJob -Job $installationJobs
}

function Install-LabBuildWorker
{
    [CmdletBinding()]
    param
    ( )

    <#
0 - Number of build agents
1 - Build machine
2 - TFS
3 - TFS web site port
4 - Build worker port
#>

    $buildWorkers = Get-LabVm -Roles TfsBuildWorker
    $tfsServer = Get-LabVm -Roles Tfs2015, Tfs2017
    $tfsPort = 8080

    $role = $buildWorker.Roles | Where-Object Name -eq TfsBuildWorker
    if ($role.Properties.ContainsKey('Port'))
    {
        $tfsPort = $role.Properties['Port']
    }
    
    $installationJobs = @()
    foreach ( $machine in $buildWorkers)
    {
        $role = $machine.Roles | Where-Object Name -eq TfsBuildWorker
        $buildAgentCount = 2
        $buildWorkerPort = 9090

        if ($role.Properties.ContainsKey('BuildAgentCount'))
        {
            $buildAgentCount = $role.Properties['BuildAgentCount']
        }

        if ($role.Properties.ContainsKey('Port'))
        {
            $buildWorkerPort = $role.Properties['Port']
        }

        $targetConfiguration = $buildWorkerConfiguration -f $buildAgentCount, $buildWorker, $tfsServer, $tfsPort, $buildWorkerPort

        $installationJobs += Invoke-LabCommand -ComputerName $machine -ScriptBlock {
            $tfsConfigPath = (Get-ChildItem -Path "$env:ProgramFiles\*Team Foundation*" -Filter tfsconfig.exe -Recurse | Select-Object -First 1).FullName
            if (-not $tfsConfiguration) { throw 'tfsconfig.exe could not be found.'}

            $config = (New-Item -Path C:\DeployDebug\TfsBuildWorker.ini -Force).FullName
            Set-Content -Path $config -Value $targetConfiguration -Encoding UTF8

            & $tfsConfigPath "unattend /configure /unattendfile:$config"
        } -AsJob -Variable (Get-Variable targetConfiguration)
    }
}
