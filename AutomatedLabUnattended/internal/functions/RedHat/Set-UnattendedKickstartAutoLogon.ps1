function Set-UnattendedKickstartAutoLogon
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$DomainName,

		[Parameter(Mandatory = $true)]
		[string]$Username,

		[Parameter(Mandatory = $true)]
		[string]$Password
    )
    Write-PSFMessage -Message "Auto-logon not implemented yet for RHEL/CentOS/Fedora"
}
