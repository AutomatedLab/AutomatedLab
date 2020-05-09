function Set-UnattendedAutoLogon
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$DomainName,

		[Parameter(Mandatory = $true)]
		[string]$Username,

		[Parameter(Mandatory = $true)]
		[string]$Password,

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

    if( $IsKickstart) { Set-UnattendedKickstartAutoLogon -DomainName $DomainName -UserName $UserName -Password $Password; return}
    if( $IsAutoYast) { Set-UnattendedYastAutoLogon -DomainName $DomainName -UserName $UserName -Password $Password; return}
    Set-UnattendedWindowsAutoLogon -DomainName $DomainName -UserName $UserName -Password $Password
}