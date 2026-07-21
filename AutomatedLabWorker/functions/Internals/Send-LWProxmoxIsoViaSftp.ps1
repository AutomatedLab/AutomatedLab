function Send-LWProxmoxIsoViaSftp
{
    <#
    .SYNOPSIS
        Uploads a local ISO file to a Proxmox storage over SFTP.

    .DESCRIPTION
        Transfers an ISO file straight into the storage's '<path>/template/iso'
        directory on the target node using SFTP (via the Posh-SSH module). This
        bypasses the Proxmox 'pveproxy' HTTP upload endpoint, which spools the upload
        to a temporary file and can fail for large ISO images (temporary space or
        proxy timeouts). Proxmox picks the file up automatically on the next content
        scan.

        Only file-based storages (dir, nfs, cifs, cephfs) are supported, which is
        where ISO content lives anyway. Requires the Posh-SSH module and SSH access
        to the node.

        Throws on any failure so the caller can decide whether to fall back to HTTP.

    .PARAMETER Node
        The Proxmox node whose storage receives the ISO.

    .PARAMETER Storage
        The target storage identifier.

    .PARAMETER File
        The local ISO file to upload.

    .PARAMETER SshHostName
        The host name or IP address to open the SSH/SFTP connection to.

    .PARAMETER SshCredential
        The SSH credential (a unix account with write access to the storage path,
        typically root).

    .PARAMETER SshPort
        The SSH port. Defaults to 22.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Node,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Storage,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $File,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SshHostName,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        $SshCredential,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [int]
        $SshPort = 22
    )

    Write-LogFunctionEntry

    if (-not (Get-Module -Name Posh-SSH -ListAvailable))
    {
        Write-Error -Message "The Posh-SSH module is required for SFTP uploads but was not found. Install it with 'Install-Module Posh-SSH'." -ErrorAction Stop
        return
    }

    Import-Module -Name Posh-SSH -ErrorAction Stop -Verbose:$false 4>$null

    # Resolve the storage's filesystem path from the cluster storage configuration
    $storageResponse = Invoke-LWProxmoxCallWithRetry -ActivityName "Get storage configuration for '$Storage'" -ScriptBlock { Get-PveStorageIdx -Storage $Storage }
    if ($storageResponse.StatusCode -ne 200 -or -not $storageResponse.Response.data)
    {
        Write-Error -Message "Could not read the configuration of storage '$Storage'." -ErrorAction Stop
        return
    }

    $storageConfig = $storageResponse.Response.data
    $basePath = if ($storageConfig.path) { $storageConfig.path } else { "/mnt/pve/$Storage" }
    $remoteIsoDir = ($basePath.TrimEnd('/')) + '/template/iso'
    $isoName = $File.Name
    $remoteIsoPath = "$remoteIsoDir/$isoName"

    Write-PSFMessage -Message "SFTP target for ISO '$isoName' on node '$Node': ${SshHostName}:$remoteIsoPath"

    $session = New-SFTPSession -ComputerName $SshHostName -Credential $SshCredential -Port $SshPort -AcceptKey -ConnectionTimeout 30 -ErrorAction Stop

    try
    {
        if (-not (Test-SFTPPath -SessionId $session.SessionId -Path $remoteIsoDir))
        {
            Write-PSFMessage -Message "Creating remote ISO directory '$remoteIsoDir'."
            $null = New-SFTPItem -SessionId $session.SessionId -Path $remoteIsoDir -ItemType Directory -Recurse -ErrorAction Stop
        }

        Set-SFTPItem -SessionId $session.SessionId -Path $File.FullName -Destination $remoteIsoDir -Force -ErrorAction Stop

        if (-not (Test-SFTPPath -SessionId $session.SessionId -Path $remoteIsoPath))
        {
            Write-Error -Message "SFTP upload of '$isoName' completed without error but the remote file '$remoteIsoPath' does not exist." -ErrorAction Stop
            return
        }
    }
    finally
    {
        $null = Remove-SFTPSession -SessionId $session.SessionId -ErrorAction SilentlyContinue
    }

    Write-LogFunctionExit
}
