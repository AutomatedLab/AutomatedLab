function Add-UnattendedRenameNetworkAdapters
{
	[CmdletBinding(DefaultParameterSetName = 'Windows')]
    param
    (
        [Parameter(ParameterSetName='Kickstart')]
        [switch]
        $IsKickstart,

        [Parameter(ParameterSetName='Yast')]
        [switch]
        $IsAutoYast,

        [Parameter(ParameterSetName='CloudInit')]
        [switch]
        $IsCloudInit
    )

	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}

    $command = Get-Command -Name $PSCmdlet.MyInvocation.MyCommand.Name.Replace('Unattended', "Unattended$($PSCmdlet.ParameterSetName)")
    & $command
}