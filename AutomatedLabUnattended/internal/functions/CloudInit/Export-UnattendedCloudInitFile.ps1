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
    $metadataDictionary = @{
        'instance-id'    = $Script:un.identity.hostname
        'local-hostname' = $Script:un.identity.hostname
        network          = $script:un.network.Clone()
        locale           = $script:un.locale
    }

    $userdataDictionary = $script:un.Clone()
    $userdataDictionary.Remove('network')
    $userdataDictionary.Remove('locale')
    $userdataDictionary.Remove('timezone')
    $userdataDictionary.identity.Remove('hostname')

    ("#cloud-config`n{0}" -f ($userdataDictionary | ConvertTo-Yaml)) | Set-Content -Path (Join-Path -Path $Path -ChildPath user-data) -Force
    ("#cloud-config`n{0}" -f ($metadataDictionary | ConvertTo-Yaml)) | ConvertTo-Yaml | Set-Content -Path (Join-Path -Path $Path -ChildPath meta-data) -Force
}