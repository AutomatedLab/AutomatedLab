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

    Write-ScreenInfo -Message "Setting 'TrustedHosts' to an empty string"
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
