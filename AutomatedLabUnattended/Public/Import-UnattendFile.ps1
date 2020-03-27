function Import-UnattendedFile
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	$script:un = [xml](Get-Content -Path $Path)
	$script:ns = @{ un = 'urn:schemas-microsoft-com:unattend' }
	$Script:wcmNamespaceUrl = 'http://schemas.microsoft.com/WMIConfig/2002/State'
}
