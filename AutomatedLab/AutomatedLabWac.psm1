function Install-LabWindowsAdminCenter
{
    [CmdletBinding()]
    param
    ( )

    $lab = Get-Lab -ErrorAction SilentlyContinue

    if (-not $lab)
    {
        Write-Error -Message 'Please deploy a lab first.'
        return
    }

    $machines = (Get-LabVM -Role WindowsAdminCenter).Where( { -not $_.SkipDeployment })
    
    if ($machines)
    {
        Start-LabVM -ComputerName $machines -Wait
        $wacDownload = Get-LabInternetFile -Uri (Get-LabConfigurationItem -Name WacDownloadUrl) -Path "$labSources\SoftwarePackages" -FileName WAC.msi -PassThru -NoDisplay
        Copy-LabFileItem -Path $wacDownload.FullName -ComputerName $machines

        $jobs = foreach ($labMachine in $machines)
        {
            if ((Invoke-LabCommand -ComputerName $labMachine -ScriptBlock { Get-Service -Name ServerManagementGateway -ErrorAction SilentlyContinue } -PassThru -NoDisplay))
            {
                Write-ScreenInfo -Type Verbose -Message "$labMachine already has Windows Admin Center installed"
                continue
            }

            $role = $labMachine.Roles.Where( { $_.Name -eq 'WindowsAdminCenter' })
            $useSsl = $true
            if ($role.Properties.ContainsKey('UseSsl'))
            {
                $useSsl = [Convert]::ToBoolean($role.Properties['UseSsl'])
            }


            if ($useSsl -and $labMachine.IsDomainJoined -and (Get-LabIssuingCA -DomainName $labMachine.DomainName -ErrorAction SilentlyContinue) )
            {
                $san = @(
                    $labMachine.Name
                    if ($lab.DefaultVirtualizationEngine -eq 'Azure') { $labMachine.AzureConnectionInfo.DnsName }
                )
                $cert = Request-LabCertificate -Subject "CN=$($labMachine.FQDN)" -SAN $san -TemplateName WebServer -ComputerName $labMachine -PassThru -ErrorAction Stop
            }

            $Port = 443
            if (-not $useSsl)
            {
                $Port = 80
            }
            if ($role.Properties.ContainsKey('Port'))
            {
                $Port = $role.Properties['Port']
            }

            $arguments = @(
                '/qn'
                '/L*v C:\wacLoc.txt'
                "SME_PORT=$Port"
            )

            if ($role.Properties.ContainsKey('EnableDevMode'))
            {
                $arguments += 'DEV_MODE=1'
            }

            if ($cert.Thumbprint)
            {
                $arguments += "SME_THUMBPRINT=$($cert.Thumbprint)"
                $arguments += "SSL_CERTIFICATE_OPTION=installed"
            }
            elseif ($useSsl)
            {
                $arguments += "SSL_CERTIFICATE_OPTION=generate"
            }

            if (-not $machine.SkipDeployment -and $lab.DefaultVirtualizationEngine -eq 'Azure')
            {
                if (-not (Get-LabAzureLoadBalancedPort -DestinationPort $Port -ComputerName $labMachine))
                {
                    $lab.AzureSettings.LoadBalancerPortCounter++
                    $remotePort = $lab.AzureSettings.LoadBalancerPortCounter
                    Add-LWAzureLoadBalancedPort -ComputerName $labMachine -DestinationPort $Port -Port $remotePort
                    $Port = $remotePort
                }
            }

            if ([Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12')
            {
                Write-Verbose -Message 'Adding support for TLS 1.2'
                [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
            }

            Write-ScreenInfo -Type Verbose -Message "Starting installation of Windows Admin Center on $labMachine"
            Install-LabSoftwarePackage -LocalPath C:\WAC.msi -CommandLine $($arguments -join ' ') -ComputerName $labMachine -ExpectedReturnCodes 0, 3010 -AsJob -PassThru -NoDisplay
        }

        if ($jobs)
        {
            Write-ScreenInfo -Message "Waiting for the installation of Windows Admin Center to finish on $machines"
            Wait-LWLabJob -Job $jobs -ProgressIndicator 5 -NoNewLine -NoDisplay

            if ($jobs.State -contains 'Failed')
            {
                $jobs.Where( { $_.State -eq 'Failed' }) | Receive-Job -Keep -ErrorAction SilentlyContinue -ErrorVariable err
                if ($err[0].Exception -is [System.Management.Automation.Remoting.PSRemotingTransportException])
                {
                    Write-ScreenInfo -Type Verbose -Message "WAC setup has restarted WinRM. The setup of WAC should be completed"
                }
                else
                {
                    Write-ScreenInfo -Type Error -Message "Installing Windows Admin Center on $($jobs.Name.Replace('WAC_')) failed. Review the errors with Get-Job -Id $($installation.Id) | Receive-Job -Keep"
                    return
                }
            }

            Restart-LabVM -ComputerName $machines -Wait -NoDisplay
        }
    }

    Add-LabWacManagedNode
}

function Add-LabWacManagedNode
{
    [CmdletBinding()]
    param
    ( )

    $lab = Get-Lab -ErrorAction SilentlyContinue

    if (-not $lab)
    {
        Write-Error -Message 'Please deploy a lab first.'
        return
    }

    $machines = Get-LabVM -Role WindowsAdminCenter

    # Add hosts through REST API
    foreach ($machine in $machines)
    {
        $role = $machine.Roles.Where( { $_.Name -eq 'WindowsAdminCenter' })
        # In case machine deployment is skipped, we are using the installation user credential of the machine to make the connection
        $wacCredential = if ($machine.SkipDeployment)
        {
            $machine.GetLocalCredential()
        }
        else
        {
            $machine.GetCredential($lab)
        }

        $useSsl = $true
        if ($role.Properties.ContainsKey('UseSsl'))
        {
            $useSsl = [Convert]::ToBoolean($role.Properties['UseSsl'])
        }

        $Port = 443
        if (-not $useSsl)
        {
            $Port = 80
        }
        if ($role.Properties.ContainsKey('Port'))
        {
            $Port = $role.Properties['Port']
        }

        if (-not $machine.SkipDeployment -and $lab.DefaultVirtualizationEngine -eq 'Azure')
        {
            $azPort = Get-LabAzureLoadBalancedPort -DestinationPort $Port -ComputerName $machine
            $Port = $azPort.Port
        }

        $filteredHosts = if ($role.Properties.ContainsKey('ConnectedNode'))
        {
            Get-LabVM | Where-Object -Property Name -in ($role.Properties['ConnectedNode'] | ConvertFrom-Json)
        }
        else
        {
            Get-LabVM | Where-Object -FilterScript { $_.Name -ne $machine.Name -and -not $_.SkipDeployment }
        }

        $wachostname = if (-not $machine.SkipDeployment -and $lab.DefaultVirtualizationEngine -eq 'Azure') 
        {
            $machine.AzureConnectionInfo.DnsName
        }
        elseif ($machine.SkipDeployment)
        {
            $machine.Name
        }
        else
        {
            $machine.FQDN
        }
        Write-ScreenInfo -Message "Adding $($filteredHosts.Count) hosts to the admin center for user $($wacCredential.UserName)"
        $apiEndpoint = "http$(if($useSsl){'s'})://$($wachostname):$Port/api/connections"

        $bodyHash = foreach ($vm in $filteredHosts)
        {
            @{
                id   = "msft.sme.connection-type.server!$($vm.FQDN)"
                name = $vm.FQDN
                type = "msft.sme.connection-type.server"
            }
        }

        try
        {
            [ServerCertificateValidationCallback]::Ignore()

            $paramIwr = @{
                Method      = 'PUT'
                Uri         = $apiEndpoint
                Credential  = $wacCredential
                Body        = $($bodyHash | ConvertTo-Json)
                ContentType = 'application/json'
                ErrorAction = 'Stop'
            }

            if ($PSEdition -eq 'Core' -and (Get-Command Invoke-RestMethod).Parameters.COntainsKey('SkipCertificateCheck'))
            {
                $paramIwr.SkipCertificateCheck = $true
            }

            $response = Invoke-RestMethod @paramIwr
            if ($response.changes.Count -ne $filteredHosts.Count)
            {
                Write-ScreenInfo -Type Error -Message "Result set too small, there has likely been an issue adding the managed nodes. Server response:`r`n`r`n$($response.changes)"
            }

            Write-ScreenInfo -Message "Successfully added $($filteredHosts.Count) machines as connections for $($wacCredential.UserName)"
        }
        catch
        {
            Write-ScreenInfo -Type Error -Message "Could not add server connections. Invoke-RestMethod says: $($_.Exception.Message)"
        }
    }
}
