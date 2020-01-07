#region Install-LWLabCAServers
function Install-LWLabCAServers
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Historic cmdlet, will not be updated")]
    param (
        [Parameter(Mandatory = $true)][string]$ComputerName,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$DomainName,
        [Parameter(Mandatory = $true)][string]$UserName,
        [Parameter(Mandatory = $true)][string]$Password,
        [Parameter(Mandatory = $false)][string]$ForestAdminUserName,
        [Parameter(Mandatory = $false)][string]$ForestAdminPassword,
        [Parameter(Mandatory = $false)][string]$ParentCA,
        [Parameter(Mandatory = $false)][string]$ParentCALogicalName,
        [Parameter(Mandatory = $true)][string]$CACommonName,
        [Parameter(Mandatory = $true)][string]$CAType,
        [Parameter(Mandatory = $true)][string]$KeyLength,
        [Parameter(Mandatory = $true)][string]$CryptoProviderName,
        [Parameter(Mandatory = $true)][string]$HashAlgorithmName,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$DatabaseDirectory,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$LogDirectory,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$CpsUrl,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$CpsText,
        [Parameter(Mandatory = $true)][boolean]$UseLDAPAIA,
        [Parameter(Mandatory = $true)][boolean]$UseHTTPAia,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$AIAHTTPURL01,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$AiaHttpUrl02,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$AIAHTTPURL01UploadLocation,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$AiaHttpUrl02UploadLocation,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$OCSPHttpUrl01,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$OCSPHttpUrl02,
        [Parameter(Mandatory = $true)][boolean]$UseLDAPCRL,
        [Parameter(Mandatory = $true)][boolean]$UseHTTPCRL,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$CDPHTTPURL01,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$CDPHTTPURL02,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$CDPHTTPURL01UploadLocation,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$CDPHTTPURL02UploadLocation,
        [Parameter(Mandatory = $true)][boolean]$InstallOCSP,
        [Parameter(Mandatory = $false)][string]$ValidityPeriod,
        [Parameter(Mandatory = $false)][int]$ValidityPeriodUnits,
        [Parameter(Mandatory = $true)][string]$CRLPeriod,
        [Parameter(Mandatory = $true)][int]$CRLPeriodUnits,
        [Parameter(Mandatory = $true)][string]$CRLOverlapPeriod,
        [Parameter(Mandatory = $true)][int]$CRLOverlapUnits,
        [Parameter(Mandatory = $true)][string]$CRLDeltaPeriod,
        [Parameter(Mandatory = $true)][int]$CRLDeltaPeriodUnits,
        [Parameter(Mandatory = $true)][string]$CertsValidityPeriod,
        [Parameter(Mandatory = $true)][int]$CertsValidityPeriodUnits,
        [Parameter(Mandatory = $true)][boolean]$InstallWebEnrollment,
        [Parameter(Mandatory = $true)][boolean]$InstallWebRole,
        [Parameter(Mandatory = $true)][boolean]$DoNotLoadDefaultTemplates,
        [Parameter(Mandatory = $false)][int]$PreDelaySeconds
    )

    Write-LogFunctionEntry

    Install-LabWindowsFeature -ComputerName $ComputerName -FeatureName RSAT-AD-Tools -IncludeAllSubFeature -NoDisplay

    #region - Create parameter table
    $param = @{ }
    $param.Add('ComputerName', $ComputerName)
    $param.add('DomainName', $DomainName)

    $param.Add('UserName', $UserName)
    $param.Add('Password', $Password)
    $param.Add('ForestAdminUserName', $ForestAdminUserName)
    $param.Add('ForestAdminPassword', $ForestAdminPassword)

    $param.Add('CACommonName', $CACommonName)

    $param.Add('CAType', $CAType)

    $param.Add('CryptoProviderName', $CryptoProviderName)
    $param.Add('HashAlgorithmName', $HashAlgorithmName)

    $param.Add('KeyLength', $KeyLength)

    $param.Add('CertEnrollFolderPath', $CertEnrollFolderPath)
    $param.Add('DatabaseDirectory', $DatabaseDirectory)
    $param.Add('LogDirectory', $LogDirectory)

    $param.Add('CpsUrl', $CpsUrl)
    $param.Add('CpsText', """$($CpsText)""")

    $param.Add('UseLDAPAIA', $UseLDAPAIA)
    $param.Add('UseHTTPAia', $UseHTTPAia)
    $param.Add('AIAHTTPURL01', $AIAHTTPURL01)
    $param.Add('AiaHttpUrl02', $AiaHttpUrl02)
    $param.Add('AIAHTTPURL01UploadLocation', $AIAHTTPURL01UploadLocation)
    $param.Add('AiaHttpUrl02UploadLocation', $AiaHttpUrl02UploadLocation)

    $param.Add('OCSPHttpUrl01', $OCSPHttpUrl01)
    $param.Add('OCSPHttpUrl02', $OCSPHttpUrl02)

    $param.Add('UseLDAPCRL', $UseLDAPCRL)
    $param.Add('UseHTTPCRL', $UseHTTPCRL)
    $param.Add('CDPHTTPURL01', $CDPHTTPURL01)
    $param.Add('CDPHTTPURL02', $CDPHTTPURL02)
    $param.Add('CDPHTTPURL01UploadLocation', $CDPHTTPURL01UploadLocation)
    $param.Add('CDPHTTPURL02UploadLocation', $CDPHTTPURL02UploadLocation)

    $param.Add('InstallOCSP', $InstallOCSP)

    $param.Add('ValidityPeriod', $ValidityPeriod)
    $param.Add('ValidityPeriodUnits', $ValidityPeriodUnits)
    $param.Add('CRLPeriod', $CRLPeriod)
    $param.Add('CRLPeriodUnits', $CRLPeriodUnits)
    $param.Add('CRLOverlapPeriod', $CRLOverlapPeriod)
    $param.Add('CRLOverlapUnits', $CRLOverlapUnits)
    $param.Add('CRLDeltaPeriod', $CRLDeltaPeriod)
    $param.Add('CRLDeltaPeriodUnits', $CRLDeltaPeriodUnits)
    $param.Add('CertsValidityPeriod', $CertsValidityPeriod)
    $param.Add('CertsValidityPeriodUnits', $CertsValidityPeriodUnits)

    $param.Add('InstallWebEnrollment', $InstallWebEnrollment)

    $param.Add('InstallWebRole', $InstallWebRole)

    $param.Add('DoNotLoadDefaultTemplates', $DoNotLoadDefaultTemplates)

    #For Subordinate CAs only
    if ($ParentCA) { $param.add('ParentCA', $ParentCA) }
    if ($ParentCALogicalname) { $param.add('ParentCALogicalname', $ParentCALogicalName) }

    $param.Add('PreDelaySeconds', $PreDelaySeconds)
    #endregion - Create parameter table


    #region - Parameters debug
    Write-Debug -Message '---------------------------------------------------------------------------------------'
    Write-Debug -Message 'Parameters - Entered Install-LWLabCAServers'
    Write-Debug -Message '---------------------------------------------------------------------------------------'
    if ($param.GetEnumerator().count)
    {
        foreach ($key in ($param.GetEnumerator() | Sort-Object -Property Name)) { Write-Debug -message "  $($key.key.padright(27)) $($key.value)" }
    }
    else
    {
        Write-Debug -message '  No parameters specified'
    }
    Write-Debug -Message '---------------------------------------------------------------------------------------'
    Write-Debug -Message ''
    #endregion - Parameters debug




    #region ScriptBlock for installation
    $caScriptBlock = {

        param ($param)

        $param | Export-Clixml C:\DeployDebug\CaParams.xml

        #Make semi-sure that each install of CA server is not done at the same time
        Start-Sleep -Seconds $param.PreDelaySeconds

        Import-Module -Name ServerManager

        #region - Check if CA is already installed
        if ((Get-WindowsFeature -Name 'ADCS-Cert-Authority').Installed)
        {
            Write-Output "A Certificate Authority is already installed on '$($param.ComputerName)'. Skipping installation."
            return
        }
        #endregion

        #region - Create CAPolicy file
        $caPolicyFileName = "$Env:Windir\CAPolicy.inf"
        if (-not (Test-Path -Path $caPolicyFileName))
        {
            Write-Verbose -Message 'Create CAPolicy.inf file'
            Set-Content $caPolicyFileName -Force -Value ';CAPolicy for CA'
            Add-Content $caPolicyFileName -Value '; Please replace sample CPS OID with your own OID'
            Add-Content $caPolicyFileName -Value ''
            Add-Content $caPolicyFileName -Value '[Version]'
            Add-Content $caPolicyFileName -Value "Signature=`"`$Windows NT`$`" "
            Add-Content $caPolicyFileName -Value ''
            Add-Content $caPolicyFileName -Value '[PolicyStatementExtension]'
            Add-Content $caPolicyFileName -Value 'Policies=LegalPolicy'
            Add-Content $caPolicyFileName -Value 'Critical=0'
            Add-Content $caPolicyFileName -Value ''
            Add-Content $caPolicyFileName -Value '[LegalPolicy]'
            Add-Content $caPolicyFileName -Value 'OID=1.3.6.1.4.1.11.21.43'
            Add-Content $caPolicyFileName -Value "Notice=$($param.CpsText)"
            Add-Content $caPolicyFileName -Value "URL=$($param.CpsUrl)"
            Add-Content $caPolicyFileName -Value ''
            Add-Content $caPolicyFileName -Value '[Certsrv_Server]'
            Add-Content $caPolicyFileName -Value 'ForceUTF8=true'
            Add-Content $caPolicyFileName -Value "RenewalKeyLength=$($param.KeyLength)"
            Add-Content $caPolicyFileName -Value "RenewalValidityPeriod=$($param.ValidityPeriod)"
            Add-Content $caPolicyFileName -Value "RenewalValidityPeriodUnits=$($param.ValidityPeriodUnits)"
            Add-Content $caPolicyFileName -Value "CRLPeriod=$($param.CRLPeriod)"
            Add-Content $caPolicyFileName -Value "CRLPeriodUnits=$($param.CRLPeriodUnits)"
            Add-Content $caPolicyFileName -Value "CRLDeltaPeriod=$($param.CRLDeltaPeriod)"
            Add-Content $caPolicyFileName -Value "CRLDeltaPeriodUnits=$($param.CRLDeltaPeriodUnits)"
            Add-Content $caPolicyFileName -Value 'EnableKeyCounting=0'
            Add-Content $caPolicyFileName -Value 'AlternateSignatureAlgorithm=0'
            if ($param.DoNotLoadDefaultTemplates) { Add-Content $caPolicyFileName -Value 'LoadDefaultTemplates=0' }
            if ($param.CAType -like '*root*')
            {
                Add-Content $caPolicyFileName -Value ''
                Add-Content $caPolicyFileName -Value '[Extensions]'
                Add-Content $caPolicyFileName -Value ';Remove CA Version Index'
                Add-Content $caPolicyFileName -Value '1.3.6.1.4.1.311.21.1='
                Add-Content $caPolicyFileName -Value ';Remove CA Hash of previous CA Certificates'
                Add-Content $caPolicyFileName -Value '1.3.6.1.4.1.311.21.2='
                Add-Content $caPolicyFileName -Value ';Remove V1 Certificate Template Information'
                Add-Content $caPolicyFileName -Value '1.3.6.1.4.1.311.20.2='
                Add-Content $caPolicyFileName -Value ';Remove CA of V2 Certificate Template Information'
                Add-Content $caPolicyFileName -Value '1.3.6.1.4.1.311.21.7='
                Add-Content $caPolicyFileName -Value ';Key Usage Attribute set to critical'
                Add-Content $caPolicyFileName -Value '2.5.29.15=AwIBBg=='
                Add-Content $caPolicyFileName -Value 'Critical=2.5.29.15'
            }

            if ($param.DebugPref -eq 'Continue')
            {
                $file = get-content -Path "$Env:Windir\CAPolicy.inf"
                Write-Debug -Message 'CApolicy.inf contents:'
                foreach ($line in $file)
                {
                    Write-Debug -Message $line
                }
            }
        }
        #endregion - Create CAPolicy file


        #region - Install CA
        $hostOSVersion = [system.version](Get-WmiObject -Class Win32_OperatingSystem).Version
        if ($hostOSVersion -ge [system.version]'6.2')
        {
            $InstallFeatures = 'Import-Module -Name ServerManager; Add-WindowsFeature -IncludeManagementTools -Name ADCS-Cert-Authority'
        }
        else
        {
            $InstallFeatures = 'Import-Module -Name ServerManager; Add-WindowsFeature -Name ADCS-Cert-Authority'
        }
        # OCSP not yet supported
        #if ($param.InstallOCSP)          { $InstallFeatures += ", ADCS-Online-Cert" }
        if ($param.InstallWebEnrollment) { $InstallFeatures += ', ADCS-Web-Enrollment' }



        if ($param.ForestAdminUserName)
        {
            Write-Verbose -Message "ForestAdminUserName=$($param.ForestAdminUserName), ForestAdminPassword=$($param.ForestAdminPassword)"

            if ($param.DebugPref -eq 'Continue')
            {
                Write-Verbose -Message "Adding $($param.ForestAdminUserName) to local administrators group"
                Write-Verbose -Message "WinNT:://$($param.ForestAdminUserName.replace('\', '/'))"
            }
            $localGroup = ([ADSI]'WinNT://./Administrators,group')
            $localGroup.psbase.Invoke('Add', ([ADSI]"WinNT://$($param.ForestAdminUserName.replace('\', '/'))").path)
            Write-Verbose -Message "Check 2c -create credential of ""$($param.ForestAdminUserName)"" and ""$($param.ForestAdminPassword)"""
            $forestAdminCred = (New-Object System.Management.Automation.PSCredential($param.ForestAdminUserName, ($param.ForestAdminPassword | ConvertTo-SecureString -AsPlainText -Force)))
        }
        else
        {
            Write-Verbose -Message 'No ForestAdminUserName!'
        }




        Write-Verbose -Message 'Installing roles and features now'
        Write-Verbose -Message "Command: $InstallFeatures"
        Invoke-Expression -Command ($InstallFeatures += " -Confirm:`$false") | Out-Null

        Write-Verbose -Message 'Installing ADCS now'
        $installCommand = 'Install-AdcsCertificationAuthority '
        $installCommand += "-CACommonName                ""$($param.CACommonName)"" "
        $installCommand += "-CAType                      $($param.CAType) "
        $installCommand += "-KeyLength                   $($param.KeyLength) "
        $installCommand += "-CryptoProviderName          ""$($param.CryptoProviderName)"" "
        $installCommand += "-HashAlgorithmName           ""$($param.HashAlgorithmName)"" "
        $installCommand += '-OverwriteExistingKey '
        $installCommand += '-OverwriteExistingDatabase '
        $installCommand += '-Force '
        $installCommand += '-Confirm:$false '
        if ($forestAdminCred) { $installCommand += '-Credential $forestAdminCred ' }

        if ($param.DatabaseDirectory) { $installCommand += "-DatabaseDirectory      $($param.DatabaseDirectory) " }
        if ($param.LogDirectory)      { $installCommand += "-LogDirectory           $($param.LogDirectory) " }

        if ($param.CAType -like '*root*')
        {
            $installCommand += "-ValidityPeriod          $($param.ValidityPeriod) "
            $installCommand += "-ValidityPeriodUnits     $($param.ValidityPeriodUnits) "
        }
        else
        {
            $installCommand += "-ParentCA                $($param.ParentCA)`\$($param.ParentCALogicalName) "
        }
        $installCommand += ' | Out-Null'

        if ($param.DebugPref -eq 'Continue')
        {
            Write-Debug -Message 'Install command:'
            Write-Debug -Message $installCommand
            Set-Content -Path 'C:\debug-CAinst.txt' -value $installCommand
        }


        Invoke-Expression -Command $installCommand


        if ($param.ForestAdminUserName)
        {
            if ($param.DebugPref -eq 'Continue')
            {
                Write-Debug -Message "Removing $($param.ForestAdminUserName) to local administrators group"
            }
            $localGroup = ([ADSI]'WinNT://./Administrators,group')
            $localGroup.psbase.Invoke('Remove', ([ADSI]"WinNT://$($param.ForestAdminUserName.replace('\', '/'))").path)
        }


        if ($param.InstallWebEnrollment)
        {
            Write-Verbose -Message 'Installing Web Enrollment service now'
            Install-ADCSWebEnrollment -Confirm:$False | Out-Null
        }

        if ($param.InstallWebRole)
        {
            if (!(Get-WindowsFeature -Name 'web-server'))
            {
                Add-WindowsFeature -Name 'Web-Server' -IncludeManagementTools

                #Allow "+" characters in URL for supporting delta CRLs
                Set-WebConfiguration -Filter system.webServer/security/requestFiltering -PSPath 'IIS:\sites\Default Web Site' -Value @{allowDoubleEscaping=$true}
            }
        }
        #endregion - Install CA

        #region - Configure IIS virtual directories
        if ($param.UseHTTPAia)
        {
            New-WebVirtualDirectory -Site 'Default Web Site' -Name Aia -PhysicalPath 'C:\Windows\System32\CertSrv\CertEnroll' | Out-Null
            New-WebVirtualDirectory -Site 'Default Web Site' -Name Cdp -PhysicalPath 'C:\Windows\System32\CertSrv\CertEnroll' | Out-Null
        }
        #endregion - Configure IIS virtual directories

        #region - Configure OCSP
        <# OCSP not yet supported
                if ($InstallOCSP)
                {
                Write-Verbose -Message "Installing Online Responder"
                Install-ADCSOnlineResponder -Force | Out-Null
                }
        #>
        #endregion - Configure OCSP







        #region - Configure CA
        function Invoke-CustomExpression
        {
            param ($Command)

            Write-Host $command
            Invoke-Expression -Command $command
        }


        #Declare configuration NC
        if ($param.CAType -like 'Enterprise*')
        {
            $lDAPname = ''
            foreach ($part in ($param.DomainName.split('.')))
            {
                $lDAPname += ",DC=$part"
            }
            Invoke-CustomExpression -Command "certutil -setreg CA\DSConfigDN ""CN=Configuration$lDAPname"""
        }

        #Apply the required CDP Extension URLs
        $command = "certutil -setreg CA\CRLPublicationURLs ""1:$($Env:WinDir)\system32\CertSrv\CertEnroll\%3%8%9.crl"
        if ($param.UseLDAPCRL) { $command += '\n11:ldap:///CN=%7%8,CN=%2,CN=CDP,CN=Public Key Services,CN=Services,%6%10' }
        if ($param.UseHTTPCRL) { $command += "\n2:$($param.CDPHTTPURL01)/%3%8%9.crl" }
        if ($param.CDPHTTPURL01UploadLocation) { $command += "\n1:$($param.CDPHTTPURL01UploadLocation)/%3%8%9.crl" }
        $command += '"'
        Invoke-CustomExpression -Command $command

        #Apply the required AIA Extension URLs
        $command = "certutil -setreg CA\CACertPublicationURLs ""1:$($Env:WinDir)\system3\CertSrv\CertEnroll\%1_%3%4.crt"
        if ($param.UseLDAPAia) { $command += '\n3:ldap:///CN=%7,CN=AIA,CN=Public Key Services,CN=Services,%6%11' }
        if ($param.UseHTTPAia) { $command += "\n2:$($param.AIAHTTPURL01)/%1_%3%4.crt" }
        if ($param.AIAHTTPURL01UploadLocation) { $command += "\n1:$($param.AIAHTTPURL01UploadLocation)/%3%8%9.crl" }
        <# OCSP not yet supported
                if ($param.InstallOCSP -and $param.OCSPHttpUrl01) { $Line += "\n34:$($param.OCSPHttpUrl01)" }
                if ($param.InstallOCSP -and $param.OCSPHttpUrl02) { $Line += "\n34:$($param.OCSPHttpUrl02)" }
        #>
        $command += '"'
        Invoke-CustomExpression -Command $command

        #Define default maximum certificate lifetime for issued certificates
        Invoke-CustomExpression -Command "certutil -setreg ca\ValidityPeriodUnits $($param.CertsValidityPeriodUnits)"
        Invoke-CustomExpression -Command "certutil -setreg ca\ValidityPeriod ""$($param.CertsValidityPeriod)"""

        #Define CRL Publication Intervals
        Invoke-CustomExpression -Command "certutil -setreg CA\CRLPeriodUnits $($param.CRLPeriodUnits)"
        Invoke-CustomExpression -Command "certutil -setreg CA\CRLPeriod ""$($param.CRLPeriod)"""

        #Define CRL Overlap
        Invoke-CustomExpression -Command "certutil -setreg CA\CRLOverlapUnits $($param.CRLOverlapUnits)"
        Invoke-CustomExpression -Command "certutil -setreg CA\CRLOverlapPeriod ""$($param.CRLOverlapPeriod)"""

        #Define Delta CRL
        Invoke-CustomExpression -Command "certutil -setreg CA\CRLDeltaUnits $($param.CRLDeltaPeriodUnits)"
        Invoke-CustomExpression -Command "certutil -setreg CA\CRLDeltaPeriod ""$($param.CRLDeltaPeriod)"""

        #Enable Auditing Logging
        Invoke-CustomExpression -Command 'certutil -setreg CA\Auditfilter 0x7F'

        #Enable UTF-8 Encoding
        Invoke-CustomExpression -Command 'certutil -setreg ca\forceteletex +0x20'

        if ($param.CAType -like '*root*')
        {
            #Disable Discrete Signatures in Subordinate Certificates (WinXP KB968730)
            Invoke-CustomExpression -Command 'certutil -setreg CA\csp\AlternateSignatureAlgorithm 0'

            #Force digital signature removal in KU for cert issuance (see also kb888180)
            Invoke-CustomExpression -Command 'certutil -setreg policy\EditFlags -EDITF_ADDOLDKEYUSAGE'

            #Enable SAN
            Invoke-CustomExpression -Command 'certutil -setreg policy\EditFlags +EDITF_ATTRIBUTESUBJECTALTNAME2'

            #Configure policy module to automatically issue certificates when requested
            Invoke-CustomExpression -Command 'certutil -setreg ca\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\RequestDisposition 1'
        }
        #If CA is Root CA and Sub CAs are present, disable (do not publish) templates (except SubCA template)
        if ($param.DoNotLoadDefaultTemplates)
        {
            Invoke-CustomExpression -Command 'certutil -SetCATemplates +SubCA'
        }
        #endregion - Configure CA





        #region - Restart of CA
        if ((Get-Service -Name 'CertSvc').Status -eq 'Running')
        {
            Write-Verbose -Message 'Stopping ADCS Service'
            $totalretries = 5
            $retries = 0
            do
            {
                Stop-Service -Name 'CertSvc' -ErrorAction SilentlyContinue
                if ((Get-Service -Name 'CertSvc').Status -ne 'Stopped')
                {
                    $retries++
                    Start-Sleep -Seconds 1
                }
            }
            until (((Get-Service -Name 'CertSvc').Status -eq 'Stopped') -or ($retries -ge $totalretries))

            if ((Get-Service -Name 'CertSvc').Status -eq 'Stopped')
            {
                Write-Verbose -Message 'ADCS service is now stopped'
            }
            else
            {
                Write-Error -Message 'Could not stop ADCS Service after several retries'
                return
            }
        }

        Write-Verbose -Message 'Starting ADCS Service now'
        $totalretries = 5
        $retries = 0
        do
        {
            Start-Service -Name 'CertSvc' -ErrorAction SilentlyContinue
            if ((Get-Service -Name 'CertSvc').Status -ne 'Running')
            {
                $retries++
                Start-Sleep -Seconds 1
            }
        }
        until (((Get-Service -Name 'CertSvc').Status -eq 'Running') -or ($retries -ge $totalretries))

        if ((Get-Service -Name 'CertSvc').Status -eq 'Running')
        {
            Write-Verbose -Message 'ADCS service is now started'
        }
        else
        {
            Write-Error -Message 'Could not start ADCS Service after several retries'
            return
        }
        #endregion - Restart of CA


        Write-Verbose -Message 'Waiting for admin interface to be ready'
        $totalretries = 10
        $retries = 0
        do
        {
            $result = Invoke-Expression -Command "certutil -pingadmin .\$($param.CACommonName)"
            if (!($result | Where-Object { $_ -like '*interface is alive*' }))
            {
                $retries++
                Write-Verbose -Message "Admin interface not ready. Check $retries of $totalretries"
                if ($retries -lt $totalretries) { Start-Sleep -Seconds 10 }
            }
        }
        until (($result | Where-Object { $_ -like '*interface is alive*' }) -or ($retries -ge $totalretries))

        if ($result | Where-Object { $_ -like '*interface is alive*' })
        {
            Write-Verbose -Message 'Admin interface is now ready'
        }
        else
        {
            Write-Error -Message 'Admin interface was not ready after several retries'
            return
        }


        #region - Issue of CRL
        Start-Sleep -Seconds 2
        Invoke-Expression -Command 'certutil -crl' | Out-Null
        $totalretries = 12
        $retries = 0
        do
        {
            Start-Sleep -Seconds 5
            $retries++
        }
        until ((Get-ChildItem "$env:systemroot\system32\CertSrv\CertEnroll\*.crl") -or ($retries -ge $totalretries))

        #endregion - Issue of CRL

        if (($param.CAType -like 'Enterprise*') -and ($param.DoNotLoadDefaultTemplates)) { Invoke-Expression 'certutil -SetCATemplates +SubCA' }
    }

    #endregion

    Write-PSFMessage -Message "Performing installation of $($param.CAType) on '$($param.ComputerName)'"
    $job = Invoke-LabCommand -ActivityName "Install CA on '$($param.Computername)'" -ComputerName $param.ComputerName`
    -Scriptblock $caScriptBlock -ArgumentList $param -NoDisplay -AsJob -PassThru

    $job

    Write-LogFunctionExit
}
#endregion Install-LWLabCAServers



#region Install-LWLabCAServers2008
function Install-LWLabCAServers2008
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Historic cmdlet, will not be updated")]
    [Cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]$param
    )

    Write-LogFunctionEntry

    #region - Parameters debug
    Write-Debug -Message '---------------------------------------------------------------------------------------'
    Write-Debug -Message 'Parameters - Entered Install-LWLabCAServers'
    Write-Debug -Message '---------------------------------------------------------------------------------------'
    if ($param.GetEnumerator().count)
    {
        foreach ($key in ($param.GetEnumerator() | Sort-Object -Property Name)) { Write-Debug -message "  $($key.key.padright(27)) $($key.value)" }
    }
    else
    {
        Write-Debug -message '  No parameters specified'
    }
    Write-Debug -Message '---------------------------------------------------------------------------------------'
    Write-Debug -Message ''
    #endregion - Parameters debug




    #region ScriptBlock for installation
    $caScriptBlock = {

        param ($param)

        function Install-WebEnrollment
        {
            [CmdletBinding()]

            param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
                [string]$CAConfig
            )

            # check if web enrollment binaries are installed
            Import-Module ServerManager

            # instanciate COM object
            try
            {
                $EWPSetup = New-Object -ComObject CertOCM.CertSrvSetup.1
            }
            catch
            {
                Write-ScreenInfo "Unable to load necessary interfaces. Your Windows Server operating system is not supported!" -Type Warning
                return
            }

            # initialize the object to install only web enrollment
            $EWPSetup.InitializeDefaults($false,$true)
            try
            {
                # set required information and install the role
                $EWPSetup.SetWebCAInformation($CAConfig)
                $EWPSetup.Install()
            }
            catch
            {
                $_
                return
            }
            Write-Host "Successfully installed Enrollment Web Pages on local computer!" -ForegroundColor Green
        }

        Import-Module -Name ServerManager

        #region - Check if CA is already installed
        Write-Verbose -Message 'Check if ADCS-Cert-Authority is already installed'
        if ((Get-WindowsFeature -Name 'ADCS-Cert-Authority').Installed)
        {
            Write-Verbose -Message 'ADCS-Cert-Authority is already installed. Returning'
            Write-Output "A Certificate Authority is already installed on '$($param.ComputerName)'. Skipping installation."
            return
        }
        #endregion

        #region - Create CAPolicy file
        $caPolicyFileName = "$Env:Windir\CAPolicy.inf"
        if (-not (Test-Path -Path $caPolicyFileName))
        {
            Write-Verbose -Message 'Create CAPolicy.inf file'
            Set-Content $caPolicyFileName -Force -Value ';CAPolicy for CA'
            Add-Content $caPolicyFileName -Value '; Please replace sample CPS OID with your own OID'
            Add-Content $caPolicyFileName -Value ''
            Add-Content $caPolicyFileName -Value '[Version]'
            Add-Content $caPolicyFileName -Value "Signature=`"`$Windows NT`$`" "
            Add-Content $caPolicyFileName -Value ''
            Add-Content $caPolicyFileName -Value '[PolicyStatementExtension]'
            Add-Content $caPolicyFileName -Value 'Policies=LegalPolicy'
            Add-Content $caPolicyFileName -Value 'Critical=0'
            Add-Content $caPolicyFileName -Value ''
            Add-Content $caPolicyFileName -Value '[LegalPolicy]'
            Add-Content $caPolicyFileName -Value 'OID=1.3.6.1.4.1.11.21.43'
            Add-Content $caPolicyFileName -Value "Notice=$($param.CpsText)"
            Add-Content $caPolicyFileName -Value "URL=$($param.CpsUrl)"
            Add-Content $caPolicyFileName -Value ''
            Add-Content $caPolicyFileName -Value '[Certsrv_Server]'
            Add-Content $caPolicyFileName -Value 'ForceUTF8=true'
            Add-Content $caPolicyFileName -Value "RenewalKeyLength=$($param.KeyLength)"
            Add-Content $caPolicyFileName -Value "RenewalValidityPeriod=$($param.ValidityPeriod)"
            Add-Content $caPolicyFileName -Value "RenewalValidityPeriodUnits=$($param.ValidityPeriodUnits)"
            Add-Content $caPolicyFileName -Value "CRLPeriod=$($param.CRLPeriod)"
            Add-Content $caPolicyFileName -Value "CRLPeriodUnits=$($param.CRLPeriodUnits)"
            Add-Content $caPolicyFileName -Value "CRLDeltaPeriod=$($param.CRLDeltaPeriod)"
            Add-Content $caPolicyFileName -Value "CRLDeltaPeriodUnits=$($param.CRLDeltaPeriodUnits)"
            Add-Content $caPolicyFileName -Value 'EnableKeyCounting=0'
            Add-Content $caPolicyFileName -Value 'AlternateSignatureAlgorithm=0'
            if ($param.DoNotLoadDefaultTemplates -eq 'True') { Add-Content $caPolicyFileName -Value 'LoadDefaultTemplates=0' }
            if ($param.CAType -like '*root*')
            {
                Add-Content $caPolicyFileName -Value ''
                Add-Content $caPolicyFileName -Value '[Extensions]'
                Add-Content $caPolicyFileName -Value ';Remove CA Version Index'
                Add-Content $caPolicyFileName -Value '1.3.6.1.4.1.311.21.1='
                Add-Content $caPolicyFileName -Value ';Remove CA Hash of previous CA Certificates'
                Add-Content $caPolicyFileName -Value '1.3.6.1.4.1.311.21.2='
                Add-Content $caPolicyFileName -Value ';Remove V1 Certificate Template Information'
                Add-Content $caPolicyFileName -Value '1.3.6.1.4.1.311.20.2='
                Add-Content $caPolicyFileName -Value ';Remove CA of V2 Certificate Template Information'
                Add-Content $caPolicyFileName -Value '1.3.6.1.4.1.311.21.7='
                Add-Content $caPolicyFileName -Value ';Key Usage Attribute set to critical'
                Add-Content $caPolicyFileName -Value '2.5.29.15=AwIBBg=='
                Add-Content $caPolicyFileName -Value 'Critical=2.5.29.15'
            }

            if ($param.DebugPref -eq 'Continue')
            {
                $file = get-content -Path "$Env:Windir\CAPolicy.inf"
                Write-Debug -Message 'CApolicy.inf contents:'
                foreach ($line in $file)
                {
                    Write-Debug -Message $line
                }
            }
        }
        #endregion - Create CAPolicy file


        #region - Install CA
        $hostOSVersion = [system.version](Get-WmiObject -Class Win32_OperatingSystem).Version
        if ($hostOSVersion -ge [system.version]'6.2')
        {
            $InstallFeatures = 'Import-Module -Name ServerManager; Add-WindowsFeature -IncludeManagementTools -Name ADCS-Cert-Authority'
        }
        else
        {
            $InstallFeatures = 'Import-Module -Name ServerManager; Add-WindowsFeature -Name ADCS-Cert-Authority'
        }
        # OCSP not yet supported
        #if ($param.InstallOCSP)          { $InstallFeatures += ", ADCS-Online-Cert" }
        if ($param.InstallWebEnrollment) { $InstallFeatures += ', ADCS-Web-Enrollment' }

        Write-Verbose -Message "Install roles and feature using command '$InstallFeatures'"
        Invoke-Expression -Command ($InstallFeatures += " -Confirm:`$false") | Out-Null

        if ($param.ForestAdminUserName)
        {
            Write-Verbose -Message "ForestAdminUserName=$($param.ForestAdminUserName), ForestAdminPassword=$($param.ForestAdminPassword)"

            Write-Verbose -Message "Adding $($param.ForestAdminUserName) to local administrators group"
            Write-Verbose -Message "WinNT:://$($param.ForestAdminUserName.replace('\', '/'))"
            $localGroup = ([ADSI]'WinNT://./Administrators,group')
            $localGroup.psbase.Invoke('Add', ([ADSI]"WinNT://$($param.ForestAdminUserName.replace('\', '/'))").path)
            $forestAdminCred = (New-Object System.Management.Automation.PSCredential($param.ForestAdminUserName, ($param.ForestAdminPassword | ConvertTo-SecureString -AsPlainText -Force)))
        }
        else
        {
            Write-Verbose -Message 'No ForestAdminUserName!'
        }





        try
        {
            $CASetup = New-Object -ComObject CertOCM.CertSrvSetup.1
        }
        catch
        {
            Write-Verbose -Message "Unable to load necessary interfaces. Operating system is not supported for PKI."
            return
        }

        try
        {
            $CASetup.InitializeDefaults($true, $false)
        }
        catch
        {
            Write-Verbose -Message "Cannot initialize setup binaries!"
        }


        $CATypesByVal = @{}
        $CATypesByName.keys | ForEach-Object {$CATypesByVal.Add($CATypesByName[$_],$_)}
        $CAPRopertyByName = @{"CAType"=0
            "CAKeyInfo"=1
            "Interactive"=2
            "ValidityPeriodUnits"=5
            "ValidityPeriod"=6
            "ExpirationDate"=7
            "PreserveDataBase"=8
            "DBDirectory"=9
            "Logdirectory"=10
            "ParentCAMachine"=12
            "ParentCAName"=13
            "RequestFile"=14
            "WebCAMachine"=15
        "WebCAName"=16}
        $CAPRopertyByVal = @{}
        $CAPRopertyByName.keys | ForEach-Object `
        {
            $CAPRopertyByVal.Add($CAPRopertyByName[$_],$_)
        }
        $ValidityUnitsByName = @{"years" = 6}
        $ValidityUnitsByVal = @{6 = "years"}

        $ofs = ", "



        #key length and hashing algorithm verification
        $CAKey = $CASetup.GetCASetupProperty(1)
        if ($param.CryptoProviderName -ne "")
        {
            if ($CASetup.GetProviderNameList() -notcontains $param.CryptoProviderName)
            {
                # TODO add available CryptoProviderName list
                Write-Host "Specified CSP '$param.CryptoProviderName' is not valid!"
            }
            else
            {
                $CAKey.ProviderName = $param.CryptoProviderName
            }
        }
        else
        {
            $CAKey.ProviderName = "RSA#Microsoft Software Key Storage Provider"
        }
        Write-Verbose -Message "ProviderName = '$($CAKey.ProviderName)'"


        if ($param.KeyLength -ne 0)
        {
            if ($CASetup.GetKeyLengthList($param.CryptoProviderName).Length -eq 1)
            {
                $CAKey.Length = $CASetup.GetKeyLengthList($param.CryptoProviderName)[0]
            }
            else
            {
                if ($CASetup.GetKeyLengthList($param.CryptoProviderName) -notcontains $param.KeyLength)
                {
                    Write-Host "The specified key length '$KeyLength' is not supported by the selected CryptoProviderName '$param.CryptoProviderName'"
                    Write-Host "The following key lengths are supported by this CryptoProviderName:"
                    foreach ($provider in ($CASetup.GetKeyLengthList($param.CryptoProviderName)))
                    {
                        Write-Host " $provider"
                    }
                }
                $CAKey.Length = $param.KeyLength
            }
        }
        Write-Verbose -Message "KeyLength = '$($CAKey.KeyLength)'"


        if ($param.HashAlgorithmName -ne "")
        {
            if ($CASetup.GetHashAlgorithmList($param.CryptoProviderName) -notcontains $param.HashAlgorithmName)
            {
                Write-ScreenInfo -Message "The specified hash algorithm is not supported by the selected CryptoProviderName '$param.CryptoProviderName'"
                Write-ScreenInfo -Message "The following hash algorithms are supported by this CryptoProviderName:" -Type Error
                foreach ($algorithm in ($CASetup.GetHashAlgorithmList($param.CryptoProviderName)))
                {
                    Write-ScreenInfo -Message " $algorithm" -Type Error
                }
            }
            $CAKey.HashAlgorithm = $param.HashAlgorithmName
        }
        $CASetup.SetCASetupProperty(1,$CAKey)
        Write-Verbose -Message "Hash Algorithm = '$($CAKey.HashAlgorithm)'"



        if ($param.CAType)
        {
            $SupportedTypes = $CASetup.GetSupportedCATypes()

            $CATypesByName = @{'EnterpriseRootCA'=0;'EnterpriseSubordinateCA'=1;'StandaloneRootCA'=3;'StandaloneSubordinateCA'=4}
            $SelectedType = $CATypesByName[$param.CAType]

            if ($SupportedTypes -notcontains $SelectedType)
            {
                Write-Host "Selected CA type: '$CAType' is not supported by current Windows Server installation."
                Write-Host "The following CA types are supported by this installation:"
                #foreach ($caType in (
                {
                    #Write-ScreenInfo -Message "$([int[]]$CASetup.GetSupportedCATypes() | %{$CATypesByVal[$_]})
                }
            }
        }
        else
        {
            $CASetup.SetCASetupProperty($CAPRopertyByName.CAType,$SelectedType)
        }
        Write-Verbose -Message "CAType = '$($param.CAType)'"



        if ($SelectedType -eq 0 -or $SelectedType -eq 3 -and $param.ValidityPeriodUnits -ne 0)
        {
            try
            {
                $CASetup.SetCASetupProperty(6,([int]$param.ValidityPeriodUnits))
            }
            catch
            {
                Write-Host "The specified CA certificate validity period '$($param.ValidityPeriodUnits)' is invalid."
            }
        }
        Write-Verbose -Message "ValidityPeriod = '$($param.ValidityPeriodUnits)'"



        $DN = New-Object -ComObject X509Enrollment.CX500DistinguishedName
        # validate X500 name format
        try
        {
            $DN.Encode("CN=$($param.CACommonName)",0x0)
        }
        catch
        {
            Write-Host "Specified CA name or CA name suffix is not correct X.500 Distinguished Name."
        }
        $CASetup.SetCADistinguishedName("CN=$($param.CACommonName)", $true, $true, $true)
        Write-Verbose -Message "CADistinguishedName = 'CN=$($param.CACommonName)'"



        if ($CASetup.GetCASetupProperty(0) -eq 1 -and $param.ParentCA)
        {
            [void]($param.ParentCA -match "^(.+)\\(.+)$")
            try
            {
                $CASetup.SetParentCAInformation($param.ParentCA)
            }
            catch
            {
                Write-Host "The specified parent CA information '$param.ParentCA' is incorrect. Make sure if parent CA information is correct (you must specify existing CA) and is supplied in a 'CAComputerName\CASanitizedName' form."
            }
        }
        Write-Verbose -Message "PArentCA = 'CN=$($param.CACommonName)'"









        if ($param.DatabaseDirectory -eq '')
        {
            $param.DatabaseDirectory = 'C:\Windows\system32\CertLog'
        }
        Write-Verbose -Message "DatabaseDirectory = '$($param.DatabaseDirectory)'"

        if ($param.LogDirectory -eq '')
        {
            $param.LogDirectory = 'C:\Windows\system32\CertLog'
        }
        Write-Verbose -Message "LogDirectory = '$($param.LogDirectory)'"



        if ($param.DatabaseDirectory -ne "" -and $param.LogDirectory -ne "")
        {
            try
            {
                $CASetup.SetDatabaseInformation($param.DatabaseDirectory,$param.LogDirectory,$null,$OverwriteExisting)
            }
            catch
            {
                Write-Verbose -Message 'Specified path to either database directory or log directory is invalid.'
            }
        }


        try
        {
            Write-Verbose -Message 'Installing Certification Authority'
            $CASetup.Install()
            if ($CASetup.GetCASetupProperty(0) -eq 1)
            {
                $CASName = (Get-ItemProperty HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration).Active
                $SetupStatus = (Get-ItemProperty HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration\$CASName).SetupStatus
                $RequestID = (Get-ItemProperty HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration\$CASName).RequestID
            }
            Write-Verbose -Message 'Certification Authority role is successfully installed'
        }
        catch
        {
            Write-Error $_ -ErrorAction Stop
        }








        if ($param.ForestAdminUserName)
        {
            Write-Verbose -Message "Removing $($param.ForestAdminUserName) to local administrators group"
            $localGroup = ([ADSI]'WinNT://./Administrators,group')
            $localGroup.psbase.Invoke('Remove', ([ADSI]"WinNT://$($param.ForestAdminUserName.replace('\', '/'))").path)
        }


        if ($param.InstallWebEnrollment)
        {
            Write-Verbose -Message 'InstallWebRole is True, hence setting InstallWebRole to True'
            $param.InstallWebRole = $true
        }

        if ($param.InstallWebRole)
        {
            Write-Verbose -Message 'Check if web role is already installed'
            if (!((Get-WindowsFeature -Name 'web-server').Installed))
            {
                Write-Verbose -Message 'Web role is NOT already installed. Installing it now.'
                Add-WindowsFeature -Name 'Web-Server' -IncludeManagementTools

                #Allow "+" characters in URL for supporting delta CRLs
                #Set-WebConfiguration -Filter system.webServer/security/requestFiltering -PSPath 'IIS:\sites\Default Web Site' -Value @{allowDoubleEscaping=$true}
            }
        }

        if ($param.InstallWebEnrollment)
        {
            Write-Verbose -Message 'Installing Web Enrollment service'
            Install-WebEnrollment "$($param.ComputerName)\$($param.CACommonName)"
        }


        #endregion - Install CA

        #region - Configure IIS virtual directories
        if ($param.UseHTTPAia)
        {
            #New-WebVirtualDirectory -Site 'Default Web Site' -Name Aia -PhysicalPath 'C:\Windows\System32\CertSrv\CertEnroll' | Out-Null
            #New-WebVirtualDirectory -Site 'Default Web Site' -Name Cdp -PhysicalPath 'C:\Windows\System32\CertSrv\CertEnroll' | Out-Null
        }
        #endregion - Configure IIS virtual directories








        #region - Configure CA
        function Invoke-CustomExpression
        {
            param ($Command)

            Invoke-Expression -Command $command
            Write-Verbose -Message $command
        }




        #Declare configuration NC
        if ($param.CAType -like 'Enterprise*')
        {
            $lDAPname = ''
            foreach ($part in ($param.DomainName.split('.')))
            {
                $lDAPname += ",DC=$part"
            }
            Invoke-CustomExpression -Command "certutil.exe -setreg ""CA\DSConfigDN"" ""CN=Configuration$lDAPname"""
        }

        #Apply the required CDP Extension URLs
        $command = "certutil.exe -setreg CA\CRLPublicationURLs ""1:$($Env:WinDir)\system32\CertSrv\CertEnroll\%3%8%9.crl"
        if ($param.UseLDAPCRL) { $command += '\n11:ldap:///CN=%7%8,CN=%2,CN=CDP,CN=Public Key Services,CN=Services,%6%10' }
        if ($param.UseHTTPCRL) { $command += "\n2:$($param.CDPHTTPURL01)/%3%8%9.crl" }
        if ($param.AIAHTTPURL01UploadLocation) { $command += "\n1:$($param.AIAHTTPURL01UploadLocation)/%3%8%9.crl" }
        $command += '"'
        Invoke-CustomExpression -Command $command

        #Apply the required AIA Extension URLs
        $command = "certutil.exe -setreg CA\CACertPublicationURLs ""1:$($Env:WinDir)\system3\CertSrv\CertEnroll\%1_%3%4.crt"
        if ($param.UseLDAPAia) { $command += '\n3:ldap:///CN=%7,CN=AIA,CN=Public Key Services,CN=Services,%6%11' }
        if ($param.UseHTTPAia) { $command += "\n2:$($param.AIAHTTPURL01)/%1_%3%4.crt" }
        if ($param.AIAHTTPURL01UploadLocation) { $command += "\n1:$($param.AIAHTTPURL01UploadLocation)/%3%8%9.crl" }
        $command += '"'
        Invoke-CustomExpression -Command $command

        #Define default maximum certificate lifetime for issued certificates
        Invoke-CustomExpression -Command "certutil.exe -setreg ca\ValidityPeriodUnits $($param.CertsValidityPeriodUnits)"
        Invoke-CustomExpression -Command "certutil.exe -setreg ca\ValidityPeriod ""$($param.CertsValidityPeriod)"""

        #Define CRL Publication Intervals
        Invoke-CustomExpression -Command "certutil.exe -setreg CA\CRLPeriodUnits $($param.CRLPeriodUnits)"
        Invoke-CustomExpression -Command "certutil.exe -setreg CA\CRLPeriod ""$($param.CRLPeriod)"""

        #Define CRL Overlap
        Invoke-CustomExpression -Command "certutil.exe -setreg CA\CRLOverlapUnits $($param.CRLOverlapUnits)"
        Invoke-CustomExpression -Command "certutil.exe -setreg CA\CRLOverlapPeriod ""$($param.CRLOverlapPeriod)"""

        #Define Delta CRL
        Invoke-CustomExpression -Command "certutil.exe -setreg CA\CRLDeltaUnits $($param.CRLDeltaPeriodUnits)"
        Invoke-CustomExpression -Command "certutil.exe -setreg CA\CRLDeltaPeriod ""$($param.CRLDeltaPeriod)"""

        #Enable Auditing Logging
        Invoke-CustomExpression -Command 'certutil.exe -setreg CA\Auditfilter 0x7F'

        #Enable UTF-8 Encoding
        Invoke-CustomExpression -Command 'certutil.exe -setreg ca\forceteletex +0x20'

        if ($param.CAType -like '*root*')
        {
            #Disable Discrete Signatures in Subordinate Certificates (WinXP KB968730)
            Invoke-CustomExpression -Command 'certutil.exe -setreg CA\csp\AlternateSignatureAlgorithm 0'

            #Force digital signature removal in KU for cert issuance (see also kb888180)
            Invoke-CustomExpression -Command 'certutil.exe -setreg policy\EditFlags -EDITF_ADDOLDKEYUSAGE'

            #Enable SAN
            Invoke-CustomExpression -Command 'certutil.exe -setreg policy\EditFlags +EDITF_ATTRIBUTESUBJECTALTNAME2'

            #Configure policy module to automatically issue certificates when requested
            Invoke-CustomExpression -Command 'certutil.exe -setreg ca\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\RequestDisposition 1'
        }
        #If CA is Root CA and Sub CAs are present, disable (do not publish) templates (except SubCA template)
        if ($param.DoNotLoadDefaultTemplates)
        {
            Invoke-CustomExpression -Command 'certutil.exe -SetCATemplates +SubCA'
        }
        #endregion - Configure CA





        #region - Restart of CA
        if ((Get-Service -Name 'CertSvc').Status -eq 'Running')
        {
            Write-Verbose -Message 'Stopping ADCS Service'
            $totalretries = 5
            $retries = 0
            do
            {
                Stop-Service -Name 'CertSvc' -ErrorAction SilentlyContinue
                if ((Get-Service -Name 'CertSvc').Status -ne 'Stopped')
                {
                    $retries++
                    Start-Sleep -Seconds 1
                }
            }
            until (((Get-Service -Name 'CertSvc').Status -eq 'Stopped') -or ($retries -ge $totalretries))

            if ((Get-Service -Name 'CertSvc').Status -eq 'Stopped')
            {
                Write-Verbose -Message 'ADCS service is now stopped'
            }
            else
            {
                Write-Error -Message 'Could not stop ADCS Service after several retries'
                return
            }
        }

        Write-Verbose -Message 'Starting ADCS Service now'
        $totalretries = 5
        $retries = 0
        do
        {
            Start-Service -Name 'CertSvc' -ErrorAction SilentlyContinue
            if ((Get-Service -Name 'CertSvc').Status -ne 'Running')
            {
                $retries++
                Start-Sleep -Seconds 1
            }
        }
        until (((Get-Service -Name 'CertSvc').Status -eq 'Running') -or ($retries -ge $totalretries))

        if ((Get-Service -Name 'CertSvc').Status -eq 'Running')
        {
            Write-Verbose -Message 'ADCS service is now started'
        }
        else
        {
            Write-Error -Message 'Could not start ADCS Service after several retries'
            return
        }
        #endregion - Restart of CA


        Write-Verbose -Message 'Waiting for admin interface to be ready'
        $totalretries = 10
        $retries = 0
        do
        {
            $result = Invoke-Expression -Command "certutil.exe -pingadmin .\$($param.CACommonName)"
            if (!($result | Where-Object { $_ -like '*interface is alive*' }))
            {
                $retries++
                Write-Verbose -Message "Admin interface not ready. Check $retries of $totalretries"
                if ($retries -lt $totalretries) { Start-Sleep -Seconds 10 }
            }
        }
        until (($result | Where-Object { $_ -like '*interface is alive*' }) -or ($retries -ge $totalretries))

        if ($result | Where-Object { $_ -like '*interface is alive*' })
        {
            Write-Verbose -Message 'Admin interface is now ready'
        }
        else
        {
            Write-Error -Message 'Admin interface was not ready after several retries'
            return
        }


        #region - Issue of CRL
        Start-Sleep -Seconds 2
        Invoke-Expression -Command 'certutil.exe -crl' | Out-Null
        $totalretries = 12
        $retries = 0
        do
        {
            Start-Sleep -Seconds 5
            $retries++
        }
        until ((Get-ChildItem "$env:systemroot\system32\CertSrv\CertEnroll\*.crl") -or ($retries -ge $totalretries))

        #endregion - Issue of CRL

        if (($param.CAType -like 'Enterprise*') -and ($param.DoNotLoadDefaultTemplates)) { Invoke-Expression 'certutil.exe -SetCATemplates +SubCA' }
    }

    #endregion

    Write-PSFMessage -Message "Performing installation of $($param.CAType) on '$($param.ComputerName)'"
    $cred = (New-Object System.Management.Automation.PSCredential($param.UserName, ($param.Password | ConvertTo-SecureString -AsPlainText -Force)))
    $caSession = New-LabPSSession -ComputerName $param.ComputerName
    $Job = Invoke-Command -Session $caSession -Scriptblock $caScriptBlock -ArgumentList $param -AsJob -JobName "Install CA on '$($param.Computername)'" -Verbose

    $Job

    Write-LogFunctionExit
}
#endregion Install-LWLabCAServers2008
