function Set-UnattendedWorkgroup
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$WorkgroupName,

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

    if ($IsKickstart) { Set-UnattendedKickstartWorkgroup -WorkgroupName $WorkgroupName; return }

    if ($IsAutoYast) { Set-UnattendedYastWorkgroup -WorkgroupName $WorkgroupName; return }

    Set-UnattendedWindowsWorkgroup -WorkgroupName $WorkgroupName
}
