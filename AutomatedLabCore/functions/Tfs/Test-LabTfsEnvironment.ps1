function Test-LabTfsEnvironment
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ComputerName,

        [switch]
        $SkipServer,

        [switch]
        $SkipWorker,

        [switch]
        $NoDisplay
    )

    $lab = Get-Lab -ErrorAction Stop
    $machine = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Where-Object -Property Name -eq $ComputerName
    $assignedBuildWorkers = Get-LabVm -Role TfsBuildWorker | Where-Object {
        ($_.Roles | Where-Object Name -eq TfsBuildWorker)[0].Properties['TfsServer'] -eq $machine.Name -or `
        ($_.Roles | Where-Object Name -eq TfsBuildWorker)[0].Properties.ContainsKey('PAT')
    }

    if (-not $machine -and -not $SkipServer.IsPresent) { return }

    if (-not $script:tfsDeploymentStatus)
    {
        $script:tfsDeploymentStatus = @{ }
    }

    if (-not $script:tfsDeploymentStatus.ContainsKey($ComputerName))
    {
        $script:tfsDeploymentStatus[$ComputerName] = @{ServerDeploymentOk = $SkipServer.IsPresent; BuildWorker = @{ } }
    }

    if (-not $script:tfsDeploymentStatus[$ComputerName].ServerDeploymentOk)
    {
        $uri = Get-LabTfsUri -ComputerName $machine -ErrorAction SilentlyContinue
        if ($null -eq $uri)
        {
            Write-PSFMessage -Message "TFS URI could not be determined."
            return $script:tfsDeploymentStatus[$ComputerName]
        }

        $defaultParam = Get-LabTfsParameter -ComputerName $machine
        $defaultParam.ErrorAction    = 'Stop'
        $defaultParam.ErrorVariable  = 'apiErr'

        try
        {
            $param = @{
                Method      = 'Get'
                Uri         = $uri
                ErrorAction = 'Stop'
            }

            if ($PSEdition -eq 'Core' -and (Get-Command Invoke-RestMethod).Parameters.ContainsKey('SkipCertificateCheck'))
            {
                $param.SkipCertificateCheck = $true
            }

            if ($accessToken)
            {
                $param.Headers = @{Authorization = Get-TfsAccessTokenString -PersonalAccessToken $accessToken }
            }
            else
            {
                $param.Credential = $defaultParam.credential
            }

            $null = Invoke-RestMethod @param
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
            $script:tfsDeploymentStatus[$ComputerName].BuildWorker[$worker.Name] = @{WorkerDeploymentOk = $SkipWorker.IsPresent }
        }

        if ($SkipWorker.IsPresent)
        {
            continue
        }

        $svcRunning = Invoke-LabCommand -PassThru -ComputerName $worker -ScriptBlock { Get-Service -Name *vsts* } -NoDisplay
        $script:tfsDeploymentStatus[$ComputerName].BuildWorker[$worker.Name].WorkerDeploymentOk = $svcRunning.Status -eq 'Running'
    }

    return $script:tfsDeploymentStatus[$ComputerName]
}
