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

        # Write to a temp file first, then rename. This avoids file-lock conflicts
        # when the target file already exists on the VM from the template and is being
        # scanned by Windows Defender or another process at boot time.
        $tempFilePath = $destinationFilePath + '.altmp'
        $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Send file to VM '$name'" -MaxRetries 8 -RetryDelaySeconds 3 -ProgressiveBackoff -ScriptBlock { New-PveNodesQemuAgentFileWrite -Node $vm.node -Vmid $vm.VmId -File $tempFilePath -Content $content }

        if ($result.StatusCode -eq 200)
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
            Write-Error "Failed to send file to VM '$name'. The error was '$($result.ReasonPhrase)'."
        }
    }
}
