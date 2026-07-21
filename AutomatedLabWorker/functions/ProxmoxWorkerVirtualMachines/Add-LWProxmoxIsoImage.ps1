function Add-LWProxmoxIsoImage
{
    <#
    .SYNOPSIS
        Uploads a local ISO image to a Proxmox storage.

    .DESCRIPTION
        Uploads an ISO file from the local file system to a Proxmox VE storage that
        supports 'iso' content.

        Two transports are available:

        - SFTP (default, preferred): the file is copied straight into the storage's
          '<path>/template/iso' directory on the target node with SFTP (Posh-SSH),
          bypassing the 'pveproxy' HTTP upload endpoint. This is reliable for large
          ISO images, which the HTTP endpoint can fail to accept because 'pveproxy'
          spools the upload to a temporary file. Requires the Posh-SSH module and SSH
          access to the node. When the connection was made with a '@pam' credential,
          that password is reused as the SSH credential unless -SshCredential is given.

        - HTTP: streams the file to the node's upload API endpoint (the same endpoint
          the web UI uses) with 'curl'. Used as an automatic fallback when SFTP is not
          available (no SSH credential or the Posh-SSH module is missing), or when
          -TransferMethod Http is specified.

        The file name on the storage is taken from the source file name and must end
        in '.iso'. If an ISO with the same name already exists on the target storage,
        the upload is skipped unless -Force is specified.

        Requires an active connection to the Proxmox cluster (Connect-LabProxmoxCluster).

    .PARAMETER Node
        The name of the Proxmox node that receives the upload.

    .PARAMETER Path
        The full path to the local ISO file to upload. The file must exist and have
        the '.iso' extension.

    .PARAMETER Storage
        The target storage identifier. Defaults to 'local'.

    .PARAMETER TransferMethod
        The upload transport: 'Auto' (default) prefers SFTP and falls back to HTTP,
        'Sftp' forces SFTP, 'Http' forces the HTTP upload endpoint.

    .PARAMETER SshHostName
        The host to open the SSH/SFTP connection to. Defaults to the host of the
        active Proxmox connection. Provide this to upload to a per-node storage on a
        node other than the one you connected to.

    .PARAMETER SshCredential
        The SSH credential for the SFTP transport. When omitted and the Proxmox
        connection was made with a '@pam' credential, that credential is reused (with
        the realm stripped, e.g. 'root@pam' -> 'root').

    .PARAMETER SshPort
        The SSH port for the SFTP transport. Defaults to 22.

    .PARAMETER Checksum
        Optional expected checksum of the file, verified by Proxmox for HTTP uploads.
        Requires -ChecksumAlgorithm. Ignored by the SFTP transport.

    .PARAMETER ChecksumAlgorithm
        The algorithm used for -Checksum. One of md5, sha1, sha224, sha256, sha384, sha512.

    .PARAMETER TimeoutInSeconds
        Maximum time to wait for the Proxmox HTTP upload task to complete. Defaults to 3600.

    .PARAMETER Force
        Overwrite an existing ISO of the same name on the target storage.

    .PARAMETER PassThru
        Return the uploaded ISO image object (as produced by Get-LWProxmoxIsoImage).

    .EXAMPLE
        Add-LWProxmoxIsoImage -Node 'rz1pinhst101' -Path 'D:\ISOs\WinServer2025.iso'

        Uploads the ISO to the 'local' storage via SFTP (falling back to HTTP if SSH
        is unavailable).

    .EXAMPLE
        Add-LWProxmoxIsoImage -Node 'rz1pinhst101' -Path 'D:\ISOs\big.iso' -Storage 'cephfs' -PassThru

        Uploads a large ISO to the shared 'cephfs' storage via SFTP and returns the result.

    .EXAMPLE
        Add-LWProxmoxIsoImage -Node 'rz1pinhst101' -Path 'D:\ISOs\setup.iso' -TransferMethod Http -Force

        Forces the HTTP upload endpoint and overwrites an existing file.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Reads $Global:PveTicketLast, the connection ticket the Corsinvest.ProxmoxVE.Api module sets on connect, to default the SFTP host and to authenticate the HTTP upload.')]
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Node,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Storage = 'local',

        [Parameter()]
        [ValidateSet('Auto', 'Sftp', 'Http')]
        [string]
        $TransferMethod = 'Auto',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $SshHostName,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        $SshCredential,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [int]
        $SshPort = 22,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Checksum,

        [Parameter()]
        [ValidateSet('md5', 'sha1', 'sha224', 'sha256', 'sha384', 'sha512')]
        [string]
        $ChecksumAlgorithm,

        [Parameter()]
        [ValidateRange(1, 86400)]
        [int]
        $TimeoutInSeconds = 3600,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [switch]
        $PassThru
    )

    Write-LogFunctionEntry

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error -Message 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf))
    {
        Write-Error -Message "The ISO file '$Path' does not exist." -ErrorAction Stop
        return
    }

    $file = Get-Item -LiteralPath $Path
    if ($file.Extension -ne '.iso')
    {
        Write-Error -Message "The file '$Path' does not have the '.iso' extension. Proxmox only accepts '.iso' files as ISO content." -ErrorAction Stop
        return
    }

    if ($Checksum -and -not $ChecksumAlgorithm)
    {
        Write-Error -Message 'When -Checksum is specified, -ChecksumAlgorithm is also required.' -ErrorAction Stop
        return
    }

    $isoName = $file.Name

    # Validate the session ticket before any transfer or destructive overwrite, so an
    # unauthenticated call never deletes an existing ISO.
    $ticket = $Global:PveTicketLast
    if (-not $ticket -or -not $ticket.HostName)
    {
        Write-Error -Message 'No Proxmox connection ticket is available. Call Connect-LabProxmoxCluster first.' -ErrorAction Stop
        return
    }

    # Look for an existing ISO of the same name and skip early when overwriting was
    # not requested.
    $existing = $null
    try { $existing = Get-LWProxmoxIsoImage -Node $Node -Storage $Storage -IsoFile $isoName -ErrorAction Stop } catch { $existing = $null }

    if ($existing -and -not $Force)
    {
        Write-ScreenInfo -Message "An ISO named '$isoName' already exists on storage '$Storage' of node '$Node'. Use -Force to overwrite. Skipping." -Type Warning
        Write-LogFunctionExit
        return
    }

    # Resolve the SSH credential for the SFTP transport: an explicit -SshCredential
    # wins; otherwise reuse the connection credential when it is a '@pam' account.
    $resolvedSshCredential = $SshCredential
    if (-not $resolvedSshCredential -and $TransferMethod -ne 'Http')
    {
        $connectionInfo = Get-LabProxmoxConnectionInfo -IncludeCredential
        if ($connectionInfo -and $connectionInfo.Credential)
        {
            $connectionUser = $connectionInfo.Credential.UserName
            if ($connectionUser -match '@pam$' -or $connectionUser -notmatch '@')
            {
                $sshUser = $connectionUser -replace '@pam$', ''
                $resolvedSshCredential = [System.Management.Automation.PSCredential]::new($sshUser, $connectionInfo.Credential.Password)
            }
        }
    }

    $resolvedSshHostName = if ($SshHostName) { $SshHostName } else { $ticket.HostName }

    if ($TransferMethod -eq 'Sftp' -and -not $resolvedSshCredential)
    {
        Write-Error -Message "TransferMethod 'Sftp' was requested but no SSH credential is available. Connect with a '@pam' credential or pass -SshCredential." -ErrorAction Stop
        return
    }

    $sizeInMb = [math]::Round($file.Length / 1MB, 2)

    if (-not $PSCmdlet.ShouldProcess("storage '$Storage' on node '$Node'", "Upload ISO image '$isoName' ($sizeInMb MB)"))
    {
        Write-LogFunctionExit
        return
    }

    # Overwrite an existing ISO only after all validation has passed.
    if ($existing)
    {
        Write-ScreenInfo -Message "Overwriting existing ISO '$isoName' on storage '$Storage' of node '$Node'." -Type Verbose
        Remove-LWProxmoxIsoImage -Node $Node -Storage $Storage -IsoFile $isoName -Force -Confirm:$false -TimeoutInSeconds $TimeoutInSeconds
    }

    $uploaded = $false

    if ($TransferMethod -ne 'Http' -and $resolvedSshCredential)
    {
        try
        {
            Write-ScreenInfo -Message "Uploading ISO '$isoName' ($sizeInMb MB) to storage '$Storage' on node '$Node' via SFTP ($resolvedSshHostName)..." -Type Info
            Send-LWProxmoxIsoViaSftp -Node $Node -Storage $Storage -File $file -SshHostName $resolvedSshHostName -SshCredential $resolvedSshCredential -SshPort $SshPort
            $uploaded = $true
        }
        catch
        {
            if ($TransferMethod -eq 'Sftp')
            {
                Write-Error -Message "SFTP upload of ISO '$isoName' failed: $($_.Exception.Message)" -ErrorAction Stop
                return
            }
            Write-ScreenInfo -Message "SFTP upload failed, falling back to HTTP. Reason: $($_.Exception.Message)" -Type Warning
        }
    }

    if (-not $uploaded)
    {
        Write-ScreenInfo -Message "Uploading ISO '$isoName' ($sizeInMb MB) to storage '$Storage' on node '$Node' via HTTP..." -Type Info

        $httpParams = @{
            Node             = $Node
            Storage          = $Storage
            File             = $file
            TimeoutInSeconds = $TimeoutInSeconds
        }
        if ($Checksum)
        {
            $httpParams['Checksum'] = $Checksum
            $httpParams['ChecksumAlgorithm'] = $ChecksumAlgorithm
        }

        Send-LWProxmoxIsoViaHttp @httpParams
    }

    Write-ScreenInfo -Message "Successfully uploaded ISO '$isoName' to storage '$Storage' on node '$Node'." -Type Info

    if ($PassThru)
    {
        Get-LWProxmoxIsoImage -Node $Node -Storage $Storage -IsoFile $isoName
    }

    Write-LogFunctionExit
}
