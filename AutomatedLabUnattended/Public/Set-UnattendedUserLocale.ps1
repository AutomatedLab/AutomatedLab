function Set-UnattendedUserLocale
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$UserLocale,

        [switch]
        $IsKickstart,

        [switch]
        $IsAutoYast
    )

	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
    }

    if ($IsKickstart) { Set-UnattendedKickstartUserLocale -UserLocale $UserLocale; return }

    if ($IsAutoYast) { Set-UnattendedYastUserLocale -UserLocale $UserLocale; return }

    Set-UnattendedWindowsUserLocale -UserLocale $UserLocale
}