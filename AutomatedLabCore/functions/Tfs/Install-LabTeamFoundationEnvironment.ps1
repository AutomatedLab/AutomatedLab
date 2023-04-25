function Install-LabTeamFoundationEnvironment
{
    [CmdletBinding()]
    param
    ( )

    $tfsMachines = Get-LabVM -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Where-Object {
        -not $_.SkipDeployment -and -not (Test-LabTfsEnvironment -ComputerName $_.Name -NoDisplay).ServerDeploymentOk
    }
    $azDevOpsService = Get-LabVM -Role AzDevOps | Where-Object SkipDeployment

    foreach ($svcConnection in $azDevOpsService)
    {
        $role = $svcConnection.Roles | Where-Object Name -Match 'AzDevOps'

        # Override port or add if empty
        $role.Properties.Port = 443
        $svcConnection.InternalNotes.Add('CertificateThumbprint', 'use SSL')
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
                if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)
                {
                    $dvdDrive = (Get-CimInstance -Class Win32_CDRomDrive | Where-Object MediaLoaded).Drive
                }
                else
                {
                    $dvdDrive = (Get-WmiObject -Class Win32_CDRomDrive | Where-Object MediaLoaded).Drive
                }
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
    Set-LabBuildWorkerCapability
}
