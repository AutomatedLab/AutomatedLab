function Add-UnattendedCloudInitSynchronousCommand
{
	[CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [string]$Description
    )

    # Ensure that installer runs to completion by returning with exit code 0
    $Command = "$Command; exit 0"
    $script:un['autoinstall']['late-commands'] += $Command
}
