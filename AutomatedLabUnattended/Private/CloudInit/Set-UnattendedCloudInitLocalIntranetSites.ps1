function Set-UnattendedCloudInitLocalIntranetSites
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string[]]$Values
	)
	
	Write-PSFMessage -Message 'No local intranet sites for CloudInit/Ubuntu'
}