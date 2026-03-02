function Send-LWProxmoxFileCopyToVM
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$SourceFilePath,

        [Parameter()]
        [string]$DestinationPath = 'C:\',

        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName
    )

    if (-not (Test-Path -Path $SourceFilePath))
    {
        Write-Error "Source file '$SourceFilePath' does not exist."
        return
    }

    $content = Get-Content -Path $SourceFilePath -Raw

    $proxmoxVms = Get-LWProxmoxVM

    $fileName = [System.IO.Path]::GetFileName($SourceFilePath)
    $destinationFilePath = Join-Path -Path $DestinationPath -ChildPath $fileName

    $maxRetries = 5
    $retryDelaySec = 15

    foreach ($name in $ComputerName)
    {
        $vm = $proxmoxVms | Where-Object { $_.Name -eq $name }
        if (-not $vm)
        {
            Write-Error "Proxmox VM '$name' not found."
            continue
        }

        $attempt = 0
        $success = $false

        while ($attempt -lt $maxRetries -and -not $success)
        {
            $attempt++
            $result = New-PveNodesQemuAgentFileWrite -Node $vm.node -Vmid $vm.VmId -File $destinationFilePath -Content $content

            if ($result.StatusCode -eq 200)
            {
                Write-ScreenInfo -Message "File '$SourceFilePath' successfully sent to VM '$name' at '$DestinationPath'." -Type Verbose
                $success = $true
            }
            elseif ($result.ReasonPhrase -match 'timeout|EAGAIN' -and $attempt -lt $maxRetries)
            {
                Write-ScreenInfo -Message "QEMU Guest Agent timeout sending file to VM '$name'. Retrying in $retryDelaySec seconds (attempt $attempt of $maxRetries)..." -Type Warning
                Start-Sleep -Seconds $retryDelaySec
            }
            elseif ($attempt -lt $maxRetries)
            {
                Write-ScreenInfo -Message "Failed to send file to VM '$name' (StatusCode '$($result.StatusCode)'). Retrying in $retryDelaySec seconds (attempt $attempt of $maxRetries)..." -Type Warning
                Start-Sleep -Seconds $retryDelaySec
            }
        }

        if (-not $success)
        {
            Write-Error "Failed to send file to VM '$name' after $maxRetries attempts. The error was '$($result.ReasonPhrase)'."
        }
    }
}
