function Install-LabBuildWorker
{
    [CmdletBinding()]
    param
    ( )

    $buildWorkers = Get-LabVM -Role TfsBuildWorker
    if (-not $buildWorkers)
    {
        return
    }

    $buildWorkerUri = Get-LabConfigurationItem -Name BuildAgentUri
    $buildWorkerPath = Join-Path -Path $labsources -ChildPath Tools\TfsBuildWorker.zip
    $download = Get-LabInternetFile -Uri $buildWorkerUri -Path $buildWorkerPath -PassThru
    Copy-LabFileItem -ComputerName $buildWorkers -Path $download.Path

    $installationJobs = @()
    foreach ($machine in $buildWorkers)
    {
        $role = $machine.Roles | Where-Object Name -eq TfsBuildWorker
        [int]$numberOfBuildWorkers = $role.Properties.NumberOfBuildWorkers
        $isOnDomainController = $machine -in (Get-LabVM -Role ADDS)
        $cred = $machine.GetLocalCredential()
        $tfsServer = Get-LabVM -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Select-Object -First 1

        $tfsPort = 8080
        $skipServerDuringTest = $false # We want to skip testing public Azure DevOps endpoints

        if ($role.Properties.ContainsKey('Organisation') -and $role.Properties.ContainsKey('PAT'))
        {
            Write-ScreenInfo -Message "Deploying agent to Azure DevOps agent pool" -NoNewLine
            $tfsServer = 'dev.azure.com'
            $useSsl = $true
            $tfsPort = 443
            $skipServerDuringTest = $true
        }
        elseif ($role.Properties.ContainsKey('TfsServer'))
        {
            $tfsServer = Get-LabVM -ComputerName $role.Properties['TfsServer'] -ErrorAction SilentlyContinue
            if (-not $tfsServer)
            {
                Write-ScreenInfo -Message "No TFS server called $($role.Properties['TfsServer']) found in lab." -NoNewLine -Type Warning
                $tfsServer = Get-LabVM -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Select-Object -First 1
                $role.Properties['TfsServer'] = $tfsServer.Name
                $shouldExport = $true
                Write-ScreenInfo -Message " Selecting $tfsServer instead." -Type Warning
            }

            $useSsl = $tfsServer.InternalNotes.ContainsKey('CertificateThumbprint') -or ($tfsServer.Roles.Name -eq 'AzDevOps' -and $tfsServer.SkipDeployment)
            
            if ($useSsl)
            {
                $machine.InternalNotes.CertificateThumpbrint = 'Use Ssl'
                $shouldExport = $true
            }
        }
        else
        {
            $useSsl = $tfsServer.InternalNotes.ContainsKey('CertificateThumbprint') -or ($tfsServer.Roles.Name -eq 'AzDevOps' -and $tfsServer.SkipDeployment)
            if ($useSsl)
            {
                $machine.InternalNotes.CertificateThumpbrint = 'Use Ssl'
            }
            $role.Properties.Add('TfsServer', $tfsServer.Name)
            $shouldExport = $true
        }

        if ($shouldExport) { Export-Lab }

        $tfsTest = Test-LabTfsEnvironment -ComputerName $tfsServer -NoDisplay -SkipServer:$skipServerDuringTest
        if ($tfsTest.ServerDeploymentOk -and $tfsTest.BuildWorker[$machine.Name].WorkerDeploymentOk)
        {
            Write-ScreenInfo -Message "Build worker $machine assigned to $tfsServer appears to be configured. Skipping..."
            continue
        }

        $tfsRole = $tfsServer.Roles | Where-Object Name -match 'Tfs\d{4}|AzDevOps'
        if ($tfsRole -and $tfsRole.Properties.ContainsKey('Port'))
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

        $pat = if ($role.Properties.ContainsKey('PAT'))
        {
            $role.Properties['PAT']
            $machineName = "dev.azure.com/$($role.Properties['Organisation'])"
        }
        elseif ($tfsRole.Properties.ContainsKey('PAT'))
        {
            $tfsRole.Properties['PAT']
            $machineName = "dev.azure.com/$($tfsRole.Properties['Organisation'])"
        }
        else
        {
            [string]::Empty
        }

        $agentPool = if ($role.Properties.ContainsKey('AgentPool'))
        {
            $role.Properties['AgentPool']
        }
        else
        {
            'default'
        }

        $installationJobs += Invoke-LabCommand -ComputerName $machine -ScriptBlock {

            if (-not (Test-Path C:\TfsBuildWorker.zip)) { throw 'Build worker installation files not available' }

            if ($numberOfBuildWorkers)
            {
                $numberOfBuildWorkers = 1..$numberOfBuildWorkers
            }
            else
            {
                $numberOfBuildWorkers = 1
            }
            foreach ($numberOfBuildWorker in $numberOfBuildWorkers)
            {
                Microsoft.PowerShell.Archive\Expand-Archive -Path C:\TfsBuildWorker.zip -DestinationPath "C:\BuildWorker$numberOfBuildWorker" -Force
                $configurationTool = Get-Item "C:\BuildWorker$numberOfBuildWorker\config.cmd" -ErrorAction Stop

                $content = if ($useSsl -and [string]::IsNullOrEmpty($pat))
                {
                    "$configurationTool --unattended --url https://$($machineName):$($tfsPort) --auth Integrated --pool $agentPool --agent $($env:COMPUTERNAME)-$numberOfBuildWorker --runasservice --sslskipcertvalidation --gituseschannel"

                }
                elseif ($useSsl -and -not [string]::IsNullOrEmpty($pat))
                {
                    "$configurationTool --unattended --url https://$($machineName) --auth pat --token $pat --pool $agentPool --agent $($env:COMPUTERNAME)-$numberOfBuildWorker --runasservice --sslskipcertvalidation --gituseschannel"
                }
                elseif (-not $useSsl -and -not [string]::IsNullOrEmpty($pat))
                {
                    "$configurationTool --unattended --url http://$($machineName) --auth pat --token $pat --pool $agentPool --agent $($env:COMPUTERNAME)-$numberOfBuildWorker --runasservice --gituseschannel"
                }
                else
                {
                    "$configurationTool --unattended --url http://$($machineName):$($tfsPort) --auth Integrated --pool $agentPool --agent $env:COMPUTERNAME --runasservice --gituseschannel"
                }

                if ($isOnDomainController)
                {
                    $content += " --windowsLogonAccount $($cred.UserName) --windowsLogonPassword $($cred.GetNetworkCredential().Password)"
                }

                $null = New-Item -ItemType Directory -Path C:\DeployDebug -ErrorAction SilentlyContinue
                Set-Content -Path "C:\DeployDebug\SetupBuildWorker$numberOfBuildWorker.cmd" -Value $content -Force

                $configResult = & "C:\DeployDebug\SetupBuildWorker$numberOfBuildWorker.cmd"

                $log = Get-ChildItem -Path "C:\BuildWorker$numberOfBuildWorker\_diag" -Filter *.log | Sort-Object -Property CreationTime | Select-Object -Last 1

                [pscustomobject]@{
                    ConfigResult = $configResult
                    LogContent   = $log | Get-Content 
                }

                if ($LASTEXITCODE -notin 0, 3010)
                {
                    Write-Warning -Message "Build worker $numberOfBuildWorker on '$env:COMPUTERNAME' failed to install. Exit code was $($LASTEXITCODE). Log is $($Log.FullName)"
                }
            }
        } -AsJob -Variable (Get-Variable machineName, tfsPort, useSsl, pat, isOnDomainController, cred, numberOfBuildWorkers, agentPool) -ActivityName "TFS_Agent_$machine" -PassThru -NoDisplay
    }

    Wait-LWLabJob -Job $installationJobs

    foreach ($job in $installationJobs)
    {
        $name = $job.Name.Replace('TFS_Agent_','')
        $type = if ($job.State -eq 'Completed') { 'Verbose' } else { 'Error' }
        $resultVariable = New-Variable -Name ("AL_TFSAgent_$($name)_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
        Write-ScreenInfo -Type $type -Message "TFS Agent deployment $($job.State.ToLower()) on '$($name)'. The job output of $job can be retrieved with `${$($resultVariable.Name)}"
        $resultVariable.Value = $job | Receive-Job -AutoRemoveJob -Wait
    }
}
