function Set-UnattendedKickstartProductKey
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProductKey
    )

    Write-PSFMessage -Message 'No product key necessary for RHEL/CentOS/Fedora'
}
