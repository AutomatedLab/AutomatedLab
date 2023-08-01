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
