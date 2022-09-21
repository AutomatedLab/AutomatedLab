function Export-UnattendedCloudInitFile
{
	[CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $script:un | ConvertTo-Yaml | Set-Content -Path $Path -Force
}