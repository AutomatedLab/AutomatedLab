function Add-UnattendedKickstartSynchronousCommand
{
    param (
        [Parameter(Mandatory)]
        [string]$Command,
		
        [Parameter(Mandatory)]
        [string]$Description
    )

    Write-Verbose -Message 'No Synchronous Command (first user logon script) for RHEL/CentOS/Fedora'
}