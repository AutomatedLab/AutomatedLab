function Add-UnattendedYastSshPublicKey
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $PublicKey
    )

    Write-PSFMessage -Message "No unattended ssh key import on Autoyast yet"
}
