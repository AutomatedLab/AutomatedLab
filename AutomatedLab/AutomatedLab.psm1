#region Enable-LabHostRemoting
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
        Start-Sleep -Seconds 5
        Write-ScreenInfo done
    }

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
#endregion Enable-LabHostRemoting

#region Undo-LabHostRemoting
function Undo-LabHostRemoting
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
    $message = "All settings altered by 'Enable-LabHostRemoting' will be set back to Windows defaults. Are you OK to proceed?"
    if (-not $Force)
    {
        $choice = Read-Choice -ChoiceList '&No','&Yes' -Caption 'Enabling WinRM and CredSsp' -Message $message -Default 1
        if ($choice -eq 0)
        {
            throw "'Undo-LabHostRemoting' cancelled. You can make the changes later by calling 'Undo-LabHostRemoting'"
        }
    }

    if ((Get-Service -Name WinRM).Status -ne 'Running')
    {
        Write-ScreenInfo 'Starting the WinRM service. This is required in order to read the WinRM configuration...' -NoNewLine
        Start-Service -Name WinRM
        Start-Sleep -Seconds 5
        Write-ScreenInfo done
    }

    Write-ScreenInfo "Calling 'Disable-WSManCredSSP -Role Client'..." -NoNewline
    Disable-WSManCredSSP -Role Client
    Write-ScreenInfo done

    Write-ScreenInfo -Message "Setting 'TrustedHosts' to an empyt string"
    Set-Item -Path Microsoft.WSMan.Management\WSMan::localhost\Client\TrustedHosts -Value '' -Force

    Write-ScreenInfo "Resetting local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials'"
    [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowFreshCredentials', $null) | Out-Null
    [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowFresh', $null) | Out-Null
    [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1', $null) | Out-Null

    Write-ScreenInfo "Resetting local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials with NTLM-only server authentication'"
    [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowFreshCredentialsWhenNTLMOnly', $null) | Out-Null
    [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowFreshNTLMOnly', $null) | Out-Null
    [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly', '1', $null) | Out-Null

    Write-ScreenInfo "Resetting local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials'"
    [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowSavedCredentials', $null) | Out-Null
    [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowSaved', $null) | Out-Null
    [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentials', '1', $null) | Out-Null

    Write-ScreenInfo "Resetting local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials with NTLM-only server authentication'"
    [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowSavedCredentialsWhenNTLMOnly', $null) | Out-Null
    [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowSavedNTLMOnly', $null) | Out-Null
    [GPO.Helper]::SetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentialsWhenNTLMOnly', '1', $null) | Out-Null

    Write-ScreenInfo "removing 'AllowEncryptionOracle' registry setting"
    if (Test-Path -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP)
    {
        Remove-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP -Recurse -Force
    }

    Write-ScreenInfo "All settings changed by the cmdlet Enable-LabHostRemoting of AutomatedLab are back to Windows defaults."

    Write-LogFunctionExit
}
#endregion Undo-LabHostRemoting

#region Test-LabHostRemoting
function Test-LabHostRemoting
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param()

    if ($IsLinux) { return }
    Write-LogFunctionEntry

    $configOk = $true

    if ($IsLinux -or $IsMacOs)
    {
        return $configOk
    }

    if ((Get-Service -Name WinRM).Status -ne 'Running')
    {
        Write-ScreenInfo 'Starting the WinRM service. This is required in order to read the WinRM configuration...' -NoNewLine
        Start-Service -Name WinRM
        Start-Sleep -Seconds 5
        Write-ScreenInfo done
    }

    # force English language output for Get-WSManCredSSP call
    [Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'; $WSManCredSSP = Get-WSManCredSSP
    if ((-not $WSManCredSSP[0].Contains('The machine is configured to') -and -not $WSManCredSSP[0].Contains('WSMAN/*')) -or (Get-Item -Path WSMan:\localhost\Client\Auth\CredSSP).Value -eq $false)
    {
        Write-ScreenInfo "'Get-WSManCredSSP' returned that CredSSP is not enabled on the host machine for role 'Client' and being able to delegate to '*'..." -Type Verbose
        $configOk = $false
    }

    $trustedHostsList = @((Get-Item -Path Microsoft.WSMan.Management\WSMan::localhost\Client\TrustedHosts).Value -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
    )

    if (-not ($trustedHostsList -contains '*'))
    {
        Write-ScreenInfo -Message "TrustedHosts does not include '*'." -Type Verbose
        $configOk = $false
    }

    $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1')
    if ($value -ne '*' -and $value -ne 'WSMAN/*')
    {
        Write-ScreenInfo "Local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials' is not configured as required" -Type Verbose
        $configOk = $false
    }

    $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly', '1')
    if ($value -ne '*' -and $value -ne 'WSMAN/*')
    {
        Write-ScreenInfo "Local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials with NTLM-only server authentication' is not configured as required" -Type Verbose
        $configOk = $false
    }

    $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentials', '1')
    if ($value -ne '*' -and $value -ne 'TERMSRV/*')
    {
        Write-ScreenInfo "Local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials' is not configured as required" -Type Verbose
        $configOk = $false
    }

    $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentialsWhenNTLMOnly', '1')
    if ($value -ne '*' -and $value -ne 'TERMSRV/*')
    {
        Write-ScreenInfo "Local policy 'Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials with NTLM-only server authentication' is not configured as required" -Type Verbose
        $configOk = $false
    }

    $allowEncryptionOracle = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters -ErrorAction SilentlyContinue).AllowEncryptionOracle
    if ($allowEncryptionOracle -ne 2)
    {
        Write-ScreenInfo "AllowEncryptionOracle is set to '$allowEncryptionOracle'. The value should be '2'" -Type Verbose
        $configOk = $false
    }

    $configOk

    Write-LogFunctionExit
}
#endregion Test-LabHostRemoting

#region Import-Lab
function Import-Lab
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByPath', Position = 1)]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 1)]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'ByValue', Position = 1)]
        [byte[]]$LabBytes,

        [switch]$PassThru,

        [switch]$NoValidation,

        [switch]$NoDisplay
    )

    Write-LogFunctionEntry

    Clear-Lab

    if ($PSCmdlet.ParameterSetName -in 'ByPath', 'ByName')
    {
        if ($Name)
        {
            $Path = "$((Get-LabConfigurationItem -Name LabAppDataRoot))/Labs/$Name"
        }

        if (Test-Path -Path $Path -PathType Container)
        {
            $newPath = Join-Path -Path $Path -ChildPath Lab.xml
            if (-not (Test-Path -Path $newPath -PathType Leaf))
            {
                throw "The file '$newPath' is missing. Please point to an existing lab file / folder."
            }
            else
            {
                $Path = $newPath
            }
        }
        elseif (Test-Path -Path $Path -PathType Leaf)
        {
            #file is there, do nothing
        }
        else
        {
            throw "The file '$Path' is missing. Please point to an existing lab file / folder."
        }

        if (Get-PSsession)
        {
            Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue
        }

        if (-not (Test-LabHostRemoting))
        {
            Enable-LabHostRemoting
        }

        if (-not ($IsLinux -or $IsMacOs) -and -not (Test-IsAdministrator))
        {
            throw 'Import-Lab needs to be called in an elevated PowerShell session.'
        }

        if (-not ($IsLinux -or $IsMacOs))
        {
            if ((Get-Item -Path Microsoft.WSMan.Management\WSMan::localhost\Client\TrustedHosts -Force).Value -ne '*')
            {
                Write-ScreenInfo 'The host system is not prepared yet. Call the cmdlet Set-LabHost to set the requirements' -Type Warning
                Write-ScreenInfo 'After installing the lab you should undo the changes for security reasons' -Type Warning
                throw "TrustedHosts need to be set to '*' in order to be able to connect to the new VMs. Please run the cmdlet 'Set-LabHostRemoting' to make the required changes."
            }

            $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1')
            if ($value -ne '*' -and $value -ne 'WSMAN/*')
            {
                throw "Please configure the local policy for allowing credentials to be delegated. Use gpedit.msc and look at the following policy: Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials. Just add '*' to the server list to be able to delegate credentials to all machines."
            }
        }

        if (-not $NoValidation)
        {
            Write-ScreenInfo -Message 'Validating lab definition' -TaskStart
            $skipHostFileModification = Get-LabConfigurationItem -Name SkipHostFileModification

            foreach ($machine in (Get-LabMachineDefinition | Where-Object HostType -in 'HyperV', 'VMware' ))
            {
                $hostEntry = Get-HostEntry -HostName $machine

                if ($machine.FriendlyName -or $skipHostFileModification)
                {
                     continue #if FriendlyName / ResourceName is defined, host file will not be modified
                }

                if ($hostEntry -and $hostEntry.IpAddress.IPAddressToString -ne $machine.IpV4Address)
                {
                    throw "There is already an entry for machine '$($machine.Name)' in the hosts file pointing to other IP address(es) ($((Get-HostEntry -HostName $machine).IpAddress.IPAddressToString -join ',')) than the machine '$($machine.Name)' in this lab will have ($($machine.IpV4Address)). Cannot continue."
                }
            }

            $validation = Test-LabDefinition -Path $Path -Quiet

            if ($validation)
            {
                Write-ScreenInfo -Message 'Success' -TaskEnd -Type Info
            }
            else
            {
                break
            }
        }

        if (Test-Path -Path $Path)
        {
            $Script:data = [AutomatedLab.Lab]::Import((Resolve-Path -Path $Path))

            $Script:data | Add-Member -MemberType ScriptMethod -Name GetMachineTargetPath -Value {
                param (
                    [string]$MachineName
                )

                (Join-Path -Path $this.Target.Path -ChildPath $MachineName)
            }
        }
        else
        {
            throw 'Lab Definition File not found'
        }

        #import all the machine files referenced in the lab.xml
        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Machine
        $importMethodInfo = $type.GetMethod('Import',[System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static, [System.Type]::DefaultBinder, [Type[]]@([string]), $null)

        try
        {
            $Script:data.Machines = $importMethodInfo.Invoke($null, $Script:data.MachineDefinitionFiles[0].Path)

            if ($Script:data.MachineDefinitionFiles.Count -gt 1)
            {
                foreach ($machineDefinitionFile in $Script:data.MachineDefinitionFiles[1..($Script:data.MachineDefinitionFiles.Count - 1)])
                {
                    $Script:data.Machines.AddFromFile($machineDefinitionFile.Path)
                }
            }

            if ($Script:data.Machines)
            {
                $Script:data.Machines | Add-Member -MemberType ScriptProperty -Name UnattendedXmlContent -Value {
                    if ($this.OperatingSystem.Version -lt '6.2')
                    {
                        $Path = Join-Path -Path (Get-Lab).Sources.UnattendedXml.Value -ChildPath 'Unattended2008.xml'
                    }
                    else
                    {
                        $Path = Join-Path -Path (Get-Lab).Sources.UnattendedXml.Value -ChildPath 'Unattended2012.xml'
                    }
                    if ($this.OperatingSystemType -eq 'Linux' -and $this.LinuxType -eq 'RedHat')
                    {
                        $Path = Join-Path -Path (Get-Lab).Sources.UnattendedXml.Value -ChildPath ks_default.cfg
                    }
                    if ($this.OperatingSystemType -eq 'Linux' -and $this.LinuxType -eq 'Suse')
                    {
                        $Path = Join-Path -Path (Get-Lab).Sources.UnattendedXml.Value -ChildPath autoinst_default.xml
                    }
                    return (Get-Content -Path $Path)
                }
            }
        }
        catch
        {
            Write-Error -Message "No machines imported from file $machineDefinitionFile" -Exception $_.Exception -ErrorAction Stop
        }

        $minimumAzureModuleVersion = Get-LabConfigurationItem -Name MinimumAzureModuleVersion
        if (($Script:data.Machines | Where-Object HostType -eq Azure) -and -not (Get-InstalledModule -Name Az | Where-Object Version -ge $minimumAzureModuleVersion))
        {
            throw "The Azure PowerShell module version $($minimumAzureModuleVersion) or greater is not available. Please install it using the command 'Install-Module -Name Az -Force'"
        }

        if (($Script:data.Machines | Where-Object HostType -eq VMWare) -and ((Get-PSSnapin -Name VMware.VimAutomation.*).Count -ne 1))
        {
            throw 'The VMWare snapin was not loaded. Maybe it is missing'
        }

        #import all the disk files referenced in the lab.xml
        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Disk
        $importMethodInfo = $type.GetMethod('Import',[System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static, [System.Type]::DefaultBinder, [Type[]]@([string]), $null)

        try
        {
            $Script:data.Disks = $importMethodInfo.Invoke($null, $Script:data.DiskDefinitionFiles[0].Path)

            if ($Script:data.DiskDefinitionFiles.Count -gt 1)
            {
                foreach ($diskDefinitionFile in $Script:data.DiskDefinitionFiles[1..($Script:data.DiskDefinitionFiles.Count - 1)])
                {
                    $Script:data.Disks.AddFromFile($diskDefinitionFile.Path)
                }
            }
        }
        catch
        {
            Write-ScreenInfo "No disks imported from file '$diskDefinitionFile': $($_.Exception.Message)" -Type Warning
        }

        if ($Script:data.VMWareSettings.DataCenterName)
        {
            Add-LabVMWareSettings -DataCenterName $Script:data.VMWareSettings.DataCenterName `
            -DataStoreName $Script:data.VMWareSettings.DataStoreName `
            -ResourcePoolName $Script:data.VMWareSettings.ResourcePoolName `
            -VCenterServerName $Script:data.VMWareSettings.VCenterServerName `
            -Credential ([System.Management.Automation.PSSerializer]::Deserialize($Script:data.VMWareSettings.Credential))
        }

        if (-not ($IsLinux -or $IsMacOs))
        {
            $powerSchemeBackup = (powercfg.exe -GETACTIVESCHEME).Split(':')[1].Trim().Split()[0]
            powercfg.exe -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        }
    }
    elseif($PSCmdlet.ParameterSetName -eq 'ByValue')
    {
        $Script:data = [AutomatedLab.Lab]::Import($LabBytes)
    }

    if ($PassThru)
    {
        $Script:data
    }

    $global:AL_CurrentLab = $Script:data

    Write-ScreenInfo ("Lab '{0}' hosted on '{1}' imported with {2} machines" -f $Script:data.Name, $Script:data.DefaultVirtualizationEngine ,$Script:data.Machines.Count) -Type Info

    Register-LabArgumentCompleters

    Write-LogFunctionExit -ReturnValue $true
}
#endregion Import-Lab

#region Export-Lab
function Export-Lab
{
    [cmdletBinding()]

    param ()

    Write-LogFunctionEntry

    $lab = Get-Lab

    Remove-Item -Path $lab.LabFilePath

    Remove-Item -Path $lab.MachineDefinitionFiles[0].Path
    Remove-Item -Path $lab.DiskDefinitionFiles[0].Path

    $lab.Machines.Export($lab.MachineDefinitionFiles[0].Path)
    $lab.Disks.Export($lab.DiskDefinitionFiles[0].Path)
    $lab.Machines.Clear()
    $lab.Disks.Clear()

    $lab.Export($lab.LabFilePath)

    Import-Lab -Name $lab.Name -NoValidation -NoDisplay

    Write-LogFunctionExit
}
#endregion Export-LabDefinition

#region Get-Lab
function Get-Lab
{
    [CmdletBinding()]
    [OutputType([AutomatedLab.Lab])]

    param (
        [switch]$List
    )

    if ($List)
    {
        $labsPath = "$((Get-LabConfigurationItem -Name LabAppDataRoot))/Labs"

        foreach ($path in Get-ChildItem -Path $labsPath -Directory)
        {
            $labXmlPath = Join-Path -Path $path.FullName -ChildPath Lab.xml
            if (Test-Path -Path $labXmlPath)
            {
                Split-Path -Path $path -Leaf
            }
        }
    }
    else
    {
        if ($Script:data)
        {
            $Script:data
        }
        else
        {
            Write-Error 'Lab data not available. Use Import-Lab and reference a Lab.xml to import one.'
        }
    }
}
#endregion Get-Lab

#region Clear-Lab
function Clear-Lab
{
    [cmdletBinding()]

    param ()

    Write-LogFunctionEntry

    $Script:data = $null
    foreach ($module in $MyInvocation.MyCommand.Module.NestedModules | Where-Object ModuleType -eq 'Script')
    {
        & $module { $Script:data = $null }
    }

    Write-LogFunctionExit
}
#endregion Clear-Lab

#region Install-Lab
function Install-Lab
{
    [cmdletBinding()]
    param (
        [switch]$NetworkSwitches,
        [switch]$BaseImages,
        [switch]$VMs,
        [switch]$Domains,
        [switch]$AdTrusts,
        [switch]$DHCP,
        [switch]$Routing,
        [switch]$PostInstallations,
        [switch]$SQLServers,
        [switch]$Orchestrator2012,
        [switch]$WebServers,
        [Alias('Sharepoint2013')]
        [switch]$SharepointServer,
        [switch]$CA,
        [switch]$ADFS,
        [switch]$DSCPullServer,
        [switch]$ConfigManager2012R2,
        [switch]$VisualStudio,
        [switch]$Office2013,
        [switch]$Office2016,
        [switch]$AzureServices,
        [switch]$TeamFoundation,
        [switch]$FailoverCluster,
        [switch]$FileServer,
        [switch]$HyperV,
        [switch]$StartRemainingMachines,
        [switch]$CreateCheckPoints,
        [switch]$NoValidation,
        [int]$DelayBetweenComputers
    )

    Write-LogFunctionEntry
    $global:PSLog_Indent = 0

    $labDiskDeploymentInProgressPath = Get-LabConfigurationItem -Name DiskDeploymentInProgressPath

    #perform full install if no role specific installation is requested
    $performAll = -not ($PSBoundParameters.Keys | Where-Object { $_ -notin ('NoValidation', 'DelayBetweenComputers' + [System.Management.Automation.Internal.CommonParameters].GetProperties().Name)}).Count

    if (-not $Global:labExported -and -not (Get-Lab -ErrorAction SilentlyContinue))
    {
        Export-LabDefinition -Force -ExportDefaultUnattendedXml

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    if ($Global:labExported -and -not (Get-Lab -ErrorAction SilentlyContinue))
    {
        if ($NoValidation)
        {
            Import-Lab -Path (Get-LabDefinition).LabFilePath -NoValidation
        }
        else
        {
            Import-Lab -Path (Get-LabDefinition).LabFilePath
        }
    }

    if (-not $Script:data)
    {
        Write-Error 'No definitions imported, so there is nothing to test. Please use Import-Lab against the xml file'
        return
    }

    try
    {
        [AutomatedLab.LabTelemetry]::Instance.LabStarted((Get-Lab).Export(), (Get-Module AutomatedLab)[-1].Version, $PSVersionTable.BuildVersion, $PSVersionTable.PSVersion)
    }
    catch
    {
        # Nothing to catch - if an error occurs, we simply do not get telemetry.
        Write-PSFMessage -Message ('Error sending telemetry: {0}' -f $_.Exception)
    }

    Unblock-LabSources

    Send-ALNotification -Activity 'Lab started' -Message ('Lab deployment started with {0} machines' -f (Get-LabVM).Count) -Provider (Get-LabConfigurationItem -Name Notifications.SubscribedProviders)
    $engine = $Script:data.DefaultVirtualizationEngine

    if (Get-LabVM -All -IncludeLinux | Where-Object HostType -eq 'HyperV')
    {
        Update-LabMemorySettings
    }

    if ($engine -ne 'Azure' -and ($NetworkSwitches -or $performAll))
    {
        Write-ScreenInfo -Message 'Creating virtual networks' -TaskStart

        New-LabNetworkSwitches

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($BaseImages -or $performAll) -and (Get-LabVM -All | Where-Object HostType -eq 'HyperV'))
    {
        try
        {
            if (Test-Path -Path $labDiskDeploymentInProgressPath)
            {
                Write-ScreenInfo "Another lab disk deployment seems to be in progress. If this is not correct, please delete the file '$labDiskDeploymentInProgressPath'." -Type Warning
                Write-ScreenInfo 'Waiting until other disk deployment is finished.' -NoNewLine
                do
                {
                    Write-ScreenInfo -Message . -NoNewLine
                    Start-Sleep -Seconds 15
                } while (Test-Path -Path $labDiskDeploymentInProgressPath)
            }
            Write-ScreenInfo 'done'

            Write-ScreenInfo -Message 'Creating base images' -TaskStart

            New-Item -Path $labDiskDeploymentInProgressPath -ItemType File -Value ($Script:data).Name | Out-Null

            New-LabBaseImages

            Write-ScreenInfo -Message 'Done' -TaskEnd
        }
        finally
        {
            Remove-Item -Path $labDiskDeploymentInProgressPath -Force
        }
    }

    if ($VMs -or $performAll)
    {
        try
        {
            if ((Test-Path -Path $labDiskDeploymentInProgressPath) -and (Get-LabVM -All -IncludeLinux | Where-Object HostType -eq 'HyperV'))
            {
                Write-ScreenInfo "Another lab disk deployment seems to be in progress. If this is not correct, please delete the file '$labDiskDeploymentInProgressPath'." -Type Warning
                Write-ScreenInfo 'Waiting until other disk deployment is finished.' -NoNewLine
                do
                {
                    Write-ScreenInfo -Message . -NoNewLine
                    Start-Sleep -Seconds 15
                } while (Test-Path -Path $labDiskDeploymentInProgressPath)
            }
            Write-ScreenInfo 'done'

            if (Get-LabVM -All -IncludeLinux | Where-Object HostType -eq 'HyperV')
            {
                Write-ScreenInfo -Message 'Creating Additional Disks' -TaskStart
                New-Item -Path $labDiskDeploymentInProgressPath -ItemType File -Value ($Script:data).Name | Out-Null
                New-LabVHDX
                Write-ScreenInfo -Message 'Done' -TaskEnd
            }

            Write-ScreenInfo -Message 'Creating VMs' -TaskStart
            #add a hosts entry for each lab machine
            $hostFileAddedEntries = 0
            foreach ($machine in ($Script:data.Machines | Where-Object {[string]::IsNullOrEmpty($_.FriendlyName)}))
            {
                if ($machine.Hosttype -eq 'HyperV' -and $machine.NetworkAdapters[0].Ipv4Address -and -not (Get-LabConfigurationItem -Name SkipHostFileModification))
                {
                    $hostFileAddedEntries += Add-HostEntry -HostName $machine.Name -IpAddress $machine.IpV4Address -Section $Script:data.Name
                    $hostFileAddedEntries += Add-HostEntry -HostName $machine.FQDN -IpAddress $machine.IpV4Address -Section $Script:data.Name
                }
            }

            if ($hostFileAddedEntries)
            {
                Write-ScreenInfo -Message "The hosts file has been added $hostFileAddedEntries records. Clean them up using 'Remove-Lab' or manually if needed" -Type Warning
            }

            if ($script:data.Machines)
            {
                New-LabVM -Name $script:data.Machines -CreateCheckPoints:$CreateCheckPoints
            }

            #VMs created, export lab definition again to update MAC addresses
            Set-LabDefinition -Machines $Script:data.Machines
            Export-LabDefinition -Force -ExportDefaultUnattendedXml -Silent

            Write-ScreenInfo -Message 'Done' -TaskEnd
        }
        finally
        {
            Remove-Item -Path $labDiskDeploymentInProgressPath -Force -ErrorAction SilentlyContinue
        }
    }

    #Root DCs are installed first, then the Routing role is installed in order to allow domain joined routers in the root domains
    if (($Domains -or $performAll) -and (Get-LabVM -Role RootDC | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing Root Domain Controllers' -TaskStart

        Write-ScreenInfo -Message "Machines with RootDC role to be installed: '$((Get-LabVM -Role RootDC).Name -join ', ')'"
        Install-LabRootDcs -CreateCheckPoints:$CreateCheckPoints

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Routing -or $performAll) -and (Get-LabVM -Role Routing | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Configuring routing' -TaskStart

        Install-LabRouting

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($DHCP -or $performAll) -and (Get-LabVM -Role DHCP | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Configuring DHCP servers' -TaskStart

        #Install-DHCP
        Write-Error 'The DHCP role is not implemented yet'

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Domains -or $performAll) -and (Get-LabVM -Role FirstChildDC | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing Child Domain Controllers' -TaskStart

        Write-ScreenInfo -Message "Machines with FirstChildDC role to be installed: '$((Get-LabVM -Role FirstChildDC).Name -join ', ')'"
        Install-LabFirstChildDcs -CreateCheckPoints:$CreateCheckPoints

        New-LabADSubnet

        $allDcVMs = Get-LabVM -Role RootDC, FirstChildDC | Where-Object { -not $_.SkipDeployment }

        if ($allDcVMs)
        {
            if ($CreateCheckPoints)
            {
                Write-ScreenInfo -Message 'Creating a snapshot of all domain controllers'
                Checkpoint-LabVM -ComputerName $allDcVMs -SnapshotName 'Post Forest Setup'
            }
        }
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Domains -or $performAll) -and (Get-LabVM -Role DC | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing Additional Domain Controllers' -TaskStart

        Write-ScreenInfo -Message "Machines with DC role to be installed: '$((Get-LabVM -Role DC).Name -join ', ')'"
        Install-LabDcs -CreateCheckPoints:$CreateCheckPoints

        New-LabADSubnet

        $allDcVMs = Get-LabVM -Role RootDC, FirstChildDC, DC | Where-Object { -not $_.SkipDeployment }

        if ($allDcVMs)
        {
            if ($CreateCheckPoints)
            {
                Write-ScreenInfo -Message 'Creating a snapshot of all domain controllers'
                Checkpoint-LabVM -ComputerName $allDcVMs -SnapshotName 'Post Forest Setup'
            }
        }
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($AdTrusts -or $performAll) -and ((Get-LabVM -Role RootDC | Measure-Object).Count -gt 1))
    {
        Write-ScreenInfo -Message 'Configuring AD trusts' -TaskStart
        Install-LabADDSTrust
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($FileServer -or $performAll) -and (Get-LabVM -Role FileServer))
    {
        Write-ScreenInfo -Message 'Installing File Servers' -TaskStart
        Install-LabFileServers -CreateCheckPoints:$CreateCheckPoints

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($CA -or $performAll) -and (Get-LabVM -Role CaRoot, CaSubordinate))
    {
        Write-ScreenInfo -Message 'Installing Certificate Servers' -TaskStart
        Install-LabCA -CreateCheckPoints:$CreateCheckPoints

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if(($HyperV -or $performAll) -and (Get-LabVm -Role HyperV | Where-Object {-not $_.SkipDeployment}))
    {
        Write-ScreenInfo -Message 'Installing HyperV servers' -TaskStart

        Install-LabHyperV

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($FailoverCluster -or $performAll) -and (Get-LabVM -Role FailoverNode,FailoverStorage | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing Failover cluster' -TaskStart

        Start-LabVM -RoleName FailoverNode,FailoverStorage -ProgressIndicator 15 -PostDelaySeconds 5 -Wait
        Install-LabFailoverCluster

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($SQLServers -or $performAll) -and (Get-LabVM -Role SQLServer2008, SQLServer2008R2, SQLServer2012, SQLServer2014, SQLServer2016, SQLServer2017, SQLServer2019 | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing SQL Servers' -TaskStart
        if (Get-LabVM -Role SQLServer2008)   { Write-ScreenInfo -Message "Machines to have SQL Server 2008 installed: '$((Get-LabVM -Role SQLServer2008).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2008R2) { Write-ScreenInfo -Message "Machines to have SQL Server 2008 R2 installed: '$((Get-LabVM -Role SQLServer2008R2).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2012)   { Write-ScreenInfo -Message "Machines to have SQL Server 2012 installed: '$((Get-LabVM -Role SQLServer2012).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2014)   { Write-ScreenInfo -Message "Machines to have SQL Server 2014 installed: '$((Get-LabVM -Role SQLServer2014).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2016)   { Write-ScreenInfo -Message "Machines to have SQL Server 2016 installed: '$((Get-LabVM -Role SQLServer2016).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2017)   { Write-ScreenInfo -Message "Machines to have SQL Server 2017 installed: '$((Get-LabVM -Role SQLServer2017).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2019)   { Write-ScreenInfo -Message "Machines to have SQL Server 2019 installed: '$((Get-LabVM -Role SQLServer2019).Name -join ', ')'" }
        Install-LabSqlServers -CreateCheckPoints:$CreateCheckPoints

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($DSCPullServer -or $performAll) -and (Get-LabVM -Role DSCPullServer | Where-Object { -not $_.SkipDeployment }))
    {
        Start-LabVM -RoleName DSCPullServer -ProgressIndicator 15 -PostDelaySeconds 5 -Wait

        Write-ScreenInfo -Message 'Installing DSC Pull Servers' -TaskStart
        Install-LabDscPullServer

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($ADFS -or $performAll) -and (Get-LabVM -Role ADFS))
    {
        Write-ScreenInfo -Message 'Configuring ADFS' -TaskStart

        Install-LabAdfs

        Write-ScreenInfo -Message 'Done' -TaskEnd

        Write-ScreenInfo -Message 'Configuring ADFS Proxies' -TaskStart

        Install-LabAdfsProxy

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($WebServers -or $performAll) -and (Get-LabVM -Role WebServer | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing Web Servers' -TaskStart
        Write-ScreenInfo -Message "Machines to have Web Server role installed: '$((Get-LabVM -Role WebServer | Where-Object { -not $_.SkipDeployment }).Name -join ', ')'"
        Install-LabWebServers -CreateCheckPoints:$CreateCheckPoints

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if ((Get-LabVm -Role WindowsAdminCenter))
    {
        Write-ScreenInfo -Message 'Installing Windows Admin Center Servers' -TaskStart
        Write-ScreenInfo -Message "Machines to have Windows Admin Center installed: '$((Get-LabVM -Role WindowsAdminCenter | Where-Object { -not $_.SkipDeployment }).Name -join ', ')'"
        Install-LabWindowsAdminCenter

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Orchestrator2012 -or $performAll) -and (Get-LabVM -Role Orchestrator2012))
    {
        Write-ScreenInfo -Message 'Installing Orchestrator Servers' -TaskStart
        Install-LabOrchestrator2012

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($SharepointServer -or $performAll) -and (Get-LabVM -Role SharePoint))
    {
        Write-ScreenInfo -Message 'Installing SharePoint Servers' -TaskStart

        Install-LabSharePoint

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($VisualStudio -or $performAll) -and (Get-LabVM -Role VisualStudio2013))
    {
        Write-ScreenInfo -Message 'Installing Visual Studio 2013' -TaskStart

        Write-ScreenInfo -Message "Machines to have Visual Studio 2013 installed: '$((Get-LabVM -Role VisualStudio2013).Name -join ', ')'"
        Install-VisualStudio2013

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($VisualStudio -or $performAll) -and (Get-LabVM -Role VisualStudio2015))
    {
        Write-ScreenInfo -Message 'Installing Visual Studio 2015' -TaskStart

        Write-ScreenInfo -Message "Machines to have Visual Studio 2015 installed: '$((Get-LabVM -Role VisualStudio2015).Name -join ', ')'"
        Install-VisualStudio2015

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Office2013 -or $performAll) -and (Get-LabVM -Role Office2013))
    {
        Write-ScreenInfo -Message 'Installing Office 2013' -TaskStart

        Write-ScreenInfo -Message "Machines to have Office 2013 installed: '$((Get-LabVM -Role Office2013).Name -join ', ')'"
        Install-LabOffice2013

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Office2016 -or $performAll) -and (Get-LabVM -Role Office2016))
    {
        Write-ScreenInfo -Message 'Installing Office 2016' -TaskStart

        Write-ScreenInfo -Message "Machines to have Office 2016 installed: '$((Get-LabVM -Role Office2016).Name -join ', ')'"
        Install-LabOffice2016

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($TeamFoundation -or $performAll) -and (Get-LabVM -Role Tfs2015,Tfs2017,Tfs2018,TfsBuildWorker,AzDevOps))
    {
        Write-ScreenInfo -Message 'Installing Team Foundation Server environment'
        Write-ScreenInfo -Message "Machines to have TFS or the build agent installed: '$((Get-LabVM -Role Tfs2015,Tfs2017,Tfs2018,TfsBuildWorker,AzDevOps).Name -join ', ')'"

        $machinesToStart = Get-LabVM -Role Tfs2015,Tfs2017,Tfs2018,TfsBuildWorker,AzDevOps | Where-Object -Property SkipDeployment -eq $false
        if ($machinesToStart)
        {
            Start-LabVm -ComputerName $machinesToStart -ProgressIndicator 15 -PostDelaySeconds 5 -Wait
        }

        Install-LabTeamFoundationEnvironment
        Write-ScreenInfo -Message 'Team Foundation Server environment deployed'
    }

    if (($Scvmm -or $performAll) -and (Get-LabVM -Role SCVMM))
    {
        Write-ScreenInfo -Message 'Installing SCVMM'
        Write-ScreenInfo -Message "Machines to have SCVMM Management or Console installed: '$((Get-LabVM -Role SCVMM).Name -join ', ')'"

        $machinesToStart = Get-LabVM -Role SCVMM | Where-Object -Property SkipDeployment -eq $false
        if ($machinesToStart)
        {
            Start-LabVm -ComputerName $machinesToStart -ProgressIndicator 15 -PostDelaySeconds 5 -Wait
        }

        Install-LabScvmm
        Write-ScreenInfo -Message 'SCVMM environment deployed'
    }

    if (($StartRemainingMachines -or $performAll) -and (Get-LabVM -IncludeLinux | Where-Object -Property SkipDeployment -eq $false))
    {
        $linuxHosts = (Get-LabVM -IncludeLinux | Where-Object OperatingSystemType -eq 'Linux').Count
        Write-ScreenInfo -Message 'Starting remaining machines' -TaskStart
        if ($linuxHosts)
        {
            Write-ScreenInfo -Type Warning -Message "There are $linuxHosts Linux hosts in the lab.
        On Windows, those are installed from scratch and do not use differencing disks.
        
        This process may take up to 30 minutes."
        }

        if (-not $DelayBetweenComputers)
        {
            $hypervMachineCount = (Get-LabVM -IncludeLinux | Where-Object HostType -eq HyperV).Count
            if ($hypervMachineCount)
            {
                $DelayBetweenComputers = [System.Math]::Log($hypervMachineCount, 5) * 30
                Write-ScreenInfo -Message "DelayBetweenComputers not defined, value calculated is $DelayBetweenComputers seconds"
            }
            else
            {
                $DelayBetweenComputers = 0
            }
            
        }

        Write-ScreenInfo -Message 'Waiting for machines to start up...' -NoNewLine

        Start-LabVM -All -DelayBetweenComputers $DelayBetweenComputers -ProgressIndicator 30 -TimeoutInMinutes 60 -Wait

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    # A new bug surfaced where on some occasion, Azure IaaS workloads were not connected to the internet
    # until a restart was done
    if ($lab.DefaultVirtualizationEngine -eq 'Azure')
    {
        $vms = Get-LabVm
        $disconnectedVms = Invoke-LabCommand -PassThru -NoDisplay -ComputerName $vms -ScriptBlock { $null -eq (Get-NetConnectionProfile -IPv4Connectivity Internet -ErrorAction SilentlyContinue) } | Where-Object { $_}
        if ($disconnectedVms) { Restart-LabVm $disconnectedVms.PSComputerName -Wait -NoDisplay -NoNewLine }
    }

    if (($PostInstallations -or $performAll) -and (Get-LabVM | Where-Object -Property SkipDeployment -eq $false))
    {
        $machines = Get-LabVM | Where-Object { -not $_.SkipDeployment }
        $jobs = Invoke-LabCommand -PostInstallationActivity -ActivityName 'Post-installation' -ComputerName $machines -PassThru -NoDisplay
        #PostInstallations can be installed as jobs or as direct calls. If there are jobs returned, wait until they are finished
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
    }

    if (($AzureServices -or $performAll) -and (Get-LabAzureWebApp))
    {
        Write-ScreenInfo -Message 'Starting deployment of Azure services' -TaskStart

        Install-LabAzureServices

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    Install-LabRdsCertificate

    try
    {
        [AutomatedLab.LabTelemetry]::Instance.LabFinished((Get-Lab).Export())
    }
    catch
    {
        # Nothing to catch - if an error occurs, we simply do not get telemetry.
        Write-PSFMessage -Message ('Error sending telemetry: {0}' -f $_.Exception)
    }

    if (-not $NoValidation.IsPresent -and (Get-InstalledModule -Name pester -MinimumVersion 5.0))
    {
        Write-ScreenInfo -Type Verbose -Message "Testing deployment with Pester"
        $result = Invoke-LabPester -Lab (Get-Lab) -Show Normal -PassThru
        if ($result.Result -eq 'Failed')
        {
            Write-ScreenInfo -Type Error -Message "Lab deployment seems to have failed. The following tests were not passed:"
        }

        foreach ($fail in $result.Failed)
        {
            Write-ScreenInfo -Type Error -Message "$($fail.Name)"
        }
    }

    Send-ALNotification -Activity 'Lab finished' -Message 'Lab deployment successfully finished.' -Provider (Get-LabConfigurationItem -Name Notifications.SubscribedProviders)

    Write-LogFunctionExit
}
#endregion Install-Lab

#region Remove-Lab
function Remove-Lab
{
    [CmdletBinding(DefaultParameterSetName = 'Path', ConfirmImpact = 'High', SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByPath')]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 1)]
        [string]$Name,
        
        [switch]$RemoveExternalSwitches
    )

    Write-LogFunctionEntry
    $global:PSLog_Indent = 0

    if ($Name)
    {
        $Path = "$((Get-LabConfigurationItem -Name LabAppDataRoot))/Labs/$Name"
        $labName = $Name
    }
    else
    {
        $labName = $script:data.Name
    }

    if ($Path)
    {
        Import-Lab -Path $Path -NoValidation
    }

    if (-not $Script:data)
    {
        Write-Error 'No definitions imported, so there is nothing to test. Please use Import-Lab against the xml file'
        return
    }

    if($pscmdlet.ShouldProcess((Get-Lab).Name, 'Remove the lab completely'))
    {
        Write-ScreenInfo -Message "Removing lab '$($Script:data.Name)'" -Type Warning -TaskStart

        try
        {
            [AutomatedLab.LabTelemetry]::Instance.LabRemoved((Get-Lab).Export())
        }
        catch
        {
            Write-PSFMessage -Message ('Error sending telemetry: {0}' -f $_.Exception)
        }

        Write-ScreenInfo -Message 'Removing lab sessions'
        Remove-LabPSSession -All
        Write-PSFMessage '...done'

        Write-ScreenInfo -Message 'Removing imported RDS certificates'
        Uninstall-LabRdsCertificate
        Write-PsfMessage '...done'

        Write-ScreenInfo -Message 'Removing lab background jobs'
        $jobs = Get-Job
        Write-PSFMessage "Removing remaining $($jobs.Count) jobs..."
        $jobs | Remove-Job -Force -ErrorAction SilentlyContinue
        Write-PSFMessage '...done'

        if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
        {
            Write-ScreenInfo -Message "Removing Resource Group '$labName' and all resources in this group"
            #without cloning the collection, a Runtime Exceptionis thrown: An error occurred while enumerating through a collection: Collection was modified; enumeration operation may not execute
            @(Get-LabAzureResourceGroup -CurrentLab).Clone() | Remove-LabAzureResourceGroup -Force
        }

        $labMachines = Get-LabVM -IncludeLinux | Where-Object HostType -eq 'HyperV' | Where-Object { -not $_.SkipDeployment }
        if ($labMachines)
        {
            $labName = (Get-Lab).Name

            $removeMachines = foreach ($machine in $labMachines)
            {
                $machineMetadata = Get-LWHypervVMDescription -ComputerName $machine.ResourceName -ErrorAction SilentlyContinue
                $vm = Get-VM -Name $machine.ResourceName -ErrorAction SilentlyContinue
                if (-not $machineMetadata)
                {
                    Write-Error -Message "Cannot remove machine '$machine' because lab meta data could not be retrieved"
                }
                elseif ($machineMetadata.LabName -ne $labName -and $vm)
                {
                    Write-Error -Message "Cannot remove machine '$machine' because it does not belong to this lab"
                }
                else
                {
                    $machine
                }
            }

            if ($removeMachines)
            {
                Remove-LabVM -Name $removeMachines

                $disks = Get-LabVHDX -All
                Write-PSFMessage "Lab knows about $($disks.Count) disks"

                if ($disks)
                {
                    Write-ScreenInfo -Message 'Removing additionally defined disks'

                    Write-PSFMessage 'Removing disks...'
                    foreach ($disk in $disks)
                    {
                        Write-PSFMessage "Removing disk '($disk.Name)'"

                        if (Test-Path -Path $disk.Path)
                        {
                            Remove-Item -Path $disk.Path
                        }
                        else
                        {
                            Write-ScreenInfo "Disk '$($disk.Path)' does not exist"
                        }
                    }
                }

                if ($Script:data.Target.Path)
                {
                    $diskPath = (Join-Path -Path $Script:data.Target.Path -ChildPath Disks)
                    #Only remove disks folder if empty
                    if ((Test-Path -Path $diskPath) -and (-not (Get-ChildItem -Path $diskPath)) )
                    {
                        Remove-Item -Path $diskPath
                    }
                }
            }

            #Only remove folder for VMs if folder is empty
            if ($Script:data.Target.Path -and (-not (Get-ChildItem -Path $Script:data.Target.Path)))
            {
                Remove-Item -Path $Script:data.Target.Path -Recurse -Force -Confirm:$false
            }

            Write-ScreenInfo -Message 'Removing entries in the hosts file'
            Clear-HostFile -Section $Script:data.Name -ErrorAction SilentlyContinue
        }

        Write-ScreenInfo -Message 'Removing virtual networks'
        Remove-LabNetworkSwitches -RemoveExternalSwitches:$RemoveExternalSwitches

        if ($Script:data.LabPath)
        {
            Write-ScreenInfo -Message 'Removing Lab XML files'
            if (Test-Path "$($Script:data.LabPath)/$(Get-LabConfigurationItem -Name LabFileName)") { Remove-Item -Path "$($Script:data.LabPath)/Lab.xml" -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)/$(Get-LabConfigurationItem -Name DiskFileName)") { Remove-Item -Path "$($Script:data.LabPath)/Disks.xml" -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)/$(Get-LabConfigurationItem -Name MachineFileName)") { Remove-Item -Path "$($Script:data.LabPath)/Machines.xml" -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)/Unattended*.xml") { Remove-Item -Path "$($Script:data.LabPath)/Unattended*.xml" -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)/armtemplate.json") { Remove-Item -Path "$($Script:data.LabPath)/armtemplate.json" -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)/ks*.cfg") { Remove-Item -Path "$($Script:data.LabPath)/ks*.cfg" -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)/autoinst*.xml") { Remove-Item -Path "$($Script:data.LabPath)/autoinst*.xml" -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)/AzureNetworkConfig.Xml") { Remove-Item -Path "$($Script:data.LabPath)/AzureNetworkConfig.Xml" -Recurse -Force -Confirm:$false }
            if (Test-Path "$($Script:data.LabPath)/Certificates") { Remove-Item -Path "$($Script:data.LabPath)/Certificates" -Recurse -Force -Confirm:$false }

            #Only remove lab path folder if empty
            if ((Test-Path "$($Script:data.LabPath)") -and (-not (Get-ChildItem -Path $Script:data.LabPath)))
            {
                Remove-Item -Path $Script:data.LabPath
            }
        }

        $Script:data = $null

        Write-ScreenInfo -Message "Done removing lab '$labName'" -TaskEnd
    }

    Write-LogFunctionExit
}
#endregion Remove-Lab

#region Get-LabAvailableOperatingSystem
function Get-LabAvailableOperatingSystem
{
    [cmdletBinding(DefaultParameterSetName='Local')]
    [OutputType([AutomatedLab.OperatingSystem])]
    param
    (
        [Parameter(ParameterSetName='Local')]
        [string[]]$Path,

        [switch]$UseOnlyCache,

        [switch]$NoDisplay,

        [Parameter(ParameterSetName = 'Azure')]
        [switch]$Azure,

        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        $Location
    )

    Write-LogFunctionEntry

    if (-not $Path)
    {
        $Path = "$(Get-LabSourcesLocationInternal -Local)/ISOs"
    }

    $storeLocationName = if ($Azure.IsPresent) { 'Azure' } else { 'Local' }

    if ($Azure)
    {
        if (-not (Get-AzContext -ErrorAction SilentlyContinue).Subscription)
        {
            throw 'Please login to Azure before trying to list Azure image SKUs'
        }

        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Azure.AzureOSImage
        if ($IsLinux -or $IsMacOS)
        {
            $cachedSkus = try { $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath "Stores/$($storeLocationName)OperatingSystems.xml")) } catch { }
        }
        else
        {
            $cachedSkus = $type::ImportFromRegistry('Cache', "$($storeLocationName)OperatingSystems")
        }

        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.OperatingSystem
        $cachedOsList = New-Object $type
        foreach ($os in $cachedSkus)
        {
            $cachedOs = [AutomatedLab.OperatingSystem]::new($os.Skus, $true)
            if ($cachedOs.OperatingSystemName) {$cachedOsList.Add($cachedOs)}
        }

        if ($UseOnlyCache)
        {
            return $cachedOsList
        }
        
        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.OperatingSystem
        $osList = New-Object $type
        $skus = (Get-LabAzureAvailableSku -Location $Location)

        foreach ($sku in $skus)
        {
            $azureOs = ([AutomatedLab.OperatingSystem]::new($sku.Skus, $true))
            if (-not $azureOs.OperatingSystemName) { continue }

            $osList.Add($azureOs )
        }
        return $osList.ToArray()
    }

    if (-not (Test-IsAdministrator))
    {
        throw 'This function needs to be called in an elevated PowerShell session.'
    }

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.OperatingSystem
    $singleFile = Test-Path -Path $Path -PathType Leaf
    $isoFiles = Get-ChildItem -Path $Path -Filter *.iso -Recurse
    Write-PSFMessage "Found $($isoFiles.Count) ISO files"

    if (-not $singleFile)
    {
        #read the cache
        try
        {
            if ($IsLinux -or $IsMacOS)
            {
                $cachedOsList = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath "Stores/$($storeLocationName)OperatingSystems.xml"))
            }
            else
            {
                $cachedOsList = $type::ImportFromRegistry('Cache', "$($storeLocationName)OperatingSystems")
            }

            Write-ScreenInfo "found $($cachedOsList.Count) OS images in the cache"
        }
        catch
        {
            Write-PSFMessage 'Could not read OS image info from the cache'
        }

        if ($cachedOsList)
        {
            $cachedIsoFileSize = [long]$cachedOsList.Metadata[0]
            $actualIsoFileSize = ($isoFiles | Measure-Object -Property Length -Sum).Sum

            if ($cachedIsoFileSize -eq $actualIsoFileSize)
            {
                Write-PSFMessage 'Cached data is still up to date'
                Write-LogFunctionExit -ReturnValue $cachedOsList
                return $cachedOsList
            }
            else
            {
                Write-ScreenInfo -Message "ISO cache is not up to date. Analyzing all ISO files and updating the cache. This happens when running AutomatedLab for the first time and when changing contents of locations used for ISO files" -Type Warning
                Write-PSFMessage ('ISO file size ({0:N2}GB) does not match cached file size ({1:N2}). Reading the OS images from the ISO files and re-populating the cache' -f $actualIsoFileSize, $cachedIsoFileSize)
                $global:AL_OperatingSystems = $null
            }
        }
    }

    if ($UseOnlyCache)
    {
        Write-Error -Message "Get-LabAvailableOperatingSystems is used with the switch 'UseOnlyCache', however the cache is empty. Please run 'Get-LabAvailableOperatingSystems' first by pointing to your LabSources\ISOs folder" -ErrorAction Stop
    }

    $osList = New-Object $type
    if ($singleFile)
    {
        Write-ScreenInfo -Message "Scanning ISO file '$([System.IO.Path]::GetFileName($Path))' files for operating systems..." -NoNewLine
    }
    else
    {
        Write-ScreenInfo -Message "Scanning $($isoFiles.Count) files for operating systems" -NoNewLine
    }

    foreach ($isoFile in $isoFiles)
    {
        Write-ProgressIndicator
        Write-PSFMessage "Mounting ISO image '$($isoFile.FullName)'"
        $drive = Mount-LabDiskImage -ImagePath $isoFile.FullName -StorageType ISO -PassThru

        Get-PSDrive | Out-Null #This is just to refresh the drives. Somehow if this cmdlet is not called, PowerShell does not see the new drives.

        $opSystems = if ($IsLinux)
        {
            Get-LabImageOnLinux -MountPoint $drive.DriveLetter -IsoFile $isoFile
        }
        else
        {
            Get-LabImageOnWindows -DriveLetter $drive.DriveLetter -IsoFile $isoFile
        }

        foreach ($os in $opSystems)
        {
            $osList.Add($os)
        }

        Write-PSFMessage 'Dismounting ISO'
        [void] (Dismount-LabDiskImage -ImagePath $isoFile.FullName)
        Write-ProgressIndicator
    }

    $osList.ToArray()

    if ($singleFile)
    {
        Write-ScreenInfo "Found $($osList.Count) OS images."
    }
    else
    {
        $osList.Timestamp = Get-Date
        $osList.Metadata.Add(($isoFiles | Measure-Object -Property Length -Sum).Sum)

        if ($IsLinux -or $IsMacOS)
        {
            $osList.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath "Stores/$($storeLocationName)OperatingSystems.xml"))
        }
        else
        {
            $osList.ExportToRegistry('Cache', "$($storeLocationName)OperatingSystems")
        }

        Write-ProgressIndicatorEnd
        Write-ScreenInfo "Found $($osList.Count) OS images."
    }
    Write-LogFunctionExit
}
#endregion Get-LabAvailableOperatingSystem

#region Enable-LabVMRemoting
function Enable-LabVMRemoting
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [switch]$All
    )

    Write-LogFunctionEntry

    if (-not (Get-LabVM))
    {
        Write-Error 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    if ($ComputerName)
    {
        $machines = Get-LabVM -All | Where-Object { $_.Name -in $ComputerName }
    }
    else
    {
        $machines = Get-LabVM -All
    }

    $hypervVMs = $machines | Where-Object HostType -eq 'HyperV'
    if ($hypervVMs)
    {
        Enable-LWHypervVMRemoting -ComputerName $hypervVMs
    }

    $azureVms = $machines | Where-Object HostType -eq 'Azure'
    if ($azureVms)
    {
        Enable-LWAzureVMRemoting -ComputerName $azureVms
    }

    $vmwareVms = $machines | Where-Object HostType -eq 'VmWare'
    if ($vmwareVms)
    {
        Enable-LWVMWareVMRemoting -ComputerName $vmwareVms
    }

    Write-LogFunctionExit
}
#endregion Enable-LabVMRemoting

#region Install-LabWebServers
function Install-LabWebServers
{
    [cmdletBinding()]
    param ([switch]$CreateCheckPoints)

    Write-LogFunctionEntry

    $roleName = [AutomatedLab.Roles]::WebServer

    if (-not (Get-LabVM))
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM | Where-Object { $roleName -in $_.Roles.Name }
    if (-not $machines)
    {
        Write-ScreenInfo -Message "There is no machine with the role '$roleName'" -Type Warning
        Write-LogFunctionExit
        return
    }

    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 30

    Write-ScreenInfo -Message 'Waiting for Web Server role to complete installation' -NoNewLine

    $coreMachines    = $machines | Where-Object { $_.OperatingSystem.Installation -match 'Core' }
    $nonCoreMachines = $machines | Where-Object { $_.OperatingSystem.Installation -notmatch 'Core' }

    $jobs = @()
    if ($coreMachines)    { $jobs += Install-LabWindowsFeature -ComputerName $coreMachines    -AsJob -PassThru -NoDisplay -IncludeAllSubFeature -FeatureName Web-WebServer, Web-Application-Proxy, Web-Health, Web-Performance, Web-Security, Web-App-Dev, Web-Ftp-Server, Web-Metabase, Web-Lgcy-Scripting, Web-WMI, Web-Scripting-Tools, Web-Mgmt-Service, Web-WHC }
    if ($nonCoreMachines) { $jobs += Install-LabWindowsFeature -ComputerName $nonCoreMachines -AsJob -PassThru -NoDisplay -IncludeAllSubFeature -FeatureName Web-Server }

    Start-LabVm -StartNextMachines 1 -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 30 -NoDisplay

    if ($CreateCheckPoints)
    {
        Checkpoint-LabVM -ComputerName $machines -SnapshotName 'Post Web Installation'
    }

    Write-LogFunctionExit
}
#endregion Install-LabWebServers

#region Install-LabFileServers
function Install-LabFileServers
{
    
    [cmdletBinding()]
    param ([switch]$CreateCheckPoints)

    Write-LogFunctionEntry

    $roleName = [AutomatedLab.Roles]::FileServer

    if (-not (Get-LabVM))
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM | Where-Object { $roleName -in $_.Roles.Name }
    if (-not $machines)
    {
        Write-ScreenInfo -Message "There is no machine with the role '$roleName'" -Type Warning
        Write-LogFunctionExit
        return
    }

    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 30

    Write-ScreenInfo -Message 'Waiting for File Server role to complete installation' -NoNewLine

    $windowsFeatures = 'FileAndStorage-Services', 'File-Services ', 'FS-FileServer', 'FS-DFS-Namespace', 'FS-Resource-Manager', 'Print-Services', 'NET-Framework-Features', 'NET-Framework-45-Core'
    $remainingMachines = $machines | Where-Object {
        Get-LabWindowsFeature -ComputerName $_ -FeatureName $windowsFeatures -NoDisplay | Where-Object -Property Installed -eq $false
    }

    if ($remainingMachines.Count -eq 0)
    {
        Write-ScreenInfo -Message "...done."
        Write-ScreenInfo -Message "All file servers are already installed."
        return
    }
    
    $jobs = @()
    $jobs += Install-LabWindowsFeature -ComputerName $remainingMachines -FeatureName $windowsFeatures -IncludeManagementTools -AsJob -PassThru -NoDisplay

    Start-LabVM -StartNextMachines 1 -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 30 -NoDisplay
    
    Write-ScreenInfo -Message "Restarting $roleName machines..." -NoNewLine
    Restart-LabVM -ComputerName $remainingMachines -Wait -NoNewLine
    Write-ScreenInfo -Message done.

    if ($CreateCheckPoints)
    {
        Checkpoint-LabVM -ComputerName $remainingMachines -SnapshotName "Post '$roleName' Installation"
    }

    Write-LogFunctionExit
}
#endregion Install-LabFileServers

#region Install-LabWindowsFeature
function Install-LabWindowsFeature
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FeatureName,

        [switch]$IncludeAllSubFeature,

        [switch]$IncludeManagementTools,

        [switch]$UseLocalCredential,

        [int]$ProgressIndicator = 5,

        [switch]$NoDisplay,

        [switch]$PassThru,

        [switch]$AsJob
    )

    Write-LogFunctionEntry

    $results = @()

    $machines = Get-LabVM -ComputerName $ComputerName
    if (-not $machines)
    {
        Write-LogFunctionExitWithError -Message 'The specified machines could not be found'
        return
    }
    if ($machines.Count -ne $ComputerName.Count)
    {
        $machinesNotFound = Compare-Object -ReferenceObject $ComputerName -DifferenceObject ($machines.Name)
        Write-ScreenInfo "The specified machines $($machinesNotFound.InputObject -join ', ') could not be found" -Type Warning
    }

    Write-ScreenInfo -Message "Installing Windows Feature(s) '$($FeatureName -join ', ')' on computer(s) '$($ComputerName -join ', ')'" -TaskStart

    if ($AsJob)
    {
        Write-ScreenInfo -Message 'Windows Feature(s) is being installed in the background' -TaskEnd
    }

    $stoppedMachines = (Get-LabVMStatus -ComputerName $ComputerName -AsHashTable).GetEnumerator() | Where-Object Value -eq Stopped
    if ($stoppedMachines)
    {
        Start-LabVM -ComputerName $stoppedMachines.Name -Wait
    }

    $hyperVMachines = Get-LabVM -ComputerName $ComputerName | Where-Object {$_.HostType -eq 'HyperV'}
    $azureMachines  = Get-LabVM -ComputerName $ComputerName | Where-Object {$_.HostType -eq 'Azure'}

    if ($hyperVMachines)
    {
        foreach ($machine in $hyperVMachines)
        {
            $isoImagePath = $machine.OperatingSystem.IsoPath
            Mount-LabIsoImage -ComputerName $machine -IsoPath $isoImagePath -SupressOutput
        }
        $jobs = Install-LWHypervWindowsFeature -Machine $hyperVMachines -FeatureName $FeatureName -UseLocalCredential:$UseLocalCredential -IncludeAllSubFeature:$IncludeAllSubFeature -IncludeManagementTools:$IncludeManagementTools -AsJob:$AsJob -PassThru:$PassThru
    }
    elseif ($azureMachines)
    {
        $jobs = Install-LWAzureWindowsFeature -Machine $azureMachines -FeatureName $FeatureName -UseLocalCredential:$UseLocalCredential -IncludeAllSubFeature:$IncludeAllSubFeature -IncludeManagementTools:$IncludeManagementTools -AsJob:$AsJob -PassThru:$PassThru
    }

    if (-not $AsJob)
    {
        if ($hyperVMachines)
        {
            Dismount-LabIsoImage -ComputerName $hyperVMachines -SupressOutput
        }
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if ($PassThru)
    {
        $jobs
    }

    Write-LogFunctionExit
}
#endregion Install-LabWindowsFeature

#region Get-LabWindowsFeature
function Get-LabWindowsFeature
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [ValidateNotNullOrEmpty()]
        [string[]]$FeatureName = '*',

        [switch]$UseLocalCredential,

        [int]$ProgressIndicator = 5,

        [switch]$NoDisplay,

        [switch]$AsJob
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName

    if (-not $machines)
    {
        Write-LogFunctionExitWithError -Message 'The specified machines could not be found'
        return
    }
    if ($machines.Count -ne $ComputerName.Count)
    {
        $machinesNotFound = Compare-Object -ReferenceObject $ComputerName -DifferenceObject ($machines.Name)
        Write-ScreenInfo "The specified machines $($machinesNotFound.InputObject -join ', ') could not be found" -Type Warning
    }

    Write-ScreenInfo -Message "Getting Windows Feature(s) '$($FeatureName -join ', ')' on computer(s) '$($ComputerName -join ', ')'" -TaskStart

    if ($AsJob)
    {
        Write-ScreenInfo -Message 'Getting Windows Feature(s) in the background' -TaskEnd
    }

    $stoppedMachines = (Get-LabVMStatus -ComputerName $ComputerName -AsHashTable).GetEnumerator() | Where-Object Value -eq Stopped
    if ($stoppedMachines)
    {
        Start-LabVM -ComputerName $stoppedMachines.Name -Wait
    }

    $hyperVMachines = Get-LabVM -ComputerName $ComputerName | Where-Object {$_.HostType -eq 'HyperV'}
    $azureMachines = Get-LabVM -ComputerName $ComputerName | Where-Object {$_.HostType -eq 'Azure'}

    if ($hyperVMachines)
    {
        $params = @{
            Machine            = $hyperVMachines
            FeatureName        = $FeatureName
            UseLocalCredential = $UseLocalCredential
            AsJob              = $AsJob
        }

        $result = Get-LWHypervWindowsFeature @params
    }
    elseif ($azureMachines)
    {
        $params = @{
            Machine            = $azureMachines
            FeatureName        = $FeatureName
            UseLocalCredential = $UseLocalCredential
            AsJob              = $AsJob
        }

        $result = Get-LWAzureWindowsFeature @params
    }

    $result

    if (-not $AsJob)
    {
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    Write-LogFunctionExit
}
#endregion Get-LabWindowsFeature


#region Uninstall-LabWindowsFeature
function Uninstall-LabWindowsFeature
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FeatureName,

        [switch]$IncludeManagementTools,

        [switch]$UseLocalCredential,

        [int]$ProgressIndicator = 5,

        [switch]$NoDisplay,

        [switch]$PassThru,

        [switch]$AsJob
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName
    if (-not $machines)
    {
        Write-LogFunctionExitWithError -Message 'The specified machines could not be found'
        return
    }
    if ($machines.Count -ne $ComputerName.Count)
    {
        $machinesNotFound = Compare-Object -ReferenceObject $ComputerName -DifferenceObject ($machines.Name)
        Write-ScreenInfo "The specified machines $($machinesNotFound.InputObject -join ', ') could not be found" -Type Warning
    }

    Write-ScreenInfo -Message "Uninstalling Windows Feature(s) '$($FeatureName -join ', ')' on computer(s) '$($ComputerName -join ', ')'" -TaskStart

    if ($AsJob)
    {
        Write-ScreenInfo -Message 'Windows Feature(s) is being uninstalled in the background' -TaskEnd
    }

    $stoppedMachines = (Get-LabVMStatus -ComputerName $ComputerName -AsHashTable).GetEnumerator() | Where-Object Value -eq Stopped
    if ($stoppedMachines)
    {
        Start-LabVM -ComputerName $stoppedMachines.Name -Wait
    }

    $hyperVMachines = Get-LabVM -ComputerName $ComputerName | Where-Object {$_.HostType -eq 'HyperV'}
    $azureMachines = Get-LabVM -ComputerName $ComputerName | Where-Object {$_.HostType -eq 'Azure'}

    if ($hyperVMachines)
    {
        $jobs = Uninstall-LWHypervWindowsFeature -Machine $hyperVMachines -FeatureName $FeatureName -UseLocalCredential:$UseLocalCredential -IncludeManagementTools:$IncludeManagementTools -AsJob:$AsJob -PassThru:$PassThru
    }
    elseif ($azureMachines)
    {
        $jobs = Uninstall-LWAzureWindowsFeature -Machine $azureMachines -FeatureName $FeatureName -UseLocalCredential:$UseLocalCredential -IncludeManagementTools:$IncludeManagementTools -AsJob:$AsJob -PassThru:$PassThru
    }

    if (-not $AsJob)
    {
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if ($PassThru)
    {
        $jobs
    }

    Write-LogFunctionExit
}
#endregion Uninstall-LabWindowsFeature

#region Install-VisualStudio2013
function Install-VisualStudio2013
{
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = (Get-LabConfigurationItem -Name Timeout_VisualStudio2013Installation)
    )

    Write-LogFunctionEntry

    $roleName = [AutomatedLab.Roles]::VisualStudio2013

    if (-not (Get-LabVM))
    {
        Write-ScreenInfo -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first' -Type Warning
        Write-LogFunctionExit
        return
    }

    $machines = Get-LabVM -Role $roleName | Where-Object HostType -eq 'HyperV'

    if (-not $machines)
    {
        return
    }

    $isoImage = $Script:data.Sources.ISOs | Where-Object Name -eq $roleName
    if (-not $isoImage)
    {
        Write-LogFunctionExitWithError -Message "There is no ISO image available to install the role '$roleName'. Please add the required ISO to the lab and name it '$roleName'"
        return
    }

    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 15

    $jobs = @()

    Mount-LabIsoImage -ComputerName $machines -IsoPath $isoImage.Path -SupressOutput

    foreach ($machine in $machines)
    {
        $parameters = @{ }
        $parameters.Add('ComputerName', $machine.Name)
        $parameters.Add('ActivityName', 'InstallationVisualStudio2013')
        $parameters.Add('Verbose', $VerbosePreference)
        $parameters.Add('Scriptblock', {
                Write-Verbose 'Installing Visual Studio 2013'

                Push-Location
                Set-Location -Path (Get-WmiObject -Class Win32_CDRomDrive).Drive
                $exe = Get-ChildItem -Filter *.exe
                if ($exe.Count -gt 1)
                {
                    Write-Error 'More than one executable found, cannot proceed. Make sure you have defined the correct ISO image'
                    return
                }
                Write-Verbose "Calling '$($exe.FullName) /quiet /norestart /noweb /Log c:\VsInstall.log'"
                Invoke-Expression -Command "$($exe.FullName) /quiet /norestart /noweb /Log c:\VsInstall.log"
                Pop-Location

                Write-Verbose 'Waiting 120 seconds'
                Start-Sleep -Seconds 120

                $installationStart = Get-Date
                $installationTimeoutInMinutes = 120
                $installationFinished = $false

                Write-Verbose "Looping until '*Exit code: 0x<digits>, restarting: No' is detected in the VsInstall.log..."
                while (-not $installationFinished)
                {
                    if ((Get-Content -Path C:\VsInstall.log | Select-Object -Last 1) -match '(?<Text1>Exit code: 0x)(?<ReturnCode>\w*)(?<Text2>, restarting: No$)')
                    {
                        $installationFinished = $true
                        Write-Verbose 'Visual Studio installation finished'
                    }
                    else
                    {
                        Write-Verbose 'Waiting for the Visual Studio installation...'
                    }

                    if ($installationStart.AddMinutes($installationTimeoutInMinutes) -lt (Get-Date))
                    {
                        Write-Error "The installation of Visual Studio did not finish within the timeout of $installationTimeoutInMinutes minutes"
                        break
                    }

                    Start-Sleep -Seconds 5
                }
                $matches.ReturnCode
                Write-Verbose '...Installation seems to be done'
            }
        )

        $jobs += Invoke-LabCommand @parameters -AsJob -PassThru -NoDisplay
    }

    Write-ScreenInfo -Message 'Waiting for Visual Studio 2013 to complete installation' -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 60 -Timeout $InstallationTimeout -NoDisplay

    foreach ($job in $jobs)
    {
        $result = Receive-Job -Job $job
        if ($result -ne 0)
        {
            $ipAddress = (Get-Job -Id $job.id).Location
            $machineName = (Get-LabVM | Where-Object {$_.IpV4Address -eq $ipAddress}).Name
            Write-ScreenInfo -Type Warning "Installation generated error or warning for machine '$machineName'. Return code is: $result"
        }
    }

    Dismount-LabIsoImage -ComputerName $machines -SupressOutput

    Write-LogFunctionExit
}
#endregion Install-VisualStudio2013

#region Install-VisualStudio2015
function Install-VisualStudio2015
{
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = (Get-LabConfigurationItem -Name Timeout_VisualStudio2015Installation)
    )

    Write-LogFunctionEntry

    $roleName = [AutomatedLab.Roles]::VisualStudio2015

    if (-not (Get-LabVM))
    {
        Write-ScreenInfo -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first' -Type Warning
        Write-LogFunctionExit
        return
    }

    $machines = Get-LabVM -Role $roleName | Where-Object HostType -eq 'HyperV'

    if (-not $machines)
    {
        return
    }

    $isoImage = $Script:data.Sources.ISOs | Where-Object Name -eq $roleName
    if (-not $isoImage)
    {
        Write-LogFunctionExitWithError -Message "There is no ISO image available to install the role '$roleName'. Please add the required ISO to the lab and name it '$roleName'"
        return
    }

    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 15

    $jobs = @()

    Mount-LabIsoImage -ComputerName $machines -IsoPath $isoImage.Path -SupressOutput

    foreach ($machine in $machines)
    {
        $parameters = @{ }
        $parameters.Add('ComputerName', $machine.Name)
        $parameters.Add('ActivityName', 'InstallationVisualStudio2015')
        $parameters.Add('Verbose', $VerbosePreference)
        $parameters.Add('Scriptblock', {
                Write-Verbose 'Installing Visual Studio 2015'

                Push-Location
                Set-Location -Path (Get-WmiObject -Class Win32_CDRomDrive).Drive
                $exe = Get-ChildItem -Filter *.exe
                if ($exe.Count -gt 1)
                {
                    Write-Error 'More than one executable found, cannot proceed. Make sure you have defined the correct ISO image'
                    return
                }
                Write-Verbose "Calling '$($exe.FullName) /quiet /norestart /noweb /Log c:\VsInstall.log'"
                $cmd = [scriptblock]::Create("$($exe.FullName) /quiet /norestart /noweb /Log c:\VsInstall.log")
                #there is something that does not work when invoked remotely. Hence a scheduled task is used to work around that.
                Register-ScheduledJob -ScriptBlock $cmd -Name VS2015Installation -RunNow | Out-Null

                Pop-Location

                Write-Verbose 'Waiting 120 seconds'
                Start-Sleep -Seconds 120

                $installationStart = Get-Date
                $installationTimeoutInMinutes = 120
                $installationFinished = $false

                Write-Verbose "Looping until '*Exit code: 0x<hex code>, restarting: No' is detected in the VsInstall.log..."
                while (-not $installationFinished)
                {
                    if ((Get-Content -Path C:\VsInstall.log | Select-Object -Last 1) -match '(?<Text1>Exit code: 0x)(?<ReturnCode>\w*)(?<Text2>, restarting: No$)')
                    {
                        $installationFinished = $true
                        Write-Verbose 'Visual Studio installation finished'
                    }
                    else
                    {
                        Write-Verbose 'Waiting for the Visual Studio installation...'
                    }

                    if ($installationStart.AddMinutes($installationTimeoutInMinutes) -lt (Get-Date))
                    {
                        Write-Error "The installation of Visual Studio did not finish within the timeout of $installationTimeoutInMinutes minutes"
                        break
                    }

                    Start-Sleep -Seconds 5
                }
                $matches.ReturnCode
                Write-Verbose '...Installation seems to be done'
            }
        )

        $jobs += Invoke-LabCommand @parameters -AsJob -PassThru -NoDisplay
    }

    Write-ScreenInfo -Message 'Waiting for Visual Studio 2015 to complete installation' -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 60 -Timeout $InstallationTimeout -NoDisplay

    foreach ($job in $jobs)
    {
        $result = Receive-Job -Job $job -Keep
        if ($result -notin '0', 'bc2') #0 == success, 0xbc2 == sucess but required reboot
        {
            $ipAddress = (Get-Job -Id $job.id).Location
            $machineName = (Get-LabVM | Where-Object {$_.IpV4Address -eq $ipAddress}).Name
            Write-ScreenInfo -Type Warning "Installation generated error or warning for machine '$machineName'. Return code is: $result"
        }
    }

    Dismount-LabIsoImage -ComputerName $machines -SupressOutput

    Restart-LabVM -ComputerName $machines

    Write-LogFunctionExit
}
#endregion Install-VisualStudio2015

#region Install-LabOrchestrator2012
function Install-LabOrchestrator2012
{
    [cmdletBinding()]
    param ()

    Write-LogFunctionEntry

    #region prepare setup script
    function Install-LabPrivateOrchestratorRole
    {
        param (
            [Parameter(Mandatory)]
            [string]$OrchServiceUser,

            [Parameter(Mandatory)]
            [string]$OrchServiceUserPassword,

            [Parameter(Mandatory)]
            [string]$SqlServer,

            [Parameter(Mandatory)]
            [string]$SqlDbName
        )

        Write-Verbose -Message 'Installing Orchestrator'

        $start = Get-Date

        if (-not ((Get-WindowsFeature -Name NET-Framework-Features).Installed))
        {
            Write-Error "The WindowsFeature 'NET-Framework-Features' must be installed prior of installing Orchestrator. Use the cmdlet 'Install-LabWindowsFeature' to install the missing feature."
            return
        }

        $TimeoutInMinutes = 15
        $productName = 'Orchestrator 2012'
        $installProcessName = 'Setup'
        $installProcessDescription = 'Orchestrator Setup'
        $drive = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 5').DeviceID
        $computerDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name
        $cmd = "$drive\Setup\Setup.exe /Silent /ServiceUserName:$computerDomain\$OrchServiceUser /ServicePassword:$OrchServiceUserPassword /Components:All /DbServer:$SqlServer /DbNameNew:$SqlDbName /WebServicePort:81 /WebConsolePort:82 /OrchestratorRemote /SendCEIPReports:0 /EnableErrorReporting:never /UseMicrosoftUpdate:0"

        Write-Verbose 'Logs can be found here: C:\Users\<UserName>\AppData\Local\Microsoft System Center 2012\Orchestrator\Logs'

        #--------------------------------------------------------------------------------------

        Write-Verbose "Starting setup of '$productName' with the following command"
        Write-Verbose "`t$cmd"
        Write-Verbose "The timeout is $timeoutInMinutes minutes"

        Invoke-Expression -Command $cmd
        Start-Sleep -Milliseconds 500

        $timeout = Get-Date

        $queryExpression = "`$_.Name -eq '$installProcessName'"
        if ($installProcessDescription)
        {
            $queryExpression += "-and `$_.Description -eq '$installProcessDescription'"
        }
        $queryExpression = [scriptblock]::Create($queryExpression)

        Write-Verbose 'Query expression for looking for the setup process:'
        Write-Verbose "`t$queryExpression"

        if (-not (Get-Process | Where-Object $queryExpression))
        {
            Write-Error "Installation of '$productName' did not start"
            return
        }
        else
        {
            $p = Get-Process | Where-Object $queryExpression
            Write-Verbose "Installation process is '$($p.Name)' with ID $($p.Id)"
        }

        while (Get-Process | Where-Object $queryExpression)
        {
            if ((Get-Date).AddMinutes(- $TimeoutInMinutes) -gt $start)
            {
                Write-Error "Installation of '$productName' hit the timeout of 30 minutes. Killing the setup process"

                if ($installProcessDescription)
                {
                    Get-Process |
                    Where-Object  { $_.Name -eq $installProcessName -and $_.Description -eq 'Orchestrator Setup' } |
                    Stop-Process -Force
                }
                else
                {
                    Get-Process -Name $installProcessName | Stop-Process -Force
                }

                Write-Error "Installation of $productName was not successfull"
                return
            }

            Start-Sleep -Seconds 10
        }

        $end = Get-Date
        Write-Verbose "Installation finished in $($end - $start)"
    }
    #endregion

    $roleName = [AutomatedLab.Roles]::Orchestrator2012

    if (-not (Get-LabVM))
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -Role $roleName
    if (-not $machines)
    {
        Write-LogFunctionExitWithError -Message "There is no machine with the role $roleName"
        return
    }

    $isoImage = $Script:data.Sources.ISOs | Where-Object { $_.Name -eq $roleName }
    if (-not $isoImage)
    {
        Write-LogFunctionExitWithError -Message "There is no ISO image available to install the role '$roleName'. Please add the required ISO to the lab and name it '$roleName'"
        return
    }

    Start-LabVM -RoleName $roleName -Wait

    Install-LabWindowsFeature -ComputerName $machines -FeatureName RSAT, NET-Framework-Core -Verbose:$false

    Mount-LabIsoImage -ComputerName $machines -IsoPath $isoImage.Path -SupressOutput

    foreach ($machine in $machines)
    {
        $role = $machine.Roles | Where-Object { $_.Name -eq $roleName }

        $createUserScript = "
            `$user = New-ADUser -Name $($role.Properties.ServiceAccount) -AccountPassword ('$($role.Properties.ServiceAccountPassword)' | ConvertTo-SecureString -AsPlainText -Force) -Description 'Orchestrator Service Account' -Enabled `$true -PassThru
            Get-ADGroup -Identity 'Domain Admins' | Add-ADGroupMember -Members `$user
        Get-ADGroup -Identity 'Administrators' | Add-ADGroupMember -Members `$user"

        $dc = Get-LabVM -All | Where-Object {
            $_.DomainName -eq $machine.DomainName -and
            $_.Roles.Name -in @([AutomatedLab.Roles]::DC, [AutomatedLab.Roles]::FirstChildDC, [AutomatedLab.Roles]::RootDC)
        } | Get-Random

        Write-PSFMessage "Domain controller for installation is '$($dc.Name)'"

        Invoke-LabCommand -ComputerName $dc -ScriptBlock ([scriptblock]::Create($createUserScript)) -ActivityName CreateOrchestratorServiceAccount -NoDisplay

        Invoke-LabCommand -ComputerName $machine -ActivityName Orchestrator2012Installation -NoDisplay -ScriptBlock (Get-Command Install-LabPrivateOrchestratorRole).ScriptBlock `
        -ArgumentList $Role.Properties.ServiceAccount, $Role.Properties.ServiceAccountPassword, $Role.Properties.DatabaseServer, $Role.Properties.DatabaseName
    }

    Dismount-LabIsoImage -ComputerName $machines -SupressOutput

    Write-LogFunctionExit
}
#endregion Install-LabOrchestrator2012

#region Install-LabSoftwarePackage
function Install-LabSoftwarePackage
{
    param (
        [Parameter(Mandatory, ParameterSetName = 'SinglePackage')]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'SingleLocalPackage')]
        [ValidateNotNullOrEmpty()]
        [string]$LocalPath,

        [Parameter(ParameterSetName = 'SinglePackage')]
        [Parameter(ParameterSetName = 'SingleLocalPackage')]
        [ValidateNotNullOrEmpty()]
        [string]$CommandLine,

        [int]$Timeout = 10,

        [Parameter(ParameterSetName = 'SinglePackage')]
        [Parameter(ParameterSetName = 'SingleLocalPackage')]
        [bool]$CopyFolder,

        [Parameter(Mandatory, ParameterSetName = 'SinglePackage')]
        [Parameter(Mandatory, ParameterSetName = 'SingleLocalPackage')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'MulitPackage')]
        [AutomatedLab.Machine[]]$Machine,

        [Parameter(Mandatory, ParameterSetName = 'MulitPackage')]
        [AutomatedLab.SoftwarePackage]$SoftwarePackage,

        [switch]$DoNotUseCredSsp,

        [switch]$AsJob,

        [switch]$AsScheduledJob,

        [switch]$UseExplicitCredentialsForScheduledJob,

        [switch]$UseShellExecute,

        [int[]]$ExpectedReturnCodes,

        [switch]$PassThru,

        [switch]$NoDisplay,

        [int]$ProgressIndicator = 5
    )

    Write-LogFunctionEntry
    $parameterSetName = $PSCmdlet.ParameterSetName

    if ($Path -and (Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        if (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $Path)
        {
            $parameterSetName = 'SingleLocalPackage'
            $LocalPath = $Path
        }
    }

    if ($parameterSetName -eq 'SinglePackage')
    {
        if (-not (Test-Path -Path $Path))
        {
            Write-Error "The file '$Path' cannot be found. Software cannot be installed"
            return
        }

        if (Get-Command -Name Unblock-File -ErrorAction SilentlyContinue)
        {
            Unblock-File -Path $Path
        }
    }

    if ($parameterSetName -like 'Single*')
    {
        $Machine = Get-LabVM -ComputerName $ComputerName

        if (-not $Machine)
        {
            Write-Error "The machine '$ComputerName' could not be found."
            return
        }

        $unknownMachines = (Compare-Object -ReferenceObject $ComputerName -DifferenceObject $Machine.Name).InputObject
        if ($unknownMachines)
        {
            Write-ScreenInfo "The machine(s) '$($unknownMachines -join ', ')' could not be found." -Type Warning
        }

        if ($AsScheduledJob -and $UseExplicitCredentialsForScheduledJob -and
        ($Machine | Group-Object -Property DomainName).Count -gt 1)
        {
            Write-Error "If you install software in a background job and require the scheduled job to run with explicit credentials, this task can only be performed on VMs being member of the same domain."
            return
        }
    }

    if ($Path)
    {
        Write-ScreenInfo -Message "Installing software package '$Path' on machines '$($ComputerName -join ', ')' " -TaskStart
    }
    else
    {
        Write-ScreenInfo -Message "Installing software package on VM '$LocalPath' on machines '$($ComputerName -join ', ')' " -TaskStart
    }

    if ('Stopped' -in (Get-LabVMStatus $ComputerName -AsHashTable).Values)
    {
        Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewLine
        Start-LabVM -ComputerName $ComputerName -Wait -ProgressIndicator 30 -NoNewline
    }

    $jobs = @()

    $parameters = @{ }
    $parameters.Add('ComputerName', $ComputerName)
    $parameters.Add('DoNotUseCredSsp', $DoNotUseCredSsp)
    $parameters.Add('PassThru', $True)
    $parameters.Add('AsJob', $True)
    $parameters.Add('ScriptBlock', (Get-Command -Name Install-SoftwarePackage).ScriptBlock)

    if ($parameterSetName -eq 'SinglePackage')
    {
        if ($CopyFolder)
        {
            $parameters.Add('DependencyFolderPath', [System.IO.Path]::GetDirectoryName($Path))
        }
        else
        {
            $parameters.Add('DependencyFolderPath', $Path)
        }

        $installPath = Join-Path -Path / -ChildPath (Split-Path -Path $Path -Leaf)
    }
    elseif ($parameterSetName -eq 'SingleLocalPackage')
    {
        $installPath = $LocalPath
    }
    else
    {
        if ($SoftwarePackage.CopyFolder)
        {
            $parameters.Add('DependencyFolderPath', [System.IO.Path]::GetDirectoryName($SoftwarePackage.Path))
        }
        else
        {
            $parameters.Add('DependencyFolderPath', $SoftwarePackage.Path)
        }

        $installPath = Join-Path -Path / -ChildPath (Split-Path -Path $SoftwarePackage.Path -Leaf)
    }

    $installParams = @{
        Path = $installPath
        CommandLine = $CommandLine
    }
    if ($AsScheduledJob) { $installParams.AsScheduledJob = $true }
    if ($UseShellExecute) { $installParams.UseShellExecute = $true }
    if ($AsScheduledJob -and $UseExplicitCredentialsForScheduledJob) { $installParams.Credential = $Machine[0].GetCredential((Get-Lab)) }
    if ($ExpectedReturnCodes) { $installParams.ExpectedReturnCodes = $ExpectedReturnCodes }

    $parameters.Add('ActivityName', "Installation of '$installPath'")

    Write-PSFMessage -Message "Starting background job for '$($parameters.ActivityName)'"

    $parameters.ScriptBlock = {
        if ($PSEdition -eq 'core')
        {
            Add-Type -Path '/ALLibraries/core/AutomatedLab.Common.dll' -ErrorAction SilentlyContinue
        }
        elseif ([System.Environment]::OSVersion.Version -ge '6.3')
        {
            Add-Type -Path '/ALLibraries/full/AutomatedLab.Common.dll' -ErrorAction SilentlyContinue
        }

        if ($installParams.Path.StartsWith('\\') -and (Test-Path /ALAzure))
        {
            # Often issues with Zone Mapping
            $newPath = if ($IsLinux) { "/$(Split-Path -Path $installParams.Path -Leaf)" } else { "C:\$(Split-Path -Path $installParams.Path -Leaf)"}
            Copy-Item -Path $installParams.Path -Destination $newPath -Force
            $installParams.Path = $newPath
        }
        Install-SoftwarePackage @installParams
    }

    $parameters.Add('NoDisplay', $True)

    if (-not $AsJob)
    {
        Write-ScreenInfo -Message "Copying files and initiating setup on '$($ComputerName -join ', ')' and waiting for completion" -NoNewLine
    }

    $job = Invoke-LabCommand @parameters -Variable (Get-Variable -Name installParams) -Function (Get-Command -Name Install-SoftwarePackage)

    if (-not $AsJob)
    {
        Write-PSFMessage "Waiting on job ID '$($job.ID -join ', ')' with name '$($job.Name -join ', ')'"
        $results = Wait-LWLabJob -Job $job -Timeout $Timeout -ProgressIndicator 15 -NoDisplay -PassThru #-ErrorAction SilentlyContinue

        Write-PSFMessage "Job ID '$($job.ID -join ', ')' with name '$($job.Name -join ', ')' finished"
    }

    if ($AsJob)
    {
        Write-ScreenInfo -Message 'Installation started in background' -TaskEnd
        if ($PassThru) { $job }
    }
    else
    {
        Write-ScreenInfo -Message 'Installation done' -TaskEnd
        if ($PassThru) { $results }
    }

    Write-LogFunctionExit
}
#endregion Install-LabSoftwarePackage

#region Get-LabSoftwarePackage
function Get-LabSoftwarePackage
{
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
                    Test-Path -Path $_
                }
        )]
        [string]$Path,

        [string]$CommandLine,

        [int]$Timeout = 10
    )

    Write-LogFunctionEntry

    $pack = New-Object -TypeName AutomatedLab.SoftwarePackage
    $pack.CommandLine = $CommandLine
    $pack.CopyFolder = $CopyFolder
    $pack.Path = $Path
    $pack.Timeout = $timeout

    $pack

    Write-LogFunctionExit
}
#endregion Get-LabSoftwarePackage

#region Install-LabSoftwarePackages
function Install-LabSoftwarePackages
{
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [AutomatedLab.Machine[]]$Machine,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [AutomatedLab.SoftwarePackage[]]$SoftwarePackage,

        [switch]$WaitForInstallation,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $start = Get-Date
    $jobs = @()

    foreach ($m in $Machine)
    {
        Write-PSFMessage -Message "Install-LabSoftwarePackages: Working on machine '$m'"
        foreach ($p in $SoftwarePackage)
        {
            Write-PSFMessage -Message "Install-LabSoftwarePackages: Building installation package for '$p'"

            $param = @{ }
            $param.Add('Path', $p.Path)
            if ($p.CommandLine)
            {
                $param.Add('CommandLine', $p.CommandLine)
            }
            $param.Add('Timeout', $p.Timeout)
            $param.Add('ComputerName', $m.Name)
            $param.Add('PassThru', $true)

            Write-PSFMessage -Message "Install-LabSoftwarePackages: Calling installation package '$p'"

            $jobs += Install-LabSoftwarePackage @param

            Write-PSFMessage -Message "Install-LabSoftwarePackages: Installation for package '$p' finished"
        }
    }

    Write-PSFMessage 'Waiting for installation jobs to finish'

    if ($WaitForInstallation)
    {
        Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -NoDisplay
    }

    $end = Get-Date

    Write-PSFMessage "Installation of all software packages took '$($end - $start)'"

    if ($PassThru)
    {
        $jobs
    }

    Write-LogFunctionExit
}
#endregion Install-LabSoftwarePackages

#region Update-LabMemorySettings
function Update-LabMemorySettings
{
    # Cmdlet is not called on Linux systems
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [Cmdletbinding()]
    Param ()

    Write-LogFunctionEntry

    $machines = Get-LabVM -All -IncludeLinux
    $lab = Get-LabDefinition

    if ($machines | Where-Object Memory -lt 32)
    {
        $totalMemoryAlreadyReservedAndClaimed = ((Get-VM -Name $machines.ResourceName -ErrorAction SilentlyContinue) | Measure-Object -Sum -Property MemoryStartup).Sum
        $machinesNotCreated = $machines | Where-Object { (-not (Get-VM -Name $_.ResourceName -ErrorAction SilentlyContinue)) }

        $totalMemoryAlreadyReserved = ($machines | Where-Object { $_.Memory -ge 128 -and $_.Name -notin $machinesNotCreated.Name } | Measure-Object -Property Memory -Sum).Sum

        $totalMemory = (Get-CimInstance -Namespace Root\Cimv2 -Class win32_operatingsystem).FreePhysicalMemory * 1KB * 0.8 - $totalMemoryAlreadyReserved + $totalMemoryAlreadyReservedAndClaimed

        if ($lab.MaxMemory -ne 0 -and $lab.MaxMemory -le $totalMemory)
        {
            $totalMemory = $lab.MaxMemory
            Write-Debug -Message "Memory in lab is manually limited to: $totalmemory MB"
        }
        else
        {
            Write-Debug -Message "80% of total available (free) physical memory minus memory already reserved by machines where memory is defined: $totalmemory bytes"
        }


        $totalMemoryUnits = ($machines | Where-Object Memory -lt 32 | Measure-Object -Property Memory -Sum).Sum

        ForEach ($machine in $machines | Where-Object Memory -ge 128)
        {
            Write-Debug -Message "$($machine.Name.PadRight(20)) $($machine.Memory / 1GB)GB (set manually)"
        }

        #Test if necessary to limit memory at all
        $memoryUsagePrediction = $totalMemoryAlreadyReserved
        foreach ($machine in $machines | Where-Object Memory -lt 32)
        {
            switch ($machine.Memory)
            {
                1 { if ($lab.UseStaticMemory)
                    {
                        $memoryUsagePrediction += 768
                    }
                    else
                    {
                        $memoryUsagePrediction += 512
                    }
                }
                2 { if ($lab.UseStaticMemory)
                    {
                        $memoryUsagePrediction += 1024
                    }
                    else
                    {
                        $memoryUsagePrediction += 512
                    }
                }
                3 { if ($lab.UseStaticMemory)
                    {
                        $memoryUsagePrediction += 2048
                    }
                    else
                    {
                        $memoryUsagePrediction += 1024
                    }
                }
                4 { if ($lab.UseStaticMemory)
                    {
                        $memoryUsagePrediction += 4096
                    }
                    else
                    {
                        $memoryUsagePrediction += 1024
                    }
                }
            }
        }

        ForEach ($machine in $machines | Where-Object { $_.Memory -lt 32 -and -not (Get-VM -Name $_.ResourceName -ErrorAction SilentlyContinue) })
        {
            $memoryCalculated = ($totalMemory / $totalMemoryUnits * $machine.Memory / 64) * 64
            if ($memoryUsagePrediction -gt $totalMemory)
            {
                $machine.Memory = $memoryCalculated
                if (-not $lab.UseStaticMemory)
                {
                    $machine.MaxMemory = $memoryCalculated * 4
                }
            }
            else
            {
                if ($lab.MaxMemory -eq 4TB)
                {
                    #If parameter UseAllMemory was used for New-LabDefinition
                    $machine.Memory = $memoryCalculated
                }
                else
                {
                    switch ($machine.Memory)
                    {
                        1 { if ($lab.UseStaticMemory)
                            {
                                $machine.Memory = 768MB
                            }
                            else
                            {
                                $machine.MinMemory = 384MB
                                $machine.Memory    = 512MB
                                $machine.MaxMemory = 1.25GB
                            }
                        }
                        2 { if ($lab.UseStaticMemory)
                            {
                                $machine.Memory = 1GB
                            }
                            else
                            {
                                $machine.MinMemory = 384MB
                                $machine.Memory    = 512MB
                                $machine.MaxMemory = 2GB
                            }
                        }
                        3 { if ($lab.UseStaticMemory)
                            {
                                $machine.Memory = 2GB
                            }
                            else
                            {
                                $machine.MinMemory = 384MB
                                $machine.Memory    = 1GB
                                $machine.MaxMemory = 4GB
                            }
                        }
                        4 { if ($lab.UseStaticMemory)
                            {
                                $machine.Memory = 4GB
                            }
                            else
                            {
                                $machine.MinMemory = 384MB
                                $machine.Memory    = 1GB
                                $machine.MaxMemory = 8GB
                            }
                        }
                    }
                }
            }
            Write-Debug -Message "$("Memory in $($machine)".PadRight(30)) $($machine.Memory / 1GB)GB (calculated)"
            if ($machine.MaxMemory)
            {
                Write-Debug -Message "$("MaxMemory in $($machine)".PadRight(30)) $($machine.MaxMemory / 1GB)GB (calculated)"
            }

            if ($memoryCalculated -lt 256)
            {
                Write-ScreenInfo -Message "Machine '$($machine.Name)' is now auto-configured with $($memoryCalculated / 1GB)GB of memory. This might give unsatisfactory performance. Consider adding memory to the host, raising the available memory for this lab or use fewer machines in this lab" -Type Warning
            }
        }
    }

    Write-LogFunctionExit
}
#endregion Update-LabMemorySettings

#region Set-LabInstallationCredential
function Set-LabInstallationCredential
{
    [OutputType([System.Int32])]
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param (
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Parameter(Mandatory=$false, ParameterSetName = 'Prompt')]
        [ValidatePattern('^([\w\.-]){2,15}$')]
        [string]$Username,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Parameter(Mandatory=$false, ParameterSetName = 'Prompt')]
        [string]$Password,

        [Parameter(Mandatory, ParameterSetName = 'Prompt')]
        [switch]$Prompt
    )

    # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm
    $azurePasswordBlacklist = @(
        'abc@123'
        'iloveyou!'
        'P@$$w0rd'
        'P@ssw0rd'
        'P@ssword123'
        'Pa$$word'
        'pass@word1'
        'Password!'
        'Password1'
        'Password22'
    )

    if (-not (Get-LabDefinition))
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabInstallationCredential.'
    }

    if ((Get-LabDefinition).DefaultVirtualizationEngine -eq 'Azure')
    {
        if ($Password -and $azurePasswordBlacklist -contains $Password)
        {
            throw "Password '$Password' is in the list of forbidden passwords for Azure VMs: $($azurePasswordBlacklist -join ', ')"
        }

        if ($Username -eq 'Administrator')
        {
            throw 'Username may not be Administrator for Azure VMs.'
        }

        $checks = @(
            $Password -match '[A-Z]'
            $Password -match '[a-z]'
            $Password -match '\d'
            $Password.Length -ge 8
        )

        if ($Password -and $checks -contains $false)
        {
            throw "Passwords for Azure VM administrator have to:
                Be at least 8 characters long
                Have lower characters
                Have upper characters
                Have a digit
            "
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'All')
    {
        $user = New-Object AutomatedLab.User($Username, $Password)
        (Get-LabDefinition).DefaultInstallationCredential = $user
    }
    else
    {
        $promptUser = Read-Host "Type desired username for admin user (or leave blank for 'Install'. Username cannot be 'Administrator' if deploying in Azure)"

        if (-not $promptUser)
        {
            $promptUser = 'Install'
        }
        do
        {
            $promptPassword = Read-Host "Type password for admin user (leave blank for 'Somepass1' or type 'x' to cancel )"

            if (-not $promptPassword)
            {
                $promptPassword = 'Somepass1'
                $checks = 5
                break
            }

            [int]$minLength  = 8
            [int]$numUpper   = 1
            [int]$numLower   = 1
            [int]$numNumbers = 1
            [int]$numSpecial = 1

            $upper   = [regex]'[A-Z]'
            $lower   = [regex]'[a-z]'
            $number  = [regex]'[0-9]'
            $special = [regex]'[^a-zA-Z0-9]'

            $checks = 0

            if ($promptPassword.length -ge 8)                            { $checks++ }
            if ($upper.Matches($promptPassword).Count -ge $numUpper )    { $checks++ }
            if ($lower.Matches($promptPassword).Count -ge $numLower )    { $checks++ }
            if ($number.Matches($promptPassword).Count -ge $numNumbers ) { $checks++ }

            if ($checks -lt 4)
            {
                if ($special.Matches($promptPassword).Count -ge $numSpecial )  { $checks }
            }

            if ($checks -lt 4)
            {
                Write-PSFMessage -Level Host 'Password must be have minimum length of 8'
                Write-PSFMessage -Level Host 'Password must contain minimum one upper case character'
                Write-PSFMessage -Level Host 'Password must contain minimum one lower case character'
                Write-PSFMessage -Level Host 'Password must contain minimum one special character'
            }
        }
        until ($checks -ge 4 -or (-not $promptUser) -or (-not $promptPassword) -or $promptPassword -eq 'x')

        if ($checks -ge 4 -and $promptPassword -ne 'x')
        {
            $user = New-Object AutomatedLab.User($promptUser, $promptPassword)
        }
    }
}
#endregion Set-LabInstallationCredential

#region Show-LabDeploymentSummary
function Show-LabDeploymentSummary
{
    [OutputType([System.TimeSpan])]
    [Cmdletbinding()]
    param (
        [switch]$Detailed
    )

    $ts = New-TimeSpan -Start $Global:AL_DeploymentStart -End (Get-Date)
    $hoursPlural = ''
    $minutesPlural = ''
    $secondsPlural = ''

    if ($ts.Hours   -gt 1) { $hoursPlural   = 's' }
    if ($ts.minutes -gt 1) { $minutesPlural = 's' }
    if ($ts.Seconds -gt 1) { $secondsPlural = 's' }

    $lab = Get-Lab
    $machines = Get-LabVM -IncludeLinux

    Write-ScreenInfo -Message '---------------------------------------------------------------------------'
    Write-ScreenInfo -Message ("Setting up the lab took {0} hour$hoursPlural, {1} minute$minutesPlural and {2} second$secondsPlural" -f $ts.hours, $ts.minutes, $ts.seconds)
    Write-ScreenInfo -Message "Lab name is '$($lab.Name)' and is hosted on '$($lab.DefaultVirtualizationEngine)'. There are $($machines.Count) machine(s) and $($lab.VirtualNetworks.Count) network(s) defined."

    if (-not $Detailed)
    {
        Write-ScreenInfo -Message '---------------------------------------------------------------------------'
    }
    else
    {
        Write-ScreenInfo -Message '----------------------------- Network Summary -----------------------------'
        $networkInfo = $lab.VirtualNetworks | Format-Table -Property Name, AddressSpace, SwitchType, AdapterName, @{ Name = 'IssuedIpAddresses'; Expression = { $_.IssuedIpAddresses.Count } } | Out-String
        $networkInfo -split "`n" | ForEach-Object {
            if ($_) { Write-ScreenInfo -Message $_ }
        }

        Write-ScreenInfo -Message '----------------------------- Domain Summary ------------------------------'
        $domainInfo = $lab.Domains | Format-Table -Property Name,
        @{ Name = 'Administrator'; Expression = { $_.Administrator.UserName } },
        @{ Name = 'Password'; Expression = { $_.Administrator.Password } },
        @{ Name = 'RootDomain'; Expression = { if ($lab.GetParentDomain($_.Name).Name -ne $_.Name) { $lab.GetParentDomain($_.Name) } } } |
        Out-String

        $domainInfo -split "`n" | ForEach-Object {
            if ($_) { Write-ScreenInfo -Message $_ }
        }

        Write-ScreenInfo -Message '------------------------- Virtual Machine Summary -------------------------'
        $vmInfo = Get-LabVM -IncludeLinux | Format-Table -Property Name, DomainName, IpAddress, Roles, OperatingSystem,
        @{ Name = 'Local Admin'; Expression = { $_.InstallationUser.UserName } },
        @{ Name = 'Password'; Expression = { $_.InstallationUser.Password } } -AutoSize |
        Out-String

        $vmInfo -split "`n" | ForEach-Object {
            if ($_) { Write-ScreenInfo -Message $_ }
        }

        Write-ScreenInfo -Message '---------------------------------------------------------------------------'
        Write-ScreenInfo -Message 'Please use the following cmdlets to interact with the machines:'
        Write-ScreenInfo -Message '- Get-LabVMStatus, Get, Start, Restart, Stop, Wait, Connect, Save-LabVM and Wait-LabVMRestart (some of them provide a Wait switch)'
        Write-ScreenInfo -Message '- Invoke-LabCommand, Enter-LabPSSession, Install-LabSoftwarePackage and Install-LabWindowsFeature (do not require credentials and'
        Write-ScreenInfo -Message '  work the same way with Hyper-V and Azure)'
        Write-ScreenInfo -Message '- Checkpoint-LabVM, Restore-LabVMSnapshot and Get-LabVMSnapshot (only for Hyper-V)'
        Write-ScreenInfo -Message '- Get-LabInternetFile downloads files from the internet and places them on LabSources (locally or on Azure)'
        Write-ScreenInfo -Message '---------------------------------------------------------------------------'
    }
}
#endregion Show-LabDeploymentSummary

#region Set-LabGlobalNamePrefix
function Set-LabGlobalNamePrefix
{
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [ValidatePattern("^([\'\""a-zA-Z0-9]){1,4}$|()")]
        [string]$Name
    )

    $Global:labNamePrefix = $Name
}
#endregion Set-LabGlobalNamePrefix

#region Set-LabToolsPath
function Set-LabDefaultToolsPath
{
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $Global:labToolsPath = $Path
}
#endregion Set-LabToolsPath

#region Set-LabDefaultOperatingSYstem
function Set-LabDefaultOperatingSystem
{
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory)]
        [alias('Name')]
        [string]$OperatingSystem,
        [string]$Version
    )

    if (Get-LabDefinition)
    {
        if ($Version)
        {
            $os = Get-LabAvailableOperatingSystem | Where-Object {$_.OperatingSystemName -eq $OperatingSystem -and $_.Version -eq $OperatingSystemVersion}
        }
        else
        {
            $os = Get-LabAvailableOperatingSystem | Where-Object {$_.OperatingSystemName -eq $OperatingSystem}
            if ($os.Count -gt 1)
            {
                $os = $os | Sort-Object Version -Descending | Select-Object -First 1
                Write-ScreenInfo "The operating system '$OperatingSystem' is available multiple times. Choosing the one with the highest version ($($os.Version)) as default operating system" -Type Warning
            }
        }

        if (-not $os)
        {
            throw "The operating system '$OperatingSystem' could not be found in the available operating systems. Call 'Get-LabAvailableOperatingSystem' to get a list of operating systems available to the lab."
        }
        (Get-LabDefinition).DefaultOperatingSystem = $os
    }
    else
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabDefaultOperatingSystem.'
    }
}
#endregion Set-LabDefaultOperatingSystem

