function Set-UnattendedProductKey
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$ProductKey,

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

    if ($IsKickstart) { Set-UnattendedKickstartProductKey -ProductKey $ProductKey; return }

    if ($IsAutoYast) { Set-UnattendedYastProductKey -ProductKey $ProductKey; return }

    Set-UnattendedWindowsProductKey -ProductKey $ProductKey
}