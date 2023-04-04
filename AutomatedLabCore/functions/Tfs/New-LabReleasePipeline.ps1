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
    $originalPort = 8080
    $tfsInstance = $tfsVm.FQDN

    if ($role.Properties.ContainsKey('Port'))
    {
        $originalPort = $role.Properties['Port']
    }

    $gitBinary = if (Get-Command git) { (Get-Command git).Source } elseif (Test-Path -Path $localLabSources\Tools\git.exe) { "$localLabSources\Tools\git.exe" }
    if (-not $gitBinary)
    {
        Write-ScreenInfo -Message 'Git is not installed. We are not be able to push any code to the remote repository and cannot proceed. Please install Git'
        return
    }

    $defaultParam = Get-LabTfsParameter -ComputerName $tfsVm
    $defaultParam.ProjectName = $ProjectName

    $project = New-TfsProject @defaultParam -SourceControlType Git -TemplateName 'Agile' -Timeout (New-TimeSpan -Minutes 5)
    $repository = Get-TfsGitRepository @defaultParam

    if ($CodeUploadMethod -eq 'git' -and -not $tfsVm.SkipDeployment -and $(Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        $repository.remoteUrl = $repository.remoteUrl -replace $originalPort, $defaultParam.Port
        if ($repository.remoteUrl -match 'http(s?)://(?<Host>[\w\.]+):')
        {
            $repository.remoteUrl = $repository.remoteUrl.Replace($Matches.Host, $tfsVm.AzureConnectionInfo.DnsName)
        }
    }

    if ($CodeUploadMethod -eq 'FileCopy' -and -not $tfsVm.SkipDeployment -and $(Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        if ($repository.remoteUrl -match 'http(s?)://(?<Host>[\w\.]+):')
        {
            $repository.remoteUrl = $repository.remoteUrl.Replace($Matches.Host, $tfsVm.FQDN)
        }
    }

    if ($SourceRepository)
    {
        if (-not $gitBinary)
        {
            Write-Error "Git.exe could not be located, cannot clone repository from '$SourceRepository'"
            return
        }

        # PAT URLs look like https://{yourPAT}@dev.azure.com/yourOrgName/yourProjectName/_git/yourRepoName
        $repoUrl = if ($defaultParam.Contains('PersonalAccessToken'))
        {
            $tmp = $repository.remoteUrl.Insert($repository.remoteUrl.IndexOf('/') + 2, '{0}@')
            $tmp -f $defaultParam.PersonalAccessToken
        }
        else
        {
            $tmp = $repository.remoteUrl.Insert($repository.remoteUrl.IndexOf('/') + 2, '{0}:{1}@')
            $tmp -f $defaultParam.Credential.GetNetworkCredential().UserName.ToLower(), $defaultParam.Credential.GetNetworkCredential().Password
        }

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

                $null = git checkout $Matches.BranchName 2>&1
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

        $repoDestination = if ($IsLinux -or $IsMacOs) { "/$ProjectName.temp" } else { "C:\$ProjectName.temp" }
        if ($repositoryPath)
        {
            Copy-LabFileItem -Path $repositoryPath -ComputerName $tfsVm -DestinationFolderPath $repoDestination -Recurse
        }
        else
        {
            Copy-LabFileItem -Path $SourcePath -ComputerName $tfsVm -DestinationFolderPath $repoDestination -Recurse
        }

        Invoke-LabCommand -ActivityName 'Push code to TFS/AZDevOps' -ComputerName $tfsVm -ScriptBlock {

            Set-Location -Path "C:\$ProjectName.temp\$ProjectName"

            git remote add tfs $repoUrl

            $pattern = '(?>remotes\/origin\/)(?<BranchName>[\w\/]+)'
            $branches = git branch -a | Where-Object { $_ -cnotlike '*HEAD*' -and -not $_.StartsWith('*') }

            foreach ($branch in $branches)
            {
                if ($branch -match $pattern)
                {
                    $null = git checkout $Matches.BranchName 2>&1
                    if ($LASTEXITCODE -eq 0)
                    {
                        git add . 2>&1
                        git commit -m 'Initial' 2>&1
                        git -c http.sslVerify=false push --set-upstream tfs $Matches.BranchName 2>&1
                    }
                }
            }

            Set-Location -Path C:\
            Remove-Item -Path "C:\$ProjectName.temp" -Recurse -Force
        } -Variable (Get-Variable -Name repoUrl, ProjectName)
    }

    if (-not ($role.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment))
    {
        Invoke-LabCommand -ActivityName 'Clone local repo from TFS' -ComputerName $tfsVm -ScriptBlock {

            if (-not (Test-Path -Path C:\Git))
            {
                New-Item -ItemType Directory -Path C:\Git | Out-Null
            }
            Set-Location -Path C:\Git
            git -c http.sslVerify=false clone $repoUrl 2>&1

        } -Variable (Get-Variable -Name repoUrl, ProjectName)
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
