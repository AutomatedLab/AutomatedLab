function Set-VMUacStatus
{
    [CmdletBinding()]
    param(
        [bool]$EnableLUA,

        [int]$ConsentPromptBehaviorAdmin,

        [int]$ConsentPromptBehaviorUser
    )

    $currentSettings = Get-VMUacStatus -ComputerName $ComputerName
    $uacStatusChanged = $false

    $registryPath = 'Software\Microsoft\Windows\CurrentVersion\Policies\System'
    $openRegistry = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, 'Default')

    $subkey = $openRegistry.OpenSubKey($registryPath,$true)

    if ($currentSettings.EnableLUA -ne $EnableLUA -and $PSBoundParameters.ContainsKey('EnableLUA'))
    {
        $subkey.SetValue('EnableLUA', [int]$EnableLUA)
        $uacStatusChanged = $true
    }

    if ($currentSettings.PromptBehaviorAdmin -ne $ConsentPromptBehaviorAdmin -and $PSBoundParameters.ContainsKey('ConsentPromptBehaviorAdmin'))
    {
        $subkey.SetValue('ConsentPromptBehaviorAdmin', $ConsentPromptBehaviorAdmin)
        $uacStatusChanged = $true
    }

    if ($currentSettings.PromptBehaviorUser -ne $ConsentPromptBehaviorUser -and $PSBoundParameters.ContainsKey('ConsentPromptBehaviorUser'))
    {
        $subkey.SetValue('ConsentPromptBehaviorUser', $ConsentPromptBehaviorUser)
        $uacStatusChanged = $true
    }

    return (New-Object psobject -Property @{ UacStatusChanged = $uacStatusChanged } )
}
