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

    foreach ($name in $ComputerName)
    {
        $vm = $proxmoxVms | Where-Object { $_.Name -eq $name }
        if (-not $vm)
        {
            Write-Error "Proxmox VM '$name' not found."
            continue
        }

        # Write to a per-attempt unique temp file, then rename. A fixed '.altmp' name
        # was being locked by Defender real-time scan after a partial write, which then
        # made every retry fail with "being used by another process". Regenerating the
        # temp name each attempt sidesteps the stale lock.
        $maxAttempts = 8
        $writeResult = $null
        $tempFilePath = $null
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++)
        {
            $tempFilePath = '{0}.altmp.{1}' -f $destinationFilePath, ([guid]::NewGuid().ToString('N').Substring(0, 8))
            $ProgressPreference = 'SilentlyContinue'
            $writeResult = New-PveNodesQemuAgentFileWrite -Node $vm.node -Vmid $vm.VmId -File $tempFilePath -Content $content
            if ($writeResult.StatusCode -eq 200) { break }

            Write-PSFMessage -Message "Send file to VM '$name' attempt $attempt of ${maxAttempts} failed: $($writeResult.ReasonPhrase)"
            if ($attempt -lt $maxAttempts)
            {
                if (-not (Test-LabProxmoxConnection))
                {
                    Write-PSFMessage -Message 'Proxmox connection lost. Reconnection was attempted by Test-LabProxmoxConnection.'
                }
                $delay = [math]::Min([int](3 * [math]::Pow(2, $attempt - 1)), 30)
                Start-Sleep -Seconds $delay
            }
        }

        if ($writeResult.StatusCode -eq 200)
        {
            # Rename temp file to final destination (overwrite if exists)
            $renameCmd = "cmd", "/c", "move", "/Y", $tempFilePath, $destinationFilePath
            $renameResult = Invoke-LWProxmoxCallWithRetry -ActivityName "Rename file on VM '$name'" -MaxRetries 3 -RetryDelaySeconds 5 -ScriptBlock { New-PveNodesQemuAgentExec -Node $vm.node -Vmid $vm.VmId -Command $renameCmd }
            if ($renameResult.StatusCode -eq 200)
            {
                Write-ScreenInfo -Message "File '$SourceFilePath' successfully sent to VM '$name' at '$DestinationPath'." -Type Verbose
            }
            else
            {
                Write-Warning "File written as '$tempFilePath' on VM '$name' but rename failed: $($renameResult.ReasonPhrase). The temp file may need manual cleanup."
            }
        }
        else
        {
            Write-Error "Failed to send file to VM '$name' after $maxAttempts attempts. The error was '$($writeResult.ReasonPhrase)'."
        }
    }
}
