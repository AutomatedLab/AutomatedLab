function Set-UnattendedYastUserLocale
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$UserLocale
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
	$component = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "oobeSystem"]/un:component[@name = "Microsoft-Windows-International-Core"]' -Namespace $ns |
	Select-Object -ExpandProperty Node
	
	#this is for getting the input locale strings like '0409:00000409'
	$component.UserLocale = $UserLocale
	$inputLocale = @((New-WinUserLanguageList -Language $UserLocale).InputMethodTips)
	$inputLocale += (New-WinUserLanguageList -Language 'en-us').InputMethodTips
	
	if ($inputLocale)
	{
		$component.InputLocale = ($inputLocale -join ';')
	}
}