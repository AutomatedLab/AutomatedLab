function Set-UnattendedWindowsUserLocale
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

	if ($IsLinux)
	{
		$inputLocale = '0409:00000409'
	}
	else
	{
		try
		{
			$inputLocale = @((New-WinUserLanguageList -Language $UserLocale).InputMethodTips)
			$inputLocale += (New-WinUserLanguageList -Language 'en-us').InputMethodTips
		}
		catch
		{
			Remove-Module -Name International -ErrorAction SilentlyContinue -Force
			Get-ChildItem -Directory -Path ([IO.Path]::GetTempPath()) -Filter RemoteIpMoProxy_International*_localhost_* | Remove-Item -Recurse -Force 
			if ((Get-Command Import-Module).Parameters.ContainsKey('UseWindowsPowerShell'))
			{
				Import-Module -Name International -UseWindowsPowerShell -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -Force
			}
			else
			{
				Import-WinModule -Name International -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -Force
			}

			$inputLocale = @((New-WinUserLanguageList -Language $UserLocale).InputMethodTips)
			$inputLocale += (New-WinUserLanguageList -Language 'en-us').InputMethodTips
		}
	}
	if ($inputLocale)
	{
		$component.InputLocale = ($inputLocale -join ';')
	}
}
