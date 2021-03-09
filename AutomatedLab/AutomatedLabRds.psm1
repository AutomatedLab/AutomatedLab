function Install-LabRemoteDesktopServices
{
    [CmdletBinding()]
    param ( )

    Write-LogFunctionEntry

    $lab = Get-Lab

    Start-LabVm -Role RemoteDesktopConnectionBroker, RemoteDesktopGateway, RemoteDesktopLicensing, RemoteDesktopSessionHost, RemoteDesktopVirtualizationHost, RemoteDesktopWebAccess -Wait
    $gw = Get-LabVm -Role RemoteDesktopGateway
    $webAccess = Get-LabVm -Role RemoteDesktopWebAccess
    $sessionHosts = Get-LabVm -Role RemoteDesktopSessionHost
    $connectionBroker = Get-LabVm -Role RemoteDesktopConnectionBroker
    $licensing = Get-LabVm -Role RemoteDesktopLicensing
    $virtHost = Get-LabVm -Role RemoteDesktopVirtualizationHost
    
    if (-not $webAccess)
    {
        $webAccess = Get-LabVm -Role RemoteDesktopGateway
    }
    if (-not $sessionHosts)
    {
        $sessionHosts = Get-LabVm -Role RemoteDesktopGateway
    }
    if (-not $connectionBroker)
    {
        $connectionBroker = Get-LabVm -Role RemoteDesktopGateway
    }
    if (-not $licensing)
    {
        $licensing = Get-LabVm -Role RemoteDesktopGateway
    }
    if (-not $virtHost)
    {
        $virtHost = Get-LabVm -Role HyperV
    }

    $gwFqdn = if ($lab.DefaultVirtualizationEngine -eq 'Azure') { $gw.AzureConnectionInfo.DnsName } else { $gw.FQDN }
    $gwRole = $gw.Roles | Where-Object Name -eq 'RemoteDesktopGateway'
    if ($gwRole -and $gwRole.Properties.ContainsKey('GatewayExternalFqdn'))
    {
        $gwFqdn = $gwRole.Properties['GatewayExternalFqdn']
    }

    if (Get-LabVm -Role CARoot)
    {
        $certGw = Request-LabCertificate -Subject "CN=$gwFqdn" -SAN ($gw.FQDN -replace $gw.Name, '*') -TemplateName WebServer -ComputerName $gw -PassThru
        $gwCredential = $gw.GetCredential($lab)

        Invoke-LabCommand -ComputerName $gw -ScriptBlock {
            Export-PfxCertificate -Cert (Get-Item cert:\localmachine\my\$($certGw.Thumbprint)) -FilePath C:\cert.pfx -ProtectTo $gwCredential.UserName -Force
            Export-Certificate -Cert (Get-Item cert:\localmachine\my\$($certGw.Thumbprint)) -FilePath C:\cert.cer -Type CERT -Force
        } -Variable (Get-Variable certGw, gwCredential) -NoDisplay
    
        Receive-File -SourceFilePath C:\cert.pfx -DestinationFilePath (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath cert.pfx) -Session (New-LabPSSession -ComputerName $gw)
        Receive-File -SourceFilePath C:\cert.cer -DestinationFilePath (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath cert.cer) -Session (New-LabPSSession -ComputerName $gw)
        $certFiles = @(
            Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath cert.pfx
            Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath cert.cer
        )

        $nonGw = Get-LabVM -Filter { $_.Roles.Name -like 'RemoteDesktop*' -and $_.Name -ne $gw.Name }
        Copy-LabFileItem -Path $certFiles -ComputerName $nonGw 
        Invoke-LabCommand -ComputerName $nonGw  -ScriptBlock {
            Import-PfxCertificate -Exportable -FilePath C:\cert.pfx -CertStoreLocation Cert:\LocalMachine\my
        } -NoDisplay
    }

    if ($lab.DefaultVirtualizationEngine -eq 'Azure') 
    {
        Add-LWAzureLoadBalancedPort -Port 443 -DestinationPort 443 -ComputerName $gw
    }

    # Initial deployment
    Install-LabWindowsFeature -ComputerName $gw -FeatureName RDS-Gateway -IncludeManagementTools -NoDisplay

    $gwRole = $gw.Roles | Where-Object Name -eq 'RemoteDesktopGateway'
    $webAccessRole = $webAccess.Roles | Where-Object Name -eq 'RemoteDesktopWebAccess'
    $connectionBrokerRole = $connectionBroker.Roles | Where-Object Name -eq 'RemoteDesktopConnectionBroker'
    $licensingRole = $licensing.Roles | Where-Object Name -eq 'RemoteDesktopLicensing'
    $virtHostRole = $virtHost.Roles | Where-Object Name -eq 'RemoteDesktopVirtualizationHost'

    $gwConfig = @{
        GatewayExternalFqdn  = $gwFqdn
        BypassLocal          = if ($gwRole -and $gwRole.Properties.ContainsKey('BypassLocal')) { [Convert]::ToBoolean($gwRole.Properties['BypassLocal']) } else { $true }
        LogonMethod          = if ($gwRole -and $gwRole.Properties.ContainsKey('LogonMethod')) { $gwRole.Properties['LogonMethod'] } else { 'Password' }
        UseCachedCredentials = if ($gwRole -and $gwRole.Properties.ContainsKey('UseCachedCredentials')) { [Convert]::ToBoolean($gwRole.Properties['UseCachedCredentials']) } else { $true }
        ConnectionBroker     = $connectionBroker.Fqdn
        GatewayMode          = if ($gwRole -and $gwRole.Properties.ContainsKey('GatewayMode')) { $gwRole.Properties['GatewayMode'] } else { 'Custom' }
        Force                = $true
    }

    $sessionHostRoles = $sessionHosts.Roles | Where-Object Name -eq 'RemoteDesktopSessionHost' | Group-Object { $_.Properties['CollectionName'] } # GROUP! CollectionName
    [hashtable[]]$sessionCollectionConfig = foreach ($sessionhost in $sessionHostRoles)
    {
        $firstRoleMember = $sessionhost.Group | Select-Object -First 1
        $param = @{
            CollectionName        = $sessionhost.Name
            CollectionDescription = if ($firstRoleMember.Properties.ContainsKey('CollectionDescription')) { $firstRoleMember.Properties['CollectionDescription'] } else { 'AutomatedLab session host collection' }
            ConnectionBroker      = $connectionBroker.Fqdn
            SessionHost           = $sessionhost.Group
        }

        if ($firstRoleMember.Properties.Keys -in 'PersonalUnmanaged', 'AutoAssignUser', 'GrantAdministrativePrivilege')
        {
            $param['PersonalUnmanaged'] = $true
            $param['AutoAssignUser'] = if ($firstRoleMember.Properties.ContainsKey('AutoAssignUser')) { [Convert]::ToBoolean($firstRoleMember.Properties['AutoAssignUser']) } else { $true }
            $param['GrantAdministrativePrivilege'] = if ($firstRoleMember.Properties.ContainsKey('GrantAdministrativePrivilege')) { [Convert]::ToBoolean($firstRoleMember.Properties['GrantAdministrativePrivilege']) } else { $false }
        }
        elseif ($firstRoleMember.Properties.ContainsKey('PooledUnmanaged'))
        {
            $param['PooledUnmanaged'] = $true
        }
        $param
    }

    $deploymentConfig = @{
        ConnectionBroker = $connectionBroker.Fqdn
        WebAccessServer  = $webAccess.Fqdn
        SessionHost      = $sessionHosts.Fqdn
    }
    $licenseConfig = @{
        Mode             = if ($licensingRole -and $licensingRole.Properties.ContainsKey('Mode')) { $licensingRole.Properties['Mode'] } else { 'PerUser' }
        ConnectionBroker = $connectionBroker.Fqdn 
        LicenseServer    = $licensing.Fqdn 
        Force            = $true
    }
    Invoke-LabCommand -ComputerName $connectionBroker -ScriptBlock {
        New-RDSessionDeployment @deploymentConfig
        New-RDSessionCollection -PersonalUnmanaged -AutoAssignUser @sessionCollectionConfig
        Set-RDDeploymentGatewayConfiguration @gwConfig
        Set-RDLicenseConfiguration @licenseConfig
    } -Variable (Get-Variable gwConfig, sessionCollectionConfig, deploymentConfig, licenseConfig) -NoDisplay

    $prefix = if (Get-LabVm -Role CARoot)
    {
        Invoke-LabCommand -ComputerName $connectionBroker -ScriptBlock {        
            Set-RDCertificate -Role RDWebAccess -Thumbprint $certGw.Thumbprint -ConnectionBroker $connectionBroker.Fqdn -Force -ErrorAction SilentlyContinue
            Set-RDCertificate -Role RDGateway -Thumbprint $certGw.Thumbprint -ConnectionBroker $connectionBroker.Fqdn -Force -ErrorAction SilentlyContinue
            Set-RDCertificate -Role RDPublishing -Thumbprint $certGw.Thumbprint -ConnectionBroker $connectionBroker.Fqdn -Force -ErrorAction SilentlyContinue
            Set-RDCertificate -Role RDRedirector -Thumbprint $certGw.Thumbprint -ConnectionBroker $connectionBroker.Fqdn -Force -ErrorAction SilentlyContinue
        } -Variable (Get-Variable connectionBroker, certGw) -NoDisplay
        'https'
    }
    else
    {
        'http'
    }

    # Web Client
    if (-not (Test-LabHostConnected)) 
    {
        Write-LogFunctionExit
        return
    }

    if (-not (Get-Module -Name PowerShellGet -ListAvailable).Where( { $_.Version -ge '2.0.0.0' }))
    {
        Write-LogFunctionExit
        return
    }

    $destination = Join-Path -Path (Get-LabSourcesLocation -Local) -ChildPath SoftwarePackages
    Save-Module -Name RDWebClientManagement -Path $destination -AcceptLicense
    Import-Module -Name (Join-Path -Path $destination -ChildPath 'RDWebClientManagement/*/RDWebClientManagement.psd1' -Resolve)
    Send-ModuleToPSSession -Module (Get-Module (Join-Path -Path $destination -ChildPath 'RDWebClientManagement/*/RDWebClientManagement.psd1' -Resolve) -ListAvailable) -Session (New-LabPSSession -ComputerName $webAccess)
    
    Save-RDWebClientPackage -Path $destination
    $client = Join-Path -Path $destination -ChildPath 'rdwebclient*.zip' -Resolve
    $localPath = Copy-LabFileItem -Path $client -ComputerName $webAccess -UseAzureLabSourcesOnAzureVm $false -PassThru -DestinationFolderPath C:\

    Invoke-LabCommand -ComputerName $webAccess -ScriptBlock {
        Install-RDWebClientPackage -Source $localPath
        if (Test-Path -Path C:\cert.cer)
        {
            Import-RDWebClientBrokerCert -Path C:\cert.cer
        }

        Publish-RDWebClientPackage -Type Production -Latest
    } -Variable (Get-Variable localPath) -PassThru

    Invoke-LabCommand -ComputerName (Get-LabVm -Role CaRoot) -ScriptBlock {
        Get-ChildItem -Path Cert:\LocalMachine\my | Select-Object -First 1 | Export-Certificate -FilePath C:\LabRootCa.cer -Type CERT -Force
    } -PassThru -NoDisplay
    Receive-File -SourceFilePath C:\LabRootCa.cer -DestinationFilePath (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath LabRootCa.cer) -Session (New-LabPSSession -ComputerName (Get-LabVm -Role CaRoot))
    Import-Certificate -FilePath (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath LabRootCa.cer) -CertStoreLocation Cert:\CurrentUser\Root

    Write-ScreenInfo -Message "RDWeb Client available at $($prefix)://$gwFqdn/RDWeb/webclient"
    Write-LogFunctionExit
}