#region Set-LabDefaultVirtualization
function Set-LabDefaultVirtualizationEngine
{
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'HyperV', 'VMware')]
        [string]$VirtualizationEngine
    )

    if (Get-LabDefinition)
    {
        (Get-LabDefinition).DefaultVirtualizationEngine = $VirtualizationEngine
    }
    else
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabDefaultOperatingSystem.'
    }
}
#endregion Set-LabDefaultVirtualizationEngine

#region Get-LabSourcesLocation
function Get-LabSourcesLocation
{
    param
    (
        [switch]$Local
    )

    Get-LabSourcesLocationInternal -Local:$Local
}
#endregion Get-LabSourcesLocation

#region Get-LabVariable
function Get-LabVariable
{
    $pattern = 'AL_([a-zA-Z0-9]{8})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{12})'
    Get-Variable -Scope Global | Where-Object Name -Match $pattern
}
#endregion Get-LabVariable

#region Remove-LabVariable
function Remove-LabVariable
{
    $pattern = 'AL_([a-zA-Z0-9]{8})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{12})'
    Get-LabVariable | Remove-Variable -Scope Global
}
#endregion Remove-LabVariable

#region Clear-LabCache
function Clear-LabCache
{
    [cmdletBinding()]

    param()

    Write-LogFunctionEntry

    if ($IsLinux -or $IsMacOs)
    {
        $storePath = Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores'
        Get-ChildItem -Path $storePath -Filter *.xml | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    else
    {
        Remove-Item -Path Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\Software\AutomatedLab\Cache -Force -ErrorAction SilentlyContinue
    }
    Write-PSFMessage 'AutomatedLab cache removed'

    Write-LogFunctionExit
}
#endregion Clear-LabCache

#region Get-LabCache
function Get-LabCache
{
    [CmdletBinding()]
    param
    ( )

    $regKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey('CurrentUser', 'Default')
    try
    {
        $key = $regKey.OpenSubKey('Software\AutomatedLab\Cache')
        foreach ($value in $key.GetValueNames())
        {
            $content = [xml]$key.GetValue($value)
            $timestamp = $content.SelectSingleNode('//Timestamp')
            [pscustomobject]@{
                Store     = $value
                Timestamp = $timestamp.datetime -as [datetime]
                Content   = $content
            }
        }
    }
    catch { Write-PSFMessage -Message "Cache not yet created" }
}
#endregion

#region function Add-LabVMUserRight
function Add-LabVMUserRight
{
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByMachine')]
        [String[]]$ComputerName,
        [string[]]$UserName,
        [validateSet('SeNetworkLogonRight',
                'SeRemoteInteractiveLogonRight',
                'SeBatchLogonRight',
                'SeInteractiveLogonRight',
                'SeServiceLogonRight',
                'SeDenyNetworkLogonRight',
                'SeDenyInteractiveLogonRight',
                'SeDenyBatchLogonRight',
                'SeDenyServiceLogonRight',
                'SeDenyRemoteInteractiveLogonRight',
                'SeTcbPrivilege',
                'SeMachineAccountPrivilege',
                'SeIncreaseQuotaPrivilege',
                'SeBackupPrivilege',
                'SeChangeNotifyPrivilege',
                'SeSystemTimePrivilege',
                'SeCreateTokenPrivilege',
                'SeCreatePagefilePrivilege',
                'SeCreateGlobalPrivilege',
                'SeDebugPrivilege',
                'SeEnableDelegationPrivilege',
                'SeRemoteShutdownPrivilege',
                'SeAuditPrivilege',
                'SeImpersonatePrivilege',
                'SeIncreaseBasePriorityPrivilege',
                'SeLoadDriverPrivilege',
                'SeLockMemoryPrivilege',
                'SeSecurityPrivilege',
                'SeSystemEnvironmentPrivilege',
                'SeManageVolumePrivilege',
                'SeProfileSingleProcessPrivilege',
                'SeSystemProfilePrivilege',
                'SeUndockPrivilege',
                'SeAssignPrimaryTokenPrivilege',
                'SeRestorePrivilege',
                'SeShutdownPrivilege',
                'SeSynchAgentPrivilege',
                'SeTakeOwnershipPrivilege'
        )]
        [Alias('Priveleges')]
        [string[]]$Privilege
    )

    $Job = @()

    foreach ($Computer in $ComputerName)
    {
        $param = @{}
        $param.add('UserName', $UserName)
        $param.add('Right', $Right)
        $param.add('ComputerName', $Computer)

        $Job += Invoke-LabCommand -ComputerName $Computer -ActivityName "Configure user rights '$($Privilege -join ', ')' for user accounts: '$($UserName -join ', ')'" -NoDisplay -AsJob -PassThru -ScriptBlock {
            Add-AccountPrivilege -UserName $UserName -Privilege $Privilege
        } -Variable (Get-Variable UserName, Privilege) -Function (Get-Command Add-AccountPrivilege)
    }
    Wait-LWLabJob -Job $Job -NoDisplay
}
#endregion function Add-LabVMUserRight

