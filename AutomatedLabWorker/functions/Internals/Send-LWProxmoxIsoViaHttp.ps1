function Send-LWProxmoxIsoViaHttp
{
    <#
    .SYNOPSIS
        Uploads a local ISO file to a Proxmox storage over the HTTP upload endpoint.

    .DESCRIPTION
        Streams an ISO file to the node's '/nodes/<node>/storage/<storage>/upload'
        API endpoint - the same endpoint the Proxmox web UI uses.

        The endpoint requests a TLS renegotiation while the request body is being
        transferred. The .NET HTTP stack (Invoke-RestMethod and HttpClient) does not
        support server-initiated renegotiation and resets the connection ('An existing
        connection was forcibly closed by the remote host'). This function therefore
        streams the file with the 'curl' executable, which handles the renegotiation
        correctly on Windows, Linux and macOS. The short-lived authentication ticket
        and CSRF token are passed to curl through a temporary config file so they never
        appear on the process command line.

        Because 'pveproxy' spools the upload to a temporary file, this transport can
        fail for very large ISO images; prefer Send-LWProxmoxIsoViaSftp for those.

        Throws on any failure.

    .PARAMETER Node
        The Proxmox node that receives the upload.

    .PARAMETER Storage
        The target storage identifier.

    .PARAMETER File
        The local ISO file to upload.

    .PARAMETER Checksum
        Optional expected checksum, verified by Proxmox after upload. Requires
        -ChecksumAlgorithm.

    .PARAMETER ChecksumAlgorithm
        The algorithm used for -Checksum. One of md5, sha1, sha224, sha256, sha384, sha512.

    .PARAMETER TimeoutInSeconds
        Maximum time to wait for the Proxmox upload task to finish. Defaults to 3600.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Reads $Global:PveTicketLast, the connection ticket the Corsinvest.ProxmoxVE.Api module sets on connect, to reuse the active session authentication for the curl-based upload.')]
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
        $TimeoutInSeconds = 3600
    )

    Write-LogFunctionEntry

    $ticket = $Global:PveTicketLast
    if (-not $ticket -or -not $ticket.HostName)
    {
        Write-Error -Message 'No Proxmox connection ticket is available. Call Connect-LabProxmoxCluster first.' -ErrorAction Stop
        return
    }

    # The PVE upload endpoint requires TLS renegotiation, which the .NET web stack
    # cannot do; curl handles it on every platform. Resolve it as an application to
    # avoid the Windows 'curl' alias for Invoke-WebRequest.
    $curlExecutable = if ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) { 'curl.exe' } else { 'curl' }
    $curlCommand = Get-Command -Name $curlExecutable -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $curlCommand)
    {
        Write-Error -Message "The '$curlExecutable' executable was not found on PATH. It is required to upload ISO images to Proxmox over HTTP because the upload endpoint requires TLS renegotiation that the .NET web stack does not support." -ErrorAction Stop
        return
    }

    $isoName = $File.Name
    $uploadUrl = "https://$($ticket.HostName):$($ticket.Port)/api2/json/nodes/$Node/storage/$Storage/upload"

    # Keep the short-lived ticket / CSRF token off the process command line by
    # passing them through a temporary curl config file that is removed afterwards.
    $configFile = [System.IO.Path]::GetTempFileName()
    $curlOutput = $null
    $curlExitCode = -1
    try
    {
        $configLines = [System.Collections.Generic.List[string]]::new()
        $configLines.Add('silent')
        $configLines.Add('show-error')
        if ($ticket.SkipCertificateCheck) { $configLines.Add('insecure') }

        if ($ticket.ApiToken)
        {
            $configLines.Add("header = `"Authorization: PVEAPIToken $($ticket.ApiToken)`"")
        }
        else
        {
            $configLines.Add("cookie = `"PVEAuthCookie=$($ticket.Ticket)`"")
            $configLines.Add("header = `"CSRFPreventionToken: $($ticket.CSRFPreventionToken)`"")
        }

        Set-Content -LiteralPath $configFile -Value $configLines -Encoding ascii

        $curlArgs = [System.Collections.Generic.List[string]]::new()
        $curlArgs.Add('--config'); $curlArgs.Add($configFile)
        $curlArgs.Add('--form'); $curlArgs.Add('content=iso')
        $curlArgs.Add('--form'); $curlArgs.Add("filename=@$($File.FullName)")
        if ($Checksum)
        {
            $curlArgs.Add('--form'); $curlArgs.Add("checksum=$Checksum")
            $curlArgs.Add('--form'); $curlArgs.Add("checksum-algorithm=$ChecksumAlgorithm")
        }
        $curlArgs.Add('--write-out'); $curlArgs.Add("`nHTTP_STATUS:%{http_code}")
        $curlArgs.Add($uploadUrl)

        $curlOutput = & $curlCommand.Source @curlArgs 2>&1
        $curlExitCode = $LASTEXITCODE
    }
    finally
    {
        Remove-Item -LiteralPath $configFile -Force -ErrorAction SilentlyContinue
    }

    $outputText = ($curlOutput | Out-String)

    if ($curlExitCode -ne 0)
    {
        Write-Error -Message "curl failed to upload ISO '$isoName' (exit code $curlExitCode): $outputText" -ErrorAction Stop
        return
    }

    $httpStatus = if ($outputText -match 'HTTP_STATUS:(\d+)') { [int]$Matches[1] } else { -1 }
    $responseBody = ($outputText -replace '(?s)\r?\nHTTP_STATUS:\d+\s*$', '').Trim()

    if ($httpStatus -ne 200)
    {
        Write-Error -Message "Proxmox rejected the upload of ISO '$isoName' with HTTP status $httpStatus. Response: $responseBody" -ErrorAction Stop
        return
    }

    $upid = $null
    try { $upid = ($responseBody | ConvertFrom-Json -ErrorAction Stop).data } catch { $upid = $null }

    if ($upid -and "$upid" -like 'UPID:*')
    {
        Write-PSFMessage -Message "Upload of '$isoName' accepted. Waiting for task '$upid' to finish."
        $exitStatus = Wait-LWProxmoxTasksStatus -Upid $upid -Node $Node -DesiredValues @{ status = 'stopped' } -TimeoutInSeconds $TimeoutInSeconds

        if ($exitStatus -ne 'OK')
        {
            Write-Error -Message "The Proxmox upload task for '$isoName' finished with a non-OK status: '$exitStatus'." -ErrorAction Stop
            return
        }
    }

    Write-LogFunctionExit
}
