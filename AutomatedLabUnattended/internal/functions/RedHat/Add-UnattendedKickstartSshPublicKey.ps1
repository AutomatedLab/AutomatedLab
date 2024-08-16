function Add-UnattendedKickstartSshPublicKey
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $PublicKey
    )

    Write-PSFMessage -Message "No unattended ssh key import on kickstart yet, we're using %post%"
}
