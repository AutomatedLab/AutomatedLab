function Start-LWProxmoxAgentExecutionOnVM
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName
    )

    $proxmoxVms = Get-LWProxmoxVM

    foreach ($name in $ComputerName)
    {
        $vm = $proxmoxVms | Where-Object { $_.Name -eq $name }
        if (-not $vm)
        {
            Write-Error "Proxmox VM '$name' not found."
            continue
        }

        # Parse the command string respecting quoted segments so that paths
        # with spaces (e.g. "HKLM\SOFTWARE\Microsoft\Windows NT\...") are
        # kept as a single argument.
        $commandParts = [System.Collections.Generic.List[string]]::new()
        foreach ($token in [System.Management.Automation.PSParser]::Tokenize($Command, [ref]$null))
        {
            if ($token.Type -in 'String', 'CommandArgument', 'Command', 'Number')
            {
                $commandParts.Add($token.Content)
            }
        }

        # Fallback to simple split if tokenizer returned nothing useful
        if ($commandParts.Count -eq 0)
        {
            $commandParts.AddRange([string[]]($Command.Split(' ')))
        }

        $param = @{
            Node    = $vm.node
            Vmid    = $vm.VmId
            Command = $commandParts.ToArray()
        }
        $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Execute command on VM '$name'" -ScriptBlock { New-PveNodesQemuAgentExec @param }

        if ($result.StatusCode -ne 200)
        {
            Write-Error "Failed to start command on VM '$name'. The error was '$($result.ReasonPhrase)'."
            continue
        }
    }
}
