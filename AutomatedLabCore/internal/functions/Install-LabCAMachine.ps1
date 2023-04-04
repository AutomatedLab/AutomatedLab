function Install-LabCAMachine
{

    [CmdletBinding()]

    param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine,

        [int]$PreDelaySeconds,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    Write-PSFMessage -Message '****************************************************'
    Write-PSFMessage -Message "Starting installation of machine: $($machine.name)"
    Write-PSFMessage -Message '****************************************************'

    $role = $machine.Roles | Where-Object { $_.Name -eq ([AutomatedLab.Roles]::CaRoot) -or $_.Name -eq ([AutomatedLab.Roles]::CaSubordinate) }

    $param = [ordered]@{ }

    #region - Locate admin username and password for machine
    if ($machine.IsDomainJoined)
    {
        $domain = $lab.Domains | Where-Object { $_.Name -eq $machine.DomainName }

        $param.Add('UserName', ('{0}\{1}' -f $domain.Name, $domain.Administrator.UserName))
        $param.Add('Password', $domain.Administrator.Password)

        $rootDc = Get-LabVM -Role RootDC | Where-Object DomainName -eq $machine.DomainName
        if ($rootDc) #if there is a root domain controller in the same domain as the machine
        {
            $rootDomain = (Get-Lab).Domains | Where-Object Name -eq $rootDc.DomainName
            $rootDomainNetBIOSName = ($rootDomain.Name -split '\.')[0]
        }
        else #else the machine is in a child domain and the parent domain need to be used for the query
        {
            $rootDomain = $lab.GetParentDomain($machine.DomainName)
            $rootDomainNetBIOSName = ($rootDomain.Name -split '\.')[0]
            $rootDc = Get-LabVM -Role RootDC | Where-Object DomainName -eq $rootDomain
        }

        $rdcProperties = $rootDc.Roles | Where-Object Name -eq 'RootDc'
        if ($rdcProperties -and $rdcProperties.Properties.ContainsKey('NetBiosDomainName'))
        {
            $rootDomainNetBIOSName = $rdcProperties.Properties['NetBiosDomainName']
        }

        $param.Add('ForestAdminUserName', ('{0}\{1}' -f $rootDomainNetBIOSName, $rootDomain.Administrator.UserName))
        $param.Add('ForestAdminPassword', $rootDomain.Administrator.Password)

        Write-Debug -Message "Machine                   : $($machine.name)"
        Write-Debug -Message "Machine Domain            : $($machine.DomainName)"
        Write-Debug -Message "Username for job          : $($param.username)"
        Write-Debug -Message "Password for job          : $($param.Password)"
        Write-Debug -Message "ForestAdmin Username      : $($param.ForestAdminUserName)"
        Write-Debug -Message "ForestAdmin Password      : $($param.ForestAdminPassword)"
    }
    else
    {
        $param.Add('UserName', ('{0}\{1}' -f $machine.Name, $machine.InstallationUser.UserName))
        $param.Add('Password', $machine.InstallationUser.Password)
    }
    $param.Add('ComputerName', $Machine.Name)
    #endregion



    #region - Determine DNS name for machine. This is used when installing Enterprise CAs
    $caDNSName = $Machine.Name
    if ($Machine.DomainName) { $caDNSName += ('.' + $Machine.DomainName) }

    if ($Machine.DomainName)
    {
        $param.Add('DomainName', $Machine.DomainName)
    }
    else
    {
        $param.Add('DomainName', '')
    }


    if ($role.Name -eq 'CaSubordinate')
    {
        if (!($role.Properties.ContainsKey('ParentCA'))) { $param.Add('ParentCA', '<auto>') }
        else { $param.Add('ParentCA', $role.Properties.ParentCA) }
        if (!($role.Properties.ContainsKey('ParentCALogicalName'))) { $param.Add('ParentCALogicalName', '<auto>') }
        else { $param.Add('ParentCALogicalName', $role.Properties.ParentCALogicalName) }
    }

    if (!($role.Properties.ContainsKey('CACommonName'))) { $param.Add('CACommonName', '<auto>') }
    else { $param.Add('CACommonName', $role.Properties.CACommonName) }
    if (!($role.Properties.ContainsKey('CAType'))) { $param.Add('CAType', '<auto>') }
    else { $param.Add('CAType', $role.Properties.CAType) }
    if (!($role.Properties.ContainsKey('KeyLength'))) { $param.Add('KeyLength', '4096') }
    else { $param.Add('KeyLength', $role.Properties.KeyLength) }

    if (!($role.Properties.ContainsKey('CryptoProviderName'))) { $param.Add('CryptoProviderName', 'RSA#Microsoft Software Key Storage Provider') }
    else { $param.Add('CryptoProviderName', $role.Properties.CryptoProviderName) }
    if (!($role.Properties.ContainsKey('HashAlgorithmName'))) { $param.Add('HashAlgorithmName', 'SHA256') }
    else { $param.Add('HashAlgorithmName', $role.Properties.HashAlgorithmName) }


    if (!($role.Properties.ContainsKey('DatabaseDirectory'))) { $param.Add('DatabaseDirectory', '<auto>') }
    else { $param.Add('DatabaseDirectory', $role.Properties.DatabaseDirectory) }
    if (!($role.Properties.ContainsKey('LogDirectory'))) { $param.Add('LogDirectory', '<auto>') }
    else { $param.Add('LogDirectory', $role.Properties.LogDirectory) }

    if (!($role.Properties.ContainsKey('ValidityPeriod'))) { $param.Add('ValidityPeriod', '<auto>') }
    else { $param.Add('ValidityPeriod', $role.Properties.ValidityPeriod) }
    if (!($role.Properties.ContainsKey('ValidityPeriodUnits'))) { $param.Add('ValidityPeriodUnits', '<auto>') }
    else { $param.Add('ValidityPeriodUnits', $role.Properties.ValidityPeriodUnits) }

    if (!($role.Properties.ContainsKey('CertsValidityPeriod'))) { $param.Add('CertsValidityPeriod', '<auto>') }
    else { $param.Add('CertsValidityPeriod', $role.Properties.CertsValidityPeriod) }
    if (!($role.Properties.ContainsKey('CertsValidityPeriodUnits'))) { $param.Add('CertsValidityPeriodUnits', '<auto>') }
    else { $param.Add('CertsValidityPeriodUnits', $role.Properties.CertsValidityPeriodUnits) }
    if (!($role.Properties.ContainsKey('CRLPeriod'))) { $param.Add('CRLPeriod', '<auto>') }
    else { $param.Add('CRLPeriod', $role.Properties.CRLPeriod) }
    if (!($role.Properties.ContainsKey('CRLPeriodUnits'))) { $param.Add('CRLPeriodUnits', '<auto>') }
    else { $param.Add('CRLPeriodUnits', $role.Properties.CRLPeriodUnits) }
    if (!($role.Properties.ContainsKey('CRLOverlapPeriod'))) { $param.Add('CRLOverlapPeriod', '<auto>') }
    else { $param.Add('CRLOverlapPeriod', $role.Properties.CRLOverlapPeriod) }
    if (!($role.Properties.ContainsKey('CRLOverlapUnits'))) { $param.Add('CRLOverlapUnits', '<auto>') }
    else { $param.Add('CRLOverlapUnits', $role.Properties.CRLOverlapUnits) }
    if (!($role.Properties.ContainsKey('CRLDeltaPeriod'))) { $param.Add('CRLDeltaPeriod', '<auto>') }
    else { $param.Add('CRLDeltaPeriod', $role.Properties.CRLDeltaPeriod) }
    if (!($role.Properties.ContainsKey('CRLDeltaPeriodUnits'))) { $param.Add('CRLDeltaPeriodUnits', '<auto>') }
    else { $param.Add('CRLDeltaPeriodUnits', $role.Properties.CRLDeltaPeriodUnits) }

    if (!($role.Properties.ContainsKey('UseLDAPAIA'))) { $param.Add('UseLDAPAIA', '<auto>') }
    else { $param.Add('UseLDAPAIA', $role.Properties.UseLDAPAIA) }
    if (!($role.Properties.ContainsKey('UseHTTPAIA'))) { $param.Add('UseHTTPAIA', '<auto>') }
    else { $param.Add('UseHTTPAIA', $role.Properties.UseHTTPAIA) }
    if (!($role.Properties.ContainsKey('AIAHTTPURL01'))) { $param.Add('AIAHTTPURL01', '<auto>') }
    else { $param.Add('AIAHTTPURL01', $role.Properties.AIAHTTPURL01) }
    if (!($role.Properties.ContainsKey('AIAHTTPURL02'))) { $param.Add('AIAHTTPURL02', '<auto>') }
    else { $param.Add('AIAHTTPURL02', $role.Properties.AIAHTTPURL02) }
    if (!($role.Properties.ContainsKey('AIAHTTPURL01UploadLocation'))) { $param.Add('AIAHTTPURL01UploadLocation', '') }
    else { $param.Add('AIAHTTPURL01UploadLocation', $role.Properties.AIAHTTPURL01UploadLocation) }
    if (!($role.Properties.ContainsKey('AIAHTTPURL02UploadLocation'))) { $param.Add('AIAHTTPURL02UploadLocation', '') }
    else { $param.Add('AIAHTTPURL02UploadLocation', $role.Properties.AIAHTTPURL02UploadLocation) }

    if (!($role.Properties.ContainsKey('UseLDAPCRL'))) { $param.Add('UseLDAPCRL', '<auto>') }
    else { $param.Add('UseLDAPCRL', $role.Properties.UseLDAPCRL) }
    if (!($role.Properties.ContainsKey('UseHTTPCRL'))) { $param.Add('UseHTTPCRL', '<auto>') }
    else { $param.Add('UseHTTPCRL', $role.Properties.UseHTTPCRL) }
    if (!($role.Properties.ContainsKey('CDPHTTPURL01'))) { $param.Add('CDPHTTPURL01', '<auto>') }
    else { $param.Add('CDPHTTPURL01', $role.Properties.CDPHTTPURL01) }
    if (!($role.Properties.ContainsKey('CDPHTTPURL02'))) { $param.Add('CDPHTTPURL02', '<auto>') }
    else { $param.Add('CDPHTTPURL02', $role.Properties.CDPHTTPURL02) }
    if (!($role.Properties.ContainsKey('CDPHTTPURL01UploadLocation'))) { $param.Add('CDPHTTPURL01UploadLocation', '') }
    else { $param.Add('CDPHTTPURL01UploadLocation', $role.Properties.CDPHTTPURL01UploadLocation) }
    if (!($role.Properties.ContainsKey('CDPHTTPURL02UploadLocation'))) { $param.Add('CDPHTTPURL02UploadLocation', '') }
    else { $param.Add('CDPHTTPURL02UploadLocation', $role.Properties.CDPHTTPURL02UploadLocation) }

    if (!($role.Properties.ContainsKey('InstallWebEnrollment'))) { $param.Add('InstallWebEnrollment', '<auto>') }
    else { $param.Add('InstallWebEnrollment', $role.Properties.InstallWebEnrollment) }
    if (!($role.Properties.ContainsKey('InstallWebRole'))) { $param.Add('InstallWebRole', '<auto>') }
    else { $param.Add('InstallWebRole', $role.Properties.InstallWebRole) }

    if (!($role.Properties.ContainsKey('CPSURL'))) { $param.Add('CPSURL', 'http://' + $caDNSName + '/cps/cps.html') }
    else { $param.Add('CPSURL', $role.Properties.CPSURL) }
    if (!($role.Properties.ContainsKey('CPSText'))) { $param.Add('CPSText', 'Certification Practice Statement') }
    else { $param.Add('CPSText', $($role.Properties.CPSText)) }

    if (!($role.Properties.ContainsKey('InstallOCSP'))) { $param.Add('InstallOCSP', '<auto>') }
    else { $param.Add('InstallOCSP', ($role.Properties.InstallOCSP -like '*Y*')) }
    if (!($role.Properties.ContainsKey('OCSPHTTPURL01'))) { $param.Add('OCSPHTTPURL01', '<auto>') }
    else { $param.Add('OCSPHTTPURL01', $role.Properties.OCSPHTTPURL01) }
    if (!($role.Properties.ContainsKey('OCSPHTTPURL02'))) { $param.Add('OCSPHTTPURL02', '<auto>') }
    else { $param.Add('OCSPHTTPURL02', $role.Properties.OCSPHTTPURL02) }

    if (-not $role.Properties.ContainsKey('DoNotLoadDefaultTemplates'))
    {
        $param.Add('DoNotLoadDefaultTemplates', '<auto>')
    }
    else
    {
        $value = if ($role.Properties.DoNotLoadDefaultTemplates -eq 'Yes') { $true } else { $false }
        $param.Add('DoNotLoadDefaultTemplates', $value)
    }

    #region - Check if any unknown parameter name was passed
    $knownParameters = @()
    $knownParameters += 'ParentCA' #(only valid for Subordinate CA. Ignored for Root CAs)
    $knownParameters += 'ParentCALogicalName' #(only valid for Subordinate CAs. Ignored for Root CAs)
    $knownParameters += 'CACommonName'
    $knownParameters += 'CAType'
    $knownParameters += 'KeyLength'
    $knownParameters += 'CryptoProviderName'
    $knownParameters += 'HashAlgorithmName'
    $knownParameters += 'DatabaseDirectory'
    $knownParameters += 'LogDirectory'
    $knownParameters += 'ValidityPeriod'
    $knownParameters += 'ValidityPeriodUnits'
    $knownParameters += 'CertsValidityPeriod'
    $knownParameters += 'CertsValidityPeriodUnits'
    $knownParameters += 'CRLPeriod'
    $knownParameters += 'CRLPeriodUnits'
    $knownParameters += 'CRLOverlapPeriod'
    $knownParameters += 'CRLOverlapUnits'
    $knownParameters += 'CRLDeltaPeriod'
    $knownParameters += 'CRLDeltaPeriodUnits'
    $knownParameters += 'UseLDAPAIA'
    $knownParameters += 'UseHTTPAIA'
    $knownParameters += 'AIAHTTPURL01'
    $knownParameters += 'AIAHTTPURL02'
    $knownParameters += 'AIAHTTPURL01UploadLocation'
    $knownParameters += 'AIAHTTPURL02UploadLocation'
    $knownParameters += 'UseLDAPCRL'
    $knownParameters += 'UseHTTPCRL'
    $knownParameters += 'CDPHTTPURL01'
    $knownParameters += 'CDPHTTPURL02'
    $knownParameters += 'CDPHTTPURL01UploadLocation'
    $knownParameters += 'CDPHTTPURL02UploadLocation'
    $knownParameters += 'InstallWebEnrollment'
    $knownParameters += 'InstallWebRole'
    $knownParameters += 'CPSURL'
    $knownParameters += 'CPSText'
    $knownParameters += 'InstallOCSP'
    $knownParameters += 'OCSPHTTPURL01'
    $knownParameters += 'OCSPHTTPURL02'
    $knownParameters += 'DoNotLoadDefaultTemplates'
    $knownParameters += 'PreDelaySeconds'
    $unkownParFound = $false
    foreach ($keySet in $role.Properties.GetEnumerator())
    {
        if ($keySet.Key -cnotin $knownParameters)
        {
            Write-ScreenInfo -Message "Parameter name '$($keySet.Key)' is unknown/ignored)" -Type Warning
            $unkownParFound = $true
        }
    }
    if ($unkownParFound)
    {
        Write-ScreenInfo -Message 'Valid parameter names are:' -Type Warning
        Foreach ($name in ($knownParameters.GetEnumerator()))
        {
            Write-ScreenInfo -Message "  $($name)" -Type Warning
        }
        Write-ScreenInfo -Message 'NOTE that all parameter names are CASE SENSITIVE!' -Type Warning
    }
    #endregion - Check if any unknown parameter names was passed

    #endregion - Parameters


    #region - Parameters debug
    Write-Debug -Message '---------------------------------------------------------------------------------------'
    Write-Debug -Message "Parameters for $($machine.name)"
    Write-Debug -Message '---------------------------------------------------------------------------------------'
    if ($machine.Roles.Properties.GetEnumerator().Count)
    {
        foreach ($r in $machine.Roles)
        {
            if (([AutomatedLab.Roles]$r.Name -band $roles) -ne 0) #if this is a CA role
            {
                foreach ($key in ($r.Properties.GetEnumerator() | Sort-Object -Property Key))
                {
                    Write-Debug -Message "  $($key.Key.PadRight(27)) $($key.Value)"
                }
            }
        }
    }
    else
    {
        Write-Debug -message '  No parameters specified'
    }
    Write-Debug -Message '---------------------------------------------------------------------------------------'
    #endregion - Parameters debug


    #region ----- Input validation (raw values) -----
    if ($role.Properties.ContainsKey('CACommonName') -and ($param.CACommonName.Length -gt 37))
    {
        Write-Error -Message "CACommonName cannot be longer than 37 characters. Specified value is: '$($param.CACommonName)'"; return
    }

    if ($role.Properties.ContainsKey('CACommonName') -and ($param.CACommonName.Length -lt 1))
    {
        Write-Error -Message "CACommonName cannot be blank. Specified value is: '$($param.CACommonName)'"; return
    }

    if ($role.Name -eq 'CaRoot')
    {
        if (-not ($param.CAType -in 'EnterpriseRootCA', 'StandAloneRootCA', '<auto>'))
        {
            Write-Error -Message "CAType needs to be 'EnterpriseRootCA' or 'StandAloneRootCA' when role is CaRoot. Specified value is: '$param.CAType'"; return
        }
    }

    if ($role.Name -eq 'CaSubordinate')
    {
        if (-not ($param.CAType -in 'EnterpriseSubordinateCA', 'StandAloneSubordinateCA', '<auto>'))
        {
            Write-Error -Message "CAType needs to be 'EnterpriseSubordinateCA' or 'StandAloneSubordinateCA' when role is CaSubordinate. Specified value is: '$param.CAType'"; return
        }
    }


    $availableCombinations = @()
    $availableCombinations += @{CryptoProviderName='Microsoft Base SMart Card Crypto Provider';           HashAlgorithmName='sha1','md2','md4','md5';                           KeyLength='1024','2048','4096'}
    $availableCombinations += @{CryptoProviderName='Microsoft Enhanced Cryptographic Provider 1.0';       HashAlgorithmName='sha1','md2','md4','md5';                           KeyLength='512','1024','2048','4096'}
    $availableCombinations += @{CryptoProviderName='ECDSA_P256#Microsoft Smart Card Key Storage Provider';HashAlgorithmName='sha256','sha384','sha512','sha1';                  KeyLength='256'}
    $availableCombinations += @{CryptoProviderName='ECDSA_P521#Microsoft Smart Card Key Storage Provider';HashAlgorithmName='sha256','sha384','sha512','sha1';                  KeyLength='521'}
    $availableCombinations += @{CryptoProviderName='RSA#Microsoft Software Key Storage Provider';         HashAlgorithmName='sha256','sha384','sha512','sha1','md5','md4','md2';KeyLength='512','1024','2048','4096'}
    $availableCombinations += @{CryptoProviderName='Microsoft Base Cryptographic Provider v1.0';          HashAlgorithmName='sha1','md2','md4','md5';                           KeyLength='512','1024','2048','4096'}
    $availableCombinations += @{CryptoProviderName='ECDSA_P521#Microsoft Software Key Storage Provider';  HashAlgorithmName='sha256','sha384','sha512','sha1';                  KeyLength='521'}
    $availableCombinations += @{CryptoProviderName='ECDSA_P256#Microsoft Software Key Storage Provider';  HashAlgorithmName='sha256','sha384','sha512','sha1';                  KeyLength='256';}
    $availableCombinations += @{CryptoProviderName='Microsoft Strong Cryptographic Provider';             HashAlgorithmName='sha1','md2','md4','md5';                           KeyLength='512','1024','2048','4096';}
    $availableCombinations += @{CryptoProviderName='ECDSA_P384#Microsoft Software Key Storage Provider';  HashAlgorithmName='sha256','sha384','sha512','sha1';                  KeyLength='384'}
    $availableCombinations += @{CryptoProviderName='Microsoft Base DSS Cryptographic Provider';           HashAlgorithmName='sha1';                                             KeyLength='512','1024'}
    $availableCombinations += @{CryptoProviderName='RSA#Microsoft Smart Card Key Storage Provider';       HashAlgorithmName='sha256','sha384','sha512','sha1','md5','md4','md2';KeyLength='1024','2048','4096'}
    $availableCombinations += @{CryptoProviderName='DSA#Microsoft Software Key Storage Provider';         HashAlgorithmName='sha1';                                             KeyLength='512','1024','2048','4096'}
    $availableCombinations += @{CryptoProviderName='ECDSA_P384#Microsoft Smart Card Key Storage Provider';HashAlgorithmName='sha256','sha384','sha512','sha1';                  KeyLength='384'}

    $combination = $availableCombinations | Where-Object {$_.CryptoProviderName -eq $param.CryptoProviderName}

    if (-not ($param.CryptoProviderName -in $combination.CryptoProviderName))
    {
        Write-Error -Message "CryptoProviderName '$($param.CryptoProviderName)' is unknown. `nList of valid options for CryptoProviderName:`n  $($availableCombinations.CryptoProviderName -join "`n  ")"; return
    }
    elseif (-not ($param.HashAlgorithmName -in $combination.HashAlgorithmName))
    {
        Write-Error -Message "HashAlgorithmName '$($param.HashAlgorithmName)' is not valid for CryptoProviderName '$($param.CryptoProviderName)'. The Crypto Provider selected supports the following Hash Algorithms:`n  $($combination.HashAlgorithmName -join "`n  ")"; return
    }
    elseif (-not ($param.KeyLength -in $combination.KeyLength))
    {
        Write-Error -Message "Keylength '$($param.KeyLength)' is not valid for CryptoProviderName '$($param.CryptoProviderName)'. The Crypto Provider selected supports the following keylengths:`n  $($combination.KeyLength -join "`n  ")"; return
    }



    if ($role.Properties.ContainsKey('DatabaseDirectory') -and -not ($param.DatabaseDirectory -match '^[C-Z]:\\'))
    {
        Write-Error -Message 'DatabaseDirectory needs to be located on a local drive (drive letter C-Z)'; return
    }

    if ($role.Properties.ContainsKey('LogDirectory') -and -not ($param.LogDirectory -match '^[C-Z]:\\'))
    {
        Write-Error -Message 'LogDirectory needs to be located on a local drive (drive letter C-Z)'; return
    }

    if (($param.UseLDAPAIA -ne '<auto>') -and ($param.UseLDAPAIA -notin ('Yes', 'No')))
    {
        Write-Error -Message "UseLDAPAIA needs to be 'Yes' or 'no'. Specified value is: '$($param.UseLDAPAIA)'"; return
    }

    if (($param.UseHTTPAIA -ne '<auto>') -and ($param.UseHTTPAIA -notin ('Yes', 'No')))
    {
        Write-Error -Message "UseHTTPAIA needs to be 'Yes' or 'no'. Specified value is: '$($param.UseHTTPAIA)'"; return
    }

    if (($param.UseLDAPCRL -ne '<auto>') -and ($param.UseLDAPCRL -notin ('Yes', 'No')))
    {
        Write-Error -Message "UseLDAPCRL needs to be 'Yes' or 'no'. Specified value is: '$($param.UseLDAPCRL)'"; return
    }

    if (($param.UseHTTPCRL -ne '<auto>') -and ($param.UseHTTPCRL -notin ('Yes', 'No')))
    {
        Write-Error -Message "UseHTTPCRL needs to be 'Yes' or 'no'. Specified value is: '$($param.UseHTTPCRL)'"; return
    }

    if (($param.InstallWebEnrollment -ne '<auto>') -and ($param.InstallWebEnrollment -notin ('Yes', 'No')))
    {
        Write-Error -Message "InstallWebEnrollment needs to be 'Yes' or 'no'. Specified value is: '$($param.InstallWebEnrollment)'"; return
    }

    if (($param.InstallWebRole -ne '<auto>') -and ($param.InstallWebRole -notin ('Yes', 'No')))
    {
        Write-Error -Message "InstallWebRole needs to be 'Yes' or 'no'. Specified value is: '$($param.InstallWebRole)'"; return
    }

    if (($param.AIAHTTPURL01 -ne '<auto>') -and ($param.AIAHTTPURL01 -notlike 'http://*'))
    {
        Write-Error -Message "AIAHTTPURL01 needs to start with 'http://' (https is not supported). Specified value is: '$($param.AIAHTTPURL01)'"; return
    }

    if (($param.AIAHTTPURL02 -ne '<auto>') -and ($param.AIAHTTPURL02 -notlike 'http://*'))
    {
        Write-Error -Message "AIAHTTPURL02 needs to start with 'http://' (https is not supported). Specified value is: '$($param.AIAHTTPURL02)'"; return
    }

    if (($param.CDPHTTPURL01 -ne '<auto>') -and ($param.CDPHTTPURL01 -notlike 'http://*'))
    {
        Write-Error -Message "CDPHTTPURL01 needs to start with 'http://' (https is not supported). Specified value is: '$($param.CDPHTTPURL01)'"; return
    }

    if (($param.CDPHTTPURL02 -ne '<auto>') -and ($param.CDPHTTPURL02 -notlike 'http://*'))
    {
        Write-Error -Message "CDPHTTPURL02 needs to start with 'http://' (https is not supported). Specified value is: '$($param.CDPHTTPURL02)'"; return
    }

    if (($role.Name -eq 'CaRoot') -and ($param.DoNotLoadDefaultTemplates -ne '<auto>') -and ($param.DoNotLoadDefaultTemplates -notin ('Yes', 'No')))
    {
        Write-Error -Message "DoNotLoadDefaultTemplates needs to be 'Yes' or 'No'. Specified value is: '$($param.DoNotLoadDefaultTemplates)'"; return
    }



    #ValidityPeriod and ValidityPeriodUnits
    if ($param.ValidityPeriodUnits -ne '<auto>')
    {
        try { $dummy = [int]$param.ValidityPeriodUnits }
        catch { Write-Error -Message 'ValidityPeriodUnits is not convertable to an integer. Please specify (enclosed as a string) a number between 1 and 2147483647'; return }
    }

    if (($param.ValidityPeriodUnits -ne '<auto>') -and ([int]$param.ValidityPeriodUnits) -lt 1)
    {
        Write-Error -Message 'ValidityPeriodUnits cannot be less than 1. Please specify (enclosed as a string) a number between 1 and 2147483647'; return
    }

    if (($param.ValidityPeriodUnits) -ne '<auto>' -and (!($role.Properties.ContainsKey('ValidityPeriod'))))
    {
        Write-Error -Message 'ValidityPeriodUnits specified (ok) while ValidityPeriod is not specified. ValidityPeriod needs to be one of "Years", "Months", "Weeks", "Days", "Hours".'; return
    }

    if ($param.ValidityPeriod -ne '<auto>' -and ($param.ValidityPeriod -notin ('Years', 'Months', 'Weeks', 'Days', 'Hours')))
    {
        Write-Error -Message "ValidityPeriod need to be one of 'Years', 'Months', 'Weeks', 'Days', 'Hours'. Specified value is: '$($param.ValidityPeriod)'"; return
    }


    #CertsValidityPeriod and CertsValidityPeriodUnits
    if ($param.CertsValidityPeriodUnits -ne '<auto>')
    {
        try { $dummy = [int]$param.CertsValidityPeriodUnits }
        catch { Write-Error -Message 'CertsValidityPeriodUnits is not convertable to an integer. Please specify (enclosed as a string) a number between 1 and 2147483647'; return }
    }

    if (($param.CertsValidityPeriodUnits) -ne '<auto>' -and (!($role.Properties.ContainsKey('CertsValidityPeriod'))))
    {
        Write-Error -Message 'CertsValidityPeriodUnits specified (ok) while CertsValidityPeriod is not specified. CertsValidityPeriod needs to be one of "Years", "Months", "Weeks", "Days", "Hours" .'; return
    }

    if ($param.CertsValidityPeriod -ne '<auto>' -and ($param.CertsValidityPeriod -notin ('Years', 'Months', 'Weeks', 'Days', 'Hours')))
    {
        Write-Error -Message "CertsValidityPeriod need to be one of 'Years', 'Months', 'Weeks', 'Days', 'Hours'. Specified value is: '$($param.CertsValidityPeriod)'"; return
    }


    #CRLPeriodUnits and CRLPeriodUnitsUnits
    if ($param.CRLPeriodUnits -ne '<auto>')
    {
        try { $dummy = [int]$param.CRLPeriodUnits }
        catch { Write-Error -Message 'CRLPeriodUnits is not convertable to an integer. Please specify (enclosed as a string) a number between 1 and 2147483647'; return }
    }

    if (($param.CRLPeriodUnits) -ne '<auto>' -and (!($role.Properties.ContainsKey('CRLPeriod'))))
    {
        Write-Error -Message 'CRLPeriodUnits specified (ok) while CRLPeriod is not specified. CRLPeriod needs to be one of "Years", "Months", "Weeks", "Days", "Hours" .'; return
    }

    if ($param.CRLPeriod -ne '<auto>' -and ($param.CRLPeriod -notin ('Years', 'Months', 'Weeks', 'Days', 'Hours')))
    {
        Write-Error -Message "CRLPeriod need to be one of 'Years', 'Months', 'Weeks', 'Days', 'Hours'. Specified value is: '$($param.CRLPeriod)'"; return
    }


    #CRLOverlapPeriod and CRLOverlapUnits
    if ($param.CRLOverlapUnits -ne '<auto>')
    {
        try { $dummy = [int]$param.CRLOverlapUnits }
        catch { Write-Error -Message 'CRLOverlapUnits is not convertable to an integer. Please specify (enclosed as a string) a number between 1 and 2147483647'; return }
    }

    if (($param.CRLOverlapUnits) -ne '<auto>' -and (!($role.Properties.ContainsKey('CRLOverlapPeriod'))))
    {
        Write-Error -Message 'CRLOverlapUnits specified (ok) while CRLOverlapPeriod is not specified. CRLOverlapPeriod needs to be one of "Years", "Months", "Weeks", "Days", "Hours" .'; return
    }

    if ($param.CRLOverlapPeriod -ne '<auto>' -and ($param.CRLOverlapPeriod -notin ('Years', 'Months', 'Weeks', 'Days', 'Hours')))
    {
        Write-Error -Message "CRLOverlapPeriod need to be one of 'Years', 'Months', 'Weeks', 'Days', 'Hours'. Specified value is: '$($param.CRLOverlapPeriod)'"; return
    }


    #CRLDeltaPeriod and CRLDeltaPeriodUnits
    if ($param.CRLDeltaPeriodUnits -ne '<auto>')
    {
        try { $dummy = [int]$param.CRLDeltaPeriodUnits }
        catch { Write-Error -Message 'CRLDeltaPeriodUnits is not convertable to an integer. Please specify (enclosed as a string) a number between 1 and 2147483647'; return }
    }

    if (($param.CRLDeltaPeriodUnits) -ne '<auto>' -and (!($role.Properties.ContainsKey('CRLDeltaPeriod'))))
    {
        Write-Error -Message 'CRLDeltaPeriodUnits specified (ok) while CRLDeltaPeriod is not specified. CRLDeltaPeriod needs to be one of "Years", "Months", "Weeks", "Days", "Hours" .'; return
    }

    if ($param.CRLDeltaPeriod -ne '<auto>' -and ($param.CRLDeltaPeriod -notin ('Years', 'Months', 'Weeks', 'Days', 'Hours')))
    {
        Write-Error -Message "CRLDeltaPeriod need to be one of 'Years', 'Months', 'Weeks', 'Days', 'Hours'. Specified value is: '$($param.CRLDeltaPeriod)'"; return
    }

    #endregion ----- Input validation (raw values) -----



    #region ----- Input validation (content analysis) -----
    if (($param.CAType -like 'Enterprise*') -and (!($machine.isDomainJoined)))
    {
        Write-Error -Message "CA Type specified is '$($param.CAType)' while machine is not domain joined. This is not possible"; return
    }

    if (($param.CAType -like 'StandAlone*') -and ($role.Properties.ContainsKey('UseLDAPAIA')) -and ($param.UseLDAPAIA))
    {
        Write-Error -Message "UseLDAPAIA is set to 'Yes' while 'CAType' is set to '$($param.CAType)'. It is not possible to use LDAP based AIA for a $($param.CAType)"; return
    }

    if (($param.CAType -like 'StandAlone*') -and ($role.Properties.ContainsKey('UseLDAPCRL')) -and ($param.UseLDAPCRL))
    {
        Write-Error -Message "UseLDAPCRL is set to 'Yes' while 'CAType' is set to '$($param.CAType)'. It is not possible to use LDAP based CRL for a $($param.CAType)"; return
    }

    if (($param.CAType -like 'StandAlone*') -and ($role.Properties.ContainsKey('InstallWebRole')) -and (!($param.InstallWebRole)))
    {
        Write-Error -Message "InstallWebRole is set to No while CAType is StandAloneCA. $($param.CAType) needs web role for hosting a CDP"
        return
    }

    if (($role.Properties.ContainsKey('OCSPHTTPURL01')) -or ($role.Properties.ContainsKey('OCSPHTTPURL02')) -or ($role.Properties.ContainsKey('InstallOCSP')))
    {
        Write-ScreenInfo -Message 'OCSP is not yet supported. OCSP parameters will be ignored and OCSP will not be installed!' -Type Warning
    }


    #if any validity parameter was defined, get these now and convert them all to hours (temporary variables)
    if ($param.ValidityPeriodUnits -ne '<auto>')
    {
        switch ($param.ValidityPeriod)
        {
            'Years'  { $validityPeriodUnitsHours = [int]$param.ValidityPeriodUnits * 365 * 24 }
            'Months' { $validityPeriodUnitsHours = [int]$param.ValidityPeriodUnits * (365/12) * 24 }
            'Weeks'  { $validityPeriodUnitsHours = [int]$param.ValidityPeriodUnits * 7 * 24 }
            'Days'   { $validityPeriodUnitsHours = [int]$param.ValidityPeriodUnits * 24 }
            'Hours'  { $validityPeriodUnitsHours = [int]$param.ValidityPeriodUnits }
        }
    }
    if ($param.CertsValidityPeriodUnits -ne '<auto>')
    {
        switch ($param.CertsValidityPeriod)
        {
            'Years'  { $certsvalidityPeriodUnitsHours = [int]$param.CertsValidityPeriodUnits * 365 * 24 }
            'Months' { $certsvalidityPeriodUnitsHours = [int]$param.CertsValidityPeriodUnits * (365/12) * 24 }
            'Weeks'  { $certsvalidityPeriodUnitsHours = [int]$param.CertsValidityPeriodUnits * 7 * 24 }
            'Days'   { $certsvalidityPeriodUnitsHours = [int]$param.CertsValidityPeriodUnits * 24 }
            'Hours'  { $certsvalidityPeriodUnitsHours = [int]$param.CertsValidityPeriodUnits }
        }
    }
    if ($param.CRLPeriodUnits -ne '<auto>')
    {
        switch ($param.CRLPeriod)
        {
            'Years'  { $cRLPeriodUnitsHours = [int]([int]$param.CRLPeriodUnits * 365 * 24) }
            'Months' { $cRLPeriodUnitsHours = [int]([int]$param.CRLPeriodUnit * (365/12) * 24) }
            'Weeks'  { $cRLPeriodUnitsHours = [int]([int]$param.CRLPeriodUnits * 7 * 24) }
            'Days'   { $cRLPeriodUnitsHours = [int]([int]$param.CRLPeriodUnits * 24) }
            'Hours'  { $cRLPeriodUnitsHours = [int]([int]$param.CRLPeriodUnits) }
        }
    }
    if ($param.CRLDeltaPeriodUnits -ne '<auto>')
    {
        switch ($param.CRLDeltaPeriod)
        {
            'Years'  { $cRLDeltaPeriodUnitsHours = [int]([int]$param.CRLDeltaPeriodUnits * 365 * 24) }
            'Months' { $cRLDeltaPeriodUnitsHours = [int]([int]$param.CRLDeltaPeriodUnits * (365/12) * 24) }
            'Weeks'  { $cRLDeltaPeriodUnitsHours = [int]([int]$param.CRLDeltaPeriodUnits * 7 * 24) }
            'Days'   { $cRLDeltaPeriodUnitsHours = [int]([int]$param.CRLDeltaPeriodUnits * 24) }
            'Hours'  { $cRLDeltaPeriodUnitsHours = [int]([int]$param.CRLDeltaPeriodUnits) }
        }
    }
    if ($param.CRLOverlapUnits -ne '<auto>')
    {
        switch ($param.CRLOverlapPeriod)
        {
            'Years'  { $CRLOverlapUnitsHours = [int]([int]$param.CRLOverlapUnits * 365 * 24) }
            'Months' { $CRLOverlapUnitsHours = [int]([int]$param.CRLOverlapUnits * (365/12) * 24) }
            'Weeks'  { $CRLOverlapUnitsHours = [int]([int]$param.CRLOverlapUnits * 7 * 24) }
            'Days'   { $CRLOverlapUnitsHours = [int]([int]$param.CRLOverlapUnits * 24) }
            'Hours'  { $CRLOverlapUnitsHours = [int]([int]$param.CRLOverlapUnits) }
        }
    }

    if ($role.Properties.ContainsKey('CRLPeriodUnits') -and ($cRLPeriodUnitsHours) -and ($validityPeriodUnitsHours) -and ($cRLPeriodUnitsHours -ge $validityPeriodUnitsHours))
    {
        Write-Error -Message "CRLPeriodUnits is longer than ValidityPeriodUnits. This is not possible. `
            Specified value for CRLPeriodUnits is: '$($param.CRLPeriodUnits) $($param.CRLPeriod)'`
        Specified value for ValidityPeriodUnits is: '$($param.ValidityPeriodUnits) $($param.ValidityPeriod)'"
        return
    }
    if ($role.Properties.ContainsKey('CertsValidityPeriodUnits') -and ($certsvalidityPeriodUnitsHours) -and ($validityPeriodUnitsHours) -and ($certsvalidityPeriodUnitsHours -ge $validityPeriodUnitsHours))
    {
        Write-Error -Message "CertsValidityPeriodUnits is longer than ValidityPeriodUnits. This is not possible. `
            Specified value for certsValidityPeriodUnits is: '$($param.CertsValidityPeriodUnits) $($param.CertsValidityPeriod)'`
        Specified value for ValidityPeriodUnits is: '$($param.ValidityPeriodUnits) $($param.ValidityPeriod)'"
        return
    }
    if ($role.Properties.ContainsKey('CRLDeltaPeriodUnits') -and ($CRLDeltaPeriodUnitsHours) -and ($cRLPeriodUnitsHours) -and ($cRLDeltaPeriodUnitsHours -ge $cRLPeriodUnitsHours))
    {
        Write-Error -Message "CRLDeltaPeriodUnits is longer than CRLPeriodUnits. This is not possible. `
            Specified value for CRLDeltaPeriodUnits is: '$($param.CRLDeltaPeriodUnits) $($param.CRLDeltaPeriod)'`
        Specified value for ValidityPeriodUnits is: '$($param.CRLPeriodUnits) $($param.CRLPeriod)'"
        return
    }
    if ($role.Properties.ContainsKey('CRLOverlapUnits') -and ($CRLOverlapUnitsHours) -and ($validityPeriodUnitsHours) -and ($CRLOverlapUnitsHours -ge $validityPeriodUnitsHours))
    {
        Write-Error -Message "CRLOverlapUnits is longer than ValidityPeriodUnits. This is not possible. `
            Specified value for CRLOverlapUnits is: '$($param.CRLOverlapUnits) $($param.CRLOverlapPeriod)'`
        Specified value for ValidityPeriodUnits is: '$($param.ValidityPeriodUnits) $($param.ValidityPeriod)'"
        return
    }
    if ($role.Properties.ContainsKey('CRLOverlapUnits') -and ($CRLOverlapUnitsHours) -and ($cRLPeriodUnitsHours) -and ($CRLOverlapUnitsHours -ge $cRLPeriodUnitsHours))
    {
        Write-Error -Message "CRLOverlapUnits is longer than CRLPeriodUnits. This is not possible. `
            Specified value for CRLOverlapUnits is: '$($param.CRLOverlapUnits) $($param.CRLOverlapPeriod)'`
        Specified value for CRLPeriodUnits is: '$($param.CRLPeriodUnits) $($param.CRLPeriod)'"
        return
    }
    if (($param.CAType -like '*root*') -and ($role.Properties.ContainsKey('ValidityPeriod')) -and ($validityPeriodUnitsHours) -and ($validityPeriodUnitsHours -gt (10 * 365 * 24)))
    {
        Write-ScreenInfo -Message "ValidityPeriod is more than 10 years. Overall validity of all issued certificates by Enterprise Root CAs will be set to specified value. `
            However, the default validity (specified by 2012/2012R2 Active Directory) of issued by Enterprise Root CAs to Subordinate CAs, is 5 years. `
        If more than 5 years is needed, a custom certificate template is needed wherein the validity can be changed." -Type Warning
    }


    #region - If DatabaseDirectory or LogDirectory is specified, Check for drive existence in the VM
    if (($param.DatabaseDirectory -ne '<auto>') -or ($param.LogDirectory -ne '<auto>'))
    {
        $caSession = New-LabPSSession -ComputerName $Machine

        if ($param.DatabaseDirectory -ne '<auto>')
        {
            $DatabaseDirectoryDrive = ($param.DatabaseDirectory.split(':')[0]) + ':'

            $disk = Invoke-LabCommand -ComputerName $Machine -ScriptBlock {
                if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)
                {
                    Get-CimInstance -Namespace Root\CIMV2 -Class Win32_LogicalDisk -Filter "DeviceID = ""$DatabaseDirectoryDrive"""
                }
                else
                {
                    Get-WmiObject -Namespace Root\CIMV2 -Class Win32_LogicalDisk -Filter "DeviceID = ""$DatabaseDirectoryDrive"""
                }
            } -Variable (Get-Variable -Name DatabaseDirectoryDrive) -PassThru

            if (-not $disk -or -not $disk.DriveType -eq 3)
            {
                Write-Error -Message "Drive for Database Directory does not exist or is not a hard disk drive. Specified value is: $DatabaseDirectory"
                return
            }
        }

        if ($param.LogDirectory -ne '<auto>')
        {
            $LogDirectoryDrive = ($param.LogDirectory.split(':')[0]) + ':'
            $disk = Invoke-LabCommand -ComputerName $Machine -ScriptBlock {
                if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)
                {
                    Get-CimInstance -Namespace Root\CIMV2 -Class Win32_LogicalDisk -Filter "DeviceID = ""$LogDirectoryDrive"""
                }
                else
                {
                    Get-WmiObject -Namespace Root\CIMV2 -Class Win32_LogicalDisk -Filter "DeviceID = ""$LogDirectoryDrive"""
                }
            } -Variable (Get-Variable -Name LogDirectoryDrive) -PassThru
            if (-not $disk -or -not $disk.DriveType -eq 3)
            {
                Write-Error -Message "Drive for Log Directory does not exist or is not a hard disk drive. Specified value is: $LogDirectory"
                return
            }
        }
    }
    #endregion - If DatabaseDirectory or LogDirectory is specified, Check for drive existence in the VM

    #endregion ----- Input validation (content analysis) -----


    #region ----- Calculations -----

    #If ValidityPeriodUnits is not defined, define it now and Update machine property "ValidityPeriod"
    if ($param.ValidityPeriodUnits -eq '<auto>')
    {
        $param.ValidityPeriod = 'Years'
        $param.ValidityPeriodUnits = '10'
        if (!($validityPeriodUnitsHours)) { $validityPeriodUnitsHours = [int]($param.ValidityPeriodUnits) * 365 * 24 }
    }


    #If CAType is not defined, define it now
    if ($param.CAType -eq '<auto>')
    {
        if ($machine.IsDomainJoined)
        {
            if ($role.Name -eq 'CaRoot')
            {
                $param.CAType = 'EnterpriseRootCA'
                if ($VerbosePreference -ne 'SilentlyContinue') { Write-ScreenInfo -Message 'Parameter "CAType" is not specified. Automatically setting CAtype to "EnterpriseRootCA" since machine is domain joined and Root CA role is specified' -Type Warning }
            }
            else
            {
                $param.CAType = 'EnterpriseSubordinateCA'
                if ($VerbosePreference -ne 'SilentlyContinue') { Write-ScreenInfo -Message 'Parameter "CAType" is not specified. Automatically setting CAtype to "EnterpriseSubordinateCA" since machine is domain joined and Subordinate CA role is specified' -Type Warning }
            }
        }
        else
        {
            if ($role.Name -eq 'CaRoot')
            {
                $param.CAType = 'StandAloneRootCA'
                if ($VerbosePreference -ne 'SilentlyContinue') { Write-ScreenInfo -Message 'Parameter "CAType" is not specified. Automatically setting CAtype to "StandAloneRootCA" since machine is not domain joined and Root CA role is specified' -Type Warning }
            }
            else
            {
                $param.CAType = 'StandAloneSubordinateCA'
                if ($VerbosePreference -ne 'SilentlyContinue') { Write-ScreenInfo -Message 'Parameter "CAType" is not specified. Automatically setting CAtype to "StandAloneSubordinateCA" since machine is not domain joined and Subordinate CA role is specified' -Type Warning }
            }
        }
    }


    #If ParentCA is not defined, try to find it automatically
    if ($param.ParentCA -eq '<auto>')
    {
        if ($param.CAType -like '*Subordinate*') #CA is a Subordinate CA
        {
            if ($param.CAType -like 'Enterprise*')
            {
                $rootCA = [array](Get-LabVM -Role CaRoot | Where-Object DomainName -eq $machine.DomainName | Sort-Object -Property DomainName) | Select-Object -First 1

                if (-not $rootCA)
                {
                    $rootCA = [array](Get-LabVM -Role CaRoot | Where-Object { -not $_.IsDomainJoined }) | Select-Object -First 1
                }

            }
            else
            {
                $rootCA = [array](Get-LabVM -Role CaRoot | Where-Object { -not $_.IsDomainJoined }) | Select-Object -First 1
            }

            if ($rootCA)
            {
                $param.ParentCALogicalName = ($rootCA.Roles | Where-Object Name -eq CaRoot).Properties.CACommonName
                $param.ParentCA = $rootCA.Name
                Write-PSFMessage "Root CA '$($param.ParentCALogicalName)' ($($param.ParentCA)) automatically selected as parent CA"
                $ValidityPeriod = $rootCA.roles.Properties.CertsValidityPeriod
                $ValidityPeriodUnits = $rootCA.roles.Properties.CertsValidityPeriodUnits
            }
            else
            {
                Write-Error -Message 'No name for Parent CA specified and no Root CA can be located automatically. Please install a Root CA in the lab before installing a Subordinate CA'
                return
            }

            #Check if Parent CA is valid
            $caSession = New-LabPSSession -ComputerName $param.ComputerName

            Write-Debug -Message "Testing ParentCA with command: 'certutil -ping $($param.ParentCA)\$($param.ParentCALogicalName)'"


            $totalretries = 20
            $retries = 0

            Write-PSFMessage -Message "Testing Root CA availability: certutil -ping $($param.ParentCA)\$($param.ParentCALogicalName)"
            do
            {
                $result = Invoke-LabCommand -ComputerName $param.ComputerName -ScriptBlock {
                    param(
                        [string]$ParentCA,
                        [string]$ParentCALogicalName
                    )
                    Invoke-Expression -Command "certutil -ping $ParentCA\$ParentCALogicalName"
                } -ArgumentList $param.ParentCA, $param.ParentCALogicalName -PassThru -NoDisplay

                if (-not ($result | Where-Object { $_ -like '*interface is alive*' }))
                {
                    $result | ForEach-Object { Write-Debug -Message $_ }
                    $retries++
                    Write-PSFMessage -Message "Could not contact ParentCA. (Computername=$($param.ParentCA), LogicalCAName=$($param.ParentCALogicalName)). (Check $retries of $totalretries)"
                    if ($retries -lt $totalretries) { Start-Sleep -Seconds 5 }
                }
            }
            until (($result | Where-Object { $_ -like '*interface is alive*' }) -or ($retries -ge $totalretries))

            if ($result | Where-Object { $_ -like '*interface is alive*' })
            {
                Write-PSFMessage -Message "Parent CA ($($param.ParentCA)) is contactable"
            }
            else
            {
                Write-Error -Message "Parent CA ($($param.ParentCA)) is not contactable. Please install a Root CA in the lab before installing a Subordinate CA"
                return
            }
        }
        else #CA is a Root CA
        {
            $param.ParentCALogicalName = ''
            $param.ParentCA = ''
        }
    }

    #Calculate and update machine property "CACommonName" if this was not specified. Note: the first instance of a name of a Root CA server, will be used by install code for Sub CAs.
    if ($param.CACommonName -eq '<auto>')
    {
        if ($role.Name -eq 'CaRoot')        { $caBaseName = 'LabRootCA' }
        if ($role.Name -eq 'CaSubordinate') { $caBaseName = 'LabSubCA'  }

        [array]$caNamesAlreadyInUse = Invoke-LabCommand -ComputerName (Get-LabVM -Role $role.Name) -ScriptBlock {
            $name = certutil.exe -getreg CA\CommonName | Where-Object { $_ -match 'CommonName REG' }
            if ($name)
            {
                $name.Split('=')[1].Trim()
            }
        } -NoDisplay -PassThru
        $num = 0
        do
        {
            $num++
        }
        until (($caBaseName + [string]($num)) -notin ((Get-LabVM).Roles.Properties.CACommonName) -and ($caBaseName + [string]($num)) -notin $caNamesAlreadyInUse)

        $param.CACommonName = $caBaseName + ([string]$num)
        ($machine.Roles | Where-Object Name -like Ca*).Properties.Add('CACommonName', $param.CACommonName)
    }

    #Converting to correct types for some parameters
    if ($param.InstallWebEnrollment -eq '<auto>')
    {
        if ($param.CAType -like 'Enterprise*')
        {
            $param.InstallWebEnrollment = $False
        }
        else
        {
            $param.InstallWebEnrollment = $True
        }
    }
    else
    {
        $param.InstallWebEnrollment = ($param.InstallWebEnrollment -like '*Y*')
    }

    if ($param.InstallWebRole -eq '<auto>')
    {
        if ($param.CAType -like 'Enterprise*')
        {
            $param.InstallWebRole = $False
        }
        else
        {
            $param.InstallWebRole = $True
        }
    }
    else
    {
        $param.InstallWebRole = ($param.InstallWebRole -like '*Y*')
    }

    if ($param.UseLDAPAIA -eq '<auto>')
    {
        if ($param.CAType -like 'Enterprise*')
        {
            $param.UseLDAPAIA = $True
        }
        else
        {
            $param.UseLDAPAIA = $False
        }
    }
    else
    {
        $param.UseLDAPAIA = ($param.UseLDAPAIA -like '*Y*')
    }

    if ($param.UseHTTPAIA -eq '<auto>')
    {
        if ($param.CAType -like 'Enterprise*')
        {
            $param.UseHTTPAIA = $False
        }
        else
        {
            $param.UseHTTPAIA = $True
        }
    }
    else
    {
        $param.UseHTTPAIA = ($param.UseHTTPAIA -like '*Y*')
    }

    if ($param.UseLDAPCRL -eq '<auto>')
    {
        if ($param.CAType -like 'Enterprise*')
        {
            $param.UseLDAPCRL = $True
        }
        else
        {
            $param.UseLDAPCRL = $False
        }
    }
    else
    {
        $param.UseLDAPCRL = ($param.UseLDAPCRL -like '*Y*')
    }

    if ($param.UseHTTPCRL -eq '<auto>')
    {
        if ($param.CAType -like 'Enterprise*')
        {
            $param.UseHTTPCRL = $False
        }
        else
        {
            $param.UseHTTPCRL = $True
        }
    }
    else
    {
        $param.UseHTTPCRL = ($param.UseHTTPCRL -like '*Y*')
    }

    $param.InstallOCSP = $False
    $param.OCSPHTTPURL01 = ''
    $param.OCSPHTTPURL02 = ''


    $param.AIAHTTPURL01UploadLocation = ''
    $param.AIAHTTPURL02UploadLocation = ''
    $param.CDPHTTPURL01UploadLocation = ''
    $param.CDPHTTPURL02UploadLocation = ''




    if (($param.CaType -like 'StandAlone*') -and $role.Properties.ContainsKey('UseLDAPAIA') -and $param.UseLDAPAIA)
    {
        Write-Error -Message "Parameter 'UseLDAPAIA' is set to 'Yes' while 'CAType' is set to '$($param.CaType)'. It is not possible to use LDAP based AIA for a $($param.CaType)"
        return
    }
    elseif (($param.CaType -like 'StandAlone*') -and (!($role.Properties.ContainsKey('UseLDAPAIA'))))
    {
        $param.UseLDAPAIA = $False
    }

    if (($param.CaType -like 'StandAlone*') -and $role.Properties.ContainsKey('UseHTTPAIA') -and (-not $param.UseHTTPAIA))
    {
        Write-Error -Message "Parameter 'UseHTTPAIA' is set to 'No' while 'CAType' is set to '$($param.CaType)'. Only AIA possible for a $($param.CaType), is Http based AIA."
        return
    }
    elseif (($param.CaType -like 'StandAlone*') -and (!($role.Properties.ContainsKey('UseHTTPAIA'))))
    {
        $param.UseHTTPAIA = $True
    }


    if (($param.CaType -like 'StandAlone*') -and $role.Properties.ContainsKey('UseLDAPCRL') -and $param.UseLDAPCRL)
    {
        Write-Error -Message "Parameter 'UseLDAPCRL' is set to 'Yes' while 'CAType' is set to '$($param.CaType)'. It is not possible to use LDAP based CRL for a $($param.CaType)"
        return
    }
    elseif (($param.CaType -like 'StandAlone*') -and (!($role.Properties.ContainsKey('UseLDAPCRL'))))
    {
        $param.UseLDAPCRL = $False
    }

    if (($param.CaType -like 'StandAlone*') -and $role.Properties.ContainsKey('UseHTTPCRL') -and (-not $param.UseHTTPCRL))
    {
        Write-Error -Message "Parameter 'UseHTTPCRL' is set to 'No' while 'CAType' is set to '$($param.CaType)'. Only CRL possible for a $($param.CaType), is Http based CRL."
        return
    }
    elseif (($param.CaType -like 'StandAlone*') -and (!($role.Properties.ContainsKey('UseHTTPCRL'))))
    {
        $param.UseHTTPCRL = $True
    }


    #If AIAHTTPURL01 or CDPHTTPURL01 was not specified but is needed, populate these now
    if (($param.CaType -like 'StandAlone*') -and (!($role.Properties.ContainsKey('AIAHTTPURL01')) -and $param.UseHTTPAIA))
    {
        $param.AIAHTTPURL01 = ('http://' + $caDNSName + '/aia')
        $param.AIAHTTPURL02 = ''
    }

    if (($param.CaType -like 'StandAlone*') -and (!($role.Properties.ContainsKey('CDPHTTPURL01')) -and $param.UseHTTPCRL))
    {
        $param.CDPHTTPURL01 = ('http://' + $caDNSName + '/cdp')
        $param.CDPHTTPURL02 = ''
    }






    #If Enterprise  CA, and UseLDAPAia is "Yes" or not specified, set UseLDAPAIA to True
    if (($param.CaType -like 'Enterprise*') -and (!($role.Properties.ContainsKey('UseLDAPAIA'))))
    {
        $param.UseLDAPAIA = $True
    }


    #If Enterprise  CA, and UseLDAPCrl is "Yes" or not specified, set UseLDAPCrl to True
    if (($param.CaType -like 'Enterprise*') -and (!($role.Properties.ContainsKey('UseLDAPCRL'))))
    {
        $param.UseLDAPCRL = $True
    }

    #If AIAHTTPURL01 or CDPHTTPURL01 was not specified but is needed, populate these now (with empty strings)
    if (($param.CaType -like 'Enterprise*') -and (!($role.Properties.ContainsKey('AIAHTTPURL01'))))
    {
        if ($param.UseHTTPAIA)
        {
            $param.AIAHTTPURL01 = 'http://' + $caDNSName + '/aia'
            $param.AIAHTTPURL02 = ''
        }
        else
        {
            $param.AIAHTTPURL01 = ''
            $param.AIAHTTPURL02 = ''
        }
    }

    if (($param.CaType -like 'Enterprise*') -and (!($role.Properties.ContainsKey('CDPHTTPURL01'))))
    {
        if ($param.UseHTTPCRL)
        {
            $param.CDPHTTPURL01 = 'http://' + $caDNSName + '/cdp'
            $param.CDPHTTPURL02 = ''
        }
        else
        {
            $param.CDPHTTPURL01 = ''
            $param.CDPHTTPURL02 = ''
        }
    }


    function Scale-Parameters
    {
        param ([int]$hours)

        $factorYears = 24 * 365
        $factorMonths = 24 * (365/12)
        $factorWeeks = 24 * 7
        $factorDays = 24
        switch ($hours)
        {
            { $_ -ge $factorYears }
            {
                if (($hours / $factorYears) * 100%100 -le 10) { return ([string][int]($hours / $factorYears)), 'Years' }
            }
            { $_ -ge $factorMonths }
            {
                if (($hours / $factorMonths) * 100%100 -le 10) { return ([string][int]($hours / $factorMonths)), 'Months' }
            }
            { $_ -ge $factorWeeks }
            {
                if (($hours / $factorWeeks) * 100%100 -le 50) { return ([string][int]($hours / $factorWeeks)), 'Weeks' }
            }
            { $_ -ge $factorDays }
            {
                if (($hours / $factorDays) * 100%100 -le 75) { return ([string][int]($hours / $factorDays)), 'Days' }
            }
        }
        $returnHours = [int]($hours)
        if ($returnHours -lt 1) { $returnHours = 1 }
        return ([string]$returnHours), 'Hours'
    }

    #if any validity parameter was not defined, calculate these now
    if ($param.CRLPeriodUnits -eq '<auto>') { $param.CRLPeriodUnits, $param.CRLPeriod = Scale-Parameters ($validityPeriodUnitsHours/8) }
    if ($param.CRLDeltaPeriodUnits -eq '<auto>') { $param.CRLDeltaPeriodUnits, $param.CRLDeltaPeriod = Scale-Parameters ($validityPeriodUnitsHours/16) }
    if ($param.CRLOverlapUnits -eq '<auto>') { $param.CRLOverlapUnits, $param.CRLOverlapPeriod = Scale-Parameters ($validityPeriodUnitsHours/32) }
    if ($param.CertsValidityPeriodUnits -eq '<auto>')
    {
        $param.CertsValidityPeriodUnits, $param.CertsValidityPeriod = Scale-Parameters ($validityPeriodUnitsHours/2)
    }

    $role = $machine.Roles | Where-Object { ([AutomatedLab.Roles]$_.Name -band $roles) -ne 0 }
    if (($param.CAType -like '*root*') -and !($role.Properties.ContainsKey('CertsValidityPeriodUnits')))
    {
        if ($VerbosePreference -ne 'SilentlyContinue') { Write-ScreenInfo -Message "Adding parameter 'CertsValidityPeriodUnits' with value of '$($param.CertsValidityPeriodUnits)' to machine roles properties of machine $($machine.Name)" -Type Warning }
        $role.Properties.Add('CertsValidityPeriodUnits', $param.CertsValidityPeriodUnits)
    }
    if (($param.CAType -like '*root*') -and !($role.Properties.ContainsKey('CertsValidityPeriod')))
    {
        if ($VerbosePreference -ne 'SilentlyContinue') { Write-ScreenInfo -Message "Adding parameter 'CertsValidityPeriod' with value of '$($param.CertsValidityPeriod)' to machine roles properties of machine $($machine.Name)" -Type Warning }
        $role.Properties.Add('CertsValidityPeriod', $param.CertsValidityPeriod)
    }

    #If any HTTP parameter is specified and any of the DNS names in these parameters points to this CA server, install Web Role to host this
    if (!($param.InstallWebRole))
    {
        if (($param.UseHTTPAIA -or $param.UseHTTPCRL) -and `
        $param.AIAHTTPURL01 -or $param.AIAHTTPURL02 -or $param.CDPHTTPURL01 -or $param.CDPHTTPURL02)
        {
            $URLs = @()
            $ErrorActionPreferenceBackup = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue'
            if ($param.AIAHTTPURL01.IndexOf('/', 2)) { $URLs += ($param.AIAHTTPURL01).Split('/')[2].Split('/')[0] }
            if ($param.AIAHTTPURL02.IndexOf('/', 2)) { $URLs += ($param.AIAHTTPURL02).Split('/')[2].Split('/')[0] }
            if ($param.CDPHTTPURL01.IndexOf('/', 2)) { $URLs += ($param.CDPHTTPURL01).Split('/')[2].Split('/')[0] }
            if ($param.CDPHTTPURL02.IndexOf('/', 2)) { $URLs += ($param.CDPHTTPURL02).Split('/')[2].Split('/')[0] }
            $ErrorActionPreference = $ErrorActionPreferenceBackup

            #$param.InstallWebRole = (($machine.Name + "." + $machine.domainname) -in $URLs)
            if (($machine.Name + '.' + $machine.domainname) -notin $URLs)
            {
                Write-ScreenInfo -Message 'Http based AIA or CDP specified but is NOT pointing to this server. Make sure to MANUALLY establish this web server and DNS name as well as copy AIA and CRL(s) to this web server' -Type Warning
            }
        }
    }


    #Setting DatabaseDirectoryh and LogDirectory to blank if automatic is selected. Hence, default locations will be used (%WINDIR%\System32\CertLog)
    if ($param.DatabaseDirectory -eq '<auto>') { $param.DatabaseDirectory = '' }
    if ($param.LogDirectory -eq '<auto>') { $param.LogDirectory = '' }


    #Test for existence of AIA location
    if (!($param.UseLDAPAia) -and !($param.UseHTTPAia)) { Write-ScreenInfo -Message 'AIA information will not be included in issued certificates because both LDAP and HTTP based AIA has been disabled' -Type Warning }

    #Test for existence of CDP location
    if (!($param.UseLDAPCrl) -and !($param.UseHTTPCrl)) { Write-ScreenInfo -Message 'CRL information will not be included in issued certificates because both LDAP and HTTP based CRLs has been disabled' -Type Warning }


    if (!($param.InstallWebRole) -and ($param.InstallWebEnrollment))
    {
        Write-Error -Message "InstallWebRole is set to No while InstallWebEnrollment is set to Yes. This is not possible. `
            Specified value for InstallWebRole is: $($param.InstallWebRole) `
        Specified value for InstallWebEnrollment is: $($param.InstallWebEnrollment)"
        return
    }



    if ('<auto>' -eq $param.DoNotLoadDefaultTemplates)
    {
        #Only for Root CA server
        if ($param.CaType -like '*Root*')
        {
            if (Get-LabVM -Role CaSubordinate -ErrorAction SilentlyContinue)
            {
                Write-ScreenInfo -Message 'Default templates will be removed (not published) except "SubCA" template, since this is an Enterprise Root CA and Subordinate CA(s) is present in the lab' -Type Verbose
                $param.DoNotLoadDefaultTemplates = $True
            }
            else
            {
                $param.DoNotLoadDefaultTemplates = $False
            }
        }
        else
        {
            $param.DoNotLoadDefaultTemplates = $False
        }
    }
    #endregion ----- Calculations -----


    $job = @()
    $targets = (Get-LabVM -Role FirstChildDC).Name
    foreach ($target in $targets)
    {
        $job += Sync-LabActiveDirectory -ComputerName $target -AsJob -PassThru
    }
    Wait-LWLabJob -Job $job -Timeout 15 -NoDisplay
    $targets = (Get-LabVM -Role DC).Name
    foreach ($target in $targets)
    {
        $job += Sync-LabActiveDirectory -ComputerName $target -AsJob -PassThru
    }
    Wait-LWLabJob -Job $job -Timeout 15 -NoDisplay

    $param.PreDelaySeconds = $PreDelaySeconds

    Write-PSFMessage -Message "Starting install of $($param.CaType) role on machine '$($machine.Name)'"
    $job = Install-LWLabCAServers @param
    if ($PassThru)
    {
        $job
    }

    Write-LogFunctionExit
}
