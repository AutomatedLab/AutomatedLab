function Set-UnattendedKickstartProductKey
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProductKey
    )

    Write-Verbose -Message 'No product key necessary for RHEL/CentOS/Fedora'
}
