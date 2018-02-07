function Set-UnattendedAdministratorPassword
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Password,
        
        [Parameter(ParameterSetName = 'Kickstart')]
        [switch]
        $IsKickstart,

        [Parameter(ParameterSetName = 'Yast')]
        [switch]
        $IsAutoYast
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
    
    if ($IsKickstart) {Set-UnattendedKickstartAdministratorPassword -Password $Password; return }
    if ($IsAutoYast) { Set-UnattendedYastAdministratorPassword -Password $Password; return }
	Set-UnattendedWindowsAdministratorPassword -Password $Password
}