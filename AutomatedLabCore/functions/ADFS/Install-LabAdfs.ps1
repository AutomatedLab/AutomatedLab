function Install-LabAdfs
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    Write-ScreenInfo -Message 'Configuring ADFS roles...'

    if (-not (Get-LabVM))
    {
        Write-ScreenInfo -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first' -Type Warning
        Write-LogFunctionExit
        return
    }

    $machines = Get-LabVM -Role ADFS

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
        Write-PSFMessage "The CA that will be used is '$ca'"
        $adfsDc = Get-LabVM -Role RootDC, FirstChildDC, DC | Where-Object DomainName -eq $domainName
        Write-PSFMessage "The DC that will be used is '$adfsDc'"

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

        Write-PSFMessage "The ADFS Farm display name in domain '$domainName' is '$adfsDisplayName'"
        $adfsCertificateSubject = "CN=adfs.$($domainGroup.Name)"
        Write-PSFMessage "The subject used to obtain an SSL certificate is '$adfsCertificateSubject'"
        $adfsCertificateSAN = "adfs.$domainName" , "enterpriseregistration.$domainName"

        $adfsFlatName = $adfsCertificateSubject.Substring(3).Split('.')[0]
        Write-PSFMessage "The ADFS flat name is '$adfsFlatName'"
        $adfsFullName = $adfsCertificateSubject.Substring(3)
        Write-PSFMessage "The ADFS full name is '$adfsFullName'"

        if (-not (Test-LabCATemplate -TemplateName AdfsSsl -ComputerName $ca))
        {
            New-LabCATemplate -TemplateName AdfsSsl -DisplayName 'ADFS SSL' -SourceTemplateName WebServer -ApplicationPolicy "Server Authentication" `
            -EnrollmentFlags Autoenrollment -PrivateKeyFlags AllowKeyExport -Version 2 -SamAccountName 'Domain Computers' -ComputerName $ca -ErrorAction Stop
        }

        Write-PSFMessage "Requesting SSL certificate on the '$1stAdfsServer'"
        $cert = Request-LabCertificate -Subject $adfsCertificateSubject -SAN $adfsCertificateSAN -TemplateName AdfsSsl -ComputerName $1stAdfsServer -PassThru
        $certThumbprint = $cert.Thumbprint
        Write-PSFMessage "Certificate thumbprint is '$certThumbprint'"

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
            # Copy Service-communication/SSL Certificate to all ADFS Servers
            Write-PSFMessage "Copying SSL Certificate to secondary AD FS nodes"
            Invoke-LabCommand -ActivityName 'Exporting SSL Cert' -ComputerName $1stAdfsServer -Variable (Get-Variable -Name certThumbprint) -ScriptBlock {
                Get-Item "Cert:\LocalMachine\My\$certThumbprint" | Export-PfxCertificate -FilePath "C:\sslcert.pfx" -ProtectTo "Domain Users"
            }
            Invoke-LabCommand -ActivityName 'Importing SSL Cert' -ComputerName $otherAdfsServers -Variable (Get-Variable -Name certThumbprint,1stAdfsServer) -ScriptBlock {
                Get-Item "\\$1stAdfsServer\C$\sslcert.pfx" | Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -Exportable
            }
            Invoke-LabCommand -ActivityName 'Removing PFX file' -ComputerName $1stAdfsServer -ScriptBlock {
                Remove-Item -Path "C:\sslcert.pfx"
            }

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
