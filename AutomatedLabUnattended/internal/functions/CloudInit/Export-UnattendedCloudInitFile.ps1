function Export-UnattendedCloudInitFile
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]$Path
    )

    # Cloud-init -> User Data cannot contain networking information
    # 
    $null = New-Item -Path $Path -Name meta-data -Force -Value "#cloud-config`ninstance-id: iid-local01`nlocal-hostname: $($Machine.Name)"
    $metadataDictionary = @{
        'instance-id'    = 'iid-local01'
        'local-hostname' = $Script:un.identity.hostname
        network          = $script:un.network.Clone()
        locale           = $script:un.locale
    }

    $userdataDictionary = $script:un.Clone()
    $userdataDictionary.Remove('network')

    $userdataDictionary | ConvertTo-Yaml | Set-Content -Path (Join-Path -Path $Path -ChildPath user-data) -Force
    $metadataDictionary | ConvertTo-Yaml | Set-Content -Path (Join-Path -Path $Path -ChildPath meta-data) -Force
}