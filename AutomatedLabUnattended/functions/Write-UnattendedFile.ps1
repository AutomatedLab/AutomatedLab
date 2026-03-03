function Write-UnattendedFile
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Content,

        [Parameter(Mandatory = $true)]
        [string]
        $DestinationPath,

        [switch]
        $Append,

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
