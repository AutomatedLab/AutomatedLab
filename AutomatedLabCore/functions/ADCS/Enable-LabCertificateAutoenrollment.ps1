function Enable-LabCertificateAutoenrollment
{

    [cmdletBinding()]

    param
    (
        [switch]$Computer,

        [switch]$User,

        [switch]$CodeSigning,

        [string]$CodeSigningTemplateName = 'LabCodeSigning'
    )

    Write-LogFunctionEntry

    $issuingCAs = Get-LabIssuingCA

    Write-PSFMessage -Message "All issuing CAs: '$($issuingCAs -join ', ')'"

    if (-not $issuingCAs)
    {
        Write-ScreenInfo -Message 'No issuing CA(s) found. Skipping operation.'
        return
    }

    Write-ScreenInfo -Message 'Configuring certificate auto enrollment' -TaskStart

    $domainsToProcess = (Get-LabVM -Role RootDC, FirstChildDC, DC | Where-Object DomainName -in $issuingCAs.DomainName | Group-Object DomainName).Name | Sort-Object -Unique
    Write-PSFMessage -Message "Domains to process: '$($domainsToProcess -join ', ')'"

    $issuingCAsToProcess = ($issuingCAs | Where-Object DomainName -in $domainsToProcess).Name
    Write-PSFMessage -Message "Issuing CAs to process: '$($issuingCAsToProcess -join ', ')'"

    $dcsToProcess = @()
    foreach ($domain in $issuingCAs.DomainName)
    {
        $dcsToProcess += Get-LabVM -Role RootDC | Where-Object { $domain -like "*$($_.DomainName)"}
    }
    $dcsToProcess = $dcsToProcess.Name | Sort-Object -Unique

    Write-PSFMessage -Message "DCs to process: '$($dcsToProcess -join ', ')'"


    if ($Computer)
    {
        Write-ScreenInfo -Message 'Configuring permissions for computer certificates' -NoNewLine
        $job = Invoke-LabCommand -ComputerName $dcsToProcess -ActivityName 'Configure permissions on workstation authentication template on CAs' -NoDisplay -AsJob -PassThru -ScriptBlock `
        {
            $domainName = ([adsi]'LDAP://RootDSE').DefaultNamingContext

            dsacls "CN=Workstation,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainName" /G 'Domain Computers:GR'
            dsacls "CN=Workstation,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainName" /G 'Domain Computers:CA;Enroll'
            dsacls "CN=Workstation,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainName" /G 'Domain Computers:CA;AutoEnrollment'
        }
        Wait-LWLabJob -Job $job -ProgressIndicator 20 -Timeout 30 -NoDisplay -NoNewLine


        $job = Invoke-LabCommand -ComputerName $issuingCAsToProcess -ActivityName 'Publish workstation authentication certificate template on CAs' -NoDisplay -AsJob -PassThru -ScriptBlock {
            certutil.exe -SetCAtemplates +Workstation
            #Add-CATemplate -Name 'Workstation' -Confirm:$false
        }
        Wait-LWLabJob -Job $job -ProgressIndicator 20 -Timeout 30 -NoDisplay
    }

    if ($CodeSigning)
    {
        Write-ScreenInfo -Message "Enabling code signing certificate and enabling auto enrollment of these. Code signing certificate template name: '$CodeSigningTemplateName'" -NoNewLine
        $job = Invoke-LabCommand -ComputerName $dcsToProcess -ActivityName 'Create certificate template for Code Signing' -AsJob -PassThru -NoDisplay -ScriptBlock {
            param ($NewCodeSigningTemplateName)

            $ConfigContext = ([adsi]'LDAP://RootDSE').ConfigurationNamingContext
            $adsi = [adsi]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"

            if (-not ($adsi.Children | Where-Object {$_.distinguishedName -like "CN=$NewCodeSigningTemplateName,*"}))
            {
                Write-Verbose -Message "Creating certificate template with name: $NewCodeSigningTemplateName"

                $codeSigningOrgiginalTemplate = $adsi.Children | Where-Object {$_.distinguishedName -like 'CN=CodeSigning,*'}


                $newCertTemplate = $adsi.Create('pKICertificateTemplate', "CN=$NewCodeSigningTemplateName")
                $newCertTemplate.put('distinguishedName',"CN=$NewCodeSigningTemplateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext")

                $newCertTemplate.put('flags','32')
                $newCertTemplate.put('displayName',$NewCodeSigningTemplateName)
                $newCertTemplate.put('revision','100')
                $newCertTemplate.put('pKIDefaultKeySpec','2')
                $newCertTemplate.SetInfo()


                $newCertTemplate.put('pKIMaxIssuingDepth','0')
                $newCertTemplate.put('pKICriticalExtensions','2.5.29.15')
                $newCertTemplate.put('pKIExtendedKeyUsage','1.3.6.1.5.5.7.3.3')
                $newCertTemplate.put('pKIDefaultCSPs','2,Microsoft Base Cryptographic Provider v1.0, 1,Microsoft Enhanced Cryptographic Provider v1.0')
                $newCertTemplate.put('msPKI-RA-Signature','0')
                $newCertTemplate.put('msPKI-Enrollment-Flag','32')
                $newCertTemplate.put('msPKI-Private-Key-Flag','16842752')
                $newCertTemplate.put('msPKI-Certificate-Name-Flag','-2113929216')
                $newCertTemplate.put('msPKI-Minimal-Key-Size','2048')
                $newCertTemplate.put('msPKI-Template-Schema-Version','2')
                $newCertTemplate.put('msPKI-Template-Minor-Revision','2')

                $LastTemplateNumber = $adsi.Children | Select-Object @{n='OIDNumber';e={[int]($_.'msPKI-Cert-Template-OID'.split('.')[-1])}} | Sort-Object -Property OIDNumber | Select-Object -ExpandProperty OIDNumber -Last 1
                $LastTemplateNumber++
                $OID = ((($adsi.Children | Select-Object -First 1).'msPKI-Cert-Template-OID'.replace('.', '\') | Split-Path -Parent) + "\$LastTemplateNumber").replace('\', '.')

                $newCertTemplate.put('msPKI-Cert-Template-OID',$OID)
                $newCertTemplate.put('msPKI-Certificate-Application-Policy','1.3.6.1.5.5.7.3.3')

                $newCertTemplate.SetInfo()


                $newCertTemplate.pKIKeyUsage = $codeSigningOrgiginalTemplate.pKIKeyUsage
                #$NewCertTemplate.pKIKeyUsage = "176" (special DSC Template)

                $newCertTemplate.pKIExpirationPeriod = $codeSigningOrgiginalTemplate.pKIExpirationPeriod
                $newCertTemplate.pKIOverlapPeriod = $codeSigningOrgiginalTemplate.pKIOverlapPeriod
                $newCertTemplate.SetInfo()

                $domainName = ([ADSI]'LDAP://RootDSE').DefaultNamingContext


                dsacls "CN=$NewCodeSigningTemplateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainName" /G 'Domain Users:GR'
                dsacls "CN=$NewCodeSigningTemplateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainName" /G 'Domain Users:CA;Enroll'
                dsacls "CN=$NewCodeSigningTemplateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainName" /G 'Domain Users:CA;AutoEnrollment'
            }
            else
            {
                Write-Verbose -Message "Certificate template with name '$NewCodeSigningTemplateName' already exists"
            }
        } -ArgumentList $CodeSigningTemplateName
        Wait-LWLabJob -Job $job -ProgressIndicator 20 -Timeout 30 -NoDisplay


        Write-ScreenInfo -Message 'Publishing Code Signing certificate template on all issuing CAs' -NoNewLine
        $job = Invoke-LabCommand -ComputerName $issuingCAsToProcess -ActivityName 'Publishing code signing certificate template' -NoDisplay -AsJob -PassThru -ScriptBlock {
            param ($NewCodeSigningTemplateName)

            $ConfigContext = ([ADSI]'LDAP://RootDSE').ConfigurationNamingContext
            $adsi = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
            while (-not ($adsi.Children | Where-Object {$_.distinguishedName -like "CN=$NewCodeSigningTemplateName,*"}))
            {
                gpupdate.exe /force
                certutil.exe -pulse

                $adsi = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
                #Start-Sleep -Seconds 2
            }
            Start-Sleep -Seconds 2

            $start = (Get-Date)
            $done = $false
            do
            {
                Write-Verbose -Message "Trying to publish '$NewCodeSigningTemplateName'"
                $result = certutil.exe -SetCAtemplates "+$NewCodeSigningTemplateName"
                if ($result -like '*successfully*')
                {
                    $done = $True
                }
                else
                {
                    gpupdate.exe /force
                    certutil.exe -pulse
                }
            }
            until ($done -or (((Get-Date)-$start)).TotalMinutes -ge 30)
            Write-Verbose -Message 'DONE'


            if (((Get-Date)-$start).TotalMinutes -ge 10)
            {
                Write-Error -Message "Could not publish certificate template '$NewCodeSigningTemplateName' as it was not found after 10 minutes"
            }
        } -ArgumentList $CodeSigningTemplateName
        Wait-LWLabJob -Job $job -ProgressIndicator 20 -Timeout 15 -NoDisplay
    }


    $machines = Get-LabVM | Where-Object {$_.DomainName -in $domainsToProcess}
    if ($Computer -and ($User -or $CodeSigning))
    {
        $out = 'computer and user'
    }
    elseif ($Computer)
    {
        $out = 'computer'
    }
    else
    {
        $out = 'user'
    }

    Write-ScreenInfo -Message "Enabling auto enrollment of $out certificates" -NoNewLine
    $job = Invoke-LabCommand -ComputerName $machines -ActivityName 'Configuring machines for auto enrollment and performing auto enrollment of certificates' -NoDisplay -AsJob -PassThru -ScriptBlock `
    {
        Add-Type -TypeDefinition $gpoType
        Set-Item WSMan:\localhost\Client\TrustedHosts '*' -Force
        Enable-WSManCredSSP -Role Client -DelegateComputer * -Force

        $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1')
        if ($value -ne '*' -and $value -ne 'WSMAN/*')
        {
            [GPO.Helper]::SetGroupPolicy($true, 'Software\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowFreshCredentials', 1) | Out-Null
            [GPO.Helper]::SetGroupPolicy($true, 'Software\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowFresh', 1) | Out-Null
            [GPO.Helper]::SetGroupPolicy($true, 'Software\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1', 'WSMAN/*') | Out-Null
        }

        Enable-AutoEnrollment -Computer:$Computer -UserOrCodeSigning:($User -or $CodeSigning)

    } -Variable (Get-Variable gpoType, Computer, User, CodeSigning) -Function (Get-Command Enable-AutoEnrollment)
    Wait-LWLabJob -Job $job -ProgressIndicator 20 -Timeout 30 -NoDisplay


    Write-ScreenInfo -Message 'Finished configuring certificate auto enrollment' -TaskEnd

    Write-LogFunctionExit
}
