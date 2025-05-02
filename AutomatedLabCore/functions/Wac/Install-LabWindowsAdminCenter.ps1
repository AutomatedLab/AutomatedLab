function Install-LabWindowsAdminCenter {
    [CmdletBinding()]
    param
    ( )

    $lab = Get-Lab -ErrorAction SilentlyContinue

    if (-not $lab) {
        Write-Error -Message 'Please deploy a lab first.'
        return
    }

    $machines = (Get-LabVM -Role WindowsAdminCenter).Where( { -not $_.SkipDeployment })
    
    if ($machines) {
        Start-LabVM -ComputerName $machines -Wait
        $wacDownload = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name WacDownloadUrl) -Path "$labSources\SoftwarePackages" -FileName WAC.exe -PassThru -NoDisplay
        Copy-LabFileItem -Path $wacDownload.FullName -ComputerName $machines
        Invoke-LabCommand -ComputerName $machines -NoDisplay -ScriptBlock {
            if ($env:PSModulePath -match 'WindowsAdminCenter') { return }
            $env:PSModulePath = "C:\Program Files\WindowsAdminCenter\PowerShellModules;$env:PSModulePath"
            [System.Environment]::SetEnvironmentVariable('PSModulePath', "C:\Program Files\WindowsAdminCenter\PowerShellModules;$env:PSModulePath", 'Machine')
        }
    }

    $jobs = foreach ($labMachine in $machines) {
        if ((Invoke-LabCommand -ComputerName $labMachine -ScriptBlock { Get-Service -Name WindowsAdminCenter -ErrorAction SilentlyContinue } -PassThru -NoDisplay)) {
            Write-ScreenInfo -Type Verbose -Message "$labMachine already has Windows Admin Center installed"
            continue
        }

        Write-ScreenInfo -Type Verbose -Message "Starting installation of Windows Admin Center on $labMachine"
        Install-LabSoftwarePackage -LocalPath C:\WAC.exe -CommandLine '/verysilent /log=C:\DeployDebug\WACSetup.log' -ComputerName $labMachine -UseShellExecute -AsJob -PassThru -NoDisplay
    }

    if ($jobs) {
        Write-ScreenInfo -Message "Waiting for the installation of Windows Admin Center to finish on $machines"
        Wait-LWLabJob -Job $jobs -ProgressIndicator 5 -NoNewLine -NoDisplay

        $installResults = Invoke-LabCommand -PassThru -NoDisplay -ComputerName $machines -ScriptBlock {
            @{
                Machine = hostname
                Failure = if (-not (Get-Command Test-WACInstallationFailure -ErrorAction SilentlyContinue)) {
                    return $false
                }
                else { [bool](Test-WACInstallationFailure C:\DeployDebug\WACSetup.log) }
            }
        }

        if ($installResults | Where-Object Failure) {
            Write-ScreenInfo -Type Error -Message "Installation of Windows Admin Center failed on $($installResults.Machine)."
        }
    }

    foreach ($labMachine in $machines) {
        $machSession = Get-LabPSSession -ComputerName $labMachine
        if ($machSession.Transport -eq 'SSH') {
            Invoke-LabCommand -NoDisplay -ComputerName $labMachine -ScriptBlock {
                Enable-PSRemoting -Force -WarningAction SilentlyContinue
            }
        }

        Remove-LabPSSession -Machine $labMachine

        Invoke-LabCommand -NoDisplay -ComputerName $labMachine -ScriptBlock {
            Register-WACLocalCredSSP
        } -ErrorAction SilentlyContinue

        $role = $labMachine.Roles.Where( { $_.Name -eq 'WindowsAdminCenter' })
        $cert = $null

        if ($labMachine.IsDomainJoined -and (Get-LabIssuingCA -DomainName $labMachine.DomainName -ErrorAction SilentlyContinue) ) {
            $san = @(
                $labMachine.Name
                if ($lab.DefaultVirtualizationEngine -eq 'Azure') { $labMachine.AzureConnectionInfo.DnsName }
            )
            $cert = Request-LabCertificate -Subject "CN=$($labMachine.FQDN)" -SAN $san -TemplateName WebServer -ComputerName $labMachine -PassThru -ErrorAction Stop
        }

        $port = 443
        if ($role.Properties.ContainsKey('Port')) {
            $port = $role.Properties['Port']
        }

        Invoke-LabCommand -ComputerName $labMachine -Variable (Get-Variable port, cert) -ActivityName 'Applying WAC customizations' -ScriptBlock {
            Import-WACExistingExtensions
            Import-WACExistingPlugins
            New-WACEventLog
            if ($Port -ne 443) {
                Set-WACHttpsPorts -WacPort $Port
            }

            $certAcl = @{}
            if ($cert.Thumbprint) {
                Set-WACCertificateSubjectName -Thumbprint $cert.Thumbprint
                $certAcl.SubjectName = $cert.Subject
            }

            Set-WACCertificateAcl @certAcl
        }

        if ($lab.DefaultVirtualizationEngine -eq 'Azure') {
            if (-not (Get-LabAzureLoadBalancedPort -DestinationPort $Port -ComputerName $labMachine)) {
                $lab.AzureSettings.LoadBalancerPortCounter++
                $remotePort = $lab.AzureSettings.LoadBalancerPortCounter
                Add-LWAzureLoadBalancedPort -ComputerName $labMachine -DestinationPort $Port -Port $remotePort
                $Port = $remotePort
            }
        }
    }

    Add-LabWacManagedNode
}
