function Set-UnattendedDomain
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
    
    if ($IsKickstart) { Set-UnattendedKickstartDomain -DomainName $DomainName -Username $Username -Password $Password; return }
    if ($IsAutoYast) { Set-UnattendedYastDomain -DomainName $DomainName -Username $Username -Password $Password; return }
    Set-UnattendedWindowsDomain -DomainName $DomainName -Username $Username -Password $Password
}
