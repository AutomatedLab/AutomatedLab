function Set-UnattendedAdministratorPassword
{
	[CmdletBinding(DefaultParameterSetName = 'Windows')]
	param (
		[Parameter(ParameterSetName = 'Windows', Mandatory = $true)]
		[Parameter(ParameterSetName = 'Kickstart', Mandatory = $true)]
		[Parameter(ParameterSetName = 'Yast', Mandatory = $true)]
		[Parameter(ParameterSetName = 'CloudInit', Mandatory = $true)]
		[string]$Password,

		[Parameter(ParameterSetName = 'Kickstart')]
		[switch]
		$IsKickstart,

		[Parameter(ParameterSetName = 'Yast')]
		[switch]
		$IsAutoYast,

		[Parameter(ParameterSetName = 'CloudInit')]
		[switch]
		$IsCloudInit
	)

	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}

	$command = Get-Command -Name $PSCmdlet.MyInvocation.MyCommand.Name.Replace('Unattended', "Unattended$($PSCmdlet.ParameterSetName)")
	$parameters = Sync-Parameter $command -Parameters $PSBoundParameters
	& $command @parameters
}