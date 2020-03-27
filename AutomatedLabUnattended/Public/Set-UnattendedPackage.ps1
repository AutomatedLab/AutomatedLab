function Set-UnattendedPackage
{
	param (
		[Parameter(Mandatory = $true)]
		[string[]]$Package,

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

    if ($IsKickstart) { Set-UnattendedKickstartPackage -Package $Package; return }

    if ($IsAutoYast) { Set-UnattendedYastPackage -Package $Package; return }

    Set-UnattendedWindowsPackage -Package $Package
}