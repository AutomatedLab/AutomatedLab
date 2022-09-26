function Add-UnattendedCloudInitSynchronousCommand
{
	[CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $script:un['late-commands'] += $Command
}
