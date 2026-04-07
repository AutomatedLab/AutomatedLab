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

        $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Send file to VM '$name'" -MaxRetries 8 -RetryDelaySeconds 3 -ProgressiveBackoff -ScriptBlock { New-PveNodesQemuAgentFileWrite -Node $vm.node -Vmid $vm.VmId -File $destinationFilePath -Content $content }

        if ($result.StatusCode -eq 200)
        {
            Write-ScreenInfo -Message "File '$SourceFilePath' successfully sent to VM '$name' at '$DestinationPath'." -Type Verbose
        }
        else
        {
            Write-Error "Failed to send file to VM '$name'. The error was '$($result.ReasonPhrase)'."
        }
    }
}
