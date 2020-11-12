function Set-UnattendedLocalIntranetSites
{
	param (
		[Parameter(Mandatory = $true)]
		[string[]]$Values,

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

    if ($IsKickstart) { Set-UnattendedKickstartLocalIntranetSites -Values $Values; return }

    if ($IsAutoYast) { Set-UnattendedYastLocalIntranetSites -Values $Values; return }

    Set-UnattendedWindowsLocalIntranetSites -Values $Values
}