#region New-LabSourcesFolder
function New-LabSourcesFolder
{
    [CmdletBinding(
            SupportsShouldProcess = $true,
    ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(Mandatory = $false)]
        [System.String]
        $DriveLetter,

        [switch]
        $Force,

        [ValidateSet('master','develop')]
        [string]
        $Branch = 'master'
    )

    $path = Get-LabSourcesLocation -Local
    if (-not $path -and (Get-LabConfigurationItem -Name LabSourcesLocation))
    {
        $path = Get-LabConfigurationItem -Name LabSourcesLocation
    }
    elseif (-not $path)
    {
        $path = (Join-Path -Path / -ChildPath LabSources)
    }

    if ($DriveLetter)
    {
        try
        {
            $drive = [System.IO.DriveInfo]$DriveLetter
        }
        catch
        {
            throw "$DriveLetter is not a valid drive letter. Exception was ($_.Exception.Message)"
        }

        if (-not $drive.IsReady)
        {
            throw "LabSource cannot be placed on $DriveLetter. The drive is not ready."
        }

        $Path = Join-Path -Path $drive.RootDirectory -ChildPath LabSources
    }

    if ((Test-Path -Path $Path) -and -not $Force)
    {
        return $Path
    }

    if (-not $Force.IsPresent)
    {
        Write-ScreenInfo -Message 'Downloading LabSources from GitHub. This only happens once if no LabSources folder can be found.' -Type Warning
    }

    if ($PSCmdlet.ShouldProcess('Downloading module and creating new LabSources', $Path))
    {
        $temporaryPath = [System.IO.Path]::GetTempFileName().Replace('.tmp', '')
        [void] (New-Item -ItemType Directory -Path $temporaryPath -Force)
        $archivePath = (Join-Path -Path $temporaryPath -ChildPath 'master.zip')

        try
        {
            Get-LabInternetFile -Uri ('https://github.com/AutomatedLab/AutomatedLab/archive/{0}.zip' -f $Branch) -Path $archivePath -ErrorAction Stop
        }
        catch
        {
            Write-Error "Could not download the LabSources folder due to connection issues. Please try again." -ErrorAction Stop
        }
        Microsoft.PowerShell.Archive\Expand-Archive -Path $archivePath -DestinationPath $temporaryPath

        if (-not (Test-Path -Path $Path))
        {
            $Path = (New-Item -ItemType Directory -Path $Path).FullName
        }

        Copy-Item -Path (Join-Path -Path $temporaryPath -ChildPath AutomatedLab-master/LabSources/*) -Destination $Path -Recurse -Force:$Force

        Remove-Item -Path $temporaryPath -Recurse -Force -ErrorAction SilentlyContinue

        $Path
    }
}
#endregion New-LabSourcesFolder

#region Telemetry
function Enable-LabTelemetry
{
    if ($IsLinux -or $IsMacOs)
    {
        $null = New-Item -ItemType File -Path "$((Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot))/telemetry.enabled" -Force
    }
    else
    {
        [Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', 'true', 'Machine')
        $env:AUTOMATEDLAB_TELEMETRY_OPTIN = 'true'
    }
}

function Disable-LabTelemetry
{
    if ($IsLinux -or $IsMacOs)
    {
        $null = Remove-Item -Path "$((Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot))/telemetry.enabled"
    }
    else
    {
        [Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', 'false', 'Machine')
        $env:AUTOMATEDLAB_TELEMETRY_OPTIN = 'false'
    }
}

$telemetryChoice = @"
We are collecting telemetry to improve AutomatedLab.

To see what we collect: https://aka.ms/ALTelemetry

We collect no personally identifiable information, ever.

Select Yes to permanently opt-in, no to permanently opt-out
or Ask me later to get asked later.
"@

if (Test-Path -Path Env:\AUTOMATEDLAB_TELEMETRY_OPTOUT)
{
    $newValue = switch -Regex ($env:AUTOMATEDLAB_TELEMETRY_OPTOUT)
    {
        'yes|1|true' {0}
        'no|0|false' {1}
    }

    [System.Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', $newValue, 'Machine')
    $env:AUTOMATEDLAB_TELEMETRY_OPTIN = $newValue
    Remove-Item -Path Env:\AUTOMATEDLAB_TELEMETRY_OPTOUT -Force -ErrorAction SilentlyContinue
    [System.Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTOUT', $null, 'Machine')
}

$type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String, DateTime
$nextCheck = (Get-Date).AddDays(-1)

try
{
    Write-PSFMessage -Message 'Trying to check if user postponed telemetry setting'
    if ($IsLinux -or $IsMacOs)
    {
        $timestamps = $type::Import((Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
    }
    else
    {
        $timestamps = $type::ImportFromRegistry('Cache', 'Timestamps')
    }
    $nextCheck = $timestamps.TelemetryNextCheck
    Write-PSFMessage -Message "Next check is '$nextCheck'."
}
catch
{
    $timestamps = New-Object $type
}

if (-not (
    (Test-Path Env:\AUTOMATEDLAB_TELEMETRY_OPTIN) -or `
    (Test-Path -Path "$((Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot))/telemetry.enabled")) -and `
    (Get-Date) -ge $nextCheck
    )
{
    $choice = Read-Choice -ChoiceList '&Yes','&No','&Ask later' -Caption 'Opt in to telemetry?' -Message $telemetryChoice -Default 0

    switch ($Choice)
    {
        0
        {
            Enable-LabTelemetry
        }
        1
        {
            Disable-LabTelemetry
        }
        2
        {
            $ts = (Get-Date).AddDays((Get-Random -Minimum 30 -Maximum 90))
            $timestamps['TelemetryNextCheck'] = $ts
            if ($IsLinux -or $IsMacOs)
            {
                $timestamps.Export((Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath 'Stores/Timestamps.xml'))
            }
            else
            {
                $timestamps.ExportToRegistry('Cache', 'Timestamps')
            }

            Write-ScreenInfo -Message "Okay, asking you again after $($ts.ToString('yyyy-MM-dd'))"
        }
    }
}

#endregion Telemetry

#region Get-LabConfigurationItem
function Get-LabConfigurationItem
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        $Default
    )

    if ($Name)
    {
        $setting = (Get-PSFConfig -Module AutomatedLab -Name $Name).Value
        if (-not $setting -and $Default)
        {
            return $Default
        }

        return $setting
    }

    Get-PSFConfig -Module AutomatedLab
}
#endregion Get-LabConfigurationItem

#region Test-LabHostConnected
function Test-LabHostConnected
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingComputerNameHardcoded", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("ALSimpleNullComparison", "", Justification="We want a boolean")]
    [CmdletBinding()]
    param
    (
        [switch]
        $Throw,

        [switch]
        $Quiet
    )

    if (Get-LabConfigurationItem -Name DisableConnectivityCheck)
    {
        $script:connected = $true
    }

    if (-not $script:connected)
    {
        $script:connected = if (Get-Command Get-NetConnectionProfile -ErrorAction SilentlyContinue)
        {
            $null -ne (Get-NetConnectionProfile | Where-Object {$_.IPv4Connectivity -eq 'Internet' -or $_.IPv6Connectivity -eq 'Internet'})
        }
        elseif ((Get-ChildItem -Path env:\ACC_OID,env:\ACC_VERSION,env:\ACC_TID -ErrorAction SilentlyContinue).Count -eq 3)
        {
            # Assuming that we are in Azure Cloud Console aka Cloud Shell which is connected but cannot send ICMP packages
            $true
        }
        elseif ($IsLinux)
        {
            # Due to an unadressed issue with Test-Connection on Linux
            $portOpen = Test-Port -ComputerName automatedlab.org -Port 443
            if (-not $portOpen.Open)
            {
                [System.Net.NetworkInformation.Ping]::new().Send('automatedlab.org').Status -eq 'Success'
            }
            else
            {
                $portOpen.Open
            }
        }
        else
        {
            Test-Connection -ComputerName automatedlab.org -Count 4 -Quiet -ErrorAction SilentlyContinue -InformationAction Ignore
        }
    }

    if ($Throw.IsPresent -and -not $script:connected)
    {
        throw "$env:COMPUTERNAME does not seem to be connected to the internet. All internet-related tasks will fail."
    }

    if ($Quiet.IsPresent)
    {
        return
    }

    $script:connected
}
#endregion

#Initialization code

#Register the $LabSources variable
$dynamicLabSources = New-Object AutomatedLab.DynamicVariable 'global:labSources', { Get-LabSourcesLocationInternal }, { $null }
$executioncontext.SessionState.PSVariable.Set($dynamicLabSources)

#download the ProductKeys.xml file if it does not exist. The installer puts the file into 'C:\ProgramData\AutomatedLab\Assets'
#but when installing AL using the PowerShell Gallery, this file is missing.
$productKeyFileLink = 'https://raw.githubusercontent.com/AutomatedLab/AutomatedLab/master/Assets/ProductKeys.xml'
$productKeyFileName = 'ProductKeys.xml'
$productKeyFilePath = Get-PSFConfigValue AutomatedLab.ProductKeyFilePath

if (-not (Test-Path -Path (Split-Path $productKeyFilePath -Parent)))
{
    New-Item -Path (Split-Path $productKeyFilePath -Parent) -ItemType Directory | Out-Null
}

if (-not (Test-Path -Path $productKeyFilePath))
{
    Invoke-RestMethod -Method Get -Uri $productKeyFileLink -OutFile $productKeyFilePath
}

$productKeyCustomFilePath = Get-PSFConfigValue AutomatedLab.ProductKeyFilePathCustom

if (-not (Test-Path -Path $productKeyCustomFilePath))
{
    $store = New-Object 'AutomatedLab.ListXmlStore[AutomatedLab.ProductKey]'

    $dummyProductKey = New-Object AutomatedLab.ProductKey -Property @{ Key = '123'; OperatingSystemName = 'OS'; Version = '1.0' }
    $store.Add($dummyProductKey)
    $store.Export($productKeyCustomFilePath)
}

Register-PSFTeppArgumentCompleter -Command Add-LabMachineDefinition -Parameter OperatingSystem -Name 'AutomatedLab-OperatingSystem'
