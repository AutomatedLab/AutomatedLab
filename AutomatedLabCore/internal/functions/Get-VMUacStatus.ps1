function Get-VMUacStatus
{
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $registryPath = 'Software\Microsoft\Windows\CurrentVersion\Policies\System'
    $uacStatus = $false

    $openRegistry = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, 'Default')
    $subkey = $openRegistry.OpenSubKey($registryPath, $false)

    $uacStatus = $subkey.GetValue('EnableLUA')
    $consentPromptBehaviorUser = $subkey.GetValue('ConsentPromptBehaviorUser')
    $consentPromptBehaviorAdmin = $subkey.GetValue('ConsentPromptBehaviorAdmin')

    New-Object -TypeName PSObject -Property @{
        ComputerName = $ComputerName
        EnableLUA = $uacStatus
        PromptBehaviorUser = $consentPromptBehaviorUser
        PromptBehaviorAdmin = $consentPromptBehaviorAdmin
    }
}
