function Get-LabProxmoxConnectionInfo
{
    <#
    .SYNOPSIS
        Returns information about the active Proxmox cluster connection.

    .DESCRIPTION
        Exposes the connection data stored by Connect-LabProxmoxCluster so other
        AutomatedLab modules (for example the worker performing an SFTP based ISO
        upload) can reuse the host, port and - when the connection was made with a
        credential - the credential of the current session.

        Returns nothing when there is no stored connection.

    .PARAMETER IncludeCredential
        When specified and the connection was made with a credential (not an API
        token), the returned object includes the PSCredential in the Credential
        property. Without this switch the Credential property is null.

    .EXAMPLE
        Get-LabProxmoxConnectionInfo

        Returns the host, port and authentication type of the current connection.

    .EXAMPLE
        Get-LabProxmoxConnectionInfo -IncludeCredential

        Additionally returns the stored credential for reuse (for example as the
        SSH credential of an SFTP based ISO upload).
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter()]
        [switch]
        $IncludeCredential
    )

    Write-LogFunctionEntry

    if (-not $script:connectionData)
    {
        Write-LogFunctionExit
        return
    }

    $authType = if ($script:connectionData.ContainsKey('ApiToken')) { 'ApiToken' } else { 'Credential' }

    $credential = if ($IncludeCredential -and $script:connectionData.ContainsKey('Credential'))
    {
        $script:connectionData.Credential
    }
    else
    {
        $null
    }

    [PSCustomObject]@{
        HostName   = $script:connectionData.HostName
        Port       = $script:connectionData.Port
        AuthType   = $authType
        Credential = $credential
    }

    Write-LogFunctionExit
}
