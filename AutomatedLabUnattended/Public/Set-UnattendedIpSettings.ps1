function Set-UnattendedIpSettings
{
    [CmdletBinding(DefaultParameterSetName = 'Windows')]
    param (
        [Parameter(ParameterSetName = 'Windows')]
        [Parameter(ParameterSetName = 'Kickstart')]
        [Parameter(ParameterSetName = 'Yast')]
        [Parameter(ParameterSetName = 'CloudInit')]
        [string]$IpAddress,

        [Parameter(ParameterSetName = 'Windows')]
        [Parameter(ParameterSetName = 'Kickstart')]
        [Parameter(ParameterSetName = 'Yast')]
        [Parameter(ParameterSetName = 'CloudInit')]
        [string]$Gateway,

        [Parameter(ParameterSetName = 'Windows')]
        [Parameter(ParameterSetName = 'Kickstart')]
        [Parameter(ParameterSetName = 'Yast')]
        [Parameter(ParameterSetName = 'CloudInit')]
        [String[]]$DnsServers,

        [Parameter(ParameterSetName = 'Windows')]
        [Parameter(ParameterSetName = 'Kickstart')]
        [Parameter(ParameterSetName = 'Yast')]
        [Parameter(ParameterSetName = 'CloudInit')]
        [string]$DnsDomain,

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