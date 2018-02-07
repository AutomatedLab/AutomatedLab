function Set-UnattendedAutoLogon
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$DomainName,
		
		[Parameter(Mandatory = $true)]
		[string]$Username,
		
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
    
    if( $IsKickstart) { Set-UnattendedKickstartAutoLogon -DomainName $DomainName -UserName $UserName -Password $Password}
    if( $IsKickstart) { Set-UnattendedYastAutoLogon -DomainName $DomainName -UserName $UserName -Password $Password}
    Set-UnattendedWindowsAutoLogon -DomainName $DomainName -UserName $UserName -Password $Password
}