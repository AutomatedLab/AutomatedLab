function Set-UnattendedYastAutoLogon
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$DomainName,
		
		[Parameter(Mandatory = $true)]
		[string]$Username,
		
		[Parameter(Mandatory = $true)]
		[string]$Password
    )
    Write-Verbose -Message "Auto-logon not implemented yet for AutoYAST file"
}