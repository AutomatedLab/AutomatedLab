function Set-UnattendedAdministratorName
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Name,
        
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
	
    if ($IsKickstart) { Set-UnattendedKickstartAdministratorName -Name $Name ; return}
    if ($IsAutoYast) { Set-UnattendedYastAdministratorName -Name $Name ; return}
    Set-UnattendedWindowsAdministratorName -Name $Name
}