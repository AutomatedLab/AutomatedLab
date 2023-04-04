function New-LabSqlAccount
{
    param
    (
        [Parameter(Mandatory = $true)]
        [AutomatedLab.Machine]
        $Machine,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $RoleProperties
    )

    $usersAndPasswords = @{}
    $groups = @()
    if ($RoleProperties.ContainsKey('SQLSvcAccount') -and $RoleProperties.ContainsKey('SQLSvcPassword'))
    {
        $usersAndPasswords[$RoleProperties['SQLSvcAccount']] = $RoleProperties['SQLSvcPassword']
    }

    if ($RoleProperties.ContainsKey('AgtSvcAccount') -and $RoleProperties.ContainsKey('AgtSvcPassword'))
    {
        $usersAndPasswords[$RoleProperties['AgtSvcAccount']] = $RoleProperties['AgtSvcPassword']
    }

    if ($RoleProperties.ContainsKey('RsSvcAccount') -and $RoleProperties.ContainsKey('RsSvcPassword'))
    {
        $usersAndPasswords[$RoleProperties['RsSvcAccount']] = $RoleProperties['RsSvcPassword']
    }

    if ($RoleProperties.ContainsKey('AsSvcAccount') -and $RoleProperties.ContainsKey('AsSvcPassword'))
    {
        $usersAndPasswords[$RoleProperties['AsSvcAccount']] = $RoleProperties['AsSvcPassword']
    }

    if ($RoleProperties.ContainsKey('IsSvcAccount') -and $RoleProperties.ContainsKey('IsSvcPassword'))
    {
        $usersAndPasswords[$RoleProperties['IsSvcAccount']] = $RoleProperties['IsSvcPassword']
    }

    if ($RoleProperties.ContainsKey('SqlSysAdminAccounts'))
    {
        $groups += $RoleProperties['SqlSysAdminAccounts']
    }

    if ($RoleProperties.ContainsKey('ConfigurationFile'))
    {        
        $confPath = if ($lab.DefaultVirtualizationEngine -eq 'Azure' -and (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $RoleProperties.ConfigurationFile))
        {
            $blob = Get-LabAzureLabSourcesContent -Path $RoleProperties.ConfigurationFile.Replace($labSources,'')
            $null = Get-AzStorageFileContent -File $blob -Destination (Join-Path $env:TEMP azsql.ini) -Force
            Join-Path $env:TEMP azsql.ini
        }
        elseif ($lab.DefaultVirtualizationEngine -ne 'Azure' -or ($lab.DefaultVirtualizationEngine -eq 'Azure' -and -not (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $RoleProperties.ConfigurationFile)))
        {
            $RoleProperties.ConfigurationFile
        }

        $config = (Get-Content -Path $confPath) -replace '\\', '\\' | ConvertFrom-String -Delimiter = -PropertyNames Key, Value

        if (($config | Where-Object Key -eq SQLSvcAccount) -and ($config | Where-Object Key -eq SQLSvcPassword))
        {
            $user = ($config | Where-Object Key -eq SQLSvcAccount).Value
            $password = ($config | Where-Object Key -eq SQLSvcPassword).Value
            $user = $user.Substring(1, $user.Length - 2)
            $password = $password.Substring(1, $password.Length - 2)
            $usersAndPasswords[$user] = $password
        }

        if (($config | Where-Object Key -eq AgtSvcAccount) -and ($config | Where-Object Key -eq AgtSvcPassword))
        {
            $user = ($config | Where-Object Key -eq AgtSvcAccount).Value
            $password = ($config | Where-Object Key -eq AgtSvcPassword).Value
            $user = $user.Substring(1, $user.Length - 2)
            $password = $password.Substring(1, $password.Length - 2)
            $usersAndPasswords[$user] = $password
        }

        if (($config | Where-Object Key -eq RsSvcAccount) -and ($config | Where-Object Key -eq RsSvcPassword))
        {
            $user = ($config | Where-Object Key -eq RsSvcAccount).Value
            $password = ($config | Where-Object Key -eq RsSvcPassword).Value
            $user = $user.Substring(1, $user.Length - 2)
            $password = $password.Substring(1, $password.Length - 2)
            $usersAndPasswords[$user] = $password
        }

        if (($config | Where-Object Key -eq AsSvcAccount) -and ($config | Where-Object Key -eq AsSvcPassword))
        {
            $user = ($config | Where-Object Key -eq AsSvcAccount).Value
            $password = ($config | Where-Object Key -eq AsSvcPassword).Value
            $user = $user.Substring(1, $user.Length - 2)
            $password = $password.Substring(1, $password.Length - 2)
            $usersAndPasswords[$user] = $password
        }

        if (($config | Where-Object Key -eq IsSvcAccount) -and ($config | Where-Object Key -eq IsSvcPassword))
        {
            $user = ($config | Where-Object Key -eq IsSvcAccount).Value
            $password = ($config | Where-Object Key -eq IsSvcPassword).Value
            $user = $user.Substring(1, $user.Length - 2)
            $password = $password.Substring(1, $password.Length - 2)
            $usersAndPasswords[$user] = $password
        }

        if (($config | Where-Object Key -eq SqlSysAdminAccounts))
        {
            $group = ($config | Where-Object Key -eq SqlSysAdminAccounts).Value
            $groups += $group.Substring(1, $group.Length - 2)
        }
    }

    foreach ($kvp in $usersAndPasswords.GetEnumerator())
    {
        $user = $kvp.Key

        if ($kvp.Key.Contains("\"))
        {
            $domain = ($kvp.Key -split "\\")[0]
            $user = ($kvp.Key -split "\\")[1]
        }

        if ($kvp.Key.Contains("@"))
        {
            $domain = ($kvp.Key -split "@")[1]
            $user = ($kvp.Key -split "@")[0]
        }

        $password = $kvp.Value

        if ($domain -match 'NT Authority|BUILTIN')
        {
            continue
        }

        if ($domain)
        {
            $dc = Get-LabVm -Role RootDC, FirstChildDC | Where-Object { $_.DomainName -eq $domain -or ($_.DomainName -split "\.")[0] -eq $domain }

            if (-not $dc)
            {
                Write-ScreenInfo -Message ('User {0} will not be created. No domain controller found for {1}' -f $user,$domain) -Type Warning
            }

            Invoke-LabCommand -ComputerName $dc -ActivityName ("Creating user '$user' in domain '$domain'") -ScriptBlock {
                $existingUser = $null #required as the session is not removed
                try
                {
                    $existingUser = Get-ADUser -Identity $user -Server localhost
                }
                catch { }

                if (-not ($existingUser))
                {
                    New-ADUser -SamAccountName $user -AccountPassword ($password | ConvertTo-SecureString -AsPlainText -Force) -Name $user -PasswordNeverExpires $true -CannotChangePassword $true -Enabled $true -Server localhost
                }
            } -Variable (Get-Variable -Name user, password)
        }
        else
        {
            Invoke-LabCommand -ComputerName $Machine -ActivityName ("Creating local user '$user'") -ScriptBlock {
                if (-not (Get-LocalUser $user -ErrorAction SilentlyContinue))
                {
                    New-LocalUser -Name $user -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword -Password ($password | ConvertTo-SecureString -AsPlainText -Force)
                }
            } -Variable (Get-Variable -Name user, password)
        }
    }

    foreach ($group in $groups)
    {
        if ($group.Contains("\"))
        {
            $domain = ($group -split "\\")[0]
            $groupName = ($group -split "\\")[1]
        }
        elseif ($group.Contains("@"))
        {
            $domain = ($group -split "@")[1]
            $groupName = ($group -split "@")[0]
        }
        else
        {
            $groupName = $group
        }

        if ($domain -match 'NT Authority|BUILTIN')
        {
            continue
        }

        if ($domain)
        {
            $dc = Get-LabVM -Role RootDC, FirstChildDC | Where-Object { $_.DomainName -eq $domain -or ($_.DomainName -split "\.")[0] -eq $domain }

            if (-not $dc)
            {
                Write-ScreenInfo -Message ('User {0} will not be created. No domain controller found for {1}' -f $user, $domain) -Type Warning
            }

            Invoke-LabCommand -ComputerName $dc -ActivityName ("Creating group '$groupName' in domain '$domain'") -ScriptBlock {
                $existingGroup = $null #required as the session is not removed
                try
                {
                    $existingGroup = Get-ADGroup -Identity $groupName -Server localhost
                }
                catch { }

                if (-not ($existingGroup))
                {
                    $newGroup = New-ADGroup -Name $groupName -GroupScope Global -Server localhost -PassThru
                    #adding the account the script is running under to the SQL admin group
                    $newGroup | Add-ADGroupMember -Members ([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)

                }
            } -Variable (Get-Variable -Name groupName)
        }
        else
        {
            Invoke-LabCommand $Machine -ActivityName "Creating local group '$groupName'" -ScriptBlock {
                if (-not (Get-LocalGroup -Name $groupName -ErrorAction SilentlyContinue))
                {
                    New-LocalGroup -Name $groupName -ErrorAction SilentlyContinue
                }
            } -Variable (Get-Variable -Name groupName)
        }
    }
}
