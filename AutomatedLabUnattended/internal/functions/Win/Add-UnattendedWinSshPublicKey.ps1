function Add-UnattendedWinSshPublicKey
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $PublicKey
    )

    Write-PSFMessage -Message "No unattended ssh key import on Windows yet"
}
