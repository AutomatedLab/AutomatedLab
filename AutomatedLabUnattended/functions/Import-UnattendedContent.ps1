function Import-UnattendedContent
{
    [CmdletBinding(DefaultParameterSetName = 'Windows')]
    param (
        [Parameter(ParameterSetName = 'Windows', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Kickstart', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Yast', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CloudInit', Mandatory = $true)]
        [string[]]
        $Content,

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

    $command = Get-Command -Name $PSCmdlet.MyInvocation.MyCommand.Name.Replace('Unattended', "Unattended$($PSCmdlet.ParameterSetName)")
    $parameters = Sync-Parameter $command -Parameters $PSBoundParameters
    & $command @parameters
}
