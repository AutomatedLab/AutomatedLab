#region Install-LabAdfs
function Install-LabAdfs
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param ()
    
    Write-LogFunctionEntry

    Write-ScreenInfo -Message 'Configuring ADFS roles...'
    
    if (-not (Get-LabMachine))
    {
        Write-Warning -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        Write-LogFunctionExit
        return
    }
    
    $machines = Get-LabMachine -Role ADFS
    
    if (-not $machines)
    {
        return
    }
    
    if ($machines | Where-Object  { -not $_.DomainName })
    {
        Write-Error "There are ADFS Server defined in the lab that are not domain joined. ADFS must be joined to a domain."
        return
    }
    
    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -ComputerName $machines -Wait -ProgressIndicator 15

    $labAdfsServers = $machines | Group-Object -Property DomainName

    foreach ($domainGroup in $labAdfsServers)
    {
        $domainName = $domainGroup.Name
        $adfsServers = $domainGroup.Group | Where-Object { $_.Roles.Name -eq 'ADFS' }
        Write-ScreenInfo "Installing the ADFS Servers '$($adfsServers -join ',')'" -Type Info
        
        $ca = Get-LabIssuingCA -DomainName $domainName
        Write-Verbose "The CA that will be used is '$ca'"
        $adfsDc = Get-LabMachine -Role RootDC, FirstChildDC, DC | Where-Object DomainName -eq $domainName
        Write-Verbose "The DC that will be used is '$adfsDc'"
    
        $1stAdfsServer = $adfsServers | Select-Object -First 1
        $1stAdfsServerAdfsRole = $1stAdfsServer.Roles | Where-Object Name -eq ADFS
        $otherAdfsServers = $adfsServers | Select-Object -Skip 1

        #use the display name as defined in the role. If it is not defined, construct one with the domain name (Adfs<FlatDomainName>)
        $adfsDisplayName = $1stAdfsServerAdfsRole.Properties.DisplayName
        if (-not $adfsDisplayName)
        {
            $adfsDisplayName = "Adfs$($1stAdfsServer.DomainName.Split('.')[0])"
        }
        
        $adfsServiceName = $1stAdfsServerAdfsRole.Properties.ServiceName
        if (-not $adfsServiceName) { $adfsServiceName = 'AdfsService'}
        $adfsServicePassword = $1stAdfsServerAdfsRole.Properties.ServicePassword
        if (-not $adfsServicePassword) { $adfsServicePassword = 'Somepass1'}
        
        Write-Verbose "The ADFS Farm display name in domain '$domainName' is '$adfsDisplayName'"
        $adfsCertificateSubject = "CN=adfs.$($domainGroup.Name)"
        Write-Verbose "The subject used to obtain an SSL certificate is '$adfsCertificateSubject'"
        $adfsCertificateSAN = "adfs.$domainName" , "enterpriseregistration.$domainName"

        $adfsFlatName = $adfsCertificateSubject.Substring(3).Split('.')[0]
        Write-Verbose "The ADFS flat name is '$adfsFlatName'"
        $adfsFullName = $adfsCertificateSubject.Substring(3)
        Write-Verbose "The ADFS full name is '$adfsFullName'"    

        if (-not (Test-LabCATemplate -TemplateName AdfsSsl -ComputerName $ca))
        {
            New-LabCATemplate -TemplateName AdfsSsl -DisplayName 'ADFS SSL' -SourceTemplateName WebServer -ApplicationPolicy ServerAuthentication `
            -EnrollmentFlags Autoenrollment -PrivateKeyFlags AllowKeyExport -Version 2 -SamAccountName 'Domain Computers' -ComputerName $ca -ErrorAction Stop
        }
    
        Write-Verbose "Requesting SSL certificate on the '$1stAdfsServer'"
        $cert = Request-LabCertificate -Subject $adfsCertificateSubject -SAN $adfsCertificateSAN -TemplateName AdfsSsl -ComputerName $1stAdfsServer -PassThru
        $certThumbprint = $cert.Thumbprint
        Write-Verbose "Certificate thumbprint is '$certThumbprint'"
    
        foreach ($otherAdfsServer in $otherAdfsServers)
        {
            Write-Verbose "Adding the SSL certificate to machine '$otherAdfsServer'"
            Get-LabCertificatePfx -ComputerName $1stAdfsServer -Thumbprint $certThumbprint | Add-LabCertificatePfx -ComputerName $otherAdfsServer
        }    

        Invoke-LabCommand -ActivityName 'Add ADFS Service User and DNS record' -ComputerName $adfsDc -ScriptBlock {
            Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10) #not required if not used GMSA
            New-ADUser -Name $adfsServiceName -AccountPassword ($adfsServicePassword | ConvertTo-SecureString -AsPlainText -Force) -Enabled $true -PasswordNeverExpires $true
    
            foreach ($entry in $adfsServers)
            {
                $ip = (Get-DnsServerResourceRecord -Name $entry -ZoneName $domainName).RecordData.IPv4Address.IPAddressToString
                Add-DnsServerResourceRecord -Name $adfsFlatName -ZoneName $domainName -IPv4Address $ip -A
            }
        } -Variable (Get-Variable -Name adfsServers, domainName, adfsFlatName, adfsServiceName, adfsServicePassword)

        Install-LabWindowsFeature -ComputerName $adfsServers -FeatureName ADFS-Federation

        $result = Invoke-LabCommand -ActivityName 'Installing ADFS Farm' -ComputerName $1stAdfsServer -ScriptBlock {
            $cred = New-Object pscredential("$($env:USERDNSDOMAIN)\$adfsServiceName", ($adfsServicePassword | ConvertTo-SecureString -AsPlainText -Force))

            $certificate = Get-Item -Path "Cert:\LocalMachine\My\$certThumbprint"
            Install-AdfsFarm -CertificateThumbprint $certificate.Thumbprint -FederationServiceDisplayName $adfsDisplayName -FederationServiceName $certificate.SubjectName.Name.Substring(3) -ServiceAccountCredential $cred
        } -Variable (Get-Variable -Name certThumbprint, adfsDisplayName, adfsServiceName, adfsServicePassword) -PassThru
        
        if ($result.Status -ne 'Success')
        {
            Write-Error "ADFS could not be configured. The error message was: '$($result.Message -join ', ')'" -TargetObject $result
            return
        }
    
        $result = if ($otherAdfsServers)
        {
            Invoke-LabCommand -ActivityName 'Installing ADFS Farm' -ComputerName $otherAdfsServers -ScriptBlock {
                $cred = New-Object pscredential("$($env:USERDNSDOMAIN)\$adfsServiceName", ($adfsServicePassword | ConvertTo-SecureString -AsPlainText -Force))

                Add-AdfsFarmNode -CertificateThumbprint $certThumbprint -PrimaryComputerName $1stAdfsServer.Name -ServiceAccountCredential $cred -OverwriteConfiguration
            } -Variable (Get-Variable -Name certThumbprint, 1stAdfsServer, adfsServiceName, adfsServicePassword) -PassThru
            
            if ($result.Status -ne 'Success')
            {
                Write-Error "ADFS could not be configured. The error message was: '$($result.Message -join ', ')'" -TargetObject $result
                return
            }
        }
    }
    
    Write-LogFunctionExit
}
#endregion Install-LabAdfs

#region Install-LabAdfsProxy
function Install-LabAdfsProxy
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param ()
    
    Write-LogFunctionEntry

    Write-ScreenInfo -Message 'Configuring ADFS roles...'
    
    $lab = Get-Lab
    
    if (-not (Get-LabMachine))
    {
        Write-Warning -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        Write-LogFunctionExit
        return
    }
    
    $machines = Get-LabMachine -Role ADFSProxy
    
    if (-not $machines)
    {
        return
    }
    
    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -RoleName ADFSProxy -Wait -ProgressIndicator 15

    $labAdfsProxies = Get-LabMachine -Role ADFSProxy
    $job = Install-LabWindowsFeature -ComputerName $labAdfsProxies -FeatureName Web-Application-Proxy -AsJob -PassThru
    Wait-LWLabJob -Job $job

    Write-ScreenInfo "Installing the ADFS Proxy Servers '$($labAdfsProxies -join ',')'" -Type Info
    foreach ($labAdfsProxy in $labAdfsProxies)
    {
        Write-Verbose "Installing ADFS Proxy on '$labAdfsProxy'"
        $adfsProxyRole = $labAdfsProxy.Roles | Where-Object Name -eq ADFSProxy
        $adfsFullName = $adfsProxyRole.Properties.AdfsFullName
        $adfsDomainName = $adfsProxyRole.Properties.AdfsDomainName
        Write-Verbose "ADFS Full Name is '$adfsFullName'"
        
        $someAdfsServer = Get-LabMachine -Role ADFS | Where-Object DomainName -eq $adfsDomainName | Get-Random
        Write-Verbose "Getting certificate from some ADFS server '$someAdfsServer'"
        $cert = Get-LabCertificatePfx -ComputerName $someAdfsServer -DnsName $adfsFullName
        if (-not $cert)
        {
            Write-Error "Could not get certificate from '$someAdfsServer'. Cannot continue with ADFS Proxy setup."
            return
        }
        Write-Verbose "Got certificate with thumbprint '$($cert.Thumbprint)'"
        
        Write-Verbose "Adding certificate to '$labAdfsProxy'"
        $cert | Add-LabCertificatePfx -ComputerName $labAdfsProxy
        
        $certThumbprint = $cert.Thumbprint
        $cred = ($lab.Domains | Where-Object Name -eq $adfsDomainName).GetCredential()

        $result = Invoke-LabCommand -ActivityName 'Configuring ADFS Proxy Servers' -ComputerName $labAdfsProxy -ScriptBlock {
            Install-WebApplicationProxy -FederationServiceTrustCredential $cred -CertificateThumbprint $certThumbprint -FederationServiceName $adfsFullName
        } -Variable (Get-Variable -Name certThumbprint, cred, adfsFullName) -PassThru
        
    }
    
    Write-LogFunctionExit
}
#endregion Install-LabAdfs