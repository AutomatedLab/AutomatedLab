function Set-UnattendedProductKey
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$ProductKey
	)

	Write-PSFMessage "No product key required on CloudInit/Ubuntu"
}