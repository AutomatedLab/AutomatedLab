function Install-LabWindowsAdminCenter {
    [CmdletBinding()]
    param
    ( )

    Write-LogFunctionEntry
    $lab = Get-Lab -ErrorAction SilentlyContinue

    if (-not $lab) {
        Write-Error -Message 'Please deploy a lab first.'
        return
    }

    $machines = (Get-LabVM -Role WindowsAdminCenter).Where( { -not $_.SkipDeployment })
    
    if (-not $machines) { return }

    Start-LabVM -ComputerName $machines -Wait
    # Exported from an installed Windows Admin Center
    $publisherCertBytes = @(48, 130, 6, 3, 48, 130, 3, 235, 160, 3, 2, 1, 2, 2, 19, 51, 0, 0, 4, 3, 189, 213, 149, 93, 15, 59, 24, 173, 0, 0, 0, 0, 4, 3, 48, 13, 6, 9, 42, 134, 72, 134, 247, 13, 1, 1, 11, 5, 0, 48, 126, 49, 11, 48, 9, 6, 3, 85, 4, 6, 19, 2, 85, 83, 49, 19, 48, 17, 6, 3, 85, 4, 8, 19, 10, 87, 97, 115, 104, 105, 110, 103, 116, 111, 110, 49, 16, 48, 14, 6, 3, 85, 4, 7, 19, 7, 82, 101, 100, 109, 111, 110, 100, 49, 30, 48, 28, 6, 3, 85, 4, 10, 19, 21, 77, 105, 99, 114, 111, 115, 111, 102, 116, 32, 67, 111, 114, 112, 111, 114, 97, 116, 105, 111, 110, 49, 40, 48, 38, 6, 3, 85, 4, 3, 19, 31, 77, 105, 99, 114, 111, 115, 111, 102, 116, 32, 67, 111, 100, 101, 32, 83, 105, 103, 110, 105, 110, 103, 32, 80, 67, 65, 32, 50, 48, 49, 49, 48, 30, 23, 13, 50, 52, 48, 57, 49, 50, 50, 48, 49, 49, 49, 51, 90, 23, 13, 50, 53, 48, 57, 49, 49, 50, 48, 49, 49, 49, 51, 90, 48, 116, 49, 11, 48, 9, 6, 3, 85, 4, 6, 19, 2, 85, 83, 49, 19, 48, 17, 6, 3, 85, 4, 8, 19, 10, 87, 97, 115, 104, 105, 110, 103, 116, 111, 110, 49, 16, 48, 14, 6, 3, 85, 4, 7, 19, 7, 82, 101, 100, 109, 111, 110, 100, 49, 30, 48, 28, 6, 3, 85, 4, 10, 19, 21, 77, 105, 99, 114, 111, 115, 111, 102, 116, 32, 67, 111, 114, 112, 111, 114, 97, 116, 105, 111, 110, 49, 30, 48, 28, 6, 3, 85, 4, 3, 19, 21, 77, 105, 99, 114, 111, 115, 111, 102, 116, 32, 67, 111, 114, 112, 111, 114, 97, 116, 105, 111, 110, 48, 130, 1, 34, 48, 13, 6, 9, 42, 134, 72, 134, 247, 13, 1, 1, 1, 5, 0, 3, 130, 1, 15, 0, 48, 130, 1, 10, 2, 130, 1, 1, 0, 159, 116, 103, 93, 192, 131, 167, 109, 22, 20, 202, 13, 55, 59, 120, 179, 215, 213, 215, 100, 249, 174, 132, 73, 150, 255, 155, 178, 16, 223, 188, 154, 12, 101, 248, 114, 70, 120, 177, 129, 71, 198, 1, 186, 209, 149, 45, 82, 183, 241, 28, 92, 85, 195, 216, 200, 81, 144, 93, 194, 156, 198, 8, 161, 227, 14, 50, 227, 50, 98, 220, 107, 218, 192, 182, 7, 150, 195, 68, 197, 12, 51, 250, 253, 35, 129, 143, 218, 122, 48, 82, 216, 66, 88, 161, 72, 75, 84, 79, 148, 205, 24, 161, 87, 202, 40, 198, 135, 237, 178, 98, 139, 111, 108, 91, 236, 26, 5, 75, 165, 0, 163, 118, 115, 225, 167, 231, 57, 218, 136, 236, 81, 168, 139, 184, 56, 191, 31, 244, 48, 135, 98, 147, 4, 231, 228, 222, 122, 77, 210, 47, 222, 108, 31, 145, 144, 133, 154, 187, 10, 164, 221, 51, 71, 193, 195, 241, 102, 44, 188, 125, 241, 42, 65, 187, 187, 252, 93, 170, 104, 79, 62, 163, 38, 156, 141, 163, 56, 92, 63, 254, 125, 154, 47, 197, 187, 139, 83, 218, 178, 54, 188, 62, 116, 87, 31, 244, 26, 84, 125, 12, 214, 118, 167, 47, 226, 200, 245, 59, 12, 111, 247, 167, 89, 245, 206, 91, 174, 70, 157, 238, 92, 168, 195, 125, 82, 135, 239, 16, 219, 93, 195, 1, 38, 39, 118, 217, 173, 194, 61, 187, 130, 217, 2, 75, 163, 2, 3, 1, 0, 1, 163, 130, 1, 130, 48, 130, 1, 126, 48, 31, 6, 3, 85, 29, 37, 4, 24, 48, 22, 6, 10, 43, 6, 1, 4, 1, 130, 55, 76, 8, 1, 6, 8, 43, 6, 1, 5, 5, 7, 3, 3, 48, 29, 6, 3, 85, 29, 14, 4, 22, 4, 20, 234, 110, 42, 2, 74, 115, 227, 174, 53, 136, 173, 162, 172, 95, 30, 90, 196, 129, 112, 25, 48, 84, 6, 3, 85, 29, 17, 4, 77, 48, 75, 164, 73, 48, 71, 49, 45, 48, 43, 6, 3, 85, 4, 11, 19, 36, 77, 105, 99, 114, 111, 115, 111, 102, 116, 32, 73, 114, 101, 108, 97, 110, 100, 32, 79, 112, 101, 114, 97, 116, 105, 111, 110, 115, 32, 76, 105, 109, 105, 116, 101, 100, 49, 22, 48, 20, 6, 3, 85, 4, 5, 19, 13, 50, 51, 48, 48, 49, 50, 43, 53, 48, 50, 57, 50, 54, 48, 31, 6, 3, 85, 29, 35, 4, 24, 48, 22, 128, 20, 72, 110, 100, 229, 80, 5, 211, 130, 170, 23, 55, 55, 34, 181, 109, 168, 202, 117, 2, 149, 48, 84, 6, 3, 85, 29, 31, 4, 77, 48, 75, 48, 73, 160, 71, 160, 69, 134, 67, 104, 116, 116, 112, 58, 47, 47, 119, 119, 119, 46, 109, 105, 99, 114, 111, 115, 111, 102, 116, 46, 99, 111, 109, 47, 112, 107, 105, 111, 112, 115, 47, 99, 114, 108, 47, 77, 105, 99, 67, 111, 100, 83, 105, 103, 80, 67, 65, 50, 48, 49, 49, 95, 50, 48, 49, 49, 45, 48, 55, 45, 48, 56, 46, 99, 114, 108, 48, 97, 6, 8, 43, 6, 1, 5, 5, 7, 1, 1, 4, 85, 48, 83, 48, 81, 6, 8, 43, 6, 1, 5, 5, 7, 48, 2, 134, 69, 104, 116, 116, 112, 58, 47, 47, 119, 119, 119, 46, 109, 105, 99, 114, 111, 115, 111, 102, 116, 46, 99, 111, 109, 47, 112, 107, 105, 111, 112, 115, 47, 99, 101, 114, 116, 115, 47, 77, 105, 99, 67, 111, 100, 83, 105, 103, 80, 67, 65, 50, 48, 49, 49, 95, 50, 48, 49, 49, 45, 48, 55, 45, 48, 56, 46, 99, 114, 116, 48, 12, 6, 3, 85, 29, 19, 1, 1, 255, 4, 2, 48, 0, 48, 13, 6, 9, 42, 134, 72, 134, 247, 13, 1, 1, 11, 5, 0, 3, 130, 2, 1, 0, 81, 104, 255, 161, 56, 45, 126, 117, 34, 161, 110, 160, 171, 212, 178, 47, 52, 67, 43, 70, 35, 144, 18, 67, 220, 236, 62, 144, 90, 211, 62, 252, 134, 235, 98, 37, 222, 176, 215, 158, 9, 145, 194, 49, 253, 254, 235, 16, 18, 184, 54, 16, 248, 12, 129, 77, 125, 24, 149, 116, 142, 196, 105, 193, 44, 236, 224, 18, 233, 1, 197, 236, 219, 126, 120, 84, 77, 57, 59, 96, 29, 191, 79, 19, 20, 114, 224, 66, 63, 142, 115, 48, 205, 2, 85, 54, 137, 19, 198, 237, 150, 128, 122, 255, 124, 27, 22, 179, 161, 189, 1, 194, 32, 188, 120, 214, 52, 221, 234, 69, 42, 225, 178, 1, 29, 168, 119, 52, 109, 16, 212, 127, 197, 8, 44, 7, 68, 100, 227, 1, 188, 162, 194, 174, 103, 254, 144, 147, 196, 188, 249, 93, 128, 174, 225, 20, 239, 203, 246, 73, 156, 85, 238, 187, 6, 114, 158, 140, 50, 142, 239, 116, 154, 231, 160, 9, 58, 19, 59, 10, 71, 128, 78, 178, 69, 196, 239, 70, 45, 122, 44, 160, 171, 235, 192, 27, 242, 159, 16, 32, 215, 197, 190, 165, 168, 19, 2, 66, 94, 127, 57, 222, 185, 100, 166, 158, 36, 238, 172, 240, 148, 19, 98, 103, 189, 110, 195, 106, 91, 206, 52, 51, 173, 27, 77, 108, 33, 80, 1, 249, 168, 78, 219, 7, 20, 61, 173, 153, 155, 208, 34, 13, 80, 86, 76, 204, 253, 93, 74, 10, 49, 203, 231, 130, 45, 168, 169, 187, 3, 46, 22, 202, 250, 150, 43, 69, 72, 17, 164, 219, 116, 203, 91, 49, 102, 197, 206, 173, 161, 145, 23, 201, 76, 217, 197, 175, 180, 73, 21, 229, 66, 254, 77, 3, 53, 166, 155, 249, 186, 112, 199, 145, 111, 9, 75, 228, 39, 124, 246, 193, 241, 214, 85, 71, 36, 102, 49, 14, 26, 99, 251, 113, 231, 30, 126, 177, 126, 172, 122, 98, 127, 252, 86, 226, 114, 84, 140, 197, 34, 62, 204, 131, 110, 214, 54, 30, 173, 213, 48, 184, 40, 190, 63, 170, 123, 74, 100, 38, 10, 88, 67, 51, 238, 144, 249, 187, 68, 216, 91, 105, 177, 77, 22, 250, 190, 145, 117, 129, 95, 252, 255, 167, 43, 168, 246, 162, 217, 125, 54, 250, 247, 181, 98, 238, 249, 101, 230, 207, 195, 6, 51, 237, 124, 202, 114, 126, 149, 134, 210, 152, 85, 156, 2, 62, 210, 99, 56, 128, 125, 61, 44, 35, 9, 80, 68, 89, 50, 11, 189, 109, 176, 134, 84, 132, 17, 237, 196, 249, 98, 25, 75, 183, 235, 105, 72, 59, 66, 233, 123, 64, 206, 174, 15, 37, 178, 153, 196, 88, 233, 7, 156, 36, 249, 36, 73, 214, 9, 188, 238, 137, 91, 124, 69, 125, 72, 87, 78, 238, 34, 247, 141, 102, 227, 129, 88, 181, 66, 205, 98, 99, 16, 102, 190, 30, 22, 132, 181, 171, 227, 203, 168, 187)

    $certDownload = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name WacMsIntermediateCaCert) -Path "$labSources/SoftwarePackages" -FileName MicCodSigPCA2011_2011-07-08.crt -PassThru -NoDisplay
    $wacDownload = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name WacDownloadUrl) -Path "$labSources/SoftwarePackages" -FileName WAC.exe -PassThru -NoDisplay
    Copy-LabFileItem -Path $wacDownload.FullName -ComputerName $machines
    Copy-LabFileItem -Path $certDownload.FullName -ComputerName $machines
    Add-LabCertificate -RawContentBytes $publisherCertBytes -Store TrustedPublisher -Location CERT_SYSTEM_STORE_LOCAL_MACHINE -ComputerName $machines
    Add-LabCertificate -RawContentBytes $publisherCertBytes -Store TrustedPublisher -Location CERT_SYSTEM_STORE_CURRENT_USER -ComputerName $machines
    $deployDebugPath = Invoke-LabCommand -ComputerName $machines -NoDisplay -ScriptBlock {
        $null = Add-Certificate2 -Path C:\MicCodSigPCA2011_2011-07-08.crt -Store CA -Location CERT_SYSTEM_STORE_LOCAL_MACHINE
        $null = Add-Certificate2 -Path C:\MicCodSigPCA2011_2011-07-08.crt -Store CA -Location CERT_SYSTEM_STORE_CURRENT_USER
        (New-Item -ItemType Directory -Path $ExecutionContext.InvokeCommand.ExpandString($AL_DeployDebugFolder) -ErrorAction SilentlyContinue -Force).FullName
    } -Variable (Get-Variable -Scope Global -Name AL_DeployDebugFolder) -PassThru | Select-Object -First 1
    

    $jobs = foreach ($labMachine in $machines) {
        if ((Invoke-LabCommand -ComputerName $labMachine -ScriptBlock { Get-Service -Name WindowsAdminCenter -ErrorAction SilentlyContinue } -PassThru -NoDisplay)) {
            Write-ScreenInfo -Type Verbose -Message "$labMachine already has Windows Admin Center installed"
            continue
        }

        Write-ScreenInfo -Type Verbose -Message "Starting installation of Windows Admin Center on $labMachine"
        if ($labMachine.SshPrivateKeyPath) {
            Invoke-LabCommand -ComputerName $labMachine -ScriptBlock {
                "Start-Process -Wait -FilePath C:\WAC.exe -ArgumentList '/SILENT /LOG=$deployDebugPath\WACSetup.log'; exit 0" | Set-Content $deployDebugPath\DeployWac.ps1
                powershell.exe -File $deployDebugPath\DeployWac.ps1
            } -AsJob -PassThru -NoDisplay -Variable (Get-Variable -Name deployDebugPath)
        }
        else {
            Install-LabSoftwarePackage -LocalPath C:\WAC.exe -CommandLine "/SILENT /LOG=$deployDebugPath\WACSetup.log" -ComputerName $labMachine -PassThru -NoDisplay -AsJob
        }
    }

    if ($jobs) {
        Write-ScreenInfo -Message "Waiting for the installation of Windows Admin Center to finish on $machines"
        Wait-LWLabJob -Job $jobs -ProgressIndicator 5 -Timeout 10 -NoNewLine -NoDisplay

        $installResults = Invoke-LabCommand -PassThru -NoDisplay -ComputerName $machines -ScriptBlock {
            $env:PSModulePath = "C:\Program Files\WindowsAdminCenter\PowerShellModules;$env:PSModulePath"
            @{
                Machine = hostname
                Failure = if (-not (Get-Command Test-WACInstallationFailure -ErrorAction SilentlyContinue)) {
                    $true
                }
                else { [bool](Test-WACInstallationFailure $deployDebugPath\WACSetup.log -ErrorAction SilentlyContinue) }
            }
        } -Variable (Get-Variable -Name deployDebugPath)

        if ($installResults | Where-Object Failure) {
            Write-ScreenInfo -Type Error -Message "Installation of Windows Admin Center failed on $($installResults.Machine)."
        }
    }

    $wacHosts = [System.Collections.Generic.List[string]]::new()
    foreach ($labMachine in $machines) {
        $machSession = Get-LabPSSession -ComputerName $labMachine
        if ($machSession.Transport -eq 'SSH') {
            Invoke-LabCommand -NoDisplay -ComputerName $labMachine -ScriptBlock {
                Enable-PSRemoting -Force -WarningAction SilentlyContinue
            } -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        }

        Remove-LabPSSession -Machine $labMachine

        Invoke-LabCommand -NoDisplay -ComputerName $labMachine -ScriptBlock {
            $env:PSModulePath = "C:\Program Files\WindowsAdminCenter\PowerShellModules;$env:PSModulePath"
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
            if ($env:PSModulePath -notmatch 'WindowsAdminCenter') {
                $env:PSModulePath = "C:\Program Files\WindowsAdminCenter\PowerShellModules;$env:PSModulePath"
            }

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

        $wachostname = if (-not $labMachine.SkipDeployment -and $lab.DefaultVirtualizationEngine -eq 'Azure') {
            $labMachine.AzureConnectionInfo.DnsName
        }
        elseif ($labMachine.SkipDeployment) {
            $labMachine.Name
        }
        else {
            $labMachine.FQDN
        }
        $wacHosts.Add("https://$($wachostname):$Port")
    }

    Write-ScreenInfo -Type Info -Message "WAC hosts configured: $($wacHosts -join ', ')"

    Write-LogFunctionExit
}
