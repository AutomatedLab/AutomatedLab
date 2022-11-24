function Set-UnattendedCloudInitAutoLogon
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$DomainName,

		[Parameter(Mandatory = $true)]
		[string]$Username,

		[Parameter(Mandatory = $true)]
		[string]$Password
    )
	
    Write-PSFMessage -Message "Auto-logon not implemented yet for CloudInit/Ubuntu"
}