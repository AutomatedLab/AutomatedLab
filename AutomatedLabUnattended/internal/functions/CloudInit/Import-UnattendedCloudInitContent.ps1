function Import-UnattendedCloudInitContent
{
	[CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $Content
    )

    $script:un = $Content -join "`r`n" | ConvertFrom-Yaml
}
