function Add-UnattendedRenameNetworkAdapters
{
    param
    (
        [switch]$IsKickstart,
        [switch]$IsAutoYast
    )
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}

    if ($IsKickstart)
    {
        Add-UnattendedKickstartRenameNetworkAdapters
    }
    elseif ($IsAutoYast)
    {
        Add-UnattendedYastRenameNetworkAdapters
    }
    else
    {
        Add-UnattendedWindowsRenameNetworkAdapters
    }
}