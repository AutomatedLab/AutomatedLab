function Add-UnattendedCloudInitPreinstallationCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [string]$Description
    )

    # Ensure that installer runs to completion by returning with exit code 0
    if (-not $script:un['autoinstall'].Contains('early-commands')) {
        $script:un['autoinstall']['early-commands'] = [System.Collections.Generic.List[string]]::new()
    }

    $Command = "$Command; exit 0"
    $script:un['autoinstall']['early-commands'].Add($Command)
}
