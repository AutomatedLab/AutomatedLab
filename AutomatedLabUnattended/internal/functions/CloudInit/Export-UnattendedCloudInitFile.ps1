﻿function Export-UnattendedCloudInitFile
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
        'instance-id'    = $Script:un['user-data']['hostname']
        'local-hostname' = $Script:un['user-data']['hostname']
    }

    $userdataDictionary = $script:un.Clone()

    ("#cloud-config`n{0}" -f ($userdataDictionary | ConvertTo-Yaml)) | Set-Content -Path (Join-Path -Path $Path -ChildPath user-data) -Force
    ("#cloud-config`n{0}" -f ($metadataDictionary | ConvertTo-Yaml)) | Set-Content -Path (Join-Path -Path $Path -ChildPath meta-data) -Force
}