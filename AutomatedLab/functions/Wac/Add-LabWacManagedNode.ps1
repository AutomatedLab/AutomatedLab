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

        if ($filteredHosts.Count -eq 0) { return }

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
