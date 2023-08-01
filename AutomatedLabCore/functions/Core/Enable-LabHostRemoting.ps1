function Enable-LabHostRemoting
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    param(
        [switch]$Force,

        [switch]$NoDisplay
    )

    if ($IsLinux) { return }

    Write-LogFunctionEntry

    if (-not (Test-IsAdministrator))
    {
        throw 'This function needs to be called in an elevated PowerShell session.'
    }
    $message = "AutomatedLab needs to enable / relax some PowerShell Remoting features.`nYou will be asked before each individual change. Are you OK to proceed?"
    if (-not $Force)
    {
        $choice = Read-Choice -ChoiceList '&No','&Yes' -Caption 'Enabling WinRM and CredSsp' -Message $message -Default 1
        if ($choice -eq 0 -and -not $Force)
        {
            throw "Changes to PowerShell remoting on the host machine are mandatory to use AutomatedLab. You can make the changes later by calling 'Enable-LabHostRemoting'"
        }
    }

    if ((Get-Service -Name WinRM).Status -ne 'Running')
    {
        Write-ScreenInfo 'Starting the WinRM service. This is required in order to read the WinRM configuration...' -NoNewLine
        Start-Service -Name WinRM
        Start-Sleep -Seconds 2
        Write-ScreenInfo done
    }

    if ((Get-Service -Name smphost).StartType -eq 'Disabled')
    {
        Write-ScreenInfo "The StartupType of the service 'smphost' is set to disabled. Setting it to 'manual'. This is required in order to read use the cmdlets in the 'Storage' module..." -NoNewLine
        Set-Service -Name smphost -StartupType Manual
        Write-ScreenInfo done
    }

    #1067

    # force English language output for Get-WSManCredSSP call
    [Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'; $WSManCredSSP = Get-WSManCredSSP
    if ((-not $WSManCredSSP[0].Contains('The machine is configured to') -and -not $WSManCredSSP[0].Contains('WSMAN/*')) -or (Get-Item -Path WSMan:/localhost/Client/Auth/CredSSP).Value -eq $false)
    {
        $message = "AutomatedLab needs to enable CredSsp on the host in order to delegate credentials to the lab VMs.`nAre you OK with enabling CredSsp?"
        if (-not $Force)
        {
            $choice = Read-Choice -ChoiceList '&No','&Yes' -Caption 'Enabling WinRM and CredSsp' -Message $message -Default 1
            if ($choice -eq 0 -and -not $Force)
            {
                throw "CredSsp is required in order to deploy VMs with AutomatedLab. You can make the changes later by calling 'Enable-LabHostRemoting'"
            }
        }

        Write-ScreenInfo "Enabling CredSSP on the host machine for role 'Client'. Delegated computers = '*'..." -NoNewLine
        Enable-WSManCredSSP -Role Client -DelegateComputer * -Force | Out-Null
        Write-ScreenInfo done
    }
    else
    {
        Write-PSFMessage 'Remoting is enabled on the host machine'
    }

    $trustedHostsList = @((Get-Item -Path Microsoft.WSMan.Management\WSMan::localhost\Client\TrustedHosts).Value -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
    )

    if (-not ($trustedHostsList -contains '*'))
    {
        Write-ScreenInfo -Message "TrustedHosts does not include '*'. Replacing the current value '$($trustedHostsList -join ', ')' with '*'" -Type Warning

        if (-not $Force)
        {
            $message = "AutomatedLab needs to connect to machines using NTLM which does not support mutual authentication. Hence all possible machine names must be put into trusted hosts.`n`nAre you ok with putting '*' into TrustedHosts to allow the host connect to any possible lab VM?"
            $choice = Read-Choice -ChoiceList '&No','&Yes' -Caption "Setting TrustedHosts to '*'" -Message $message -Default 1
            if ($choice -eq 0 -and -not $Force)
            {
                throw "AutomatedLab requires the host to connect to any possible lab machine using NTLM. You can make the changes later by calling 'Enable-LabHostRemoting'"
            }
        }

        Set-Item -Path Microsoft.WSMan.Management\WSMan::localhost\Client\TrustedHosts -Value '*' -Force
    }
    else
    {
        Write-PSFMessage "'*' added to TrustedHosts"
    }

    $allowFreshCredentials = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1')
    $allowFreshCredentialsWhenNTLMOnly = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly', '1')
    $allowSavedCredentials = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentials', '1')
    $allowSavedCredentialsWhenNTLMOnly = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentialsWhenNTLMOnly', '1')

    if (
        ($allowFreshCredentials -ne '*' -and $allowFreshCredentials -ne 'WSMAN/*') -or
        ($allowFreshCredentialsWhenNTLMOnly -ne '*' -and $allowFreshCredentialsWhenNTLMOnly -ne 'WSMAN/*') -or
        ($allowSavedCredentials -ne '*' -and $allowSavedCredentials -ne 'TERMSRV/*') -or
        ($allowSavedCredentialsWhenNTLMOnly -ne '*' -and $allowSavedCredentialsWhenNTLMOnly -ne 'TERMSRV/*')
    )
    {
        $message = @'
The following local policies will be configured if not already done.

Computer Configuration -> Administrative Templates -> System -> Credentials Delegation ->
Allow Delegating Fresh Credentials                                   WSMAN/*
Allow Delegating Fresh Credentials when NTLM only        WSMAN/*
Allow Delegating Saved Credentials                                   TERMSRV/*
Allow Delegating Saved Credentials when NTLM only       TERMSRV/*

This is required to allow the host computer / AutomatedLab to delegate lab credentials to the lab VMs.

Are you OK with that?
'@
        if (-not $Force)
        {
            $choice = Read-Choice -ChoiceList '&No','&Yes' -Caption "Setting TrustedHosts to '*'" -Message $message -Default 1
            if ($choice -eq 0 -and -not $Force)
            {
                throw "AutomatedLab requires the the previously mentioned policies to be set. You can make the changes later by calling 'Enable-LabHostRemoting'"
            }
        }
    }

    $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1')
    if ($value -ne '*' -and $value -ne 'WSMAN/*')
    {
        Write-ScreenInfo 'Configuring the local policy for allowing credentials to be delegated to all machines (*). You can find the modified policy using gpedit.msc by navigating to: Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials' -Type Warning
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowFreshCredentials', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowFresh', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1', 'WSMAN/*') | Out-Null
    }
    else
    {
        Write-PSFMessage "Local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials' configured correctly"
    }

    $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly', '1')
    if ($value -ne '*' -and $value -ne 'WSMAN/*')
    {
        Write-ScreenInfo 'Configuring the local policy for allowing credentials to be delegated to all machines (*). You can find the modified policy using gpedit.msc by navigating to: Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials with NTLM-only server authentication' -Type Warning
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowFreshCredentialsWhenNTLMOnly', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowFreshNTLMOnly', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly', '1', 'WSMAN/*') | Out-Null
    }
    else
    {
        Write-PSFMessage "Local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials when NTLM only' configured correctly"
    }

    $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentials', '1')
    if ($value -ne '*' -and $value -ne 'TERMSRV/*')
    {
        Write-ScreenInfo 'Configuring the local policy for allowing credentials to be delegated to all machines (*). You can find the modified policy using gpedit.msc by navigating to: Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials' -Type Warning
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowSavedCredentials', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowSaved', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentials', '1', 'TERMSRV/*') | Out-Null
    }
    else
    {
        Write-PSFMessage "Local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Saved Credentials' configured correctly"
    }

    $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentialsWhenNTLMOnly', '1')
    if ($value -ne '*' -and $value -ne 'TERMSRV/*')
    {
        Write-ScreenInfo 'Configuring the local policy for allowing credentials to be delegated to all machines (*). You can find the modified policy using gpedit.msc by navigating to: Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials with NTLM-only server authentication' -Type Warning
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowSavedCredentialsWhenNTLMOnly', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowSavedNTLMOnly', 1) | Out-Null
        [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentialsWhenNTLMOnly', '1', 'TERMSRV/*') | Out-Null
    }
    else
    {
        Write-PSFMessage "Local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Saved Credentials when NTLM only' configured correctly"
    }

    $allowEncryptionOracle = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters -ErrorAction SilentlyContinue).AllowEncryptionOracle
    if ($allowEncryptionOracle -ne 2)
    {
        $message = @"
A CredSSP vulnerability has been addressed with`n`n
CVE-2018-0886`n
https://support.microsoft.com/en-us/help/4093492/credssp-updates-for-cve-2018-0886-march-13-2018`n`n
The security setting must be relexed in order to connect to machines using CredSSP that do not have the security patch installed. Are you fine setting the value 'AllowEncryptionOracle' to '2'?
"@
        if (-not $Force)
        {
            $choice = Read-Choice -ChoiceList '&No','&Yes' -Caption "Setting AllowEncryptionOracle to '2'" -Message $message -Default 1
            if ($choice -eq 0 -and -not $Force)
            {
                throw "AutomatedLab requires the the AllowEncryptionOracle setting to be 2. You can make the changes later by calling 'Enable-LabHostRemoting'"
            }
        }

        Write-ScreenInfo "Setting registry value 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters\AllowEncryptionOracle' to '2'."
        New-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters -Force | Out-Null
        Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters -Name AllowEncryptionOracle -Value 2 -Force
    }


    Write-LogFunctionExit
}
